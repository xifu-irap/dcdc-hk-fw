###############################################################################################################
#                            Copyright (C) 2023-2030 Ken-ji de la ROSA, IRAP Toulouse.
###############################################################################################################
#                            This file is part of the ATHENA X-IFU DRE Telemetry and Telecommand Firmware.
#
#                            dcdc-hk-fw is free software: you can redistribute it and/or modify
#                            it under the terms of the GNU General Public License as published by
#                            the Free Software Foundation, either version 3 of the License, or
#                            (at your option) any later version.
#
#                            This program is distributed in the hope that it will be useful,
#                            but WITHOUT ANY WARRANTY; without even the implied warranty of
#                            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#                            GNU General Public License for more details.
#
#                            You should have received a copy of the GNU General Public License
#                            along with this program.  If not, see <https://www.gnu.org/licenses/>.
###############################################################################################################
#    email                   kenji.delarosa@alten.com
#    @file                   test_IO.xdc
###############################################################################################################
#    Automatic Generation    No
#    Code Rules Reference    N/A
###############################################################################################################
#    @details
#    This file set the timing constraints on the top_level I/O ports (temporary)
#
#
###############################################################################################################

###############################################################################################################
# xem7350 : system clock
###############################################################################################################
# create_clock -name sys_clk -period 5 [get_ports sys_clkp]

###############################################################################################################
# usb @100.8 MHz
###############################################################################################################
# 100.8 MHz
create_clock -period 9.920 -name usb_clk_in [get_ports {i_okUH[0]}];

# 250 MHz
create_clock -period 4 -name adc_clk_in [get_ports {i_clk_ab_p}];
create_clock -name virt_adc_clk_in   -period 4;

# 500 MHz (data part)
create_clock -name virt_dac_clk   -period 2;

# 250 MHz (sys)
create_clock -name virt_sys_clk   -period 4;

###############################################################################################################
# usb
###############################################################################################################
set_input_delay -add_delay -max -clock [get_clocks {okUH0}]  8.000 [get_ports {i_okUH[*]}]
set_input_delay -add_delay -min -clock [get_clocks {okUH0}] 10.000 [get_ports {i_okUH[*]}]
set_multicycle_path -setup -from [get_ports {i_okUH[*]}] 2

set_input_delay -add_delay -max -clock [get_clocks {okUH0}]  8.000 [get_ports {b_okUHU[*]}]
set_input_delay -add_delay -min -clock [get_clocks {okUH0}]  2.000 [get_ports {b_okUHU[*]}]
set_multicycle_path -setup -from [get_ports {b_okUHU[*]}] 2

set_output_delay -add_delay -max -clock [get_clocks {okUH0}]  2.000 [get_ports {o_okHU[*]}]
set_output_delay -add_delay -min -clock [get_clocks {okUH0}]  -0.500 [get_ports {o_okHU[*]}]

set_output_delay -add_delay -max -clock [get_clocks {okUH0}]  2.000 [get_ports {b_okUHU[*]}]
set_output_delay -add_delay -min -clock [get_clocks {okUH0}]  -0.500 [get_ports {b_okUHU[*]}]

###############################################################################################################
# rename auto-derived clock
###############################################################################################################
# define variables
set usb_clk_in_pin [get_pins inst_regdecode_top/inst_usb_opal_kelly/inst_Opal_Kelly_Host/mmcm0/CLKIN1];
set usb_clk_out_pin  [get_pins inst_regdecode_top/inst_usb_opal_kelly/inst_Opal_Kelly_Host/mmcm0/CLKOUT0];

# rename clocks
create_generated_clock -name usb_clk -source $usb_clk_in_pin $usb_clk_out_pin;


###############################################################################################################
# ODDR : forward clock
###############################################################################################################
create_generated_clock -name gen_spi_clk -multiply_by 1 -source [get_pins inst_io_top/inst_io_spi/gen_user_to_pads_clk.inst_oddr/C] [get_ports {o_dcdc_hk_adc_sclk_a}];


###############################################################################################################
# usb: constraints register/Q on register/clk
###############################################################################################################
set usb_src [get_pins inst_regdecode_top/inst_usb_opal_kelly/inst_Opal_Kelly_Host/core0/core0/a0/d0/lc4da648cb12eeeb24e4d199c1195ed93_reg[4]/C];
set usb_dest [get_pins inst_regdecode_top/inst_usb_opal_kelly/inst_Opal_Kelly_Host/core0/core0/a0/d0/lc4da648cb12eeeb24e4d199c1195ed93_reg[4]/Q];
create_generated_clock -name usb_clk_regQ_on_clk_pin -source $usb_src -divide_by 2 $usb_dest;


##################################################################################
# SPI: timing constraints (output ports)
#    for all spi, we consider the worst case (CDCE @20MHz: cdce72010)
##################################################################################
#  Rising Edge Source Synchronous Outputs
#
#  Source synchronous output interfaces can be constrained either by the max data skew
#  relative to the generated clock or by the destination device setup/hold requirements.
#
#  Setup/Hold Case:
#  Setup and hold requirements for the destination device and board trace delays are known.
#
# forwarded         ____                      ___________________
# clock                 |____________________|                   |____________
#                                            |
#                                     tsu    |    thd
#                                <---------->|<--------->
#                                ____________|___________
# data @ destination    XXXXXXXXX________________________XXXXX
#
# Example of creating generated clock at clock output port
# create_generated_clock -name <gen_clock_name> -multiply_by 1 -source [get_pins <source_pin>] [get_ports <output_clock_port>]
# gen_clock_name is the name of forwarded clock here. It should be used below for defining "fwclk".

set fwclk        usb_clk;      # forwarded clock name (generated using create_generated_clock at output clock port)
set tsu          2.5;           # destination device setup time requirement
set thd          2.5;           # destination device hold time requirement
set trce_dly_max 0.000;            # maximum board trace delay
set trce_dly_min 0.000;            # minimum board trace delay
set output_ports {o_dcdc_hk_adc_mosi_a o_dcdc_hk_adc_cs_n_a};   # list of output ports

# Output Delay Constraints
set_output_delay -clock $fwclk -max [expr $trce_dly_max + $tsu] [get_ports $output_ports];
set_output_delay -clock $fwclk -min [expr $trce_dly_min - $thd] [get_ports $output_ports];

##################################################################################
# SPI: timing constraints (input ports)
#    for all spi, we consider the worst case (CDCE @20MHz: cdce72010)
##################################################################################
# Center-Aligned Rising Edge Source Synchronous Inputs
#
# For a center-aligned Source Synchronous interface, the clock
# transition is aligned with the center of the data valid window.
# The same clock edge is used for launching and capturing the
# data. The constraints below rely on the default timing
# analysis (setup = 1 cycle, hold = 0 cycle).
#
# input    ____           __________
# clock        |_________|          |_____
#                        |
#                 dv_bre | dv_are
#                <------>|<------>
#          __    ________|________    __
# data     __XXXX____Rise_Data____XXXX__
#

set input_clock         usb_clk;      # Name of input clock
set input_clock_period  9.92;              # Period of input clock
set dv_bre              7.5;          # Data valid before the rising clock edge
set dv_are              3.500;          # Data valid after the rising clock edge
set input_ports         {i_dcdc_hk_adc_miso_a};     # List of input ports

# Input Delay Constraint
set_input_delay -clock $input_clock -max [expr $input_clock_period - $dv_bre] [get_ports $input_ports];
set_input_delay -clock $input_clock -min $dv_are                              [get_ports $input_ports];


##################################################################################
# power: timing constraints (output ports)
#    for all spi, we consider the worst case (CDCE @20MHz: cdce72010)
##################################################################################
#  Rising Edge Source Synchronous Outputs
#
#  Source synchronous output interfaces can be constrained either by the max data skew
#  relative to the generated clock or by the destination device setup/hold requirements.
#
#  Setup/Hold Case:
#  Setup and hold requirements for the destination device and board trace delays are known.
#
# forwarded         ____                      ___________________
# clock                 |____________________|                   |____________
#                                            |
#                                     tsu    |    thd
#                                <---------->|<--------->
#                                ____________|___________
# data @ destination    XXXXXXXXX________________________XXXXX
#
# Example of creating generated clock at clock output port
# create_generated_clock -name <gen_clock_name> -multiply_by 1 -source [get_pins <source_pin>] [get_ports <output_clock_port>]
# gen_clock_name is the name of forwarded clock here. It should be used below for defining "fwclk".

set fwclk        usb_clk;      # forwarded clock name (generated using create_generated_clock at output clock port)
set tsu          2.5;           # destination device setup time requirement
set thd          2.5;           # destination device hold time requirement
set trce_dly_max 0.000;            # maximum board trace delay
set trce_dly_min 0.000;            # minimum board trace delay
set output_ports {o_power_on[*] o_power_off[*]};   # list of output ports

# Output Delay Constraints
set_output_delay -clock $fwclk -max [expr $trce_dly_max + $tsu] [get_ports $output_ports];
set_output_delay -clock $fwclk -min [expr $trce_dly_min - $thd] [get_ports $output_ports];


##################################################################################
# others (input ports): asynchronuous ports
##################################################################################
# hardware_id is constant => no constraints
# set_false_path -from [get_ports i_hardware_id[*]]
# constants value in the steady state => no constraints
set_false_path -to   [get_ports o_leds[*]];


##################################################################################
# IO: spi
#   use IO register when possible
##################################################################################
set_property IOB true [get_ports i_dcdc_hk_adc_miso_a];
set_property IOB true [get_ports o_dcdc_hk_adc_mosi_a];
set_property IOB true [get_ports o_dcdc_hk_adc_sclk_a];
set_property IOB true [get_ports o_dcdc_hk_adc_cs_n_a];

##################################################################################
# led
##################################################################################
# set_property IOB true [get_ports o_leds[*]];

##################################################################################
# power
##################################################################################
# power on
set_property IOB true [get_ports o_en_wfee];
set_property IOB true [get_ports o_en_ras];
set_property IOB true [get_ports o_en_dmx1];
set_property IOB true [get_ports o_en_dmx0];

set_property IOB true [get_ports o_dis_wfee];
set_property IOB true [get_ports o_dis_ras];
set_property IOB true [get_ports o_dis_dmx1];
set_property IOB true [get_ports o_dis_dmx0];