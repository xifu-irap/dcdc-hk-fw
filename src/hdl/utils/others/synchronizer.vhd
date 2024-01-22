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
--    @file                   synchronizer.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--   @details
--
--   Asynchronous Input Synchronization
--
--   This module synchronizes an asynchronous input bus of a design in order to
--   reduce the probability of metastability affecting a circuit.
--
--   g_SYNC_STAGES     - Integer value for number of synchronizing registers, must be 2 or higher
--   g_PIPELINE_STAGES - Integer value for number of registers on the output of the
--                     synchronizer for the purpose of improving performance. Possible values: [1; integer max value [
--                     Particularly useful for high-fanout nets.
--   g_INIT            - Initial value of synchronizer registers upon startup, 1'b0 or 1'b1.
--
--  Note:
--    . This code is based on the code example of the Xilinx language template
--
--  IMPORTANT: At the output, when the input data is a bus, the bus bits may not keep synchronization between each other.
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity synchronizer is
  generic(
    -- Initial value of synchronizer registers upon startup, 1'b0 or 1'b1.
    g_INIT            : std_logic := '0';
    -- Integer value. Number of synchronizing registers, must be 2 or higher
    g_SYNC_STAGES     : natural   := 3;
    -- Integer value. Number of registers at the output of the synchronizer for the purpose of improving performance. Possible values: [0; integer max value [
    g_PIPELINE_STAGES : natural   := 1;
    -- data width expressed in bits
    g_DATA_WIDTH      : integer   := 1
    );
  port(
    ---------------------------------------------------------------------
    -- input
    ---------------------------------------------------------------------
    -- async input
    i_async_data : in  std_logic_vector(g_DATA_WIDTH - 1 downto 0);
    ---------------------------------------------------------------------
    -- output
    ---------------------------------------------------------------------
    -- output clock
    i_clk        : in  std_logic;
    -- output data with/without delay
    o_data       : out std_logic_vector(g_DATA_WIDTH - 1 downto 0)
    );
end entity synchronizer;

architecture RTL of synchronizer is

  -- define an array of registers
  type t_array_data is array (natural range <>) of std_logic_vector(i_async_data'range);

  -- shift registers
  signal s_r1                 : t_array_data(g_SYNC_STAGES-1 downto 0) := (others => (others => g_INIT));
  -- fpga specific attribute: force to use registers (very close)
  attribute async_reg         : string;
  -- apply attribute on signal
  attribute async_reg of s_r1 : signal is "true";

  -- output data
  signal data_tmp : std_logic_vector(o_data'range);

begin

  ---------------------------------------------------------------------
  -- shift the input data
  ---------------------------------------------------------------------
  p_shift_data : process(i_clk)
  begin
    if rising_edge(i_clk) then
      s_r1 <= s_r1(s_r1'high - 1 downto 0) & i_async_data;  -- Async Input <async_in>
    end if;
  end process p_shift_data;

  -- add no register on the data path (<=> wire)
  no_pipeline : if g_PIPELINE_STAGES = 0 generate
  begin
    data_tmp <= s_r1(s_r1'high);
  end generate no_pipeline;

  -- add 1 register on the data path
  one_pipeline : if g_PIPELINE_STAGES = 1 generate
  begin
    ---------------------------------------------------------------------
    -- delayed the input data
    ---------------------------------------------------------------------
    p_pipe_data : process(i_clk)
    begin
      if rising_edge(i_clk) then
        data_tmp <= s_r1(s_r1'high);
      end if;
    end process p_pipe_data;
  end generate one_pipeline;

  -- add 2 or more registers on the data path
  multiple_pipeline : if g_PIPELINE_STAGES > 1 generate
    -- additionnal output registers
    signal sreg_pipe_r1                     : t_array_data(g_PIPELINE_STAGES-1 downto 0) := (others => (others => g_INIT));
    -- fpga specific attribute: force to use registers (no shift_register)
    attribute shreg_extract                 : string;
    -- apply attribute on signal
    attribute shreg_extract of sreg_pipe_r1 : signal is "false";
  begin
    ---------------------------------------------------------------------
    -- shift the input data to the left
    ---------------------------------------------------------------------
    p_shift_data : process(i_clk)
    begin
      if rising_edge(i_clk) then
        sreg_pipe_r1 <= sreg_pipe_r1(sreg_pipe_r1'high - 1 downto 0) & s_r1(s_r1'high);
      end if;
    end process p_shift_data;
    data_tmp <= sreg_pipe_r1(sreg_pipe_r1'high);
  end generate multiple_pipeline;

---------------------------------------------------------------------
-- output
---------------------------------------------------------------------
  o_data <= data_tmp;

end architecture RTL;
