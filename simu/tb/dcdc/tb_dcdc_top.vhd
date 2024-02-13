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
--    @file                   tb_dcdc_top.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--   @details
--
--   This is the testbench of the dcdc_top
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity tb_dcdc_top is

end entity tb_dcdc_top;

architecture RTL of tb_dcdc_top is

  ---------------------------------------------------------------------
  -- ADC
  ---------------------------------------------------------------------
  -- ADC analog voltage
  constant c_VA      : real    := 5.0;
  -- ADC resolution (expressed in bits)
  constant c_ADC_RES : integer := 12;
  -- ADC0 input voltage (expressed in V)
  constant c_ADC0    : real    := 0.1;
  -- ADC1 input voltage (expressed in V)
  constant c_ADC1    : real    := 1.0;
  -- ADC2 input voltage (expressed in V)
  constant c_ADC2    : real    := 2.0;
  -- ADC3 input voltage (expressed in V)
  constant c_ADC3    : real    := 3.0;
  -- ADC4 input voltage (expressed in V)
  constant c_ADC4    : real    := 4.0;
  -- ADC5 input voltage (expressed in V)
  constant c_ADC5    : real    := 5.0;
  -- ADC6 input voltage (expressed in V)
  constant c_ADC6    : real    := 1.2;
  -- ADC7 input voltage (expressed in V)
  constant c_ADC7    : real    := 2.5;

  ---------------------------------------------------------------------
  -- dcdc_top
  ---------------------------------------------------------------------
  -- clock
  signal i_clk             : std_logic := '0';
  -- reset
  signal i_rst             : std_logic := '0';
  -- reset error flag(s)
  signal i_rst_status      : std_logic := '0';
  -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s)
  signal i_debug_pulse     : std_logic := '0';
  -- Valid start ADCs' acquisition
  signal i_adc_start_valid : std_logic := '0';
  -- start ADCs' acquisition
  signal i_adc_start       : std_logic := '0';
  -- '1': tx_ready to start an acquisition, '0': busy
  signal o_adc_ready       : std_logic;
  -- ADC values valid
  signal o_adc_valid       : std_logic;
  -- ADC7 value
  signal o_adc7            : std_logic_vector(15 downto 0);
  -- ADC6 value
  signal o_adc6            : std_logic_vector(15 downto 0);
  -- ADC5 value
  signal o_adc5            : std_logic_vector(15 downto 0);
  -- ADC4 value
  signal o_adc4            : std_logic_vector(15 downto 0);
  -- ADC3 value
  signal o_adc3            : std_logic_vector(15 downto 0);
  -- ADC2 value
  signal o_adc2            : std_logic_vector(15 downto 0);
  -- ADC1 value
  signal o_adc1            : std_logic_vector(15 downto 0);
  -- ADC0 value
  signal o_adc0            : std_logic_vector(15 downto 0);

  ---------------------------------------------------------------------
  -- spi interface
  ---------------------------------------------------------------------
  -- SPI MISO
  signal adc_spi_miso : std_logic;
  -- SPI MOSI
  signal adc_spi_mosi : std_logic;
  -- SPI clock
  signal adc_spi_sclk : std_logic;
  -- SPI chip select
  signal adc_spi_cs_n : std_logic;

  ---------------------------------------------------------------------
  -- Status/errors
  ---------------------------------------------------------------------
  -- adc errors
  signal o_adc_errors : std_logic_vector(15 downto 0);
  -- adc status
  signal o_adc_status : std_logic_vector(7 downto 0);


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
  -- from/to user: @i_clk
  ---------------------------------------------------------------------
  -- bitwise power_on pulse
  signal i_power_on  : std_logic_vector(3 downto 0);
  -- bitwise power_off pulse
  signal i_power_off : std_logic_vector(3 downto 0);


  ---------------------------------------------------------------------
  -- Clock period
  ---------------------------------------------------------------------
  -- clock period
  constant c_CLK_PERIOD : time := 9.92 ns;  -- 100.8 MHz

  -- compute the ADC voltage from the numerical value
  function compute_voltage (
    -- ADC value (numerical)
    i_adc     : in std_logic_vector;
    -- ADC analog voltage (supply)
    i_VA      : in real;
    -- ADC res
    i_adc_res : in integer

    )
    -- computed analog voltage
    return real is
  begin
    return to_integer(unsigned(i_adc)) * i_VA / (2**i_adc_res);
  end function compute_voltage;

  -- check if the computed ADCs voltage is equal to the input ADC voltage
  function check_adc_values (
    -- message
    i_msg      : in string;
    -- ADC value (numerical)
    i_adc_meas : in std_logic_vector;
    -- ADC analog
    i_adc      : in real;
    -- ADC analog voltage (supply)
    i_VA       : in real;
    -- ADC res
    i_adc_res  : in integer

    )
    return integer is
    -- computed adc voltage (from the numerical value)
    variable v_adc_meas : real;
    -- computed adc quantum
    variable v_step     : real;
    -- returned error
    variable v_error    : integer;

  begin

    v_adc_meas := compute_voltage(i_adc => i_adc_meas, i_VA => i_VA, i_adc_res => i_adc_res);
    v_step     := i_VA/(2**i_adc_res);

    if abs(v_adc_meas - i_adc) <= v_step then
      v_error := 0;
      report "[OK]: " & i_msg & " adc_meas = "& to_string(v_adc_meas) & ", adc = " & to_string(i_adc) &")" severity note;
    else
      v_error := -1;
      report "[KO]: " & i_msg & " too much gap adc_meas = "& to_string(v_adc_meas) & ", adc = " & to_string(i_adc) &")" severity error;
    end if;
    return v_error;

  end function check_adc_values;

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
    -- error
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

    wait on i_clk until o_adc_ready = '1';
    wait for 12 ps;
    -- start an acquisition
    i_adc_start_valid <= '1';
    i_adc_start       <= '1';

    wait until rising_edge(i_clk);
    wait for 12 ps;
    -- desassert the start acquisition
    i_adc_start_valid <= '0';

    wait on i_clk until o_adc_valid = '1';

    -- check computed ADCs values (voltage) vs input ADCs values (voltage)
    v_error := check_adc_values(i_msg => "ADC0", i_adc_meas => o_adc0, i_adc => c_ADC0, i_VA => c_VA, i_adc_res => c_ADC_RES);
    v_error := check_adc_values(i_msg => "ADC1", i_adc_meas => o_adc1, i_adc => c_ADC1, i_VA => c_VA, i_adc_res => c_ADC_RES);
    v_error := check_adc_values(i_msg => "ADC2", i_adc_meas => o_adc2, i_adc => c_ADC2, i_VA => c_VA, i_adc_res => c_ADC_RES);
    v_error := check_adc_values(i_msg => "ADC3", i_adc_meas => o_adc3, i_adc => c_ADC3, i_VA => c_VA, i_adc_res => c_ADC_RES);
    v_error := check_adc_values(i_msg => "ADC4", i_adc_meas => o_adc4, i_adc => c_ADC4, i_VA => c_VA, i_adc_res => c_ADC_RES);
    v_error := check_adc_values(i_msg => "ADC5", i_adc_meas => o_adc5, i_adc => c_ADC5, i_VA => c_VA, i_adc_res => c_ADC_RES);
    v_error := check_adc_values(i_msg => "ADC6", i_adc_meas => o_adc6, i_adc => c_ADC6, i_VA => c_VA, i_adc_res => c_ADC_RES);
    v_error := check_adc_values(i_msg => "ADC7", i_adc_meas => o_adc7, i_adc => c_ADC7, i_VA => c_VA, i_adc_res => c_ADC_RES);


    -- check internal errors
    v_error := check_errors(i_msg => "o_adc_errors", i_error => o_adc_errors);


    -- tempo
    wait for c_CLK_PERIOD*1000;
    wait;
  end process;

---------------------------------------------------------------------
-- DUT
---------------------------------------------------------------------
  inst_dcdc_top : entity work.dcdc_top
    generic map(
      -- enable the DEBUG by ILA
      g_DEBUG => false
      )
    port map(
      -- clock
      i_clk             => i_clk,
      -- reset
      i_rst             => i_rst,
      -- reset error flag(s)
      i_rst_status      => i_rst_status,
      -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s)
      i_debug_pulse     => i_debug_pulse,
      -- Valid start ADCs' acquisition
      i_adc_start_valid => i_adc_start_valid,

      -- '1': tx_ready to start an acquisition, '0': busy
      o_adc_ready    => o_adc_ready,
      -- ADC values valid
      o_adc_valid    => o_adc_valid,
      -- ADC7 value
      o_adc7         => o_adc7,
      -- ADC6 value
      o_adc6         => o_adc6,
      -- ADC5 value
      o_adc5         => o_adc5,
      -- ADC4 value
      o_adc4         => o_adc4,
      -- ADC3 value
      o_adc3         => o_adc3,
      -- ADC2 value
      o_adc2         => o_adc2,
      -- ADC1 value
      o_adc1         => o_adc1,
      -- ADC0 value
      o_adc0         => o_adc0,
      ---------------------------------------------------------------------
      -- spi interface
      ---------------------------------------------------------------------
      -- SPI MISO
      i_adc_spi_miso => adc_spi_miso,
      -- SPI MOSI
      o_adc_spi_mosi => adc_spi_mosi,
      -- SPI clock
      o_adc_spi_sclk => adc_spi_sclk,
      -- SPI chip select
      o_adc_spi_cs_n => adc_spi_cs_n,
      ---------------------------------------------------------------------
      -- Status/errors
      ---------------------------------------------------------------------
      -- adc errors
      o_adc_errors   => o_adc_errors,
      -- adc status
      o_adc_status   => o_adc_status
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
      i_spi_miso    => spi_miso,
      -- Shared SPI MOSI
      o_spi_mosi    => spi_mosi,
      -- Shared SPI clock line
      o_spi_sclk    => spi_sclk,
      -- SPI chip select
      o_spi_cs_n    => spi_cs_n,
      ---------------------------------------------------------------------
      -- to user: spi interface @i_sys_spi_clk
      ---------------------------------------------------------------------
      -- SPI --
      -- Shared SPI MISO
      o_ui_spi_miso => adc_spi_miso,
      -- Shared SPI MOSI
      i_ui_spi_mosi => adc_spi_mosi,
      -- Shared SPI clock line
      i_ui_spi_sclk => adc_spi_sclk,
      -- SPI chip select
      i_ui_spi_cs_n => adc_spi_cs_n,

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
      i_power_on  => i_power_on,
      -- bitwise power_off pulse
      i_power_off => i_power_off

      );


---------------------------------------------------------------------
-- ADC SPI device
--   . From an ADC numerical value, get the corresponding analog tension (U):
--      . Formula:
--         . U = adc_value * VA /(2**adc_res)
--          with:
--           . U (in Volts): computed tension from an unsigned adc_value
--           . adc_value: unsigned ADC numerical value
--           . VA (in Volts): analog supply
--           . adc_res: ADC resolution (12 bits)
---------------------------------------------------------------------
  inst_adc128s102 : entity work.adc128s102
--generic map(
--    -- Interconnect path delays
--tipd_SCLK => tipd_SCLK,
--tipd_CSNeg => tipd_CSNeg,
--tipd_DIN => tipd_DIN,
--    -- Propagation delays
--tpd_SCLK_DOUT => tpd_SCLK_DOUT,
--tpd_CSNeg_DOUT => tpd_CSNeg_DOUT,
--    -- Setup/hold violation
--tsetup_CSNeg_SCLK => tsetup_CSNeg_SCLK,
--tsetup_DIN_SCLK => tsetup_DIN_SCLK,
--thold_CSNeg_SCLK => thold_CSNeg_SCLK,
--thold_DIN_SCLK => thold_DIN_SCLK,
--    -- Puls width checks
--tpw_SCLK_posedge => tpw_SCLK_posedge,
--tpw_SCLK_negedge => tpw_SCLK_negedge,
--    -- Period checks
--tperiod_SCLK_posedge => tperiod_SCLK_posedge,
--    -- generic control parameters
--InstancePath => InstancePath,
--TimingChecksOn => TimingChecksOn,
--MsgOn => MsgOn,
--XOn => XOn,
--    -- For FMF SDF technology file usage
--TimingModel => TimingModel
--)
    port map(
      SCLK  => spi_sclk,
      CSNeg => spi_cs_n,
      DIN   => spi_mosi,
      VA    => c_VA,
      IN0   => c_ADC0,
      IN1   => c_ADC1,
      IN2   => c_ADC2,
      IN3   => c_ADC3,
      IN4   => c_ADC4,
      IN5   => c_ADC5,
      IN6   => c_ADC6,
      IN7   => c_ADC7,
      DOUT  => spi_miso
      );


end architecture RTL;
