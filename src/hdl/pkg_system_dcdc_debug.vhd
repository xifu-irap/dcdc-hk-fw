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
--    @file                   pkg_system_dcdc_debug.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This package defines all constants associated to the system_tmtc function and its sub-functions (debugging)
--
-- -------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.math_real.all;

package pkg_system_dcdc_debug is


  ---------------------------------------------------------------------
  -- REGDECODE_TOP
  ---------------------------------------------------------------------
  -- user-defined: true: use Xilinx debugging modules (ILA, VIO,..), false: otherwise
  constant pkg_REGDECODE_TOP_DEBUG : boolean := false;

  ---------------------------------------------------------------------
  -- DCDC_TOP
  ---------------------------------------------------------------------
  -- user-defined: true: use Xilinx debugging modules (ILA, VIO,..), false: otherwise
  constant pkg_DCDC_ADC128S102_DEBUG : boolean := true;

  ---------------------------------------------------------------------
  -- POWER_TOP
  ---------------------------------------------------------------------
  -- user-defined: true: use Xilinx debugging modules (ILA, VIO,..), false: otherwise
  constant pkg_POWER_RHRPMICL1A_DEBUG : boolean := true;


end pkg_system_dcdc_debug;

