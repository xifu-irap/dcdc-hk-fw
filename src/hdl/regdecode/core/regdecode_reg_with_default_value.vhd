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
--    @file                   regdecode_reg_with_default_value.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module does the following steps:
--      1. After the reset, set the output data to a default value
--      2. On Input data change, copy the input data to the output data.
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity regdecode_reg_with_default_value is
  generic (
    -- data default value (on the Reset)
    g_DATA_DEFAULT : integer := 0;
    -- input/output data width
    g_DATA_WIDTH   : integer := 32
    );
  port (

    -- input clock
    i_clk : in std_logic;
    -- input reset
    i_rst : in std_logic;

    ---------------------------------------------------------------------
    -- input register
    ---------------------------------------------------------------------
    i_data : in std_logic_vector(g_DATA_WIDTH - 1 downto 0);

    ---------------------------------------------------------------------
    -- output
    ---------------------------------------------------------------------
    -- data valid
    o_data_valid : out std_logic;
    -- data
    o_data       : out std_logic_vector(g_DATA_WIDTH - 1 downto 0)

    );
end entity regdecode_reg_with_default_value;

architecture RTL of regdecode_reg_with_default_value is

  -- default data value
  constant c_DATA_DEFAULT : std_logic_vector(i_data'range) := std_logic_vector(to_unsigned(g_DATA_DEFAULT, i_data'length));
  ---------------------------------------------------------------------
  -- pipe
  ---------------------------------------------------------------------
  -- delayed data
  signal data_pipe_r1     : std_logic_vector(i_data'range);

  ---------------------------------------------------------------------
  -- State machine
  ---------------------------------------------------------------------
  -- fsm type declaration
  type t_state is (E_RST, E_WAIT_DATA_CHANGE);
  -- state
  signal sm_state_next : t_state;
  -- state (registered)
  signal sm_state_r1   : t_state := E_RST;

  -- data valid
  signal data_valid_next : std_logic;
  -- delayed data valid
  signal data_valid_r1   : std_logic;

  -- data
  signal data_next : std_logic_vector(i_data'range);
  -- delayed data
  signal data_r1   : std_logic_vector(i_data'range);


begin

  -- delayed the input data in order to detect a change
  p_pipe : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      data_pipe_r1 <= i_data;
    end if;
  end process p_pipe;

  ---------------------------------------------------------------------
  -- State machine
  ---------------------------------------------------------------------
  -- 1. On Reset, set the output data to a default value
  -- 2. On input value change, copy the input data value to the output
  p_decode_state : process (data_pipe_r1, data_r1, i_data, sm_state_r1) is
  begin

    -- default values
    data_valid_next <= '0';
    data_next       <= data_r1;

    case sm_state_r1 is

      when E_RST =>                     -- load defaut value
        data_next     <= c_DATA_DEFAULT;
        sm_state_next <= E_WAIT_DATA_CHANGE;

      when E_WAIT_DATA_CHANGE =>  -- update output data on input data change
        if unsigned(data_pipe_r1) /= unsigned(i_data) then
          data_valid_next <= '1';
          data_next       <= i_data;
          sm_state_next   <= E_WAIT_DATA_CHANGE;
        else
          sm_state_next <= E_WAIT_DATA_CHANGE;
        end if;

      when others =>
        sm_state_next <= E_RST;
    end case;
  end process p_decode_state;

  -- FSM: registred signals
  p_state : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      if i_rst = '1' then
        sm_state_r1 <= E_RST;
      else
        sm_state_r1 <= sm_state_next;
      end if;

      data_valid_r1 <= data_valid_next;
      data_r1       <= data_next;

    end if;
  end process p_state;

  ---------------------------------------------------------------------
  -- output
  ---------------------------------------------------------------------
  o_data_valid <= data_valid_r1;
  o_data       <= data_r1;

end architecture RTL;
