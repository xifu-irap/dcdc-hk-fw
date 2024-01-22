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


  -- led: count clock cycle
  signal cnt_r1 : unsigned(26 downto 0) := (others => '0');
  -- led: change state
  signal trig   : std_logic;

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
  -- output
  ---------------------------------------------------------------------
  o_leds(0) <= '0';                     -- ON: led_fw
  o_leds(1) <= 'Z';                     -- OFF: N/A: led_pll_lock
  o_leds(2) <= '0' when trig = '1' else 'Z';



end architecture RTL;
