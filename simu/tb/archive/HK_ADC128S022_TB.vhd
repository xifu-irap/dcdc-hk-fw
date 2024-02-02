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


library ieee;
use ieee.std_logic_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;

entity HK_ADC128S022_TB is
end HK_ADC128S022_TB;

architecture behavior of HK_ADC128S022_TB is

  -- Component Declaration for the Unit Under Test (UUT)

  component ADC128Sxxx
    port(
      Reset_n         : in  std_logic;
      clk             : in  std_logic;
      channel_address : in  std_logic_vector(2 downto 0);
      Output_value    : out std_logic_vector(11 downto 0);
      Start           : in  std_logic;
      Done            : out std_logic;
      ADC_Sclk        : out std_logic;
      ADC_Dout        : in  std_logic;
      ADC_Din         : out std_logic;
      ADC_Cs_n        : out std_logic
      );
  end component;

  component adc128s102
    port (
      SCLK  : in  std_ulogic := 'U';
      CSNeg : in  std_ulogic := 'U';
      DIN   : in  std_ulogic := 'U';
      VA    : in  real       := 5.0;
      IN0   : in  real       := 0.0;
      IN1   : in  real       := 0.0;
      IN2   : in  real       := 0.0;
      IN3   : in  real       := 0.0;
      IN4   : in  real       := 0.0;
      IN5   : in  real       := 0.0;
      IN6   : in  real       := 0.0;
      IN7   : in  real       := 0.0;
      DOUT  : out std_ulogic := 'U'
      );
  end component;


  --Inputs
  signal reset_n         : std_logic                    := '0';
  signal clk             : std_logic                    := '0';
  signal channel_address : std_logic_vector(2 downto 0) := (others => '0');
  signal start           : std_logic                    := '0';
  signal adc_dout        : std_logic                    := '0';

  --Outputs
  signal output_value : std_logic_vector(11 downto 0);
  signal done         : std_logic;
  signal adc_sclk     : std_logic;
  signal adc_din      : std_logic;
  signal adc_cs_n     : std_logic;

  -- Clock period definitions
  constant clk_period : time := 312.5 ns;  --3.2MHz

begin

  -- Instantiate the Unit Under Test (UUT)
  uut : ADC128Sxxx port map (
    Reset_n         => reset_n,
    clk             => clk,
    channel_address => channel_address,
    Output_value    => output_value,
    Start           => start,
    Done            => done,
    ADC_Sclk        => adc_sclk,
    ADC_Dout        => adc_dout,
    ADC_Din         => adc_din,
    ADC_Cs_n        => adc_cs_n
    );


  ADC_Component : adc128s102
    port map(
      SCLK  => adc_sclk,
      CSNeg => adc_cs_n,
      DIN   => adc_din,
      VA    => 5.0,
      IN0   => 0.1,
      IN1   => 1.0,
      IN2   => 2.0,
      IN3   => 3.0,
      IN4   => 4.0,
      IN5   => 5.0,
      IN6   => 1.2,
      IN7   => 2.5,
      DOUT  => adc_dout
      );

  -- Clock process definitions
  p_clk : process
  begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
  end process;



  -- Stimulus process
  p_stim : process
  begin
    -- hold reset state for 100 ns.
    wait for 100 ns;

    reset_n <= '1';

    wait for clk_period*10;

    -- insert stimulus here
    channel_address <= "000";
    start           <= '1';
    -- attente 2 clk
    wait for clk_period*2;
    start           <= '0';
    --attente pour tempo 100kHz
    wait for clk_period*100;

    channel_address <= "100";
    wait for clk_period*10;
    start           <= '1';



    wait;
  end process;


end;

