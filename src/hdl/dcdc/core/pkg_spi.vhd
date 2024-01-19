-- -------------------------------------------------------------------------------------------------------------
--                              Copyright (C) 2022-2030 Ken-ji de la Rosa, IRAP Toulouse.
-- -------------------------------------------------------------------------------------------------------------
--                              This file is part of the ATHENA X-IFU DRE Focal Plane Assembly simulator.
--
--                              fpasim-fw is free software: you can redistribute it and/or modify
--                              it under the terms of the GNU General Public License as published by
--                              the Free Software Foundation, either version 3 of the License, or
--                              (at your option) any later version.
--
--                              This program is distributed in the hope that it will be useful,
--                              but WITHOUT ANY WARRANTY; without even the implied warranty of
--                              MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--                              GNU General Public License for more details.
--
--                              You should have received a copy of the GNU General Public License
--                              along with this program.  If not, see <https://www.gnu.org/licenses/>.
-- -------------------------------------------------------------------------------------------------------------
--    email                   kenji.delarosa@alten.com
--    @file                   pkg_spi.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This package defines all constant used by the spi function.
--    These constants configure the SPI parameters for the differents device
--
--    Note: (see: https://www.analog.com/en/analog-dialogue/articles/introduction-to-spi-interface.html)
--     SPI_MODE |CPOL|CPHA| clock polarity (idle state)| clock data sampling | clock data shift out
--     0        |  0 | 0  | 0                          | rising_edge         | falling_edge
--     1        |  0 | 1  | 0                          | falling_edge        | rising_edge
--     2        |  1 | 0  | 1                          | rising_edge         | falling_edge
--     3        |  1 | 1  | 1                          | falling_edge        | rising_edge
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;


package pkg_spi is

  -- user-defined : usb_clock frequency
  constant pkg_USB_SYSTEM_FREQUENCY_HZ : positive := 100_800_000;

  ---------------------------------------------------------------------
  -- spi_device_select
  ---------------------------------------------------------------------
   -- hardcoded : Number of clock periods for mosi signal (spi_master) between the spi devices and the module output
  constant pkg_SPI_DEVICE_SELECT_MOSI_DELAY : positive := 1;

  ---------------------------------------------------------------------
  -- io
  ---------------------------------------------------------------------
   -- hardcoded : Number of clock periods for mosi signal between the user side -> pads side
  constant pkg_IO_MOSI_DELAY : positive := 1;
   -- hardcoded : Number of clock periods for miso signal between the pads side -> user side
  constant pkg_IO_MISO_DELAY : positive := 3;


  -------------------------------------------------------------------
  -- AMC7823
  --   .see: https://www.analog.com/en/analog-dialogue/articles/introduction-to-spi-interface.html
  -------------------------------------------------------------------
  -- user-defined : SPI clock polarity
  constant pkg_SPI_CPOL                 : std_logic := '0';
  -- user-defined : SPI clock phase
  constant pkg_SPI_CPHA                 : std_logic := '1';
  -- auto-computed : input clock frequency of the module (expressed in Hz). (possible values: ]2*g_SPI_FREQUENCY_MAX_HZ: max_integer_value])
  constant pkg_SPI_SYSTEM_FREQUENCY_HZ  : positive  := pkg_USB_SYSTEM_FREQUENCY_HZ;
  -- user-defined : spi output clock frequency to generate (expressed in Hz)
  constant pkg_SPI_SPI_FREQUENCY_MAX_HZ : positive  := 6_000_000; -- 12 MHz max
  -- user-defined : Number of clock period for mosi signal between the state machine output to the output ports (spi_master)
  -- (possible values [0;max_integer_value[)
  constant pkg_SPI_MOSI_DELAY           : natural   := 0;
  -- auto-computed : Number of clock period for miso signal by considering the FPGA loopback delay
  -- (the external device delay is not taken into account): FSM (spi_master) -> IO (out) -> IO (IN). (possible values [0;max_integer_value[)
  constant pkg_SPI_MISO_DELAY           : natural   := pkg_SPI_MOSI_DELAY +
                                                           pkg_SPI_DEVICE_SELECT_MOSI_DELAY +
                                                           pkg_IO_MOSI_DELAY +
                                                           pkg_IO_MISO_DELAY;


end pkg_spi;

