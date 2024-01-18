-- -------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2023-2030 Ken-ji de la Rosa, IRAP Toulouse.
-- -------------------------------------------------------------------------------------------------------------
--                            This file is part of the ATHENA X-IFU DRE Telemetry and Telecommand Firmware.
--
--                            tmtc-fw is free software: you can redistribute it and/or modify
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
--    @file                   pkg_utils.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This package defines commonly used function/procedure
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.math_real.all;

package pkg_utils is

  ---------------------------------------------------------------------
  -- This function computes the minimal width bus necessary to represent a value
  --   res = ceil(log2(i_value))
  --   example:
  --     i_value = 1 => res = 1 (particular case)
  --     i_value = 2 => res = 1
  --     i_value = 16 => res = 4
  --     i_value = 8  => res = 3
  ---------------------------------------------------------------------
  function pkg_width_from_value(
    -- value to use in order to compute its width (minimal number of bits to represent its value)
    i_value : in positive
    ) return integer;

  ---------------------------------------------------------------------
  -- This function computes the width bus from 2 indexes
  --   example:
  --     i_idx_high = 15 and i_idx_low = 0 => res = (i_idx_high - i_idx_low) + 1
  ---------------------------------------------------------------------
  function pkg_width_from_indexes(
    -- bus index max
    i_idx_high : in integer;
    -- bus index min
    i_idx_low  : in integer
    ) return integer;

  ---------------------------------------------------------------------
  -- This function return the max value of 2 input integers: i_value0 and i_value1
  ---------------------------------------------------------------------
  function max(
    -- data value0
    i_value0 : in integer;
    -- data value1
    i_value1 : in integer
    ) return integer;

  ---------------------------------------------------------------------
  -- This function return the min value of 2 input integers: i_value0 and i_value1
  ---------------------------------------------------------------------
  function min(
    -- data value0
    i_value0 : in integer;
    -- data value1
    i_value1 : in integer
    ) return integer;

end pkg_utils;

package body pkg_utils is

  ---------------------------------------------------------------------
  -- This function computes the minimal width bus necessary to represent a value
  --   res = ceil(log2(i_value))
  --   example:
  --     i_value = 1 => res = 1 (particular case)
  --     i_value = 2 => res = 1
  --     i_value = 16 => res = 4
  --     i_value = 8  => res = 3
  ---------------------------------------------------------------------
  function pkg_width_from_value(
    -- value to use in order to compute its width (minimal number of bits to represent its value)
    i_value : in positive
    ) return integer is

    -- compute the log2(i_value). Number of minimum bits to represente i_value.
    variable v_result : integer;

  begin
    if i_value = 1 then
      v_result := 1;
    else
      v_result := integer(ceil(log2(real(i_value))));
    end if;
    return v_result;
  end;

  ---------------------------------------------------------------------
  -- This function computes the width bus from 2 indexes
  --   example:
  --     i_idx_high = 15 and i_idx_low = 0 => res = (i_idx_high - i_idx_low) + 1
  ---------------------------------------------------------------------
  function pkg_width_from_indexes(
    -- bus index max
    i_idx_high : in integer;
    -- bus index min
    i_idx_low  : in integer
    ) return integer is

    -- computed width (expressed in bits)
    variable v_result : integer;

  begin
    v_result := (i_idx_high - i_idx_low) + 1;
    return v_result;
  end;

  ---------------------------------------------------------------------
  -- This function return the max value of 2 input integers: i_value0 and i_value1
  ---------------------------------------------------------------------
  function max(
    -- data value0
    i_value0 : in integer;
    -- data value1
    i_value1 : in integer
    ) return integer is

    -- computed max value
    variable v_result : integer;

  begin
    if i_value0 > i_value1 then
      v_result := i_value0;
    else
      v_result := i_value1;
    end if;
    return v_result;
  end;

  ---------------------------------------------------------------------
  -- This function return the min value of 2 input integers: i_value0 and i_value1
  ---------------------------------------------------------------------
  function min(
    -- data value0
    i_value0 : in integer;
    -- data value1
    i_value1 : in integer
    ) return integer is

    -- computed min value
    variable v_result : integer;

  begin
    if i_value0 < i_value1 then
      v_result := i_value0;
    else
      v_result := i_value1;
    end if;
    return v_result;
  end;


end pkg_utils;
