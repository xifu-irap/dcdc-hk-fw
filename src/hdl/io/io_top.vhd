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
--    @file                   io_top.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module is the top level for the IOs.
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;


entity io_top is
  port (

    ---------------------------------------------------------------------
    -- from/to FPGA io: spi @i_sys_spi_clk
    ---------------------------------------------------------------------
    -- system spi clock
    i_sys_spi_clk : in  std_logic;
    -- SPI --
    -- Shared SPI MISO
    i_spi_miso    : in  std_logic;
    -- Shared SPI MOSI
    o_spi_mosi    : out std_logic;
    -- Shared SPI clock line
    o_spi_sclk    : out std_logic;
    -- SPI chip select
    o_spi_cs_n    : out std_logic;

    ---------------------------------------------------------------------
    -- to user: spi interface @i_sys_spi_clk
    ---------------------------------------------------------------------
    -- SPI --
    -- Shared SPI MISO
    o_ui_spi_miso : out std_logic;
    -- Shared SPI MOSI
    i_ui_spi_mosi : in  std_logic;
    -- Shared SPI clock line
    i_ui_spi_sclk : in  std_logic;
    -- SPI chip select
    i_ui_spi_cs_n : in  std_logic;

    ---------------------------------------------------------------------
    -- power
    ---------------------------------------------------------------------
    -- power_clock
    i_power_clk : in  std_logic;
    ---------------------------------------------------------------------
    -- from/to IOs: @i_clk
    ---------------------------------------------------------------------
    -- bitwise power_on pulse
    o_power_on  : out std_logic_vector(g_POWER_WIDTH - 1 downto 0);
    -- bitwise power_off pulse
    o_power_off : out std_logic_vector(g_POWER_WIDTH - 1 downto 0);

    ---------------------------------------------------------------------
    -- from/to user: @i_clk
    ---------------------------------------------------------------------
    -- bitwise power_on pulse
    i_power_on  : in std_logic_vector(g_POWER_WIDTH - 1 downto 0);
    -- bitwise power_off pulse
    i_power_off : in std_logic_vector(g_POWER_WIDTH - 1 downto 0)

    );
end entity io_top;

architecture RTL of io_top is


begin

  ---------------------------------------------------------------------
  -- spi
  ---------------------------------------------------------------------
  inst_io_spi : entity work.io_spi
    port map(
      ---------------------------------------------------------------------
      -- from/to FPGA io: spi @i_sys_spi_clk
      ---------------------------------------------------------------------
      i_sys_spi_clk => i_sys_spi_clk,
      -- SPI --
      i_spi_miso    => i_spi_miso,
      o_spi_mosi    => o_spi_mosi,
      o_spi_sclk    => o_spi_sclk,
      o_spi_cs_n    => o_spi_cs_n,
      ---------------------------------------------------------------------
      -- to user: science interface @i_sys_spi_clk
      ---------------------------------------------------------------------
      -- SPI --
      o_ui_spi_miso => o_ui_spi_miso,
      i_ui_spi_mosi => i_ui_spi_mosi,
      i_ui_spi_sclk => i_ui_spi_sclk,
      i_ui_spi_cs_n => i_ui_spi_cs_n
      );

  ---------------------------------------------------------------------
  -- power
  ---------------------------------------------------------------------
  inst_io_power : entity work.io_power
    generic map(
      -- width of the input/output power value
      g_POWER_WIDTH => i_power_on'length
      )
    port map(
      -- clock
      i_clk       => i_power_clk,
      ---------------------------------------------------------------------
      -- from/to IOs: @i_clk
      ---------------------------------------------------------------------
      -- bitwise power_on pulse
      o_power_on  => o_power_on,
      -- bitwise power_off pulse
      o_power_off => o_power_off,
      ---------------------------------------------------------------------
      -- from/to user: @i_clk
      ---------------------------------------------------------------------
      -- bitwise power_on pulse
      i_power_on  => i_power_on,
      -- bitwise power_off pulse
      i_power_off => i_power_off
      );


end architecture RTL;
