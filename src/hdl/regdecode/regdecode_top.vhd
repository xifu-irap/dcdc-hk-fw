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
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_regdecode.all;

entity regdecode_top is
  generic (
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
    o_reg_ctrl       : out std_logic_vector(31 downto 0);
    -- power_ctrl register (writting)
    o_reg_power_ctrl : out std_logic_vector(31 downto 0);

    -- ADC @o_usb_clk
    ---------------------------------------------------------------------
    -- adc_ctrl valid
    o_reg_adc_ctrl_valid : out std_logic;
    -- adc_ctrl register (reading)
    o_reg_adc_ctrl       : out std_logic_vector(31 downto 0);

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
    -- status register: errors1
    i_reg_wire_errors1 : in std_logic_vector(31 downto 0);
    -- status register: errors0
    i_reg_wire_errors0 : in std_logic_vector(31 downto 0);
    -- status register: status1
    i_reg_wire_status1 : in std_logic_vector(31 downto 0);
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

  -- adc_status register value
  signal usb_wireout_adc_status : std_logic_vector(31 downto 0);

  -- ctrl register value
  signal usb_wireout_ctrl : std_logic_vector(31 downto 0);

  -- adc_ctrl register value
  signal usb_wireout_adc_ctrl : std_logic_vector(31 downto 0);

  -- power_ctrl register value
  signal usb_wireout_power_ctrl : std_logic_vector(31 downto 0);


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


  -- Common Register configuration
  ---------------------------------------------------------------------
  -- ctrl register value
  signal usb_wirein_ctrl       : std_logic_vector(31 downto 0);
  -- power_ctrl register value
  signal usb_wirein_power_ctrl : std_logic_vector(31 downto 0);
  -- adc_ctrl register value
  signal usb_wirein_adc_ctrl   : std_logic_vector(31 downto 0);

  -- Debugging Registers
  ---------------------------------------------------------------------
  -- debug_ctrl register value
  signal usb_wirein_debug_ctrl : std_logic_vector(31 downto 0);
  -- sel_errors register value
  signal usb_wirein_sel_errors : std_logic_vector(31 downto 0);


  -- usb clock
  signal usb_clk         : std_logic;
  -- rst @usb_clk
  signal usb_rst         : std_logic;
  -- rst_status @usb_clk
  signal usb_rst_status  : std_logic;
  -- debug_pulse @usb_clk
  signal usb_debug_pulse : std_logic;

  -- sel_errors value
  signal sel_errors : std_logic_vector(pkg_ERROR_SEL_WIDTH - 1 downto 0);

  ---------------------------------------------------------------------
  -- inst_regdecode_reg_with_default_value_power_ctrl
  ---------------------------------------------------------------------
  -- power_ctrl valid
  signal power_ctrl_valid : std_logic;
  -- power_ctrl value
  signal power_ctrl       : std_logic_vector(o_reg_power_ctrl'range);

  ---------------------------------------------------------------------
  -- inst_regdecode_reg_with_default_value_adc_ctrl
  ---------------------------------------------------------------------
  -- adc_ctrl valid
  signal adc_ctrl_valid : std_logic;
  -- adc_ctrl value
  signal adc_ctrl       : std_logic_vector(o_reg_adc_ctrl'range);

  ---------------------------------------------------------------------
  -- debug_ctrl regdecode_register_to_user
  ---------------------------------------------------------------------
  -- debug_ctrl valid
  signal reg_debug_ctrl_valid : std_logic;
  -- debug_ctrl register
  signal reg_debug_ctrl       : std_logic_vector(o_reg_debug_ctrl'range);
  -- debug_ctrl errors
  signal debug_ctrl_errors    : std_logic_vector(15 downto 0);
  -- debug_ctrl status
  signal debug_ctrl_status    : std_logic_vector(7 downto 0);

  ---------------------------------------------------------------------
  -- build errors/status
  ---------------------------------------------------------------------
  -- errors2
  signal usb_wire_errors2 : std_logic_vector(31 downto 0);
  -- errors1
  signal usb_wire_errors1 : std_logic_vector(31 downto 0);
  -- errors0
  signal usb_wire_errors0 : std_logic_vector(31 downto 0);
  -- status2
  signal usb_wire_status2 : std_logic_vector(31 downto 0);
  -- status1
  signal usb_wire_status1 : std_logic_vector(31 downto 0);
  -- status0
  signal usb_wire_status0 : std_logic_vector(31 downto 0);

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
      i_usb_wireout_power_ctrl => usb_wireout_power_ctrl,  -- power_ctrl register (reading)

      i_usb_wireout_adc_ctrl   => usb_wireout_adc_ctrl,  -- adc_ctrl register (reading)
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
      o_usb_wirein_power_ctrl => usb_wirein_power_ctrl,  -- power_ctrl register (writting)
      o_usb_wirein_adc_ctrl   => usb_wirein_adc_ctrl,  -- adc_ctrl register (writting)

      -- debugging
      o_usb_wirein_debug_ctrl => usb_wirein_debug_ctrl,  -- debug_ctrl register (writting)
      o_usb_wirein_sel_errors => usb_wirein_sel_errors  -- sel_errors register (writting)
      );

  -- extract bits
  usb_rst_status  <= usb_wirein_debug_ctrl(pkg_DEBUG_CTRL_RST_STATUS_IDX_H);
  usb_debug_pulse <= usb_wirein_debug_ctrl(pkg_DEBUG_CTRL_DEBUG_PULSE_IDX_H);
  usb_rst         <= usb_wirein_ctrl(pkg_CTRL_RST_IDX_H);
  sel_errors      <= usb_wirein_sel_errors(pkg_ERROR_SEL_IDX_H downto pkg_ERROR_SEL_IDX_L);
  ---------------------------------------------------------------------
  -- output @usb_clk
  ---------------------------------------------------------------------

  o_reg_ctrl <= usb_wirein_ctrl;



  o_usb_clk <= usb_clk;

---------------------------------------------------------------------
-- internal loopback
---------------------------------------------------------------------
  inst_pipeliner_with_init_optional_pipe_ctrl : entity work.pipeliner_with_init
    generic map(
      g_INIT       => '0',
      g_NB_PIPES   => pkg_WIRE_LOOPBACK_DELAY,  -- number of consecutives registers. Possibles values: [0, integer max value[
      g_DATA_WIDTH => usb_wirein_ctrl'length  -- width of the input/output data.  Possibles values: [1, integer max value[
      )
    port map(
      i_clk  => usb_clk,
      i_data => usb_wirein_ctrl,
      o_data => usb_wireout_ctrl
      );

  inst_pipeliner_with_init_optional_pipe_tc_hk_conf : entity work.pipeliner_with_init
    generic map(
      g_INIT       => '0',
      g_NB_PIPES   => pkg_WIRE_LOOPBACK_DELAY,  -- number of consecutives registers. Possibles values: [0, integer max value[
      g_DATA_WIDTH => usb_wirein_power_ctrl'length  -- width of the input/output data.  Possibles values: [1, integer max value[
      )
    port map(
      i_clk  => usb_clk,
      i_data => usb_wirein_power_ctrl,
      o_data => usb_wireout_power_ctrl
      );

  inst_pipeliner_with_init_optional_pipe_icu_conf : entity work.pipeliner_with_init
    generic map(
      g_INIT       => '0',
      g_NB_PIPES   => pkg_WIRE_LOOPBACK_DELAY,  -- number of consecutives registers. Possibles values: [0, integer max value[
      g_DATA_WIDTH => usb_wirein_adc_ctrl'length  -- width of the input/output data.  Possibles values: [1, integer max value[
      )
    port map(
      i_clk  => usb_clk,
      i_data => usb_wirein_adc_ctrl,
      o_data => usb_wireout_adc_ctrl
      );

  inst_pipeliner_with_init_optional_pipe_debug_ctrl : entity work.pipeliner_with_init
    generic map(
      g_INIT       => '0',
      g_NB_PIPES   => pkg_WIRE_LOOPBACK_DELAY,  -- number of consecutives registers. Possibles values: [0, integer max value[
      g_DATA_WIDTH => usb_wirein_debug_ctrl'length  -- width of the input/output data.  Possibles values: [1, integer max value[
      )
    port map(
      i_clk  => usb_clk,
      i_data => usb_wirein_debug_ctrl,
      o_data => usb_wireout_debug_ctrl
      );

  inst_pipeliner_with_init_optional_pipe_sel_errors : entity work.pipeliner_with_init
    generic map(
      g_INIT       => '0',
      g_NB_PIPES   => pkg_WIRE_LOOPBACK_DELAY,  -- number of consecutives registers. Possibles values: [0, integer max value[
      g_DATA_WIDTH => usb_wirein_sel_errors'length  -- width of the input/output data.  Possibles values: [1, integer max value[
      )
    port map(
      i_clk  => usb_clk,
      i_data => usb_wirein_sel_errors,
      o_data => usb_wireout_sel_errors
      );



---------------------------------------------------------------------
-- power_ctrl register
---------------------------------------------------------------------
  inst_regdecode_reg_with_default_value_power_ctrl : entity work.regdecode_reg_with_default_value
    generic map(
      g_DATA_DEFAULT => pkg_POWER_CTRL_DEFAULT,
      g_DATA_WIDTH   => usb_wirein_power_ctrl'length
      )
    port map(
      -- input clock
      i_clk        => usb_clk,
      -- input reset
      i_rst        => usb_rst,
      ---------------------------------------------------------------------
      -- input register
      ---------------------------------------------------------------------
      i_data       => usb_wirein_power_ctrl,
      ---------------------------------------------------------------------
      -- output
      ---------------------------------------------------------------------
      -- data valid
      o_data_valid => power_ctrl_valid,
      -- data
      o_data       => power_ctrl
      );

  o_reg_power_ctrl <= power_ctrl;


  ---------------------------------------------------------------------
-- adc_ctrl register
---------------------------------------------------------------------
  inst_regdecode_reg_with_default_value_adc_ctrl : entity work.regdecode_reg_with_default_value
    generic map(
      g_DATA_DEFAULT => pkg_ADC_CTRL_DEFAULT,
      g_DATA_WIDTH   => usb_wirein_adc_ctrl'length
      )
    port map(
      -- input clock
      i_clk        => usb_clk,
      -- input reset
      i_rst        => usb_rst,
      ---------------------------------------------------------------------
      -- input register
      ---------------------------------------------------------------------
      i_data       => usb_wirein_adc_ctrl,
      ---------------------------------------------------------------------
      -- output
      ---------------------------------------------------------------------
      -- data valid
      o_data_valid => adc_ctrl_valid,
      -- data
      o_data       => adc_ctrl
      );

  o_reg_adc_ctrl_valid <= adc_ctrl_valid;
  o_reg_adc_ctrl       <= adc_ctrl;


  ---------------------------------------------------------------------
  -- debug_ctrl register
  --   cross clock domain: @i_clk -> @i_out_clk
  ---------------------------------------------------------------------
  inst_regdecode_register_to_user_debug_ctrl : entity work.regdecode_register_to_user
    generic map(
      g_DATA_WIDTH     => usb_wirein_debug_ctrl'length,
      g_FIFO_DEPTH_OUT => pkg_DEBUG_CTRL_FIFO_DEPTH
      )
    port map(
      ---------------------------------------------------------------------
      -- from/to the usb:  @i_clk
      ---------------------------------------------------------------------
      i_clk         => usb_clk,
      i_rst         => usb_rst,
      i_rst_status  => usb_rst_status,
      i_debug_pulse => usb_debug_pulse,

      -- input
      i_data    => usb_wirein_debug_ctrl,
      ---------------------------------------------------------------------
      -- to the user: @i_out_clk
      ---------------------------------------------------------------------
      i_out_clk => i_out_clk,

      -- data
      o_fifo_data_valid => reg_debug_ctrl_valid,
      o_fifo_data       => reg_debug_ctrl,
      ---------------------------------------------------------------------
      -- errors/status @ i_clk
      ---------------------------------------------------------------------
      o_errors          => debug_ctrl_errors,
      o_status          => debug_ctrl_status
      );

  o_reg_debug_ctrl_valid <= reg_debug_ctrl_valid;
  o_reg_debug_ctrl       <= reg_debug_ctrl;



  ---------------------------------------------------------------------
  -- errors/status wire
  ---------------------------------------------------------------------
  inst_regdecode_wire_errors : entity work.regdecode_wire_errors
    generic map(
      g_ERROR_SEL_WIDTH => sel_errors'length  -- define the width of the error selection
      )
    port map(
      ---------------------------------------------------------------------
      -- input @i_out_clk
      ---------------------------------------------------------------------
      i_out_clk          => i_out_clk,  -- clock
      -- errors
      i_reg_wire_errors1 => i_reg_wire_errors1,  -- errors value
      i_reg_wire_errors0 => i_reg_wire_errors0,  -- errors value
      -- status
      i_reg_wire_status1 => i_reg_wire_status1,  -- status value
      i_reg_wire_status0 => i_reg_wire_status0,  -- status value
      ---------------------------------------------------------------------
      -- input @i_clk
      ---------------------------------------------------------------------
      i_clk              => usb_clk,    -- clock
      i_error_sel        => sel_errors,  -- select the errors/status to output
      -- errors
      i_usb_reg_errors2  => usb_wire_errors2,    -- errors value
      i_usb_reg_errors1  => usb_wire_errors1,    -- errors value
      i_usb_reg_errors0  => usb_wire_errors0,    -- errors value
      -- status
      i_usb_reg_status2  => usb_wire_status2,    -- status value
      i_usb_reg_status1  => usb_wire_status1,    -- status value
      i_usb_reg_status0  => usb_wire_status0,    -- status value
      ---------------------------------------------------------------------
      -- output @ i_clk
      ---------------------------------------------------------------------
      o_wire_errors      => wire_errors,      -- output errors
      o_wire_status      => wire_status  -- output status
      );

  usb_wireout_errors <= wire_errors;
  usb_wireout_status <= wire_status;

  ---------------------------------------------------------------------
  -- debugging
  ---------------------------------------------------------------------
  gen_debug : if g_DEBUG generate

  begin

    inst_ila_regdecode_top : entity work.ila_regdecode_top
      port map (
        clk => usb_clk,

        probe0(63 downto 32)   => adc_ctrl,
        probe0(31 downto 0)    => power_ctrl,
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
        probe2(127 downto 96) => usb_wireout_adc_status,
        probe2(95 downto 64)  => usb_wire_errors2,
        probe2(63 downto 32)  => usb_wire_errors1,
        probe2(31 downto 0)   => usb_wire_errors0,

        probe3(1) => adc_ctrl_valid,
        probe3(0) => power_ctrl_valid
        );


  end generate gen_debug;


end architecture RTL;
