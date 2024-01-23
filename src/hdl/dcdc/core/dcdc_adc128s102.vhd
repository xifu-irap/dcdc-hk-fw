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
--    @file                   dcdc_adc128s102.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--   @details
--
--   This is the top level of the dcdc function
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_system_dcdc.all;

entity dcdc_adc128s102 is
  generic (
    -- enable the DEBUG by ILA
    g_DEBUG : boolean := false
    );
  port(
    -- clock
    i_clk : in std_logic;
    -- reset
    i_rst : in std_logic;

    -- reset error flag(s)
    i_rst_status  : in std_logic;
    -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s)
    i_debug_pulse : in std_logic;

    -- Valid start ADCs' acquisition
    i_adc_start_valid : in std_logic;
    -- start ADCs' acquisition
    i_adc_start       : in std_logic;

    -- '1': tx_ready to start an acquisition, '0': busy
    o_ready : out std_logic;

    -- ADC values valid
    o_adc_valid : out std_logic;
    -- ADC7 value
    o_adc7      : out std_logic_vector(15 downto 0);
    -- ADC6 value
    o_adc6      : out std_logic_vector(15 downto 0);
    -- ADC5 value
    o_adc5      : out std_logic_vector(15 downto 0);
    -- ADC4 value
    o_adc4      : out std_logic_vector(15 downto 0);
    -- ADC3 value
    o_adc3      : out std_logic_vector(15 downto 0);
    -- ADC2 value
    o_adc2      : out std_logic_vector(15 downto 0);
    -- ADC1 value
    o_adc1      : out std_logic_vector(15 downto 0);
    -- ADC0 value
    o_adc0      : out std_logic_vector(15 downto 0);

    ---------------------------------------------------------------------
    -- spi interface
    ---------------------------------------------------------------------
    -- SPI MISO
    i_spi_miso : in  std_logic;
    -- SPI MOSI
    o_spi_mosi : out std_logic;
    -- SPI clock
    o_spi_sclk : out std_logic;
    -- SPI chip select
    o_spi_cs_n : out std_logic;

    ---------------------------------------------------------------------
    -- Status/errors
    ---------------------------------------------------------------------
    o_errors : out std_logic_vector(15 downto 0);
    o_status : out std_logic_vector(7 downto 0)
    );
end entity dcdc_adc128s102;

architecture RTL of dcdc_adc128s102 is
-- define the width of the address field.
  constant c_ADDR_WIDTH : integer                             := 3;
-- define ADDR7 value
  constant c_ADDR7      : unsigned(c_ADDR_WIDTH - 1 downto 0) := to_unsigned(7, c_ADDR_WIDTH);
-- define ADDR6 value
  constant c_ADDR6      : unsigned(c_ADDR_WIDTH - 1 downto 0) := to_unsigned(6, c_ADDR_WIDTH);
-- define ADDR5 value
  constant c_ADDR5      : unsigned(c_ADDR_WIDTH - 1 downto 0) := to_unsigned(5, c_ADDR_WIDTH);
-- define ADDR4 value
  constant c_ADDR4      : unsigned(c_ADDR_WIDTH - 1 downto 0) := to_unsigned(4, c_ADDR_WIDTH);
-- define ADDR3 value
  constant c_ADDR3      : unsigned(c_ADDR_WIDTH - 1 downto 0) := to_unsigned(3, c_ADDR_WIDTH);
-- define ADDR2 value
  constant c_ADDR2      : unsigned(c_ADDR_WIDTH - 1 downto 0) := to_unsigned(2, c_ADDR_WIDTH);
-- define ADDR1 value
  constant c_ADDR1      : unsigned(c_ADDR_WIDTH - 1 downto 0) := to_unsigned(1, c_ADDR_WIDTH);
-- define ADDR0 value
  constant c_ADDR0      : unsigned(c_ADDR_WIDTH - 1 downto 0) := to_unsigned(0, c_ADDR_WIDTH);

---------------------------------------------------------------------
-- state machine
---------------------------------------------------------------------
  -- detect an start acquisition
  signal start         : std_logic;
-- fsm type declaration
  type t_state is (E_RST, E_INIT_LOAD_ADDR, E_INIT_TX_END, E_WAIT, E_RD_ADC0, E_RD_ADC1, E_RD_ADC2, E_RD_ADC3, E_RD_ADC4, E_RD_ADC5, E_RD_ADC6, E_RD_ADC7, E_WAIT_TX_END);
  -- state
  signal sm_state_next : t_state;
  -- state (registered)
  signal sm_state_r1   : t_state := E_RST;

  -- tx_data valid
  signal tx_data_valid_next : std_logic;
  -- delayed tx_data valid
  signal tx_data_valid_r1   : std_logic;

  -- tx_addr
  signal tx_addr_next : unsigned(c_ADDR_WIDTH - 1 downto 0);
  -- delayed tx_addr
  signal tx_addr_r1   : unsigned(c_ADDR_WIDTH - 1 downto 0);

  -- rx_sel
  signal rx_sel_next : unsigned(c_ADDR_WIDTH - 1 downto 0);
  -- delayed rx_sel
  signal rx_sel_r1   : unsigned(c_ADDR_WIDTH - 1 downto 0);

  -- fsm ready
  signal ready_next : std_logic;
  -- delayed fsm ready
  signal ready_r1   : std_logic;

  -- error
  signal error_next : std_logic;
  -- delayed error
  signal error_r1   : std_logic;

  -- tx_data
  signal tx_data_tmp : std_logic_vector(15 downto 0);

  ---------------------------------------------------------------------
  -- spi_master
  ---------------------------------------------------------------------
  -- 1: MSB bits sent first, 0: LSB bits sent first
  signal tx_msb_first : std_logic;
  -- tx_mode (1:wr , 0:rd)
  signal tx_wr_rd     : std_logic;

  -- SPI Transmit link busy ('0' = Busy, '1' = Not Busy)
  signal tx_ready  : std_logic;
  -- pulse on finish (end of spi transaction: wr or rd)
  signal tx_finish : std_logic;

  -- received data valid
  signal rx_data_valid : std_logic;
  -- received data (device spi register value)
  signal rx_data       : std_logic_vector(15 downto 0);

  -- SPI MISO
  signal spi_miso : std_logic;
  -- SPI MOSI
  signal spi_mosi : std_logic;
  -- SPI clock
  signal spi_sclk : std_logic;
  -- SPI chip select
  signal spi_cs_n : std_logic;

  ---------------------------------------------------------------------
  -- Select the ADCs
  ---------------------------------------------------------------------
  -- ADC values valid
  signal adc_valid_r2 : std_logic;
  -- ADC7 value
  signal adc7_r2      : std_logic_vector(o_adc7'range);
  -- ADC6 value
  signal adc6_r2      : std_logic_vector(o_adc6'range);
  -- ADC5 value
  signal adc5_r2      : std_logic_vector(o_adc5'range);
  -- ADC4 value
  signal adc4_r2      : std_logic_vector(o_adc4'range);
  -- ADC3 value
  signal adc3_r2      : std_logic_vector(o_adc3'range);
  -- ADC2 value
  signal adc2_r2      : std_logic_vector(o_adc2'range);
  -- ADC1 value
  signal adc1_r2      : std_logic_vector(o_adc1'range);
  -- ADC0 value
  signal adc0_r2      : std_logic_vector(o_adc0'range);

  ---------------------------------------------------------------------
  -- error latching
  ---------------------------------------------------------------------
  -- define the width of the temporary errors signals
  constant c_NB_ERRORS : integer := 1;
  -- temporary input errors
  signal error_tmp     : std_logic_vector(c_NB_ERRORS - 1 downto 0);
  -- temporary output errors
  signal error_tmp_bis : std_logic_vector(c_NB_ERRORS - 1 downto 0);

begin

  start <= '1' when i_adc_start_valid = '1' and i_adc_start = '1' else '0';

  ---------------------------------------------------------------------
  -- ADC128S102 SPI device: For each received command, sequentially read the following ADCs:
  --   . ADC0 -> ADC1 -> ... -> ADC7
  ---------------------------------------------------------------------
  -- The steps are:
  --    1. On reset, for the next read access, force the address of the spi device at @0x0
  --    2. wait a new command
  --    3. sequencially read the following ADCs: ADC0 -> ADC1 -> ... -> ADC7
  --    4. Repeat 2. and 3.
  p_decode_state : process (ready_r1, rx_sel_r1, sm_state_r1, start,
                            tx_addr_r1, tx_finish, tx_ready) is
  begin
    -- default value
    tx_data_valid_next <= '0';
    tx_addr_next       <= tx_addr_r1;
    rx_sel_next        <= rx_sel_r1;
    error_next         <= '0';
    ready_next         <= ready_r1;

    case sm_state_r1 is
      when E_RST =>
        ready_next    <= '0';
        sm_state_next <= E_INIT_LOAD_ADDR;

      when E_INIT_LOAD_ADDR =>  -- force the spi device to start @0x0 for the next read access
        if tx_ready = '1' then
          tx_data_valid_next <= '1';
          tx_addr_next       <= c_ADDR0;
          sm_state_next      <= E_INIT_TX_END;
        else
          sm_state_next <= E_INIT_LOAD_ADDR;
        end if;

      when E_INIT_TX_END =>  -- the SPI device is loaded with the @0x0
        if tx_finish = '1' then
          sm_state_next <= E_WAIT;
        else
          sm_state_next <= E_INIT_TX_END;
        end if;

      when E_WAIT =>                    -- wait a new command
        if start = '1' then
          ready_next    <= '0';
          sm_state_next <= E_RD_ADC0;
        else
          ready_next    <= '1';
          sm_state_next <= E_WAIT;
        end if;

      when E_RD_ADC0 =>
        if tx_ready = '1' then
          tx_data_valid_next <= '1';
          -- compute the address for the next read access
          tx_addr_next       <= c_ADDR1;
          -- select the read ADC register
          rx_sel_next        <= c_ADDR0;
          -- read ADC word
          sm_state_next      <= E_WAIT_TX_END;
        else
          sm_state_next <= E_RD_ADC0;
        end if;


      when E_RD_ADC1 =>

        if tx_ready = '1' then
          tx_data_valid_next <= '1';
          -- compute the address for the next read access
          tx_addr_next       <= c_ADDR2;
          -- select the read ADC register
          rx_sel_next        <= c_ADDR1;
          -- read ADC word
          sm_state_next      <= E_WAIT_TX_END;
        else
          sm_state_next <= E_RD_ADC1;
        end if;

      when E_RD_ADC2 =>

        if tx_ready = '1' then
          tx_data_valid_next <= '1';
          -- compute the address for the next read access
          tx_addr_next       <= c_ADDR3;
          -- select the read ADC register
          rx_sel_next        <= c_ADDR2;
          -- read ADC word
          sm_state_next      <= E_WAIT_TX_END;
        else
          sm_state_next <= E_RD_ADC2;
        end if;

      when E_RD_ADC3 =>

        if tx_ready = '1' then
          tx_data_valid_next <= '1';
          -- compute the address for the next read access
          tx_addr_next       <= c_ADDR4;
          -- select the read ADC register
          rx_sel_next        <= c_ADDR3;
          -- read ADC word
          sm_state_next      <= E_WAIT_TX_END;
        else
          sm_state_next <= E_RD_ADC3;
        end if;

      when E_RD_ADC4 =>

        if tx_ready = '1' then
          tx_data_valid_next <= '1';
          -- compute the address for the next read access
          tx_addr_next       <= c_ADDR5;
          -- select the read ADC register
          rx_sel_next        <= c_ADDR4;
          -- read ADC word
          sm_state_next      <= E_WAIT_TX_END;
        else
          sm_state_next <= E_RD_ADC4;
        end if;

      when E_RD_ADC5 =>

        if tx_ready = '1' then
          tx_data_valid_next <= '1';
          -- compute the address for the next read access
          tx_addr_next       <= c_ADDR6;
          -- select the read ADC register
          rx_sel_next        <= c_ADDR5;
          -- read ADC word
          sm_state_next      <= E_WAIT_TX_END;
        else
          sm_state_next <= E_RD_ADC5;
        end if;

      when E_RD_ADC6 =>

        if tx_ready = '1' then
          tx_data_valid_next <= '1';
          -- compute the address for the next read access
          tx_addr_next       <= c_ADDR7;
          -- select the read ADC register
          rx_sel_next        <= c_ADDR6;
          -- read ADC word
          sm_state_next      <= E_WAIT_TX_END;
        else
          sm_state_next <= E_RD_ADC6;
        end if;

      when E_RD_ADC7 =>

        if tx_ready = '1' then
          tx_data_valid_next <= '1';
          -- compute the address for the next read access
          tx_addr_next       <= c_ADDR0;
          -- select the read ADC register
          rx_sel_next        <= c_ADDR7;
          -- read ADC word
          sm_state_next      <= E_WAIT_TX_END;
        else
          sm_state_next <= E_RD_ADC7;
        end if;

      when E_WAIT_TX_END =>
        if tx_finish = '1' then
          case tx_addr_r1 is
            --when "000" => -- 0
            when c_ADDR0 =>             -- 0
              sm_state_next <= E_WAIT;
            --when "001" => -- 1
            when c_ADDR1 =>             -- 1
              sm_state_next <= E_RD_ADC1;
            --when "010" => -- 2
            when c_ADDR2 =>             -- 2
              sm_state_next <= E_RD_ADC2;
            --when "011" => -- 3
            when c_ADDR3 =>             -- 3
              sm_state_next <= E_RD_ADC3;
            --when "100" => -- 4
            when c_ADDR4 =>             -- 4
              sm_state_next <= E_RD_ADC4;
            --when "101" => -- 5
            when c_ADDR5 =>             -- 5
              sm_state_next <= E_RD_ADC5;
            --when "110" => -- 6
            when c_ADDR6 =>             -- 6
              sm_state_next <= E_RD_ADC6;
            when others =>              -- 7
              sm_state_next <= E_RD_ADC7;
          end case;
        else
          sm_state_next <= E_WAIT_TX_END;
        end if;

      when others =>
        sm_state_next <= E_RST;
    end case;
  end process p_decode_state;

  p_state : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      if i_rst = '1' then
        sm_state_r1 <= E_RST;
      else
        sm_state_r1 <= sm_state_next;
      end if;
      tx_data_valid_r1 <= tx_data_valid_next;
      tx_addr_r1       <= tx_addr_next;
      ready_r1         <= ready_next;

      -- generate error: no command during tx transmission
      if ready_r1 = '0' and start = '1' then
        error_r1 <= '1';
      else
        error_r1 <= '0';
      end if;
    end if;
  end process p_state;

  -- output
  o_ready <= ready_r1;

  ---------------------------------------------------------------------
  -- spi master
  ---------------------------------------------------------------------
  tx_msb_first              <= '1';
  tx_wr_rd                  <= '0';
  -- see the ADC128S102 datasheet
  tx_data_tmp(15 downto 14) <= (others => '0');  -- don't Care
  tx_data_tmp(13 downto 11) <= std_logic_vector(tx_addr_r1);
  tx_data_tmp(10 downto 0)  <= (others => '0');  -- don't Care

  inst_spi_master : entity work.spi_master
    generic map(
      g_CPOL                 => pkg_ADC_SPI_CPOL,        -- clock polarity
      g_CPHA                 => pkg_ADC_SPI_CPHA,        -- clock phase
      g_SYSTEM_FREQUENCY_HZ  => pkg_ADC_SPI_SYSTEM_FREQUENCY_HZ,  -- input system clock frequency  (expressed in Hz). The range is ]2*g_SPI_FREQUENCY_MAX_HZ: max_integer_value]
      g_SPI_FREQUENCY_MAX_HZ => pkg_ADC_SPI_SPI_FREQUENCY_MAX_HZ,  -- output max spi clock frequency (expressed in Hz)
      g_MOSI_DELAY           => pkg_ADC_SPI_MOSI_DELAY,  -- Number of clock period for mosi signal delay from state machine to the output
      g_MISO_DELAY           => pkg_ADC_SPI_MISO_DELAY,  -- Number of clock period for miso signal delay from spi pin input to spi master input
      g_DATA_WIDTH           => tx_data_tmp'length         -- Data bus size
      )
    port map(
      -- Clock
      i_clk => i_clk,
      -- Reset
      i_rst => i_rst,

      -- write side
      ---------------------------------------------------------------------
      -- 1:wr , 0:rd
      i_wr_rd        => tx_wr_rd,
      -- 1: MSB bits sent first, 0: LSB bits sent first
      i_tx_msb_first => tx_msb_first,

      -- Start transmit ('0' = Inactive, '1' = Active)
      i_tx_data_valid => tx_data_valid_r1,
      -- Data to transmit (stall on MSB)
      i_tx_data       => tx_data_tmp,

      -- Transmit link busy ('0' = Busy, '1' = Not Busy)
      o_ready  => tx_ready,
      -- pulse on finish (end of spi transaction: wr or rd)
      o_finish => tx_finish,

      -- rd side
      ---------------------------------------------------------------------
      -- received data valid
      o_rx_data_valid => rx_data_valid,  -- to connect
      -- received data (device spi register value)
      o_rx_data       => rx_data,        -- to connect

      ---------------------------------------------------------------------
      -- spi interface
      ---------------------------------------------------------------------
      -- SPI MISO (Master Input - Slave Output)
      i_miso => i_spi_miso,
      -- SPI Serial Clock
      o_sclk => spi_sclk,
      -- SPI Chip Select ('0' = Active, '1' = Inactive)
      o_cs_n => spi_cs_n,
      -- SPI MOSI (Master Output - Slave Input)
      o_mosi => spi_mosi
      );

---------------------------------------------------------------------
-- Select the ADCs
---------------------------------------------------------------------
  p_select_ADC_register : process (i_clk) is
  begin
    if rising_edge(i_clk) then
        -- default value
      adc_valid_r2 <= '0';
      case rx_sel_r1 is
        when "000" =>                   -- 0
        if rx_data_valid = '1' then
          adc0_r2 <= rx_data;
        end if;

        when "001" =>                   -- 1
        if rx_data_valid = '1' then
          adc1_r2 <= rx_data;
        end if;

        when "010" =>                   -- 2
        if rx_data_valid = '1' then
          adc2_r2 <= rx_data;
        end if;

        when "011" =>                   -- 3
        if rx_data_valid = '1' then
          adc3_r2 <= rx_data;
        end if;

        when "100" =>                   -- 4
        if rx_data_valid = '1' then
          adc4_r2 <= rx_data;
        end if;

        when "101" =>                   -- 5
        if rx_data_valid = '1' then
          adc5_r2 <= rx_data;
        end if;

        when "110" =>                   -- 6
        if rx_data_valid = '1' then
          adc6_r2 <= rx_data;
        end if;

        when others =>                  -- 7
        -- generate data valid on the last read ADC (ADC7)
        adc_valid_r2 <= rx_data_valid;
        if rx_data_valid = '1' then
          adc7_r2 <= rx_data;
        end if;

      end case;
    end if;
  end process p_select_ADC_register;

  ---------------------------------------------------------------------
  -- output
  ---------------------------------------------------------------------

  -- SPI
  ---------------------------------------------------------------------
  o_spi_sclk <= spi_sclk;
  o_spi_cs_n <= spi_cs_n;
  o_spi_mosi <= spi_mosi;

  --
  ---------------------------------------------------------------------
  o_adc_valid <= adc_valid_r2;
  o_adc7      <= adc7_r2;
  o_adc6      <= adc6_r2;
  o_adc5      <= adc5_r2;
  o_adc4      <= adc4_r2;
  o_adc3      <= adc3_r2;
  o_adc2      <= adc2_r2;
  o_adc1      <= adc1_r2;
  o_adc0      <= adc0_r2;


  ---------------------------------------------------------------------
-- errors/status
---------------------------------------------------------------------
  error_tmp(0) <= error_r1; -- error: new received spi tx command during the tx transmission
  gen_errors_latch : for i in error_tmp'range generate
    inst_one_error_latch : entity work.one_error_latch
      port map(
        i_clk         => i_clk,
        i_rst         => i_rst_status,
        i_debug_pulse => i_debug_pulse,
        i_error       => error_tmp(i),
        o_error       => error_tmp_bis(i)
        );
  end generate gen_errors_latch;

  o_errors(15 downto 1) <= (others => '0');
  o_errors(0)           <= error_tmp_bis(0);

  o_status(7 downto 1) <= (others => '0');
  o_status(0)          <= ready_r1;

  ---------------------------------------------------------------------
  -- for simulation only
  ---------------------------------------------------------------------
  assert not (error_tmp_bis(0) = '1') report "[dcdc_adc128s102] => new received spi tx command during the tx transmission" severity error;


end architecture RTL;
