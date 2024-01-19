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
--    @file                   pkg_regdecode.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--  This package defines all constants associtated to the regdecode function and its sub-functions.
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


use work.pkg_utils;

package pkg_regdecode is

  ---------------------------------------------------------------------
  --
  ---------------------------------------------------------------------
  -- user-defined: Firmware ID Value
  constant pkg_FIRMWARE_ID_VALUE : integer := 0;

  -- user-defined: FIRMWARE name (character3)
  constant pkg_FIRMWARE_NAME_CHAR3 : character := 'D';  -- ascii character
  -- user-defined: FIRMWARE name (character2)
  constant pkg_FIRMWARE_NAME_CHAR2 : character := 'C';  -- ascii character
  -- user-defined: FIRMWARE name (character1)
  constant pkg_FIRMWARE_NAME_CHAR1 : character := 'D';  -- ascii character
  -- user-defined: FIRMWARE name (character0)
  constant pkg_FIRMWARE_NAME_CHAR0 : character := 'C';  -- ascii character

  -- auto-computed: firmware name
  constant pkg_FIRMWARE_NAME : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(character'pos(pkg_FIRMWARE_NAME_CHAR3), 8)) &
                                                                std_logic_vector(to_unsigned(character'pos(pkg_FIRMWARE_NAME_CHAR2), 8)) &
                                                                std_logic_vector(to_unsigned(character'pos(pkg_FIRMWARE_NAME_CHAR1), 8)) &
                                                                std_logic_vector(to_unsigned(character'pos(pkg_FIRMWARE_NAME_CHAR0), 8));
  -- auto-computed: firmware id
  constant pkg_FIRMWARE_ID : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(pkg_FIRMWARE_ID_VALUE, 32));


  ---------------------------------------------------------------------
  -- register field definition
  -- The following constants define the bit range of each register field.
  -- Note:
  --   .the bit range should match the bit range of the api_register doc
  --   . when the field is composed by 1 bit, only 1 XXX_IDX_H constant is defined
  --   . When the field is composed by 2 bits or more, 2 constants are defined:
  --      . XXX_IDX_H
  --      . XXX_IDX_L
  ---------------------------------------------------------------------

  -- wire in/wire out
  -----------------------------------------------------------------

  -- wire loopback
  -----------------------------------------------------------------
  -- user-defined: define the number of tap delay for loopback (wire). The range is [0;max int value[
  constant pkg_WIRE_LOOPBACK_DELAY : integer := 1;

  -- ctrl register
  ---------------------------------------------------------------------
  -- user-defined: ctrl rst (bit index)
  constant pkg_CTRL_RST_IDX_H : integer := 0;

  -- debug_ctrl register
  ---------------------------------------------------------------------
  -- user-defined: debug_pulse (bit index)
  constant pkg_DEBUG_CTRL_DEBUG_PULSE_IDX_H : integer := 0;
  -- user-defined: rst_status (bit index)
  constant pkg_DEBUG_CTRL_RST_STATUS_IDX_H  : integer := 1;

  -- POWER_CTRL register
  ---------------------------------------------------------------------
  -- user-defined: default value of the POWER_CTRL register
  constant pkg_POWER_CTRL_DEFAULT : integer := x"F";
  -- user-defined: index high
  constant pkg_POWER_CTRL_POWER_IDX_H : integer := 3;
  -- user-defined: index low
  constant pkg_POWER_CTRL_POWER_IDX_L : integer := 0;
  -- auto-computed: power_ctrl width
  constant pkg_POWER_CTRL_WIDTH : integer := work.pkg_utils.pkg_width_from_indexes(i_idx_high => pkg_POWER_CTRL_POWER_IDX_H, i_idx_low => pkg_POWER_CTRL_POWER_IDX_L);

  -- ADC_CTRL register
  ---------------------------------------------------------------------
  -- user-defined: default value of the ADC_CTRL register
  constant pkg_ADC_CTRL_DEFAULT : integer := x"0";
  -- user-defined: adc_spi_start (bit index)
  constant pkg_ADC_CTRL_ADC_SPI_START_IDX_H : integer := 0;


  -- error_sel register
  ---------------------------------------------------------------------
  -- user-defined: error_sel (bit index high)
  constant pkg_ERROR_SEL_IDX_H : integer := 2;
  -- user-defined: error_sel (bit index low)
  constant pkg_ERROR_SEL_IDX_L : integer := 0;
  -- auto-computed: error_sel width
  constant pkg_ERROR_SEL_WIDTH : integer := work.pkg_utils.pkg_width_from_indexes(i_idx_high => pkg_ERROR_SEL_IDX_H, i_idx_low => pkg_ERROR_SEL_IDX_L);


end pkg_regdecode;

