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
--    @file                   system_dcdc_top.vhd
--    reference design        Yann PAROT (IRAP Toulouse)
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--    Top level architecture
--
-- -------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity system_dcdc_top is
  port (
    --  Opal Kelly inouts --
    -- usb interface signal
    i_okUH  : in    std_logic_vector(4 downto 0);
    -- usb interface signal
    o_okHU  : out   std_logic_vector(2 downto 0);
    -- usb interface signal
    b_okUHU : inout std_logic_vector(31 downto 0);
    -- usb interface signal
    b_okAA  : inout std_logic;

    -- ADC128S102 HK
    o_adc_sclk : out std_logic;
    i_adc_dout : in  std_logic;
    o_adc_din  : out std_logic;
    o_adc_cs_n : out std_logic;

    -- power card controls
    o_power_on_off: out std_logic_vector(3 downto 0)


    );
end system_dcdc_top;

architecture arch of system_dcdc_top is



begin






end arch;
