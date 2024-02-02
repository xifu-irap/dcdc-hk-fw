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
--    This module is the top_level for the leds' management.
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

    -- power_valid (for power_on and power_off)
    i_power_valid : in std_logic;
    -- bitwise power ('1': power_on, '0':power off)
    i_power       : in std_logic_vector(3 downto 0);

    ---------------------------------------------------------------------
    -- output @i_clk
    ---------------------------------------------------------------------
    -- FPGA board: status leds ('0':ON, 'Z':OFF)
    o_leds : out std_logic_vector(7 downto 0)

    );
end entity leds_top;

architecture RTL of leds_top is

  ---------------------------------------------------------------------
  -- led_blink
  ---------------------------------------------------------------------
  -- periodic led blink
  signal led_blink : std_logic;

  ---------------------------------------------------------------------
  -- inst_led_blink_on_adc_start
  ---------------------------------------------------------------------
  -- aperiodic led blink on start command.
  signal led_adc_start : std_logic;

  ---------------------------------------------------------------------
  -- inst_led_blink_on_power_start
  ---------------------------------------------------------------------
  -- aperiodic led blink on start command.
  signal led_power_start : std_logic;


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
  -- ADC: pulse on start adc
  ---------------------------------------------------------------------
  inst_led_blink_on_adc_start : entity work.led_blink_on_start
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
      i_start => i_adc_start_valid,
      ---------------------------------------------------------------------
      -- output @i_clk
      ---------------------------------------------------------------------
      -- FPGA board: status led
      o_led   => led_adc_start
      );

  ---------------------------------------------------------------------
  -- ADC: pulse on start adc
  ---------------------------------------------------------------------
  inst_led_blink_on_power_start : entity work.led_blink_on_start
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
      i_start => i_power_valid,
      ---------------------------------------------------------------------
      -- output @i_clk
      ---------------------------------------------------------------------
      -- FPGA board: status led
      o_led   => led_power_start
      );


  ---------------------------------------------------------------------
  -- output
  --  The FPGA leds board must respected the following behaviour:
  --   . status leds ('0':ON, 'Z':OFF)
  ---------------------------------------------------------------------
  o_leds(0)          <= '0';            -- ON: led_fw
  o_leds(1)          <= '0' when led_blink = '1'    else 'Z';
  o_leds(2)          <= '0' when led_adc_start = '1' else 'Z';
  o_leds(3)          <= '0' when led_power_start = '1' else 'Z';
  o_leds(4)          <= '0' when i_power(0) = '1' else 'Z';
  o_leds(5)          <= '0' when i_power(1) = '1' else 'Z';
  o_leds(6)          <= '0' when i_power(2) = '1' else 'Z';
  o_leds(7)          <= '0' when i_power(3) = '1' else 'Z';



end architecture RTL;
