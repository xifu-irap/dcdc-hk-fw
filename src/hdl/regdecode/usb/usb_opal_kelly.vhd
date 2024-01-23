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
--    @file                   usb_opal_kelly.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module instanciates the necessary different opal kelly components
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.frontpanel.all;

entity usb_opal_kelly is
  port(
    --  Opal Kelly inouts --
    -- usb interface signal
    i_okUH  : in    std_logic_vector(4 downto 0);
    -- usb interface signal
    o_okHU  : out   std_logic_vector(2 downto 0);
    -- usb interface signal
    b_okUHU : inout std_logic_vector(31 downto 0);
    -- usb interface signal
    b_okAA  : inout std_logic;

    ---------------------------------------------------------------------
    -- from the user @o_usb_clk
    ---------------------------------------------------------------------
    -- wire_out
    -- ctrl register (reading)
    i_usb_wireout_ctrl       : in std_logic_vector(31 downto 0);
    -- power_ctrl register (reading)
    i_usb_wireout_power_ctrl : in std_logic_vector(31 downto 0);

    -- ADC
    ---------------------------------------------------------------------
    -- adc_ctrl register (reading)
    i_usb_wireout_adc_ctrl   : in std_logic_vector(31 downto 0);
    -- adc_status register (reading)
    i_usb_wireout_adc_status : in std_logic_vector(31 downto 0);

    -- adc0 register (reading)
    i_usb_wireout_adc0 : in std_logic_vector(31 downto 0);
    -- adc1 register (reading)
    i_usb_wireout_adc1 : in std_logic_vector(31 downto 0);
    -- adc2 register (reading)
    i_usb_wireout_adc2 : in std_logic_vector(31 downto 0);
    -- adc3 register (reading)
    i_usb_wireout_adc3 : in std_logic_vector(31 downto 0);
    -- adc4 register (reading)
    i_usb_wireout_adc4 : in std_logic_vector(31 downto 0);
    -- adc5 register (reading)
    i_usb_wireout_adc5 : in std_logic_vector(31 downto 0);
    -- adc6 register (reading)
    i_usb_wireout_adc6 : in std_logic_vector(31 downto 0);
    -- adc7 register (reading)
    i_usb_wireout_adc7 : in std_logic_vector(31 downto 0);


    -- hardware id register (reading)
    i_usb_wireout_hardware_id   : in std_logic_vector(31 downto 0);
    -- firmware_name register (reading)
    i_usb_wireout_firmware_name : in std_logic_vector(31 downto 0);
    -- firmware_id register (reading)
    i_usb_wireout_firmware_id   : in std_logic_vector(31 downto 0);

    -- errors/status
    -- debug_ctrl register (reading)
    i_usb_wireout_debug_ctrl : in std_logic_vector(31 downto 0);
    -- sel_errors register (reading)
    i_usb_wireout_sel_errors : in std_logic_vector(31 downto 0);
    -- errors register (reading)
    i_usb_wireout_errors     : in std_logic_vector(31 downto 0);
    -- status register (reading)
    i_usb_wireout_status     : in std_logic_vector(31 downto 0);

    ---------------------------------------------------------------------
    -- to the user @o_usb_clk
    ---------------------------------------------------------------------
    -- usb clock
    o_usb_clk : out std_logic;


    -- wire
    -- ctrl register (writting)
    o_usb_wirein_ctrl       : out std_logic_vector(31 downto 0);
    -- power_ctrl register (writting)
    o_usb_wirein_power_ctrl : out std_logic_vector(31 downto 0);
    -- adc_ctrl register (writting)
    o_usb_wirein_adc_ctrl   : out std_logic_vector(31 downto 0);
    -- debugging
    -- debug_ctrl register (writting)
    o_usb_wirein_debug_ctrl : out std_logic_vector(31 downto 0);
    -- sel_errors register (writting)
    o_usb_wirein_sel_errors : out std_logic_vector(31 downto 0)
    );
end entity usb_opal_kelly;

architecture RTL of usb_opal_kelly is

  -- total number of used wire out, pipe out, pipe in and trigger out
  constant c_WIRE_PIPE_TRIG_NUMBER_OUT : integer := 19;

  ---- Opal Kelly signals ----
  -- usb interface signal
  signal okClk : std_logic;
  -- usb interface signal
  signal okHE  : std_logic_vector(112 downto 0);
  -- usb interface signal
  signal okEH  : std_logic_vector(64 downto 0);
  -- usb interface signal
  signal okEHx : std_logic_vector(c_WIRE_PIPE_TRIG_NUMBER_OUT * 65 - 1 downto 0);

  -- type definition for the used wire out, pipe out, pipe in and trigger out
  type t_array65 is array (0 to c_WIRE_PIPE_TRIG_NUMBER_OUT - 1) of std_logic_vector(64 downto 0);

  -- array of vector
  signal okEHx_array : t_array65;

  -- wires in
  signal ep00_wire : std_logic_vector(31 downto 0);  -- wire in00
  signal ep01_wire : std_logic_vector(31 downto 0);  -- wire in01
  --signal ep02_wire : std_logic_vector(31 downto 0);  -- wire in02
  --signal ep03_wire : std_logic_vector(31 downto 0);-- wire in03
  signal ep04_wire : std_logic_vector(31 downto 0);  -- wire in04
  --signal ep05_wire : std_logic_vector(31 downto 0);-- wire in05
  --signal ep06_wire : std_logic_vector(31 downto 0);-- wire in06
  --signal ep07_wire : std_logic_vector(31 downto 0);-- wire in07
  --signal ep08_wire : std_logic_vector(31 downto 0);-- wire in08
  --signal ep09_wire : std_logic_vector(31 downto 0);-- wire in09
  --signal ep0A_wire : std_logic_vector(31 downto 0);-- wire in10
  --signal ep0B_wire : std_logic_vector(31 downto 0);-- wire in11
  --signal ep0C_wire : std_logic_vector(31 downto 0);-- wire in12
  --signal ep0D_wire : std_logic_vector(31 downto 0);-- wire in13
  --signal ep0E_wire : std_logic_vector(31 downto 0);-- wire in14
  --signal ep0F_wire : std_logic_vector(31 downto 0);-- wire in15
  --signal ep10_wire : std_logic_vector(31 downto 0);-- wire in16
  --signal ep11_wire : std_logic_vector(31 downto 0);-- wire in17
  --signal ep12_wire : std_logic_vector(31 downto 0);-- wire in18
  --signal ep13_wire : std_logic_vector(31 downto 0);-- wire in19
  --signal ep14_wire : std_logic_vector(31 downto 0);-- wire in20
  --signal ep15_wire : std_logic_vector(31 downto 0);-- wire in21
  --signal ep16_wire : std_logic_vector(31 downto 0);-- wire in22
  --signal ep17_wire : std_logic_vector(31 downto 0);-- wire in23
  signal ep18_wire : std_logic_vector(31 downto 0);  -- wire in24
  signal ep19_wire : std_logic_vector(31 downto 0);  -- wire in25
  --signal ep1A_wire : std_logic_vector(31 downto 0);-- wire in26
  --signal ep1B_wire : std_logic_vector(31 downto 0);-- wire in27
  --signal ep1C_wire : std_logic_vector(31 downto 0);-- wire in28
  --signal ep1D_wire : std_logic_vector(31 downto 0);-- wire in29
  --signal ep1E_wire : std_logic_vector(31 downto 0);-- wire in30
  --signal ep1F_wire : std_logic_vector(31 downto 0);-- wire in31

  -- wires out
  signal ep20_wire : std_logic_vector(31 downto 0);  -- wire out00
  signal ep21_wire : std_logic_vector(31 downto 0);  -- wire out01
  --signal ep22_wire : std_logic_vector(31 downto 0);  -- wire out02
  --signal ep23_wire : std_logic_vector(31 downto 0);  -- wire out03
  signal ep24_wire : std_logic_vector(31 downto 0);  -- wire out04
  signal ep25_wire : std_logic_vector(31 downto 0);  -- wire out05
  --signal ep26_wire : std_logic_vector(31 downto 0);  -- wire out06
  --signal ep27_wire : std_logic_vector(31 downto 0);  -- wire out07
  --signal ep28_wire : std_logic_vector(31 downto 0);  -- wire out08
  --signal ep29_wire : std_logic_vector(31 downto 0);  -- wire out09
  --signal ep2A_wire : std_logic_vector(31 downto 0); -- wire out10
  --signal ep2B_wire : std_logic_vector(31 downto 0); -- wire out11
  --signal ep2C_wire : std_logic_vector(31 downto 0); -- wire out12
  --signal ep2D_wire : std_logic_vector(31 downto 0); -- wire out13
  --signal ep2E_wire : std_logic_vector(31 downto 0); -- wire out14
  --signal ep2F_wire : std_logic_vector(31 downto 0); -- wire out15
  signal ep30_wire : std_logic_vector(31 downto 0);  -- wire out16
  signal ep31_wire : std_logic_vector(31 downto 0);  -- wire out17
  signal ep32_wire : std_logic_vector(31 downto 0);  -- wire out18
  signal ep33_wire : std_logic_vector(31 downto 0);  -- wire out19
  signal ep34_wire : std_logic_vector(31 downto 0);  -- wire out20
  signal ep35_wire : std_logic_vector(31 downto 0);  -- wire out21
  signal ep36_wire : std_logic_vector(31 downto 0);  -- wire out22
  signal ep37_wire : std_logic_vector(31 downto 0);  -- wire out23
  signal ep38_wire : std_logic_vector(31 downto 0);  -- wire out24
  signal ep39_wire : std_logic_vector(31 downto 0);  -- wire out25
  signal ep3A_wire : std_logic_vector(31 downto 0);  -- wire out26
  signal ep3B_wire : std_logic_vector(31 downto 0);  -- wire out27
  --signal ep3C_wire : std_logic_vector(31 downto 0); -- wire out28
  signal ep3D_wire : std_logic_vector(31 downto 0);  -- wire out29
  signal ep3E_wire : std_logic_vector(31 downto 0);  -- wire out30
  signal ep3F_wire : std_logic_vector(31 downto 0);  -- wire out31


begin

  ----------------------------------------------------
  --    Opal Kelly Host
  ----------------------------------------------------
  inst_Opal_Kelly_Host : okHost
    port map(
      okUH  => i_okUH,
      okHU  => o_okHU,
      okUHU => b_okUHU,
      okAA  => b_okAA,
      okClk => okClk,  -- Clock Opal Kelly generated in the okLibrary
      okHE  => okHE,
      okEH  => okEH
      );
  ----------------------------------------------------
  --    Opal Kelly Wire OR
  ----------------------------------------------------
  inst_wireor_opak_kelly : okWireOR
    generic map(N => c_WIRE_PIPE_TRIG_NUMBER_OUT)  -- N = Number of wires + pipes used
    port map(
      okEH  => okEH,
      okEHx => okEHx
      );

  ---------------------------------------------------------------------
  -- inputs
  ---------------------------------------------------------------------
  -- to wire_out: main
  ep20_wire <= i_usb_wireout_ctrl;
  ep21_wire <= i_usb_wireout_power_ctrl;

  ep24_wire <= i_usb_wireout_adc_ctrl;
  ep25_wire <= i_usb_wireout_adc_status;

  ep30_wire <= i_usb_wireout_adc0;
  ep31_wire <= i_usb_wireout_adc1;
  ep32_wire <= i_usb_wireout_adc2;
  ep33_wire <= i_usb_wireout_adc3;
  ep34_wire <= i_usb_wireout_adc4;
  ep35_wire <= i_usb_wireout_adc5;
  ep36_wire <= i_usb_wireout_adc6;
  ep37_wire <= i_usb_wireout_adc7;

  -- to wire_out: debug
  ep38_wire <= i_usb_wireout_debug_ctrl;
  ep39_wire <= i_usb_wireout_sel_errors;
  ep3A_wire <= i_usb_wireout_errors;
  ep3B_wire <= i_usb_wireout_status;

  ep3D_wire <= i_usb_wireout_hardware_id;
  ep3E_wire <= i_usb_wireout_firmware_name;
  ep3F_wire <= i_usb_wireout_firmware_id;

  ----------------------------------------------------
  --    Opal Kelly Wire in
  ----------------------------------------------------
  inst_okwirein_ep00 : okWireIn
    port map(
      okHE       => okHE,
      ep_addr    => x"00",              -- Endpoint address
      ep_dataout => ep00_wire           -- Endpoint data in 32 bits
      );

  inst_okwirein_ep01 : okWireIn
    port map(
      okHE       => okHE,
      ep_addr    => x"01",              -- Endpoint address
      ep_dataout => ep01_wire           -- Endpoint data in 32 bits
      );

  inst_okwirein_ep02 : okWireIn
    port map(
      okHE       => okHE,
      ep_addr    => x"04",              -- Endpoint address
      ep_dataout => ep04_wire           -- Endpoint data in 32 bits
      );


  inst_okwirein_ep18 : okWireIn
    port map(
      okHE       => okHE,
      ep_addr    => x"18",              -- Endpoint address
      ep_dataout => ep18_wire           -- Endpoint data in 32 bits
      );

  inst_okwirein_ep19 : okWireIn
    port map(
      okHE       => okHE,
      ep_addr    => x"19",              -- Endpoint address
      ep_dataout => ep19_wire           -- Endpoint data in 32 bits
      );

  ----------------------------------------------------
  --    Opal Kelly Wire out
  ----------------------------------------------------
  gen_array : for i in 0 to c_WIRE_PIPE_TRIG_NUMBER_OUT - 1 generate
    okEHx(65*(i+1)-1 downto i*65) <= okEHx_array(i);
  end generate gen_array;

  inst_okwireout_ep20 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(0),
      ep_addr   => x"20",               -- Endpoint address
      ep_datain => ep20_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep21 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(1),
      ep_addr   => x"21",               -- Endpoint address
      ep_datain => ep21_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep24 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(2),
      ep_addr   => x"24",               -- Endpoint address
      ep_datain => ep24_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep25 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(3),
      ep_addr   => x"25",               -- Endpoint address
      ep_datain => ep25_wire            -- Endpoint data out 32 bits
      );


  inst_okwireout_ep30 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(4),
      ep_addr   => x"30",               -- Endpoint address
      ep_datain => ep30_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep31 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(5),
      ep_addr   => x"31",               -- Endpoint address
      ep_datain => ep31_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep32 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(6),
      ep_addr   => x"32",               -- Endpoint address
      ep_datain => ep32_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep33 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(7),
      ep_addr   => x"33",               -- Endpoint address
      ep_datain => ep33_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep34 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(8),
      ep_addr   => x"34",               -- Endpoint address
      ep_datain => ep34_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep35 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(9),
      ep_addr   => x"35",               -- Endpoint address
      ep_datain => ep35_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep36 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(10),
      ep_addr   => x"36",               -- Endpoint address
      ep_datain => ep36_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep37 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(11),
      ep_addr   => x"37",               -- Endpoint address
      ep_datain => ep37_wire            -- Endpoint data out 32 bits
      );


  inst_okwireout_ep38 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(12),
      ep_addr   => x"38",               -- Endpoint address
      ep_datain => ep38_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep39 : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(13),
      ep_addr   => x"39",               -- Endpoint address
      ep_datain => ep39_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep3A : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(14),
      ep_addr   => x"3A",               -- Endpoint address
      ep_datain => ep3A_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep3B : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(15),
      ep_addr   => x"3B",               -- Endpoint address
      ep_datain => ep3B_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep3D : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(16),
      ep_addr   => x"3D",               -- Endpoint address
      ep_datain => ep3D_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep3E : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(17),
      ep_addr   => x"3E",               -- Endpoint address
      ep_datain => ep3E_wire            -- Endpoint data out 32 bits
      );

  inst_okwireout_ep3F : okWireOut
    port map(
      okHE      => okHE,
      okEH      => okEHx_array(18),
      ep_addr   => x"3F",               -- Endpoint address
      ep_datain => ep3F_wire            -- Endpoint data out 32 bits
      );

  ---------------------------------------------------------------------
  -- output
  ---------------------------------------------------------------------
  -- from okhost
  o_usb_clk <= okClk;

  -- from wire in
  o_usb_wirein_ctrl       <= ep00_wire;
  o_usb_wirein_power_ctrl <= ep01_wire;
  o_usb_wirein_adc_ctrl   <= ep04_wire;

  o_usb_wirein_debug_ctrl <= ep18_wire;
  o_usb_wirein_sel_errors <= ep19_wire;

end architecture RTL;
