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
--    @file                   io_power.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    Manage IO for the power
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.pkg_system_dcdc.all;

library unisim;

entity io_power is
  generic (
    -- width of the input/output power value
    g_POWER_WIDTH : integer := 4
    );
  port (
    -- clock
    i_clk       : in  std_logic;
    ---------------------------------------------------------------------
    -- from/to IOs: @i_clk
    ---------------------------------------------------------------------
    -- bitwise power_on pulse
    o_power_on  : out std_logic_vector(g_POWER_WIDTH - 1 downto 0);
    -- bitwise power_off pulse
    o_power_off : out std_logic_vector(g_POWER_WIDTH - 1 downto 0);

    ---------------------------------------------------------------------
    -- from/to user: @i_clk
    ---------------------------------------------------------------------
    -- bitwise power_on pulse
    i_power_on  : in std_logic_vector(g_POWER_WIDTH - 1 downto 0);
    -- bitwise power_off pulse
    i_power_off : in std_logic_vector(g_POWER_WIDTH - 1 downto 0)

    );
end entity io_power;

architecture RTL of io_power is

  -- initial state of the bits at the startup
  constant c_BIT_OFF : std_logic := not(pkg_POWER_BIT_ON);

  ---------------------------------------------------------------------
  -- add an optional output pipe
  ---------------------------------------------------------------------
  -- index0: low
  constant c_IDX0_L : integer := 0;
  --index0: high
  constant c_IDX0_H : integer := c_IDX0_L + o_power_off'length - 1;

  -- index1: low
  constant c_IDX1_L : integer := c_IDX0_H + 1;
  --index1: high
  constant c_IDX1_H : integer := c_IDX1_L + o_power_on'length - 1;


  -- temporary input pipe
  signal data_pipe_tmp0 : std_logic_vector(c_IDX1_H downto 0);
  -- temporary output pipe
  signal data_pipe_tmp1 : std_logic_vector(c_IDX1_H downto 0);


begin

  ---------------------------------------------------------------------
  -- add an optional output pipe
  -- data part
  ---------------------------------------------------------------------
  data_pipe_tmp0(c_IDX1_H downto c_IDX1_L) <= i_power_on;
  data_pipe_tmp0(c_IDX0_H downto c_IDX0_L) <= i_power_off;

  inst_pipeliner_optional_output_data : entity work.pipeliner_with_init
    generic map(
      g_INIT       => c_BIT_OFF,
      g_NB_PIPES   => pkg_IO_POWER_DELAY,  -- number of consecutives registers. Possibles values: [0, integer max value[
      g_DATA_WIDTH => data_pipe_tmp2'length  -- width of the input/output data.  Possibles values: [1, integer max value[
      )
    port map(
      i_clk  => i_sys_spi_clk,
      i_data => data_pipe_tmp0,
      o_data => data_pipe_tmp1
      );

  -- output
  o_power_on  <= data_pipe_tmp1(c_IDX1_H downto c_IDX1_L);
  o_power_off <= data_pipe_tmp1(c_IDX0_H downto c_IDX0_L);


end architecture RTL;
