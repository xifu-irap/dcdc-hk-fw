-- -------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2023-2030 Ken-ji de la ROSA, IRAP Toulouse.
-- -------------------------------------------------------------------------------------------------------------
--                            This file is part of the ATHENA X-IFU DRE Telemetry and Telecommand Firmware.
--
--                            dcdc-hk-fw is free software: you can redistribute it and/or modify
--                            it under the terms of the GNU General Public License as published by
--                            the Free Software Foundation, either version 3 of the License, or
--                            (at your option) any later version.
--
--                            This program is distributed in the hope that it will be useful,
--                            but WITHOUT ANY WARRANTY; without even the implied warranty of
--                            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--                            GNU General Public License for more details.
--
--                            You should have received a copy of the GNU General Public License
--                            along with this program.  If not, see <https://www.gnu.org/licenses/>.
-- -------------------------------------------------------------------------------------------------------------
--    email                   kenji.delarosa@alten.com
--    @file                   spi_master.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module does the following tasks:
--      . generate a spi clock from the system clock
--      . perform a spi communication:
--          . data serialization for the writting/reading
--          . data de-serialization for the reading
--
--   Note: (see: https://www.analog.com/en/analog-dialogue/articles/introduction-to-spi-interface.html)
--    SPI_MODE |CPOL|CPHA| clock polarity (idle state)| clock data sampling | clock data shift out
--    0        |  0 | 0  | 0                          | rising_edge         | falling_edge
--    1        |  0 | 1  | 0                          | falling_edge        | rising_edge
--    2        |  1 | 0  | 1                          | rising_edge         | falling_edge
--    3        |  1 | 1  | 1                          | falling_edge        | rising_edge
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity spi_master is
  generic
    (
      -- clock polarity
      g_CPOL                 : std_logic := '0';
      -- clock phase
      g_CPHA                 : std_logic := '0';
      -- input system clock frequency  (expressed in Hz). The range is ]2*g_SPI_FREQUENCY_MAX_HZ: max_integer_value]
      g_SYSTEM_FREQUENCY_HZ  : natural   := 128_000_000;
      -- output max spi clock frequency (expressed in Hz)
      g_SPI_FREQUENCY_MAX_HZ : natural   := 20_000_000;
      -- Number of clock period for mosi signal delay from state machine to the output
      g_MOSI_DELAY           : natural   := 0;
      -- Number of clock period for miso signal delay from spi pin input to spi master input
      g_MISO_DELAY           : natural   := 0;
      -- Data bus size
      g_DATA_WIDTH           : natural   := 16

      );
  port
    (
      -- Clock
      i_clk           : in  std_logic;
      -- Reset
      i_rst           : in  std_logic;
      -- write side
      ---------------------------------------------------------------------
      -- 1:wr , 0:rd
      i_wr_rd         : in  std_logic;
      -- 1: MSB bits sent first, 0: LSB bits sent first
      i_tx_msb_first  : in  std_logic;
      -- Start transmit ('0' = Inactive, '1' = Active)
      i_tx_data_valid : in  std_logic;
      -- Data to transmit (stall on MSB)
      i_tx_data       : in  std_logic_vector(g_DATA_WIDTH -1 downto 0);
      -- Transmit link busy ('0' = Busy, '1' = Not Busy)
      o_ready         : out std_logic;
      -- pulse on finish (end of spi transaction: wr or rd)
      o_finish        : out std_logic;
      -- rd side
      ---------------------------------------------------------------------
      -- received data valid
      o_rx_data_valid : out std_logic;
      -- received data (device spi register value)
      o_rx_data       : out std_logic_vector(g_DATA_WIDTH -1 downto 0);
      ---------------------------------------------------------------------
      -- spi interface
      ---------------------------------------------------------------------
      -- SPI MISO (Master Input - Slave Output)
      i_miso          : in  std_logic;
      -- SPI Serial Clock
      o_sclk          : out std_logic;
      -- SPI Chip Select ('0' = Active, '1' = Inactive)
      o_cs_n          : out std_logic;
      -- SPI MOSI (Master Output - Slave Input)
      o_mosi          : out std_logic
      );
end entity spi_master;

architecture RTL of spi_master is

  -- counter width (expressed in bits)
  constant c_CNT_BIT_WIDTH : integer := integer(ceil(log2(real(i_tx_data'length))));
  -- max counter value
  constant c_CNT_MAX_VALUE : integer := i_tx_data'length - 1;  -- -1 start from 0,

---------------------------------------------------------------------
-- clock generator
---------------------------------------------------------------------
  -- spi clock
  signal sclk_tmp              : std_logic;
  -- pulse when the spi data needs to be shifted
  signal pulse_data_shift_tmp  : std_logic;
  -- pulse when the spi data needs to be sampled
  signal pulse_data_sample_tmp : std_logic;

---------------------------------------------------------------------
-- write state machine
---------------------------------------------------------------------
  -- fsm type declaration
  type t_wr_state is (E_RST, E_WAIT, E_SET_CS0, E_SET_CS1, E_SHIFT_DATA, E_UNSET_CS);

   -- state
  signal sm_wr_state_next : t_wr_state;
  -- state (registered)
  signal sm_wr_state_r1   : t_wr_state := E_RST;

  -- tx spi clock
  signal tx_sclk_next : std_logic;
  -- tx spi clock (registered)
  signal tx_sclk_r1   : std_logic := g_CPOL;

  -- tx spi chip select
  signal tx_cs_n_next : std_logic;
  -- tx spi chip select (registered)
  signal tx_cs_n_r1   : std_logic := '1';

  -- tx data_valid
  signal tx_data_valid_next : std_logic;
  -- tx data_valid (registered)
  signal tx_data_valid_r1   : std_logic := '0';

  -- tx data
  signal tx_data_next : std_logic_vector(i_tx_data'range);
  -- tx data (registered)
  signal tx_data_r1   : std_logic_vector(i_tx_data'range) := (others => '0');

  -- ready
  signal ready_next : std_logic;
  -- ready (registered)
  signal ready_r1   : std_logic := '0';

   -- pulse finish
  signal finish_next : std_logic;
  -- pulse finish (registered)
  signal finish_r1   : std_logic := '0';

  -- data bit counter
  signal tx_cnt_bit_next : unsigned(c_CNT_BIT_WIDTH - 1 downto 0);
  -- data bit counter (registered)
  signal tx_cnt_bit_r1   : unsigned(c_CNT_BIT_WIDTH - 1 downto 0);

  -- read data_valid
  signal rx_data_valid_next : std_logic;
  -- read data_valid (registered)
  signal rx_data_valid_r1   : std_logic := '0';

  -- spi mode: read enable
  signal rx_rd_en_next : std_logic;
  -- spi mode: read enable (registered)
  signal rx_rd_en_r1   : std_logic := '0';

  -- spi mode
  signal rd_en_next       : std_logic;
  -- spi mode (registred)
  signal rd_en_r1         : std_logic := '0';
---------------------------------------------------------------------
-- optional: tx pipeline
---------------------------------------------------------------------
  -- delayed: spi mode: read enable
  signal rx_rd_en_rx      : std_logic;
  -- delayed: read data valid
  signal rx_data_valid_rx : std_logic;
  -- delayed: tx finish
  signal tx_finish_rx     : std_logic;
  -- delayed: tx spi clock
  signal tx_sclk_rx       : std_logic;
  -- delayed: tx spi chip select
  signal tx_cs_n_rx       : std_logic;
  -- delayed: tx data
  signal tx_data_rx       : std_logic := '0';

---------------------------------------------------------------------
-- optional: rx pipeline
---------------------------------------------------------------------
-- delayed: rx finish (from tx version)
  signal rx_finish_ry     : std_logic;
  -- delayed: rx data_valid (from tx version)
  signal rx_data_valid_ry : std_logic;
  -- delayed: rx read enable (from tx version)
  signal rx_rd_en_ry      : std_logic;

  -- rx finish
  signal rx_finish_all_rz : std_logic                         := '0';
  -- rx read data_valid
  signal rx_data_valid_rz : std_logic                         := '0';
  -- rx read data
  signal rx_data_rz       : std_logic_vector(o_rx_data'range) := (others => '0');

begin

  inst_spi_master_clock_gen : entity work.spi_master_clock_gen
    generic map(
      g_CPOL                 => g_CPOL,
      g_CPHA                 => g_CPHA,
      g_SYSTEM_FREQUENCY_HZ  => g_SYSTEM_FREQUENCY_HZ,
      g_SPI_FREQUENCY_MAX_HZ => g_SPI_FREQUENCY_MAX_HZ
      )
    port map(
      i_clk               => i_clk,
      i_rst               => i_rst,
      ---------------------------------------------------------------------
      -- output
      ---------------------------------------------------------------------
      o_sclk              => sclk_tmp,
      o_pulse_data_sample => pulse_data_sample_tmp,
      o_pulse_data_shift  => pulse_data_shift_tmp
      );

---------------------------------------------------------------------
-- Tx: write data
--   According the different SPI mode defined by the (g_CPOL,g_CPHA)
--   it generates the SPI protocol (chip select, data serialization,...)
---------------------------------------------------------------------
  p_wr_decode_state : process (i_tx_data, i_tx_data_valid, i_tx_msb_first,
                               i_wr_rd, pulse_data_sample_tmp,
                               pulse_data_shift_tmp, rd_en_r1, sclk_tmp,
                               sm_wr_state_r1, ready_r1, tx_cnt_bit_r1,
                               tx_cs_n_r1, tx_data_r1, tx_sclk_r1) is
  begin
    tx_cnt_bit_next    <= tx_cnt_bit_r1;
    tx_sclk_next       <= tx_sclk_r1;
    tx_cs_n_next       <= tx_cs_n_r1;
    rd_en_next         <= rd_en_r1;
    tx_data_valid_next <= '0';
    tx_data_next       <= tx_data_r1;
    ready_next         <= ready_r1;
    finish_next        <= '0';
    rx_data_valid_next <= '0';
    rx_rd_en_next      <= '0';

    case sm_wr_state_r1 is
      when E_RST =>
        tx_cs_n_next     <= '1';
        tx_sclk_next     <= g_CPOL;
        tx_cnt_bit_next  <= (others => '0');
        ready_next       <= '0';
        sm_wr_state_next <= E_WAIT;

      when E_WAIT =>
        if i_tx_data_valid = '1' then
          if i_tx_msb_first = '1' then
            tx_data_next <= i_tx_data;
          else
            -- reverse the bit order: bit(x) -> bit(0), bit(x-1) -> bit1 and so on.
            for i in i_tx_data'range loop
              tx_data_next(i_tx_data'high - i) <= i_tx_data(i);
            end loop;
          end if;

          rd_en_next <= not(i_wr_rd);

          tx_cs_n_next     <= '1';
          tx_sclk_next     <= g_CPOL;
          tx_cnt_bit_next  <= (others => '0');
          ready_next       <= '0';
          sm_wr_state_next <= E_SET_CS0;
        else
          ready_next       <= '1';
          sm_wr_state_next <= E_WAIT;
        end if;

      when E_SET_CS0 =>
        tx_cs_n_next <= '0';
        if pulse_data_shift_tmp = '1' then
          sm_wr_state_next <= E_SET_CS1;
        else
          sm_wr_state_next <= E_SET_CS0;
        end if;

      when E_SET_CS1 =>
        tx_cs_n_next <= '0';
        if pulse_data_shift_tmp = '1' then
          tx_sclk_next     <= sclk_tmp;
          sm_wr_state_next <= E_SHIFT_DATA;
        else
          sm_wr_state_next <= E_SET_CS1;
        end if;

      when E_SHIFT_DATA =>

        if (pulse_data_shift_tmp = '1') then
          -- shift on the falling edge
          tx_data_valid_next <= '1';
          tx_cnt_bit_next    <= tx_cnt_bit_r1 + 1;
          tx_data_next       <= tx_data_r1(tx_data_r1'high - 1 downto 0) & '0';
        else
          tx_data_valid_next <= '0';
          tx_data_next       <= tx_data_r1;
          tx_cnt_bit_next    <= tx_cnt_bit_r1;
        end if;
        rx_data_valid_next <= pulse_data_sample_tmp;

        if (pulse_data_shift_tmp = '1') then
          if tx_cnt_bit_r1 = to_unsigned(c_CNT_MAX_VALUE, tx_cnt_bit_r1'length) then
            tx_sclk_next     <= g_CPOL;
            --tx_cs_n_next     <= '1';
            rx_rd_en_next    <= rd_en_r1;
            sm_wr_state_next <= E_UNSET_CS;
          else
            tx_sclk_next     <= sclk_tmp;
            sm_wr_state_next <= E_SHIFT_DATA;
          end if;
        else
          tx_sclk_next     <= sclk_tmp;
          sm_wr_state_next <= E_SHIFT_DATA;
        end if;

      when E_UNSET_CS =>
        if (pulse_data_shift_tmp = '1') then
          tx_cs_n_next     <= '1';
          finish_next      <= '1';
          sm_wr_state_next <= E_WAIT;
        else
          sm_wr_state_next <= E_UNSET_CS;
        end if;
      when others =>
        sm_wr_state_next <= E_RST;
    end case;
  end process p_wr_decode_state;


  ---------------------------------------------------------------------
  -- State process : register signals
  ---------------------------------------------------------------------
  p_wr_state : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      if i_rst = '1' then
        sm_wr_state_r1 <= E_RST;
      else
        sm_wr_state_r1 <= sm_wr_state_next;
      end if;
      tx_cnt_bit_r1    <= tx_cnt_bit_next;
      tx_sclk_r1       <= tx_sclk_next;
      tx_cs_n_r1       <= tx_cs_n_next;
      tx_data_valid_r1 <= tx_data_valid_next;
      rd_en_r1         <= rd_en_next;
      tx_data_r1       <= tx_data_next;
      ready_r1         <= ready_next;
      finish_r1        <= finish_next;

      rx_data_valid_r1 <= rx_data_valid_next;
      rx_rd_en_r1      <= rx_rd_en_next;

    end if;
  end process p_wr_state;

  -- output: to the user
  o_ready <= ready_r1;

  ---------------------------------------------------------------------
  -- optional tx pipeline
  ---------------------------------------------------------------------
  gen_pipe_tx_no_init : if true generate
    -- temporary input pipe
    signal data_tmp0 : std_logic_vector(4 downto 0);
    -- temporary output pipe
    signal data_tmp1 : std_logic_vector(4 downto 0);
  begin
    data_tmp0(4) <= rx_rd_en_r1;
    data_tmp0(3) <= rx_data_valid_r1;
    data_tmp0(2) <= finish_r1;
    data_tmp0(1) <= tx_sclk_r1;
    data_tmp0(0) <= tx_data_r1(tx_data_r1'high);

    inst_pipeliner_tx : entity work.pipeliner
      generic map(
        g_NB_PIPES   => g_MOSI_DELAY,
        g_DATA_WIDTH => data_tmp0'length
        )
      port map(
        i_clk  => i_clk,
        i_data => data_tmp0,
        o_data => data_tmp1
        );
    rx_rd_en_rx      <= data_tmp1(4);
    rx_data_valid_rx <= data_tmp1(3);
    tx_finish_rx     <= data_tmp1(2);
    tx_sclk_rx       <= data_tmp1(1);
    tx_data_rx       <= data_tmp1(0);
  end generate gen_pipe_tx_no_init;

  -- pipe with special init value
  gen_pipe_tx : if true generate
    -- temporary input pipe
    signal data_tmp0 : std_logic_vector(0 downto 0);
    -- temporary output pipe
    signal data_tmp1 : std_logic_vector(0 downto 0);
  begin
    data_tmp0(0) <= tx_cs_n_r1;
    inst_pipeliner_with_init : entity work.pipeliner_with_init
      generic map(
        g_INIT       => '1',
        -- number of consecutives registers. Possibles values: [0, integer max value[
        g_NB_PIPES   => g_MOSI_DELAY,
        -- width of the input/output data.  Possibles values: [1, integer max value[
        g_DATA_WIDTH => data_tmp0'length
        )
      port map(
        i_clk  => i_clk,
        i_data => data_tmp0,
        o_data => data_tmp1
        );

    tx_cs_n_rx <= data_tmp1(0);
  end generate gen_pipe_tx;


  ---------------------------------------------------------------------
  -- output
  ---------------------------------------------------------------------
  -- to the IOs
  o_sclk <= tx_sclk_rx;
  o_cs_n <= tx_cs_n_rx;
  o_mosi <= tx_data_rx;

  ---------------------------------------------------------------------
  --  compensate the MISO delay from io
  --
  --  Note: the delay depends on the IO management
  ---------------------------------------------------------------------
  gen_pipe_rx : if true generate
    -- temporary input pipe
    signal data_tmp0 : std_logic_vector(2 downto 0);
    -- temporary output pipe
    signal data_tmp1 : std_logic_vector(2 downto 0);
  begin
    data_tmp0(2) <= rx_rd_en_rx;
    data_tmp0(1) <= tx_finish_rx;
    data_tmp0(0) <= rx_data_valid_rx;

    inst_pipeliner_rx : entity work.pipeliner
      generic map(
        g_NB_PIPES   => g_MISO_DELAY,
        g_DATA_WIDTH => data_tmp0'length
        )
      port map(
        i_clk  => i_clk,
        i_data => data_tmp0,
        o_data => data_tmp1
        );
    rx_rd_en_ry      <= data_tmp1(2);
    rx_finish_ry     <= data_tmp1(1);
    rx_data_valid_ry <= data_tmp1(0);
  end generate gen_pipe_rx;

  ---------------------------------------------------------------------
  -- Tx Read data
  ---------------------------------------------------------------------
  p_read : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      rx_finish_all_rz <= rx_finish_ry;
      rx_data_valid_rz <= rx_rd_en_ry;
      if rx_data_valid_ry = '1' then
        rx_data_rz <= rx_data_rz(rx_data_rz'high - 1 downto 0) & i_miso;
      end if;
    end if;
  end process p_read;
  ---------------------------------------------------------------------
  -- output
  ---------------------------------------------------------------------
  o_rx_data_valid <= rx_data_valid_rz;
  o_rx_data       <= rx_data_rz;
  o_finish        <= rx_finish_all_rz;

end architecture RTL;
