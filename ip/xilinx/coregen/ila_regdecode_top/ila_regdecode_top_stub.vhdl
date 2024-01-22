-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.1 (win64) Build 3526262 Mon Apr 18 15:48:16 MDT 2022
-- Date        : Mon Jan 22 15:54:34 2024
-- Host        : PC-PAUL running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               d:/dcdc-hk-fw-hardware/dcdc-hk-fw/ip/xilinx/coregen/ila_regdecode_top/ila_regdecode_top_stub.vhdl
-- Design      : ila_regdecode_top
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a75tfgg484-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ila_regdecode_top is
  Port ( 
    clk : in STD_LOGIC;
    probe0 : in STD_LOGIC_VECTOR ( 63 downto 0 );
    probe1 : in STD_LOGIC_VECTOR ( 255 downto 0 );
    probe2 : in STD_LOGIC_VECTOR ( 95 downto 0 );
    probe3 : in STD_LOGIC_VECTOR ( 1 downto 0 )
  );

end ila_regdecode_top;

architecture stub of ila_regdecode_top is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,probe0[63:0],probe1[255:0],probe2[95:0],probe3[1:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "ila,Vivado 2022.1";
begin
end;
