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
--    @file                   led_blink.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module generates a periodic pulse width with a ratio of 50%.
--      . The high level duration (expressed in clock period) is defined by the g_NB_CYCLES_LED_ON value
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_utils.all;

entity led_blink is
  generic (
    -- LED ON: number of cycles (should be a power of 2)
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

    ---------------------------------------------------------------------
    -- output @i_clk
    ---------------------------------------------------------------------
    -- FPGA board: status led
    o_led : out std_logic

    );
end entity led_blink;

architecture RTL of led_blink is

  -- counter width
  constant c_CNT_WIDTH : integer := work.pkg_utils.pkg_width_from_value(g_NB_CYCLES_LED_ON*2);

  ---------------------------------------------------------------------
  -- counter
  ---------------------------------------------------------------------
  -- led: count the number of clock cycles
  signal cnt_r1 : unsigned(c_CNT_WIDTH - 1 downto 0) := (others => '0');
  -- led: change state
  signal trig   : std_logic;

  ---------------------------------------------------------------------
  -- optional output delay
  ---------------------------------------------------------------------
  -- temporary input pipe
  signal data_tmp0 : std_logic_vector(0 downto 0);
  -- temporary output pipe
  signal data_tmp1 : std_logic_vector(0 downto 0);

  -- delayed led value.
  signal led_rx : std_logic;

begin


  ---------------------------------------------------------------------
  -- detect @clk alive
  ---------------------------------------------------------------------
  p_blink : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      cnt_r1 <= cnt_r1 + 1;
    end if;
  end process p_blink;

  trig <= cnt_r1(cnt_r1'high);

  ---------------------------------------------------------------------
  -- optional output pipe
  ---------------------------------------------------------------------
  data_tmp0(0) <= trig;

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

  led_rx <= data_tmp1(0);

  ---------------------------------------------------------------------
  -- output
  ---------------------------------------------------------------------
  o_led <= led_rx;


end architecture RTL;
