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
--    @file                   power_top.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--   @details
--
--   This is the top level of the power management function
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;


entity power_top is
  generic (
    -- enable the DEBUG by ILA
    g_DEBUG       : boolean := false;
    g_POWER_WIDTH : integer := 4
    );
  port(
    -- clock
    i_clk : in std_logic;
    -- reset
    i_rst : in std_logic;

    -- reset error flag(s)
    i_rst_status  : in std_logic;
    -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s)
    i_debug_pulse : in std_logic;

    ---------------------------------------------------------------------
    -- inputs
    ---------------------------------------------------------------------
    -- power_valid (for power_on and power_off)
    i_power_valid : in std_logic;
    -- bitwise power ('1': power_on, '0':power off)
    i_power       : in std_logic_vector(g_POWER_WIDTH - 1 downto 0);

    ---------------------------------------------------------------------
    -- outputs
    ---------------------------------------------------------------------
    -- '1': ready to configure the power, '0': busy
    o_ready : out std_logic;

    -- start of frame (pulse)
    o_power_sof   : out std_logic;
    -- end of frame (pulse)
    o_power_eof   : out std_logic;
    -- output power valid
    o_power_valid : out std_logic;
    -- bitwise power_on pulse
    o_power_on    : out std_logic_vector(g_POWER_WIDTH - 1 downto 0);
    -- bitwise power_off pulse
    o_power_off   : out std_logic_vector(g_POWER_WIDTH - 1 downto 0);

    ---------------------------------------------------------------------
    -- Status/errors
    ---------------------------------------------------------------------
    --  errors
    o_errors : out std_logic_vector(15 downto 0);
    -- status
    o_status : out std_logic_vector(7 downto 0)
    );
end entity power_top;

architecture RTL of power_top is

  ---------------------------------------------------------------------
  -- inst_dcdc_adc128s102
  ---------------------------------------------------------------------
  -- '1': tx_ready to start an acquisition, '0': busy
  signal power_ready : std_logic;

  -- start of frame (pulse)
  signal power_eof   : std_logic;
  -- end of frame (pulse)
  signal power_eof   : std_logic;
  -- power_valid
  signal power_valid : std_logic;
  -- power_on
  signal power_on    : std_logic_vector(o_power_on'range);
  -- power_off
  signal power_off   : std_logic_vector(o_power_off'range);


  -- errors
  signal errors : std_logic_vector(15 downto 0);
  -- status
  signal status : std_logic_vector(7 downto 0);

begin

  ---------------------------------------------------------------------
  -- power_rhrpmicl1a
  ---------------------------------------------------------------------
  inst_power_rhrpmicl1a : entity work.power_rhrpmicl1a
    generic map(
      -- enable the DEBUG by ILA
      g_DEBUG => g_DEBUG
      )
    port map(
      -- clock
      i_clk         => i_clk,
      -- reset
      i_rst         => i_rst,
      -- reset error flag(s)
      i_rst_status  => i_rst_status,
      -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s)
      i_debug_pulse => i_debug_pulse,

      ---------------------------------------------------------------------
      -- inputs
      ---------------------------------------------------------------------
      -- Valid start ADCs' acquisition
      i_adc_start_valid => i_power_valid,
      -- start ADCs' acquisition
      i_adc_start       => i_power,

      ---------------------------------------------------------------------
      -- FSM status
      ---------------------------------------------------------------------
      -- '1': tx_ready to start an acquisition, '0': busy
      o_ready => power_ready,

      ---------------------------------------------------------------------
      -- ADC outputs
      ---------------------------------------------------------------------
      -- start of frame (pulse)
      o_power_sof   => power_sof,
      -- end of frame (pulse)
      o_power_eof   => power_eof,
      -- power_valid
      o_power_valid => power_valid,
      -- bitwise power_on pulse
      o_power_on    => power_on,
      -- bitwise power_off pulse
      o_power_off   => power_off,

      ---------------------------------------------------------------------
      -- Status/error      ---------------------------------------------------------------------
      o_errors => errors,
      o_status => status
      );

  ---------------------------------------------------------------------
  -- output
  ---------------------------------------------------------------------
  -- FSM state
  o_ready <= power_ready;

  -- adc
  o_power_sof   <= power_sof;
  o_power_eof   <= power_eof;
  o_power_valid <= power_valid;
  o_power_on    <= power_on;
  o_power_off   <= power_off;


  -- error/status
  o_errors <= errors;
  o_status <= status;


end architecture RTL;
