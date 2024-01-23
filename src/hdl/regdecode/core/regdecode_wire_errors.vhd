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
--    @file                   regdecode_wire_errors.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--   @details
--
--   This module outputs one of the (errors,status) inputs.
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_regdecode.all;

entity regdecode_wire_errors is
  generic(
    -- define the width of the error selection
    g_ERROR_SEL_WIDTH : integer := 4
    );
  port(

    ---------------------------------------------------------------------
    -- input @i_clk
    ---------------------------------------------------------------------
    -- clock
    i_clk             : in std_logic;
    -- error/status selection
    i_error_sel       : in std_logic_vector(g_ERROR_SEL_WIDTH - 1 downto 0);
    -- errors
    i_usb_reg_errors0 : in std_logic_vector(31 downto 0);
    -- status
    i_usb_reg_status0 : in std_logic_vector(31 downto 0);

    ---------------------------------------------------------------------
    -- output @ i_clk
    ---------------------------------------------------------------------
    -- output errors
    o_wire_errors : out std_logic_vector(31 downto 0);
    -- output status
    o_wire_status : out std_logic_vector(31 downto 0)
    );
end entity regdecode_wire_errors;

architecture RTL of regdecode_wire_errors is

  -- define the number total of selectable wire
  constant c_NB_WIRE_TOT : integer := 1;

  -- type definition: array of wire
  type t_wire_array is array (natural range <>) of std_logic_vector(31 downto 0);

  ---------------------------------------------------------------------
  -- errors/status selection
  ---------------------------------------------------------------------
  -- array of selectable errors
  signal errors_array_tmp : t_wire_array(c_NB_WIRE_TOT - 1 downto 0);
  -- array of selectable status
  signal status_array_tmp : t_wire_array(c_NB_WIRE_TOT - 1 downto 0);
  -- selected errors
  signal errors_r1        : std_logic_vector(31 downto 0);
  -- selected status
  signal status_r1        : std_logic_vector(31 downto 0);

begin

  -----------------------------------------------------------------
  -- available errors/status
  -----------------------------------------------------------------
  -- error table
  errors_array_tmp(0) <= i_usb_reg_errors0;

  -- status table
  status_array_tmp(0) <= i_usb_reg_status0;

  ---------------------------------------------------------------------
  -- Select the error/status value
  ---------------------------------------------------------------------
  p_select_error_status : process(i_clk) is
  begin
    if rising_edge(i_clk) then
      case i_error_sel is
        when "0" =>
          errors_r1 <= errors_array_tmp(0);
          status_r1 <= status_array_tmp(0);
        when others =>
          errors_r1 <= errors_r1;
          status_r1 <= status_r1;
      end case;
    end if;
  end process p_select_error_status;

  ---------------------------------------------------------------------
  -- output
  ---------------------------------------------------------------------
  o_wire_errors <= errors_r1;
  o_wire_status <= status_r1;


end architecture RTL;
