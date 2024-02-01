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
--    @file                   regdecode_top.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    This module is the top_level of the regdecode
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_regdecode.all;

entity regdecode_top is
  generic (
    -- enable the DEBUG by ILA
    g_DEBUG : boolean := false
    );
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

    ---------------------------------------------------------------------
    -- From IO
    ---------------------------------------------------------------------
    -- hardware id register (reading)
    i_hardware_id : in std_logic_vector(7 downto 0);

    ---------------------------------------------------------------------
    -- to the user @o_usb_clk
    ---------------------------------------------------------------------
    -- usb clock
    o_usb_clk : out std_logic;

    -- wire
    -- ctrl register (writting)
    o_reg_ctrl             : out std_logic_vector(31 downto 0);
    -- power_conf valid
    o_reg_power_conf_valid : out std_logic;
    -- power_conf register (writting)
    o_reg_power_conf       : out std_logic_vector(31 downto 0);

    -- ADC @o_usb_clk
    ---------------------------------------------------------------------
    -- adc_ctrl valid
    o_reg_adc_valid : out std_logic;

    -- adc_status register (reading)
    i_reg_adc_status : in std_logic_vector(31 downto 0);
    -- adc0 register (reading)
    i_reg_adc0       : in std_logic_vector(31 downto 0);
    -- adc1 register (reading)
    i_reg_adc1       : in std_logic_vector(31 downto 0);
    -- adc2 register (reading)
    i_reg_adc2       : in std_logic_vector(31 downto 0);
    -- adc3 register (reading)
    i_reg_adc3       : in std_logic_vector(31 downto 0);
    -- adc4 register (reading)
    i_reg_adc4       : in std_logic_vector(31 downto 0);
    -- adc5 register (reading)
    i_reg_adc5       : in std_logic_vector(31 downto 0);
    -- adc6 register (reading)
    i_reg_adc6       : in std_logic_vector(31 downto 0);
    -- adc7 register (reading)
    i_reg_adc7       : in std_logic_vector(31 downto 0);

    -- debug_ctrl @o_usb_clk
    ---------------------------------------------------------------------
    -- debug_ctrl data valid
    o_reg_debug_ctrl_valid : out std_logic;
    -- debug_ctrl register value
    o_reg_debug_ctrl       : out std_logic_vector(31 downto 0);

    -- errors/status
    ---------------------------------------------------------------------
    -- status register: errors0
    i_reg_wire_errors0 : in std_logic_vector(31 downto 0);
    -- status register: status0
    i_reg_wire_status0 : in std_logic_vector(31 downto 0)

    );
end entity regdecode_top;

architecture RTL of regdecode_top is

  ---------------------------------------------------------------------
  -- usb_opal_kelly
  ---------------------------------------------------------------------

  -- Common Register configuration
  ---------------------------------------------------------------------

  -- ctrl register value
  signal usb_wireout_ctrl : std_logic_vector(31 downto 0);

  -- power_ctrl register value
  signal usb_wireout_power_conf : std_logic_vector(31 downto 0);


  -- firmware_id register value
  signal usb_wireout_firmware_id : std_logic_vector(31 downto 0);

  -- hardware_id register value
  signal usb_wireout_hardware_id : std_logic_vector(31 downto 0);


  -- firmware_name register value
  signal usb_wireout_firmware_name : std_logic_vector(31 downto 0);

  -- Debugging Registers
  ---------------------------------------------------------------------
  -- debug_ctrl register value
  signal usb_wireout_debug_ctrl : std_logic_vector(31 downto 0);
  -- sel_errors register value
  signal usb_wireout_sel_errors : std_logic_vector(31 downto 0);
  -- errors register value
  signal usb_wireout_errors     : std_logic_vector(31 downto 0);
  -- status register value
  signal usb_wireout_status     : std_logic_vector(31 downto 0);


  -- Trig in
  ---------------------------------------------------------------------
  -- trig_ctrl access
  signal usb_trigin_ctrl   : std_logic_vector(31 downto 0);

  -- Common Register configuration
  ---------------------------------------------------------------------
  -- ctrl register value
  signal usb_wirein_ctrl       : std_logic_vector(31 downto 0);
  -- power_ctrl register value
  signal usb_wirein_power_conf : std_logic_vector(31 downto 0);

  -- Debugging Registers
  ---------------------------------------------------------------------
  -- debug_ctrl register value
  signal usb_wirein_debug_ctrl : std_logic_vector(31 downto 0);
  -- sel_errors register value
  signal usb_wirein_sel_errors : std_logic_vector(31 downto 0);


  -- usb clock
  signal usb_clk : std_logic;
  -- rst @usb_clk
  signal usb_rst : std_logic;
  -- rst_status @usb_clk
  --signal usb_rst_status  : std_logic;
  -- debug_pulse @usb_clk
  --signal usb_debug_pulse : std_logic;

  -- sel_errors value
  signal sel_errors : std_logic_vector(pkg_ERROR_SEL_WIDTH - 1 downto 0);

  ---------------------------------------------------------------------
  -- inst_pipeliner_adc_power
  ---------------------------------------------------------------------
  -- power_conf valid
  signal power_conf_valid : std_logic;
  -- power_conf value
  signal power_conf       : std_logic_vector(o_reg_power_conf'range);

  -- trig_ctrl
  signal trigin_ctrl : std_logic_vector(31 downto 0);
  -- adc_ctrl valid
  signal adc_valid : std_logic;

  ---------------------------------------------------------------------
  -- debug_ctrl regdecode_register_to_user
  ---------------------------------------------------------------------
  -- debug_ctrl valid
  signal reg_debug_ctrl_valid : std_logic;
  -- debug_ctrl register
  signal reg_debug_ctrl       : std_logic_vector(o_reg_debug_ctrl'range);

  ---------------------------------------------------------------------
  -- regdecode_wire_errors
  ---------------------------------------------------------------------
  -- selected wire
  signal wire_errors : std_logic_vector(31 downto 0);
  -- selected status
  signal wire_status : std_logic_vector(31 downto 0);

begin

  usb_wireout_hardware_id   <= std_logic_vector(resize(unsigned(i_hardware_id), usb_wireout_hardware_id'length));
  usb_wireout_firmware_id   <= pkg_FIRMWARE_ID;
  usb_wireout_firmware_name <= pkg_FIRMWARE_NAME;

  ---------------------------------------------------------------------
  -- usb_opal_kelly
  ---------------------------------------------------------------------
  inst_usb_opal_kelly : entity work.usb_opal_kelly
    port map(
      --  Opal Kelly inouts --
      i_okUH                   => i_okUH,
      o_okHU                   => o_okHU,
      b_okUHU                  => b_okUHU,
      b_okAA                   => b_okAA,
      ---------------------------------------------------------------------
      -- from the user @o_usb_clk
      ---------------------------------------------------------------------
      -- wire_out
      i_usb_wireout_ctrl       => usb_wireout_ctrl,  -- ctrl register (reading)
      i_usb_wireout_power_conf => usb_wireout_power_conf,  -- power_ctrl register (reading)

      i_usb_wireout_adc_status => i_reg_adc_status,  -- adc_status register (reading)
      i_usb_wireout_adc0       => i_reg_adc0,        -- adc0 register (reading)
      i_usb_wireout_adc1       => i_reg_adc1,        -- adc1 register (reading)
      i_usb_wireout_adc2       => i_reg_adc2,        -- adc2 register (reading)
      i_usb_wireout_adc3       => i_reg_adc3,        -- adc3 register (reading)
      i_usb_wireout_adc4       => i_reg_adc4,        -- adc4 register (reading)
      i_usb_wireout_adc5       => i_reg_adc5,        -- adc5 register (reading)
      i_usb_wireout_adc6       => i_reg_adc6,        -- adc6 register (reading)
      i_usb_wireout_adc7       => i_reg_adc7,        -- adc7 register (reading)

      i_usb_wireout_hardware_id   => usb_wireout_hardware_id,  -- hardware id register (reading)
      i_usb_wireout_firmware_name => usb_wireout_firmware_name,  -- firmware_name register (reading)
      i_usb_wireout_firmware_id   => usb_wireout_firmware_id,  -- firmware_id register (reading)

      -- errors/status
      i_usb_wireout_debug_ctrl => usb_wireout_debug_ctrl,  -- debug_ctrl register (reading)
      i_usb_wireout_sel_errors => usb_wireout_sel_errors,  -- sel_errors register (reading)
      i_usb_wireout_errors     => usb_wireout_errors,  -- errors register (reading)
      i_usb_wireout_status     => usb_wireout_status,  -- status register (reading)


      ---------------------------------------------------------------------
      -- to the user @o_usb_clk
      ---------------------------------------------------------------------
      o_usb_clk => usb_clk,             -- usb clock


      -- wire
      o_usb_wirein_ctrl       => usb_wirein_ctrl,  -- ctrl register (writting)
      o_usb_wirein_power_conf => usb_wirein_power_conf,  -- power_ctrl register (writting)

      -- debugging
      o_usb_wirein_debug_ctrl => usb_wirein_debug_ctrl,  -- debug_ctrl register (writting)
      o_usb_wirein_sel_errors => usb_wirein_sel_errors,  -- sel_errors register (writting)

      -- trigger
      o_usb_trigin_ctrl        => usb_trigin_ctrl
      );

  -- extract bits
  ---------------------------------------------------------------------
  --usb_rst_status  <= usb_wirein_debug_ctrl(pkg_DEBUG_CTRL_RST_STATUS_IDX_H);
  --usb_debug_pulse <= usb_wirein_debug_ctrl(pkg_DEBUG_CTRL_DEBUG_PULSE_IDX_H);
  usb_rst    <= usb_wirein_ctrl(pkg_CTRL_RST_IDX_H);
  sel_errors <= usb_wirein_sel_errors(pkg_ERROR_SEL_IDX_H downto pkg_ERROR_SEL_IDX_L);

  ---------------------------------------------------------------------
  -- output @usb_clk
  ---------------------------------------------------------------------
  o_reg_ctrl <= usb_wirein_ctrl;
  o_usb_clk  <= usb_clk;

  ---------------------------------------------------------------------
  -- internal loopback
  ---------------------------------------------------------------------
  inst_pipeliner_with_init_optional_pipe_ctrl : entity work.pipeliner_with_init
    generic map(
      -- register init value
      g_INIT       => '0',
      -- number of consecutives registers. Possibles values: [0, integer max value[
      g_NB_PIPES   => pkg_WIRE_LOOPBACK_DELAY,
      -- width of the input/output data.  Possibles values: [1, integer max value[
      g_DATA_WIDTH => usb_wirein_ctrl'length
      )
    port map(
      i_clk  => usb_clk,
      i_data => usb_wirein_ctrl,
      o_data => usb_wireout_ctrl
      );

  inst_pipeliner_with_init_optional_pipe_tc_hk_conf : entity work.pipeliner_with_init
    generic map(
      -- register init value
      g_INIT       => '0',
      -- number of consecutives registers. Possibles values: [0, integer max value[
      g_NB_PIPES   => pkg_WIRE_LOOPBACK_DELAY,
      -- width of the input/output data.  Possibles values: [1, integer max value[
      g_DATA_WIDTH => usb_wirein_power_conf'length
      )
    port map(
      i_clk  => usb_clk,
      i_data => usb_wirein_power_conf,
      o_data => usb_wireout_power_conf
      );


  inst_pipeliner_with_init_optional_pipe_debug_ctrl : entity work.pipeliner_with_init
    generic map(
      -- register init value
      g_INIT       => '0',
      -- number of consecutives registers. Possibles values: [0, integer max value[
      g_NB_PIPES   => pkg_WIRE_LOOPBACK_DELAY,
      -- width of the input/output data.  Possibles values: [1, integer max value[
      g_DATA_WIDTH => usb_wirein_debug_ctrl'length
      )
    port map(
      i_clk  => usb_clk,
      i_data => usb_wirein_debug_ctrl,
      o_data => usb_wireout_debug_ctrl
      );

  inst_pipeliner_with_init_optional_pipe_sel_errors : entity work.pipeliner_with_init
    generic map(
      -- register init value
      g_INIT       => '0',
      -- number of consecutives registers. Possibles values: [0, integer max value[
      g_NB_PIPES   => pkg_WIRE_LOOPBACK_DELAY,
      -- width of the input/output data.  Possibles values: [1, integer max value[
      g_DATA_WIDTH => usb_wirein_sel_errors'length
      )
    port map(
      i_clk  => usb_clk,
      i_data => usb_wirein_sel_errors,
      o_data => usb_wireout_sel_errors
      );



  ---------------------------------------------------------------------
  -- power_ctrl register
  ---------------------------------------------------------------------
  gen_pipe: if true generate
    -- temporary input pipe
    signal data_tmp0 : std_logic_vector(63 downto 0);
    -- temporary output pipe
    signal data_tmp1 : std_logic_vector(63 downto 0);
    begin
      data_tmp0(63 downto 32) <= usb_trigin_ctrl;
      data_tmp0(31 downto 0)  <= usb_wirein_power_conf;

    inst_pipeliner_adc_power : entity work.pipeliner_with_init
    generic map(
      -- register init value
      g_INIT       => '0',
      -- number of consecutives registers. Possibles values: [0, integer max value[
      g_NB_PIPES   => 1,
      -- width of the input/output data.  Possibles values: [1, integer max value[
      g_DATA_WIDTH => data_tmp0'length
      )
    port map(
      i_clk  => usb_clk,
      i_data => data_tmp0,
      o_data => data_tmp1
      );

  trigin_ctrl <= data_tmp1(63 downto 32);
  power_conf  <= data_tmp1(31 downto 0);

  -- extract bits
  power_conf_valid <= trigin_ctrl(pkg_TRIG_IN_POWER_VALID_IDX_H);
  adc_valid        <= trigin_ctrl(pkg_TRIG_IN_ADC_VALID_IDX_H);

  -- output
  -- power
  o_reg_power_conf_valid <= power_conf_valid;
  o_reg_power_conf       <= power_conf;

  -- adc
  o_reg_adc_valid <= adc_valid;

  end generate gen_pipe;




  ---------------------------------------------------------------------
  -- debug_ctrl register
  ---------------------------------------------------------------------
  inst_regdecode_reg_with_default_value_debug_ctrl : entity work.regdecode_reg_with_default_value
    generic map(
      -- data default value (on the Reset)
      g_DATA_DEFAULT => pkg_DEBUG_CTRL_DEFAULT,
      -- input/output data width
      g_DATA_WIDTH   => usb_trigin_ctrl'length
      )
    port map(
      -- input clock
      i_clk => usb_clk,
      -- input reset
      i_rst => usb_rst,

      ---------------------------------------------------------------------
      -- input register
      ---------------------------------------------------------------------
      i_data => usb_wirein_debug_ctrl,

      ---------------------------------------------------------------------
      -- output
      ---------------------------------------------------------------------
      -- data valid
      o_data_valid => reg_debug_ctrl_valid,
      -- data
      o_data       => reg_debug_ctrl
      );

  -- output
  o_reg_debug_ctrl_valid <= reg_debug_ctrl_valid;
  o_reg_debug_ctrl       <= reg_debug_ctrl;


  ---------------------------------------------------------------------
  -- errors/status wire
  ---------------------------------------------------------------------
  inst_regdecode_wire_errors : entity work.regdecode_wire_errors
    generic map(
      -- define the width of the error selection
      g_ERROR_SEL_WIDTH => sel_errors'length
      )
    port map(
      ---------------------------------------------------------------------
      -- input @i_clk
      ---------------------------------------------------------------------
      -- clock
      i_clk             => usb_clk,
      -- error/status selection
      i_error_sel       => sel_errors,
      -- errors
      i_usb_reg_errors0 => i_reg_wire_errors0,
      -- status
      i_usb_reg_status0 => i_reg_wire_status0,
      ---------------------------------------------------------------------
      -- output @ i_clk
      ---------------------------------------------------------------------
      -- output errors
      o_wire_errors     => wire_errors,
      -- output status
      o_wire_status     => wire_status
      );

  usb_wireout_errors <= wire_errors;
  usb_wireout_status <= wire_status;

  ---------------------------------------------------------------------
  -- debugging: ILAs, etc.
  ---------------------------------------------------------------------
  gen_debug : if g_DEBUG generate

  begin

    inst_ila_regdecode_top : entity work.ila_regdecode_top
      port map (
        clk => usb_clk,

        probe0(31 downto 0)    => power_conf,
        -- probe1
        probe1(255 downto 224) => i_reg_adc7,
        probe1(223 downto 192) => i_reg_adc6,
        probe1(191 downto 160) => i_reg_adc5,
        probe1(159 downto 128) => i_reg_adc4,
        probe1(127 downto 96)  => i_reg_adc3,
        probe1(95 downto 64)   => i_reg_adc2,
        probe1(63 downto 32)   => i_reg_adc1,
        probe1(31 downto 0)    => i_reg_adc0,

        -- probe2
        probe2(95 downto 64) => i_reg_adc_status,
        probe2(63 downto 32) => i_reg_wire_errors0,
        probe2(31 downto 0)  => i_reg_wire_status0,

        probe3(33) => adc_valid,
        probe3(32) => power_conf_valid,
        probe3(31 downto 0) => trigin_ctrl
        );

  end generate gen_debug;

end architecture RTL;
