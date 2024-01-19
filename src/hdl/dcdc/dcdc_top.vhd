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
--    @file                   dcdc_top.vhd
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

use work.pkg_spi.all;

entity dcdc_top is
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
    -- ADC0 value
    o_adc0      : out std_logic_vector(11 downto 0);
    -- ADC1 value
    o_adc1      : out std_logic_vector(11 downto 0);
    -- ADC2 value
    o_adc2      : out std_logic_vector(11 downto 0);
    -- ADC3 value
    o_adc3      : out std_logic_vector(11 downto 0);
    -- ADC4 value
    o_adc4      : out std_logic_vector(11 downto 0);
    -- ADC5 value
    o_adc5      : out std_logic_vector(11 downto 0);
    -- ADC6 value
    o_adc6      : out std_logic_vector(11 downto 0);
    -- ADC7 value
    o_adc7      : out std_logic_vector(11 downto 0);

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
end entity dcdc_top;

architecture RTL of dcdc_top is

---------------------------------------------------------------------
-- state machine
---------------------------------------------------------------------
  -- detect an start acquisition
  signal start         : std_logic;
-- fsm type declaration
  type t_state is (E_RST, E_CHANGE);
  -- state
  signal sm_state_next : t_state;
  -- state (registered)
  signal sm_state_r1   : t_state := E_RST;

  -- tx_data valid
  signal tx_data_valid_next : std_logic;
  -- delayed tx_data valid
  signal tx_data_valid_r1   : std_logic;


  -- tx_data
  signal tx_data_next : std_logic_vector(15 downto 0);
  -- delayed tx_data
  signal tx_data_r1   : std_logic_vector(15 downto 0);

  -- fsm ready
  signal ready_next : std_logic;
  -- delayed fsm ready
  signal ready_r1   : std_logic;

  -- error
  signal error_next : std_logic;
  -- delayed error
  signal error_r1   : std_logic;

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
  signal rx_data_valid : out std_logic;
-- received data (device spi register value)
  signal rx_data       : out std_logic_vector(g_DATA_WIDTH -1 downto 0);

-- SPI MISO
  signal spi_miso : std_logic;
-- SPI MOSI
  signal spi_mosi : std_logic;
  -- SPI clock
  signal spi_sclk : std_logic;
-- SPI chip select
  signal spi_cs_n : std_logic;



begin

  start <= '1' when i_adc_start_valid = '1' and i_adc_start = '1' else '0';

  p_decode_state : process (sm_state_r1) is
  begin
    -- default value
    tx_data_valid_next <= '0';
    tx_data_next       <= tx_data_r1;
    ready_next         <= ready_r1;
    error_next         <= '0';

    case sm_state_r1 is
      when E_RST =>
        tx_data_next  <= (others => '0');
        sm_state_next <= E_WAIT;

      when E_WAIT =>
        if start = '1' then
          ready_next    <= '0';
          sm_state_next <= E_WORD1;
        else
          ready_next    <= '1';
          sm_state_next <= E_WAIT;
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
      tx_data_r1       <= tx_data_next;
      ready_r1         <= ready_next;
      error_r1         <= error_next;
    end if;
  end process p_state;



  ---------------------------------------------------------------------
  -- spi master
  ---------------------------------------------------------------------
  tx_msb_first <= '1';
  tx_wr_rd     <= '0';

  inst_spi_master : entity work.spi_master
    generic map(
      g_CPOL                 => pkg_SPI_CPOL,        -- clock polarity
      g_CPHA                 => pkg_SPI_CPHA,        -- clock phase
      g_SYSTEM_FREQUENCY_HZ  => pkg_SPI_SYSTEM_FREQUENCY_HZ,  -- input system clock frequency  (expressed in Hz). The range is ]2*g_SPI_FREQUENCY_MAX_HZ: max_integer_value]
      g_SPI_FREQUENCY_MAX_HZ => pkg_SPI_SPI_FREQUENCY_MAX_HZ,  -- output max spi clock frequency (expressed in Hz)
      g_MOSI_DELAY           => pkg_SPI_MOSI_DELAY,  -- Number of clock period for mosi signal delay from state machine to the output
      g_MISO_DELAY           => pkg_SPI_MISO_DELAY,  -- Number of clock period for miso signal delay from spi pin input to spi master input
      g_DATA_WIDTH           => g_DATA_WIDTH         -- Data bus size
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
      i_tx_data       => tx_data_r1,

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
-- output
---------------------------------------------------------------------
  o_spi_sclk <= spi_sclk;
  o_spi_cs_n <= spi_cs_n;
  o_spi_mosi <= spi_mosi;


end architecture RTL;
