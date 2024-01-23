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
--    @file                   led_blink_on_start.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module generates a positive pulse only when an input start command is received.
--      . The positive pulse duration (expressed in clock period) is defined by the g_NB_CYCLES_LED_ON value
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_utils.all;

entity led_blink_on_start is
  generic (
    -- LED ON: number of cycles (must be >0)
    g_NB_CYCLES_LED_ON : integer := 10_0000;
    -- optional output latency (range >= 0)
    g_OUTPUT_LATENCY   : integer := 0
    );
  port (

    ---------------------------------------------------------------------
    -- input @i_clk
    ---------------------------------------------------------------------
    -- clock
    i_clk : in std_logic;
    -- reset
    i_rst : in std_logic;

    -- start
    i_start : in std_logic;

    ---------------------------------------------------------------------
    -- output @i_clk
    ---------------------------------------------------------------------
    -- FPGA board: status led
    o_led : out std_logic

    );
end entity led_blink_on_start;

architecture RTL of led_blink_on_start is

  -- counter width
  constant c_CNT_WIDTH : integer := work.pkg_utils.pkg_width_from_value(g_NB_CYCLES_LED_ON*2);

  ---------------------------------------------------------------------
  -- counter
  ---------------------------------------------------------------------
  -- fsm type declaration
  type t_state is (E_RST, E_WAIT, E_RUN);
  -- state
  signal sm_state_next : t_state;
  -- state (registered)
  signal sm_state_r1   : t_state := E_RST;

  -- count clock cycle ON
  signal cnt_next : unsigned(c_CNT_WIDTH - 1 downto 0) := (others => '0');
  -- delayed count clock cycle ON
  signal cnt_r1   : unsigned(c_CNT_WIDTH - 1 downto 0) := (others => '0');

  -- positive pulse
  signal pulse_next : std_logic;
  -- delayed positive pulse
  signal pulse_r1   : std_logic;

  ---------------------------------------------------------------------
  -- optional output delay
  ---------------------------------------------------------------------
  -- temporary input pipe
  signal data_tmp0 : std_logic_vector(0 downto 0);
  -- temporary output pipe
  signal data_tmp1 : std_logic_vector(0 downto 0);

  -- delayed pulse value.
  signal pulse_rx : std_logic;

begin


  ---------------------------------------------------------------------
  -- fsm: On new start command, generate a pulse.
  ---------------------------------------------------------------------
  -- The steps are:
  --   1. reset the counter (for the led ON)
  --   2. wait a new start command
  --   3. generate a positive pulse during g_NB_CYCLES_LED_ON clock cycles
  --   4. repeate 2. to 3.
  p_decode_state : process (cnt_r1, i_start, sm_state_r1) is
  begin
    pulse_next <= '0';
    cnt_next   <= cnt_r1;
    case sm_state_r1 is
      when E_RST =>
        cnt_next      <= (others => '0');
        sm_state_next <= E_RST;

      when E_WAIT =>                    -- wait a new start command
        cnt_next <= (others => '0');

        if i_start = '1' then
          sm_state_next <= E_RUN;
        else
          sm_state_next <= E_WAIT;
        end if;

      when E_RUN =>  -- generate a high level pulse during g_NB_CYCLES_LED_ON clock cycles

        cnt_next   <= cnt_r1 + 1;
        pulse_next <= '1';

        if cnt_r1 = to_unsigned(g_NB_CYCLES_LED_ON - 1, cnt_r1'length) then
          sm_state_next <= E_WAIT;
        else
          sm_state_next <= E_RUN;
        end if;

      when others =>
        sm_state_next <= E_RST;
    end case;
  end process p_decode_state;

  -- registered FSM signals
  p_state : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      if i_rst = '1' then
        sm_state_r1 <= E_RST;
      else
        sm_state_r1 <= sm_state_next;
      end if;
      cnt_r1   <= cnt_next;
      pulse_r1 <= pulse_next;
    end if;
  end process p_state;

  ---------------------------------------------------------------------
  -- optional output pipe
  ---------------------------------------------------------------------
  data_tmp0(0) <= pulse_r1;

  inst_pipeliner_with_init : entity work.pipeliner_with_init
    generic map(
      -- register init value
      g_INIT       => '0',
      -- number of consecutives registers. Possibles values: [0, integer max value[
      g_NB_PIPES   => g_OUTPUT_LATENCY,
      -- width of the input/output data.  Possibles values: [1, integer max value[
      g_DATA_WIDTH => data_tmp0'length
      )
    port map(
      -- clock
      i_clk  => i_clk,
      -- input data
      i_data => data_tmp0,
      -- output data with/without delay
      o_data => data_tmp1
      );

  pulse_rx <= data_tmp1(0);

  ---------------------------------------------------------------------
  -- output
  ---------------------------------------------------------------------
  o_led <= pulse_rx;


end architecture RTL;
