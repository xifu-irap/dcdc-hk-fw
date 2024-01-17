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
--    @file                   DCM_20MHz.vhd
--    reference design        Yann PAROT (IRAP Toulouse)
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--    Generated by Xilinx Architecture Wizard (ISE design Suite 14.7): Device: xc3s1500-4fg320.
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.Vcomponents.all;

entity DCM_20MHz is
  port (
    CLKIN_IN        : in  std_logic;
    CLKIN_IBUFG_OUT : out std_logic;
    CLK0_OUT        : out std_logic;
    LOCKED_OUT      : out std_logic
    );
end DCM_20MHz;

architecture BEHAVIORAL of DCM_20MHz is
  signal CLKFB_IN    : std_logic;
  signal CLKIN_IBUFG : std_logic;
  signal CLK0_BUF    : std_logic;
  signal GND_BIT     : std_logic;

begin
  GND_BIT         <= '0';
  CLKIN_IBUFG_OUT <= CLKIN_IBUFG;
  CLK0_OUT        <= CLKFB_IN;

  CLKIN_IBUFG_INST : IBUFG
    port map (
      I => CLKIN_IN,
      O => CLKIN_IBUFG
      );

  CLK0_BUFG_INST : BUFG
    port map (
      I => CLK0_BUF,
      O => CLKFB_IN
      );

  DCM_INST : DCM
    generic map(
      CLK_FEEDBACK          => "1X",
      CLKDV_DIVIDE          => 2.0,
      CLKFX_DIVIDE          => 1,
      CLKFX_MULTIPLY        => 4,
      CLKIN_DIVIDE_BY_2     => false,
      CLKIN_PERIOD          => 25.000,
      CLKOUT_PHASE_SHIFT    => "NONE",
      DESKEW_ADJUST         => "SYSTEM_SYNCHRONOUS",
      DFS_FREQUENCY_MODE    => "LOW",
      DLL_FREQUENCY_MODE    => "LOW",
      DUTY_CYCLE_CORRECTION => true,
      FACTORY_JF            => x"8080",
      PHASE_SHIFT           => 0,
      STARTUP_WAIT          => false
      )
    port map (
      CLKFB    => CLKFB_IN,
      CLKIN    => CLKIN_IBUFG,
      DSSEN    => GND_BIT,
      PSCLK    => GND_BIT,
      PSEN     => GND_BIT,
      PSINCDEC => GND_BIT,
      RST      => GND_BIT,
      CLKDV    => open,
      CLKFX    => open,
      CLKFX180 => open,
      CLK0     => CLK0_BUF,
      CLK2X    => open,
      CLK2X180 => open,
      CLK90    => open,
      CLK180   => open,
      CLK270   => open,
      LOCKED   => LOCKED_OUT,
      PSDONE   => open,
      STATUS   => open
      );

end BEHAVIORAL;


