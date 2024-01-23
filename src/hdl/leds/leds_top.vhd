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
--    @file                   leds_top.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module manages the leds
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity leds_top is
  port (

    ---------------------------------------------------------------------
    -- input @i_clk
    ---------------------------------------------------------------------
    -- clock
    i_clk : in std_logic;
    -- reset  @i_clk
    i_rst : in std_logic;

    ---------------------------------------------------------------------
    -- from science @i_clk
    ---------------------------------------------------------------------
    -- -- Valid start ADCs' acquisition
    i_adc_start_valid : in std_logic;
    -- start ADCs' acquisition
    i_adc_start       : in std_logic;

    ---------------------------------------------------------------------
    -- output @i_clk
    ---------------------------------------------------------------------
    -- FPGA board: status leds ('1':ON, 'Z':OFF)
    o_leds : out std_logic_vector(7 downto 0)

    );
end entity leds_top;

architecture RTL of leds_top is

  ---------------------------------------------------------------------
  -- led_blink
  ---------------------------------------------------------------------
  signal led_blink : std_logic;

  ---------------------------------------------------------------------
  -- led_blink_on_start
  ---------------------------------------------------------------------
  signal start        : std_logic;
  signal led_on_start : std_logic;

begin



  ---------------------------------------------------------------------
  -- led blink
  ---------------------------------------------------------------------
  -- detect the @i_clk is alive
  inst_led_blink : entity work.led_blink
    generic map(
      -- LED ON: number of cycles (should be a power of 2)
      g_NB_CYCLES_LED_ON => 2**26,
      -- optional output latency (range >= 0)
      g_OUTPUT_LATENCY   => 1
      )
    port map(
      ---------------------------------------------------------------------
      -- input @i_clk
      ---------------------------------------------------------------------
      -- clock
      i_clk => i_clk,
      ---------------------------------------------------------------------
      -- output @i_clk
      ---------------------------------------------------------------------
      -- FPGA board: status led
      o_led => led_blink
      );

  ---------------------------------------------------------------------
  -- led_blink_on_start
  ---------------------------------------------------------------------
  start <= '1' when i_adc_start = '1' and i_adc_start_valid = '1' else '0';

  inst_led_blink_on_start : entity work.led_blink_on_start
    generic map(
      -- LED ON: number of cycles (must be >0)
      g_NB_CYCLES_LED_ON => 2**26,
      -- optional output latency (range >= 0)
      g_OUTPUT_LATENCY   => 1
      )
    port map(
      ---------------------------------------------------------------------
      -- input @i_clk
      ---------------------------------------------------------------------
      -- clock
      i_clk   => i_clk,
      -- reset
      i_rst   => i_rst,
      -- start
      i_start => start,
      ---------------------------------------------------------------------
      -- output @i_clk
      ---------------------------------------------------------------------
      -- FPGA board: status led
      o_led   => led_on_start
      );


  ---------------------------------------------------------------------
  -- output
  ---------------------------------------------------------------------
  o_leds(0)          <= '0';            -- ON: led_fw
  o_leds(1)          <= 'Z';  -- OFF: N/A: no pll_lock signal available
  o_leds(2)          <= '0' when led_blink = '1'    else 'Z';
  o_leds(3)          <= '0' when led_on_start = '1' else 'Z';
  o_leds(7 downto 4) <= (others => 'Z');



end architecture RTL;
