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
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--    This package defines constants for the system_dcdc function and its sub-functions (except for the regdecode).
--
-- -------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

package pkg_system_dcdc is

  ---------------------------------------------------------------------
  -- io_top
  ---------------------------------------------------------------------
  -- io_spi
  ---------------------------------------------------------------------
  -- user-defined : Input Delay. Number of delay clock periods for miso signal
  constant pkg_IO_SPI_MISO_DELAY        : positive := 1;  -- must be >= 0
  -- user-defined: Input resynchronization stage. Number of resync stage
  constant pkg_IO_SPI_MISO_RESYNC_DELAY : positive := 2;  -- must be >= 2
  -- auto-computed: Number of delay clock periods for miso signal between the pads side -> user side
  constant pkg_IO_SPI_MISO_LATENCY      : positive := pkg_IO_SPI_MISO_DELAY + pkg_IO_SPI_MISO_RESYNC_DELAY;
  -- user-defined : Number of delay clock periods for mosi signal between the user side -> pads side
  constant pkg_IO_SPI_MOSI_DELAY        : positive := 1;  -- must be >= 1

  -- user-defined : usb_clock frequency (expressed in Hz) (must match the constraint file)
  constant pkg_USB_SYSTEM_FREQUENCY_HZ : positive := 100_800_000;

  ---------------------------------------------------------------------
  -- io_top/io_spi: rename
  ---------------------------------------------------------------------
  -- auto-computed : Number of clock periods for mosi signal between the user side -> pads side
  constant pkg_IO_ADC_MOSI_DELAY : positive := pkg_IO_SPI_MOSI_DELAY;
  -- auto-computed : Number of clock periods for miso signal between the pads side -> user side
  constant pkg_IO_ADC_MISO_DELAY : positive := pkg_IO_SPI_MISO_DELAY;

  ---------------------------------------------------------------------
  -- io_top/io_power
  ---------------------------------------------------------------------
  -- user-defined: number of tap delay for the power signals
  constant pkg_IO_POWER_DELAY : positive := 1;

  -------------------------------------------------------------------
  -- dcdc_top/dcdc_adc128s102
  --   .see: datasheet
  --    SPI_MODE |CPOL|CPHA| clock polarity (idle state)| clock data sampling | clock data shift out
  --    0        |  0 | 0  | 0                          | rising_edge         | falling_edge
  --    1        |  0 | 1  | 0                          | falling_edge        | rising_edge
  --    2        |  1 | 0  | 1                          | rising_edge         | falling_edge
  --    3        |  1 | 1  | 1                          | falling_edge        | rising_edge
  -------------------------------------------------------------------
  -- user-defined : SPI clock polarity (see: https://www.analog.com/en/analog-dialogue/articles/introduction-to-spi-interface.html)
  constant pkg_ADC_SPI_CPOL                 : std_logic := '1';
  -- user-defined : SPI clock phase (see: https://www.analog.com/en/analog-dialogue/articles/introduction-to-spi-interface.html)
  constant pkg_ADC_SPI_CPHA                 : std_logic := '0';
  -- auto-computed : input clock frequency of the module (expressed in Hz). (possible values: ]2*g_SPI_FREQUENCY_MAX_HZ: max_integer_value])
  constant pkg_ADC_SPI_SYSTEM_FREQUENCY_HZ  : positive  := pkg_USB_SYSTEM_FREQUENCY_HZ;
  -- user-defined : spi output clock frequency to generate (expressed in Hz) (datasheet: 8 to 18 MHz max)
  constant pkg_ADC_SPI_SPI_FREQUENCY_MAX_HZ : positive  := 1_000;  -- 1KHz
  -- user-defined : Number of clock period for mosi signal between the state machine output to the output ports (spi_master)
  -- (possible values [0;max_integer_value[)
  constant pkg_ADC_SPI_MOSI_DELAY           : natural   := 0;
  -- auto-computed : Number of clock period for miso signal by considering the FPGA loopback delay
  -- (the external device delay is not taken into account): FSM (spi_master) -> IO (out) -> IO (IN). (possible values [0;max_integer_value[)
  constant pkg_ADC_SPI_MISO_DELAY           : natural   := pkg_ADC_SPI_MOSI_DELAY +
                                               pkg_IO_ADC_MOSI_DELAY +
                                               pkg_IO_ADC_MISO_DELAY;


  ---------------------------------------------------------------------
  -- power_top/power_rhrpmicl1a
  ---------------------------------------------------------------------
  -- user-defined : Pulse width (expressed in samples) of the TC commands.
  --     At least 30 us, typical: 100 us (see datasheet: https://www.st.com/en/space-products/rhrpmicl1a.html)
  --     range: [1; max integer value[
  constant pkg_POWER_TC_PULSE_NB_SAMPLES : integer := 4*10080; -- ~400 us @usb_clk (100.8 MHz)
  -- user-defined (optional): number of delay tap
  constant pkg_POWER_DELAY_OUT : integer := 1; -- range [0; max integer value[
  -- user-defined: active state of the power bit
  constant pkg_POWER_BIT_ON : std_logic := '1';

end pkg_system_dcdc;

package body pkg_system_dcdc is


end pkg_system_dcdc;
