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
--    @file                   one_error_latch.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module defines 2 modes of error management.
--       . The transparent mode: the error is delayed by one clock cycle.
--         . If the input error is a pulse then the output error will also be a pulse.
--         . If the input error is a level then the output error will also be a level.
--       . The capture mode: if the input error is set to '1', the output error is set to '1' until a reset signal is received
--
-- -------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;


entity one_error_latch is
  port (
    -- clock
    i_clk         : in  std_logic;
    -- reset error flag
    i_rst         : in  std_logic;
    -- error mode (transparent vs capture). Possible values: '1': delay the error, '0': capture the error
    i_debug_pulse : in  std_logic;
    -- input error
    i_error       : in  std_logic;
    -- output error
    o_error       : out std_logic
    );
end entity one_error_latch;

architecture RTL of one_error_latch is
  -- output error
  signal error_r : std_logic := '0';

begin

  ---------------------------------------------------------------------
  -- This process pass or latch an input error (user-defined)
  ---------------------------------------------------------------------
  p_detect_error : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      if i_rst = '1' then
        error_r <= '0';
      elsif i_debug_pulse = '1' then
        -- delay the input error
        error_r <= i_error;
      elsif i_error = '1' then
        -- latch the input error
        error_r <= '1';
      end if;
    end if;
  end process p_detect_error;

  ---------------------------------------------------------------------
  -- output
  ---------------------------------------------------------------------
  o_error <= error_r;

end architecture RTL;
