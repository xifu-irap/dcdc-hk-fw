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
--    @file                   tb_power_top.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--   @details
--
--   This is the testbench of the power_top
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity tb_power_top is

end entity tb_power_top;

architecture RTL of tb_power_top is

  ---------------------------------------------------------------------
  -- power_top
  ---------------------------------------------------------------------
  -- clock
  signal i_clk         : std_logic;
  -- reset
  signal i_rst         : std_logic;
  -- reset error flag(s)
  signal i_rst_status  : std_logic;
  -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s)
  signal i_debug_pulse : std_logic;
  ---------------------------------------------------------------------
  -- inputs
  ---------------------------------------------------------------------
  -- power_valid (for power_on and power_off)
  signal i_power_valid : std_logic;
  -- bitwise power ('1': power_on, '0':power off)
  signal i_power       : std_logic_vector(3 downto 0);
  ---------------------------------------------------------------------
  -- outputs
  ---------------------------------------------------------------------
  -- '1': ready to configure the power, '0': busy
  signal o_ready       : std_logic;
  -- start of frame (pulse)
  signal o_power_sof   : std_logic;
  -- end of frame (pulse)
  signal o_power_eof   : std_logic;
  -- output power valid
  signal o_power_valid : std_logic;
  -- bitwise power_on pulse
  signal power_on      : std_logic_vector(3 downto 0);
  -- bitwise power_off pulse
  signal power_off     : std_logic_vector(3 downto 0);
  ---------------------------------------------------------------------
  -- Status/errors
  ---------------------------------------------------------------------
  --  errors
  signal o_errors      : std_logic_vector(15 downto 0);
  -- status
  signal o_status      : std_logic_vector(7 downto 0);

  ---------------------------------------------------------------------
  -- io interface
  ---------------------------------------------------------------------
  -- SPI MISO
  signal spi_miso : std_logic;
  -- SPI MOSI
  signal spi_mosi : std_logic;
  -- SPI clock
  signal spi_sclk : std_logic;
  -- SPI chip select
  signal spi_cs_n : std_logic;

  -- bitwise power_on pulse
  signal o_power_on  : std_logic_vector(3 downto 0);
  -- bitwise power_off pulse
  signal o_power_off : std_logic_vector(3 downto 0);


  ---------------------------------------------------------------------
  -- Clock period
  ---------------------------------------------------------------------
  -- clock period
  constant c_CLK_PERIOD : time := 9.92 ns;  -- 100.8 MHz

  -- check errors
  function check_errors (
    -- message
    i_msg   : in string;
    -- ADC value (numerical)
    i_error : in std_logic_vector

    )
    return integer is

    -- returned error
    variable v_error : integer;

  begin

    v_error := to_integer(unsigned(i_error));

    if v_error = 0 then
      report "[OK]: " & i_msg & " has 0 errors" severity note;
    else
      report "[KO]: " & i_msg & " has " & to_string(v_error) & " errors." severity error;
    end if;
    return v_error;

  end function check_errors;



begin

  -- Clock process definitions
  p_clk : process
  begin
    i_clk <= '0';
    wait for c_CLK_PERIOD/2;
    i_clk <= '1';
    wait for c_CLK_PERIOD/2;
  end process;

  -- Stimulus process
  p_stim : process
    -- error value
    variable v_error : integer;

  begin

    i_rst         <= '1';
    i_rst_status  <= '1';
    i_debug_pulse <= '1';
    -- hold reset state for 100 ns.
    wait for 100 ns;
    -- deassert reset
    i_rst         <= '0';
    i_rst_status  <= '0';

    -- tempo
    wait for 100 ns;

    wait on i_clk until o_ready = '1';
    wait for 12 ps;
    -- start an acquisition
    i_power_valid <= '1';
    i_power       <= std_logic_vector(to_unsigned(9, i_power'length));

    wait until rising_edge(i_clk);
    wait for 12 ps;
    -- desassert the start acquisition
    i_power_valid <= '0';

    wait on i_clk until o_power_valid = '1';

    -- check internal errors
    v_error := check_errors(i_msg => "o_errors", i_error => o_errors);


    -- tempo
    wait for c_CLK_PERIOD*1000;
    wait;
  end process;

---------------------------------------------------------------------
-- DUT
---------------------------------------------------------------------
  inst_power_top : entity work.power_top
    generic map(
      -- enable the DEBUG by ILA
      g_DEBUG       => false,
      -- width of the input/output power value
      g_POWER_WIDTH => i_power'length
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
      -- power_valid (for power_on and power_off)
      i_power_valid => i_power_valid,
      -- bitwise power ('1': power_on, '0':power off)
      i_power       => i_power,
      ---------------------------------------------------------------------
      -- outputs
      ---------------------------------------------------------------------
      -- '1': ready to configure the power, '0': busy
      o_ready       => o_ready,
      -- start of frame (pulse)
      o_power_sof   => o_power_sof,
      -- end of frame (pulse)
      o_power_eof   => o_power_eof,
      -- output power valid
      o_power_valid => o_power_valid,
      -- bitwise power_on pulse
      o_power_on    => power_on,
      -- bitwise power_off pulse
      o_power_off   => power_off,
      ---------------------------------------------------------------------
      -- Status/errors
      ---------------------------------------------------------------------
      --  errors
      o_errors      => o_errors,
      -- status
      o_status      => o_status
      );



---------------------------------------------------------------------
-- io
---------------------------------------------------------------------
  inst_io_top : entity work.io_top
    port map(
      ---------------------------------------------------------------------
      -- from/to FPGA io: spi @i_sys_spi_clk
      ---------------------------------------------------------------------
      -- system spi clock
      i_sys_spi_clk => i_clk,
      -- SPI --
      -- Shared SPI MISO
      i_spi_miso    => '0',
      -- Shared SPI MOSI
      o_spi_mosi    => open,
      -- Shared SPI clock line
      o_spi_sclk    => open,
      -- SPI chip select
      o_spi_cs_n    => open,
      ---------------------------------------------------------------------
      -- to user: spi interface @i_sys_spi_clk
      ---------------------------------------------------------------------
      -- SPI --
      -- Shared SPI MISO
      o_ui_spi_miso => open,
      -- Shared SPI MOSI
      i_ui_spi_mosi => '0',
      -- Shared SPI clock line
      i_ui_spi_sclk => '0',
      -- SPI chip select
      i_ui_spi_cs_n => '0',

      ---------------------------------------------------------------------
      -- power
      ---------------------------------------------------------------------
      -- power_clock
      i_power_clk => i_clk,
      ---------------------------------------------------------------------
      -- from/to IOs: @i_clk
      ---------------------------------------------------------------------
      -- bitwise power_on pulse
      o_power_on  => o_power_on,
      -- bitwise power_off pulse
      o_power_off => o_power_off,
      ---------------------------------------------------------------------
      -- from/to user: @i_clk
      ---------------------------------------------------------------------
      -- bitwise power_on pulse
      i_power_on  => power_on,
      -- bitwise power_off pulse
      i_power_off => power_off

      );



end architecture RTL;
