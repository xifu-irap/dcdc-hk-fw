-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.1 (win64) Build 3526262 Mon Apr 18 15:48:16 MDT 2022
-- Date        : Tue Jan 23 08:12:32 2024
-- Host        : PC-PAUL running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               d:/dcdc-hk-fw-hardware/dcdc-hk-fw/ip/xilinx/coregen/ila_dcdc_adc128s102/ila_dcdc_adc128s102_stub.vhdl
-- Design      : ila_dcdc_adc128s102
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a75tfgg484-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ila_dcdc_adc128s102 is
  Port ( 
    clk : in STD_LOGIC;
    probe0 : in STD_LOGIC_VECTOR ( 6 downto 0 );
    probe1 : in STD_LOGIC_VECTOR ( 34 downto 0 );
    probe2 : in STD_LOGIC_VECTOR ( 127 downto 0 );
    probe3 : in STD_LOGIC_VECTOR ( 3 downto 0 )
  );

end ila_dcdc_adc128s102;

architecture stub of ila_dcdc_adc128s102 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,probe0[6:0],probe1[34:0],probe2[127:0],probe3[3:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "ila,Vivado 2022.1";
begin
end;
