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
    i_clk  : in  std_logic;
    -- reset
    i_rst : in std_logic;

    -- reset error flag(s)
    i_rst_status  : in std_logic;
    -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s)
    i_debug_pulse : in std_logic;

    -- Valid start ADCs' acquisition
    i_adc_start_valid : in std_logic;
    -- start ADCs' acquisition
    i_adc_start       : in  std_logic;

    -- '1': ready to start an acquisition, '0': busy
    o_ready : out std_logic;

    -- ADC values valid
    o_adc_valid: out std_logic;
    -- ADC0 value
    o_adc0 : out std_logic_vector(11 downto 0);
    -- ADC1 value
    o_adc1 : out std_logic_vector(11 downto 0);
    -- ADC2 value
    o_adc2 : out std_logic_vector(11 downto 0);
    -- ADC3 value
    o_adc3 : out std_logic_vector(11 downto 0);
    -- ADC4 value
    o_adc4 : out std_logic_vector(11 downto 0);
    -- ADC5 value
    o_adc5 : out std_logic_vector(11 downto 0);
    -- ADC6 value
    o_adc6 : out std_logic_vector(11 downto 0);
    -- ADC7 value
    o_adc7 : out std_logic_vector(11 downto 0);

    ---------------------------------------------------------------------
    -- spi interface
    ---------------------------------------------------------------------
    -- SPI MISO
    i_spi_miso : in  std_logic;
    -- SPI MOSI
    o_spi_mosi  : out std_logic;
    -- SPI clock
    o_spi_sclk : out std_logic;
    -- SPI chip select
    o_spi_cs_n : out std_logic;

    ---------------------------------------------------------------------
    -- Status/errors
    ---------------------------------------------------------------------
    o_errors: out std_logic_vector(15 downto 0);
    o_status: out std_logic_vector(7 downto 0)
    );
end entity dcdc_top;

architecture RTL of dcdc_top is


begin



end architecture RTL;
