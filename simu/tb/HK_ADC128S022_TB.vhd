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
--    @file                   HK_ADC128S022_TB.vhd
--    reference design        Yann PAROT (IRAP Toulouse)
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--    VHDL Test Bench Created by ISE for module: ADC128Sxxx
--
--    Notes:
--      This testbench has been automatically generated using types std_logic and
--      std_logic_vector for the ports of the unit under test.  Xilinx recommends
--      that these types always be used for the top-level I/O of a design in order
--      to guarantee that the testbench will bind correctly to the post-implementation
--      simulation model.
-- -------------------------------------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;

ENTITY HK_ADC128S022_TB IS
END HK_ADC128S022_TB;

ARCHITECTURE behavior OF HK_ADC128S022_TB IS

    -- Component Declaration for the Unit Under Test (UUT)

    COMPONENT ADC128Sxxx
    PORT(
         Reset_n : IN  std_logic;
         clk : IN  std_logic;
         channel_address : IN  std_logic_vector(2 downto 0);
         Output_value : OUT  std_logic_vector(11 downto 0);
         Start : IN  std_logic;
         Done : OUT  std_logic;
         ADC_Sclk : OUT  std_logic;
         ADC_Dout : IN  std_logic;
         ADC_Din : OUT  std_logic;
         ADC_Cs_n : OUT  std_logic
        );
    END COMPONENT;

   COMPONENT adc128s102
   PORT (
        SCLK  : IN  std_ulogic := 'U';
        CSNeg : IN  std_ulogic := 'U';
        DIN   : IN  std_ulogic := 'U';
        VA    : IN  real       := 5.0;
        IN0   : IN  real       := 0.0;
        IN1   : IN  real       := 0.0;
        IN2   : IN  real       := 0.0;
        IN3   : IN  real       := 0.0;
        IN4   : IN  real       := 0.0;
        IN5   : IN  real       := 0.0;
        IN6   : IN  real       := 0.0;
        IN7   : IN  real       := 0.0;
        DOUT  : OUT std_ulogic := 'U'
        );
  END COMPONENT;


   --Inputs
   signal Reset_n : std_logic := '0';
   signal clk : std_logic := '0';
   signal channel_address : std_logic_vector(2 downto 0) := (others => '0');
   signal Start : std_logic := '0';
   signal ADC_Dout : std_logic := '0';

  --Outputs
   signal Output_value : std_logic_vector(11 downto 0);
   signal Done : std_logic;
   signal ADC_Sclk : std_logic;
   signal ADC_Din : std_logic;
   signal ADC_Cs_n : std_logic;

   -- Clock period definitions
   constant clk_period : time := 312.5 ns; --3.2MHz

BEGIN

  -- Instantiate the Unit Under Test (UUT)
   uut: ADC128Sxxx PORT MAP (
          Reset_n => Reset_n,
          clk => clk,
          channel_address => channel_address,
          Output_value => Output_value,
          Start => Start,
          Done => Done,
          ADC_Sclk => ADC_Sclk,
          ADC_Dout => ADC_Dout,
          ADC_Din => ADC_Din,
          ADC_Cs_n => ADC_Cs_n
        );


  ADC_Component: adc128s102
   PORT MAP(
        SCLK  => ADC_Sclk,
        CSNeg => ADC_Cs_n,
        DIN   => ADC_Din,
        VA    => 5.0,
        IN0   => 0.1,
        IN1   => 1.0,
        IN2   => 2.0,
        IN3   => 3.0,
        IN4   => 4.0,
        IN5   => 5.0,
        IN6   =>1.2,
        IN7   => 2.5,
        DOUT  => ADC_Dout
        );

   -- Clock process definitions
   clk_process :process
   begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
   end process;



   -- Stimulus process
   stim_proc: process
   begin
      -- hold reset state for 100 ns.
      wait for 100 ns;

    Reset_n <= '1';

      wait for clk_period*10;

      -- insert stimulus here
    channel_address <= "000";
    start <= '1';
    -- attente 2 clk
    wait for clk_period*2;
    start <='0';
    --attente pour tempo 100kHz
    wait for clk_period*100;

    channel_address <= "100";
    wait for clk_period*10;
    start <= '1';



      wait;
   end process;

END;
