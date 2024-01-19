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
--    @file                   system_dcdc_top.vhd
--    reference design        Yann PAROT (IRAP Toulouse)
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--    Top level architecture
--
-- -------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use pkg_regdecode.all;
use pkg_system_dcdc_debug.all;

entity system_dcdc_top is
  port (
    ---------------------------------------------------------------------
    -- Opal Kelly inouts
    ---------------------------------------------------------------------
    -- usb interface signal
    i_okUH  : in    std_logic_vector(4 downto 0);
    -- usb interface signal
    o_okHU  : out   std_logic_vector(2 downto 0);
    -- usb interface signal
    b_okUHU : inout std_logic_vector(31 downto 0);
    -- usb interface signal
    b_okAA  : inout std_logic;

    ---------------------------------------------------------------------
    --
    ---------------------------------------------------------------------
    -- hardware id register (reading)
    --i_hardware_id : in std_logic_vector(7 downto 0);

    ---------------------------------------------------------------------
    -- ADC128S102 HK
    ---------------------------------------------------------------------
    -- adc SPI MISO
    i_adc_spi_miso : in  std_logic;
    -- adc SPI MOSI
    o_adc_spi_mosi  : out std_logic;
    -- adc SPI clock
    o_adc_spi_sclk : out std_logic;
    -- adc SPI chip select
    o_adc_spi_cs_n : out std_logic;

    ---------------------------------------------------------------------
    -- power card
    ---------------------------------------------------------------------
    -- control boards' power
    o_power_on_off : out std_logic_vector(3 downto 0);

    ---------------------------------------------------------------------
    -- LEDS
    ---------------------------------------------------------------------
    -- fpga board leds ('0': ON, 'Z': OFF )
    o_leds: out std_logic_vector(7 downto 0)

    );
end system_dcdc_top;

architecture RTL of system_dcdc_top is
  ---------------------------------------------------------------------
  -- regdecode_top
  ---------------------------------------------------------------------
  -- hardware id register (reading)
  signal hardware_id : std_logic_vector(i_hardware_id'range);

  -- usb clock
  signal usb_clk : std_logic;
  -- reset @usb_clk
  signal usb_rst : std_logic;

  -- ctrl register (writting)
  signal reg_ctrl             : std_logic_vector(31 downto 0);
  -- power_ctrl register (writting)
  signal reg_power_ctrl       : std_logic_vector(31 downto 0);
  -- adc_ctrl valid
  signal reg_adc_ctrl_valid         : std_logic;
  -- adc_ctrl register (reading)
  signal reg_adc_ctrl         : std_logic_vector(31 downto 0);
  -- adc_status register (reading)
  signal reg_adc_status       : std_logic_vector(31 downto 0);
  -- adc0 register (reading)
  signal reg_adc0             : std_logic_vector(31 downto 0);
  -- adc1 register (reading)
  signal reg_adc1             : std_logic_vector(31 downto 0);
  -- adc2 register (reading)
  signal reg_adc2             : std_logic_vector(31 downto 0);
  -- adc3 register (reading)
  signal reg_adc3             : std_logic_vector(31 downto 0);
  -- adc4 register (reading)
  signal reg_adc4             : std_logic_vector(31 downto 0);
  -- adc5 register (reading)
  signal reg_adc5             : std_logic_vector(31 downto 0);
  -- adc6 register (reading)
  signal reg_adc6             : std_logic_vector(31 downto 0);
  -- adc7 register (reading)
  signal reg_adc7             : std_logic_vector(31 downto 0);
  -- debug_ctrl data valid
  signal reg_debug_ctrl_valid : std_logic;
  -- debug_ctrl register value
  signal reg_debug_ctrl       : std_logic_vector(31 downto 0);

  -- status register: errors1
  signal reg_wire_errors1 : std_logic_vector(31 downto 0);
  -- status register: errors0
  signal reg_wire_errors0 : std_logic_vector(31 downto 0);
  -- status register: status1
  signal reg_wire_status1 : std_logic_vector(31 downto 0);
  -- status register: status0
  signal reg_wire_status0 : std_logic_vector(31 downto 0);

  -- software reset @usb_clk
  signal rst           : std_logic;
  -- start the adcs' acquisition
  signal adc_spi_start : std_logic;
  -- power the signals
  signal power_on_off  : std_logic_vector(o_power_on_off'range);

begin

--hardware_id <= i_hardware_id;
  hardware_id <= (others => '0');       -- TODO

  inst_regdecode_top : entity work.regdecode_top
    generic map(
      g_DEBUG => pkg_REGDECODE_TOP_DEBUG
      )
    port map(
      --  Opal Kelly inouts --
      -- usb interface signal
      i_okUH                 => i_okUH,
      -- usb interface signal
      o_okHU                 => o_okHU,
      -- usb interface signal
      b_okUHU                => b_okUHU,
      -- usb interface signal
      b_okAA                 => b_okAA,
      ---------------------------------------------------------------------
      -- From IO
      ---------------------------------------------------------------------
      -- hardware id register (reading)
      i_hardware_id          => hardware_id,
      ---------------------------------------------------------------------
      -- to the user @o_usb_clk
      ---------------------------------------------------------------------
      -- usb clock
      o_usb_clk              => o_usb_clk,

      -- wire
      -- ctrl register (writting)
      o_reg_ctrl             => reg_ctrl,
      -- power_ctrl register (writting)
      o_reg_power_ctrl       => reg_power_ctrl,

      -- ADC @o_usb_clk
      ---------------------------------------------------------------------
      -- adc_ctrl valid (reading)
      o_reg_adc_ctrl_valid  => reg_adc_ctrl_valid,
      -- adc_ctrl register (reading)
      o_reg_adc_ctrl         => reg_adc_ctrl,
      -- adc_status register (reading)
      i_reg_adc_status       => reg_adc_status,        -- to connect
      -- adc0 register (reading)
      i_reg_adc0             => reg_adc0,              -- to connect
      -- adc1 register (reading)
      i_reg_adc1             => reg_adc1,              -- to connect
      -- adc2 register (reading)
      i_reg_adc2             => reg_adc2,              -- to connect
      -- adc3 register (reading)
      i_reg_adc3             => reg_adc3,              -- to connect
      -- adc4 register (reading)
      i_reg_adc4             => reg_adc4,              -- to connect
      -- adc5 register (reading)
      i_reg_adc5             => reg_adc5,              -- to connect
      -- adc6 register (reading)
      i_reg_adc6             => reg_adc6,              -- to connect
      -- adc7 register (reading)
      i_reg_adc7             => reg_adc7,              -- to connect

      -- debug_ctrl @o_usb_clk
      ---------------------------------------------------------------------
      -- debug_ctrl data valid
      o_reg_debug_ctrl_valid => reg_debug_ctrl_valid,  -- to connect
      -- debug_ctrl register value
      o_reg_debug_ctrl       => reg_debug_ctrl,

      -- errors/status
      ---------------------------------------------------------------------
      -- status register: errors1
      i_reg_wire_errors1     => reg_wire_errors1,      -- to connect
      -- status register: errors0
      i_reg_wire_errors0     => reg_wire_errors0,      -- to connect
      -- status register: status1
      i_reg_wire_status1     => reg_wire_status1,      -- to connect
      -- status register: status0
      i_reg_wire_status0     => reg_wire_status0       -- to connect
      );


  -- extract bits from register
  ---------------------------------------------------------------------
  -- ctrl register
  rst           <= reg_ctrl(pkg_CTRL_RST_IDX_H);
  -- debug_ctrl register
  rst_status    <= reg_debug_ctrl(pkg_DEBUG_CTRL_RST_STATUS_IDX_H);
  debug_pulse   <= reg_debug_ctrl(pkg_DEBUG_CTRL_DEBUG_PULSE_IDX_H);
  -- adc_ctrl register
  adc_spi_start <= reg_adc_ctrl(pkg_ADC_CTRL_ADC_SPI_START_IDX_H);
  -- power_ctrl register
  power_on_off  <= reg_power_ctrl(pkg_POWER_CTRL_POWER_IDX_H downto pkg_POWER_CTRL_POWER_IDX_L);


---------------------------------------------------------------------
-- Power
---------------------------------------------------------------------
  o_power_on_off <= power_on_off;




end RTL;
