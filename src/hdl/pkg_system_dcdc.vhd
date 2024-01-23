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
--    @file                   pkg_system_dcdc.vhd
--    reference design        Yann PAROT (IRAP Toulouse)
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--    This package defines supplemental types, subtypes, constants, and functions
--
-- -------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

package pkg_system_dcdc is



  ---------------------------------------------------------------------
  -- IO
  ---------------------------------------------------------------------

  -- IO SPI
  ---------------------------------------------------------------------
  -- user-defined : Input Delay. Number of delay clock periods for miso signal
  constant pkg_IO_SPI_MISO_DELAY : positive := 1; -- must be >= 0
  -- user-defined: Input resynchronization stage. Number of resync stage
  constant pkg_IO_SPI_MISO_RESYNC_DELAY : positive := 2; -- must be >= 2
  -- auto-computed: Number of delay clock periods for miso signal between the pads side -> user side
  constant pkg_IO_SPI_MISO_LATENCY : positive := pkg_IO_SPI_MISO_DELAY + pkg_IO_SPI_MISO_RESYNC_DELAY;
  -- user-defined : Number of delay clock periods for mosi signal between the user side -> pads side
  constant pkg_IO_SPI_MOSI_DELAY : positive := 1; -- must be >= 1

  -- user-defined : usb_clock frequency
  constant pkg_USB_SYSTEM_FREQUENCY_HZ : positive := 100_800_000;

  ---------------------------------------------------------------------
  -- spi_device_select
  ---------------------------------------------------------------------
   -- hardcoded : Number of clock periods for mosi signal (spi_master) between the spi devices and the module output
  constant pkg_ADC_SPI_DEVICE_SELECT_MOSI_DELAY : positive := 1;

  ---------------------------------------------------------------------
  -- io
  ---------------------------------------------------------------------
   -- auto-computed : Number of clock periods for mosi signal between the user side -> pads side
  constant pkg_IO_ADC_MOSI_DELAY : positive := pkg_IO_SPI_MOSI_DELAY;
   -- auto-computed : Number of clock periods for miso signal between the pads side -> user side
  constant pkg_IO_ADC_MISO_DELAY : positive := pkg_IO_SPI_MISO_DELAY;


  -------------------------------------------------------------------
  -- ADC128S102
  --   .see: datasheet
  -------------------------------------------------------------------
  -- user-defined : SPI clock polarity
  constant pkg_ADC_SPI_CPOL                 : std_logic := '0';
  -- user-defined : SPI clock phase
  constant pkg_ADC_SPI_CPHA                 : std_logic := '1';
  -- auto-computed : input clock frequency of the module (expressed in Hz). (possible values: ]2*g_SPI_FREQUENCY_MAX_HZ: max_integer_value])
  constant pkg_ADC_SPI_SYSTEM_FREQUENCY_HZ  : positive  := pkg_USB_SYSTEM_FREQUENCY_HZ;
  -- user-defined : spi output clock frequency to generate (expressed in Hz)
  constant pkg_ADC_SPI_SPI_FREQUENCY_MAX_HZ : positive  := 12_000_000; -- 8 to 18 MHz max
  -- user-defined : Number of clock period for mosi signal between the state machine output to the output ports (spi_master)
  -- (possible values [0;max_integer_value[)
  constant pkg_ADC_SPI_MOSI_DELAY           : natural   := 0;
  -- auto-computed : Number of clock period for miso signal by considering the FPGA loopback delay
  -- (the external device delay is not taken into account): FSM (spi_master) -> IO (out) -> IO (IN). (possible values [0;max_integer_value[)
  constant pkg_ADC_SPI_MISO_DELAY           : natural   := pkg_ADC_SPI_MOSI_DELAY +
                                                           pkg_ADC_SPI_DEVICE_SELECT_MOSI_DELAY +
                                                           pkg_IO_ADC_MOSI_DELAY +
                                                           pkg_IO_ADC_MISO_DELAY;


end pkg_system_dcdc;

package body pkg_system_dcdc is


end pkg_system_dcdc;
