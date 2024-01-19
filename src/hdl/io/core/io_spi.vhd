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
--    @file                   io_spi.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--    @details
--
--    Manage IO for the spi
--
--
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.pkg_system_tmtc.all;

library unisim;

entity io_spi is
  port (
    ---------------------------------------------------------------------
    -- from/to IOs: spi @i_sys_spi_clk
    ---------------------------------------------------------------------
    -- system spi clock
    i_sys_spi_clk : in  std_logic;
    -- SPI --
    -- Shared SPI MISO
    i_spi_miso    : in  std_logic;
    -- Shared SPI MOSI
    o_spi_mosi    : out std_logic;
    -- Shared SPI clock line
    o_spi_sclk    : out std_logic;
    -- SPI chip select
    o_spi_cs_n    : out std_logic;

    ---------------------------------------------------------------------
    -- from/to user: spi interface @i_sys_spi_clk
    ---------------------------------------------------------------------
    -- SPI --
    -- Shared SPI MISO
    o_ui_spi_miso : out std_logic;
    -- Shared SPI MOSI
    i_ui_spi_mosi : in  std_logic;
    -- Shared SPI clock line
    i_ui_spi_sclk : in  std_logic;
    -- SPI chip select
    i_ui_spi_cs_n : in  std_logic

    );
end entity io_spi;

architecture RTL of io_spi is

---------------------------------------------------------------------
-- add an optional input pipe
---------------------------------------------------------------------
-- temporary input pipe
  signal data_pipe_tmp0 : std_logic_vector(0 downto 0);
-- temporary output pipe
  signal data_pipe_tmp1 : std_logic_vector(0 downto 0);

-- temporary resync pipe
  signal data_pipe_resync_tmp2 : std_logic_vector(0 downto 0);

---------------------------------------------------------------------
-- add an optional output pipe
---------------------------------------------------------------------
  -- index0: low
  constant c_IDX0_L : integer := 0;
  --index0: high
  constant c_IDX0_H : integer := c_IDX0_L + 1 - 1;

  -- index1: low
  constant c_IDX1_L : integer := c_IDX0_H + 1;
  --index1: high
  constant c_IDX1_H : integer := c_IDX1_L + 1 - 1;


-- temporary input pipe
  signal data_pipe_tmp2 : std_logic_vector(c_IDX1_H downto 0);
-- temporary output pipe
  signal data_pipe_tmp3 : std_logic_vector(c_IDX1_H downto 0);


begin

---------------------------------------------------------------------
-- add an optional input pipe
---------------------------------------------------------------------
  data_pipe_tmp0(0) <= i_spi_miso;

  inst_pipeliner_optional_input_miso : entity work.pipeliner_with_init
    generic map(
      g_INIT       => '0',
      g_NB_PIPES   => pkg_IO_SPI_MISO_DELAY,  -- number of consecutives registers. Possibles values: [0, integer max value[
      g_DATA_WIDTH => data_pipe_tmp0'length  -- width of the input/output data.  Possibles values: [1, integer max value[
      )
    port map(
      i_clk  => i_sys_spi_clk,
      i_data => data_pipe_tmp0,
      o_data => data_pipe_tmp1
      );

  inst_synchronizer_miso : entity work.synchronizer
    generic map(
      -- Initial value of synchronizer registers upon startup, 1'b0 or 1'b1.
      g_INIT            => '0',
      -- Integer value. Number of synchronizing registers, must be 2 or higher
      g_SYNC_STAGES     => pkg_IO_SPI_MISO_RESYNC_DELAY,
      -- Integer value. Number of registers at the output of the synchronizer for the purpose of improving performance. Possible values: [1; integer max value [
      g_PIPELINE_STAGES => 0,
      -- data width expressed in bits
      g_DATA_WIDTH      => data_pipe_tmp1'length
      )
    port map(
      ---------------------------------------------------------------------
      -- input
      ---------------------------------------------------------------------
      -- async input
      i_async_data => data_pipe_tmp1,
      ---------------------------------------------------------------------
      -- output
      ---------------------------------------------------------------------
      -- output clock
      i_clk        => i_sys_spi_clk,
      -- output data with/without delay
      o_data       => data_pipe_resync_tmp2
      );


  o_ui_spi_miso <= data_pipe_resync_tmp2(0);

  ---------------------------------------------------------------------
  -- from the user to the pads
  -- add an optional output pipe
  -- spi clock part
  ---------------------------------------------------------------------
  gen_user_to_pads_clk : if true generate
    -- temporary input clock pipe
    signal clk_pipe_tmp0 : std_logic_vector(0 downto 0);
    -- temporary output clock pipe
    signal clk_pipe_tmp1 : std_logic_vector(0 downto 0);
    -- delayed clock (data)
    signal clk_tmp       : std_logic;
    -- temporary clock
    signal clk_fwd_out   : std_logic;
    -- temporary clock
    signal clk_to_pins   : std_logic;
  begin
    clk_pipe_tmp0(0) <= i_ui_spi_sclk;

    inst_pipeliner_optional_output_clk : entity work.pipeliner_with_init
      generic map(
        g_INIT       => '0',
        g_NB_PIPES   => pkg_IO_SPI_MOSI_DELAY - 1,  -- number of consecutives registers. Possibles values: [0, integer max value[
        g_DATA_WIDTH => clk_pipe_tmp0'length  -- width of the input/output data.  Possibles values: [1, integer max value[
        )
      port map(
        i_clk  => i_sys_spi_clk,
        i_data => clk_pipe_tmp0,
        o_data => clk_pipe_tmp1
        );
    clk_tmp <= clk_pipe_tmp1(0);

    inst_oddr : unisim.vcomponents.ODDR
      generic map(
        DDR_CLK_EDGE   => "SAME_EDGE",
        INIT           => '0',
        IS_C_INVERTED  => '0',
        IS_D1_INVERTED => '0',
        IS_D2_INVERTED => '0',
        SRTYPE         => "ASYNC"
        )
      port map (
        C  => i_sys_spi_clk,
        CE => '1',
        D1 => clk_tmp,
        D2 => clk_tmp,
        Q  => clk_fwd_out,
        R  => '0',
        S  => '0'
        );

    inst_obuf : unisim.vcomponents.OBUF
      port map (
        I => clk_fwd_out,
        O => clk_to_pins
        );
    o_spi_sclk <= clk_to_pins;
  end generate gen_user_to_pads_clk;

  ---------------------------------------------------------------------
  -- add an optional output pipe
  -- data part
  ---------------------------------------------------------------------
  data_pipe_tmp2(c_IDX1_H) <= i_ui_spi_mosi;
  data_pipe_tmp2(c_IDX0_H) <= i_ui_spi_cs_n;

  inst_pipeliner_optional_output_data : entity work.pipeliner_with_init
    generic map(
      g_INIT       => '1',
      g_NB_PIPES   => pkg_IO_SPI_MOSI_DELAY,  -- number of consecutives registers. Possibles values: [0, integer max value[
      g_DATA_WIDTH => data_pipe_tmp2'length  -- width of the input/output data.  Possibles values: [1, integer max value[
      )
    port map(
      i_clk  => i_sys_spi_clk,
      i_data => data_pipe_tmp2,
      o_data => data_pipe_tmp3
      );

  o_spi_mosi <= data_pipe_tmp3(c_IDX1_H);
  o_spi_cs_n <= data_pipe_tmp3(c_IDX0_H);


end architecture RTL;
