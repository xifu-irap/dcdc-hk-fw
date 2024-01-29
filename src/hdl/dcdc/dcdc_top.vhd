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

    ---------------------------------------------------------------------
    -- inputs
    ---------------------------------------------------------------------
    -- Valid start ADCs' acquisition
    i_adc_start_valid : in std_logic;
    -- start ADCs' acquisition
    i_adc_start       : in std_logic;

    ---------------------------------------------------------------------
    -- outputs
    ---------------------------------------------------------------------
    -- '1': tx_ready to start an acquisition, '0': busy
    o_adc_ready : out std_logic;

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
    i_adc_spi_miso : in  std_logic;
    -- SPI MOSI
    o_adc_spi_mosi : out std_logic;
    -- SPI clock
    o_adc_spi_sclk : out std_logic;
    -- SPI chip select
    o_adc_spi_cs_n : out std_logic;

    ---------------------------------------------------------------------
    -- Status/errors
    ---------------------------------------------------------------------
    -- adc errors
    o_adc_errors : out std_logic_vector(15 downto 0);
    -- adc status
    o_adc_status : out std_logic_vector(7 downto 0)
    );
end entity dcdc_top;

architecture RTL of dcdc_top is

  ---------------------------------------------------------------------
  -- inst_dcdc_adc128s102
  ---------------------------------------------------------------------
  -- '1': tx_ready to start an acquisition, '0': busy
  signal adc_ready : std_logic;

  -- ADC values valid
  signal adc_valid : std_logic;
  -- ADC7 value
  signal adc7      : std_logic_vector(o_adc7'range);
  -- ADC6 value
  signal adc6      : std_logic_vector(o_adc6'range);
  -- ADC5 value
  signal adc5      : std_logic_vector(o_adc5'range);
  -- ADC4 value
  signal adc4      : std_logic_vector(o_adc4'range);
  -- ADC3 value
  signal adc3      : std_logic_vector(o_adc3'range);
  -- ADC2 value
  signal adc2      : std_logic_vector(o_adc2'range);
  -- ADC1 value
  signal adc1      : std_logic_vector(o_adc1'range);
  -- ADC0 value
  signal adc0      : std_logic_vector(o_adc0'range);

  -- SPI MOSI
  signal adc_spi_mosi : std_logic;
  -- SPI clock
  signal adc_spi_sclk : std_logic;
  -- SPI chip select
  signal adc_spi_cs_n : std_logic;

  -- adc errors
  signal adc_errors : std_logic_vector(15 downto 0);
  -- adc status
  signal adc_status : std_logic_vector(7 downto 0);

begin

  ---------------------------------------------------------------------
  -- dcdc_adc128s102
  ---------------------------------------------------------------------
  inst_dcdc_adc128s102 : entity work.dcdc_adc128s102
    generic map(
      -- enable the DEBUG by ILA
      g_DEBUG => g_DEBUG
      )
    port map(
      -- clock
      i_clk             => i_clk,
      -- reset
      i_rst             => i_rst,
      -- reset error flag(s)
      i_rst_status      => i_rst_status,
      -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s)
      i_debug_pulse     => i_debug_pulse,

      ---------------------------------------------------------------------
      -- inputs
      ---------------------------------------------------------------------
      -- Valid start ADCs' acquisition
      i_adc_start_valid => i_adc_start_valid,
      -- start ADCs' acquisition
      i_adc_start       => i_adc_start,

      ---------------------------------------------------------------------
      -- FSM status
      ---------------------------------------------------------------------
      -- '1': tx_ready to start an acquisition, '0': busy
      o_ready           => adc_ready,

      ---------------------------------------------------------------------
      -- ADC outputs
      ---------------------------------------------------------------------
      -- ADC values valid
      o_adc_valid       => adc_valid,
      -- ADC7 value
      o_adc7            => adc7,
      -- ADC6 value
      o_adc6            => adc6,
      -- ADC5 value
      o_adc5            => adc5,
      -- ADC4 value
      o_adc4            => adc4,
      -- ADC3 value
      o_adc3            => adc3,
      -- ADC2 value
      o_adc2            => adc2,
      -- ADC1 value
      o_adc1            => adc1,
      -- ADC0 value
      o_adc0            => adc0,

      ---------------------------------------------------------------------
      -- spi interface
      ---------------------------------------------------------------------
      -- SPI MISO
      i_spi_miso        => i_adc_spi_miso,
      -- SPI MOSI
      o_spi_mosi        => adc_spi_mosi,
      -- SPI clock
      o_spi_sclk        => adc_spi_sclk,
      -- SPI chip select
      o_spi_cs_n        => adc_spi_cs_n,
      ---------------------------------------------------------------------
      -- Status/errors
      ---------------------------------------------------------------------
      o_errors          => adc_errors,
      o_status          => adc_status
      );

  ---------------------------------------------------------------------
  -- output
  ---------------------------------------------------------------------
  -- FSM state
  o_adc_ready <= adc_ready;

  -- adc
  o_adc_valid <= adc_valid;
  o_adc7      <= adc7;
  o_adc6      <= adc6;
  o_adc5      <= adc5;
  o_adc4      <= adc4;
  o_adc3      <= adc3;
  o_adc2      <= adc2;
  o_adc1      <= adc1;
  o_adc0      <= adc0;

  -- spi
  o_adc_spi_mosi <= adc_spi_mosi;
  o_adc_spi_sclk <= adc_spi_sclk;
  o_adc_spi_cs_n <= adc_spi_cs_n;

  -- errors/status
  o_adc_errors <= adc_errors;
  o_adc_status <= adc_status;


end architecture RTL;
