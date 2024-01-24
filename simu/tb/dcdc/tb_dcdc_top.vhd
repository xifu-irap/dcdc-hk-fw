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


entity tb_dcdc_top is

end entity tb_dcdc_top;

architecture RTL of tb_dcdc_top is

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
  signal i_adc_spi_miso    : std_logic;
  -- SPI MOSI
  signal o_adc_spi_mosi    : std_logic;
  -- SPI clock
  signal o_adc_spi_sclk    : std_logic;
  -- SPI chip select
  signal o_adc_spi_cs_n    : std_logic;
  ---------------------------------------------------------------------
  -- Status/errors
  ---------------------------------------------------------------------
  -- adc errors
  signal o_adc_errors      : std_logic_vector(15 downto 0);
  -- adc status
  signal o_adc_status      : std_logic_vector(7 downto 0);


  ---------------------------------------------------------------------
  -- Clock period
  ---------------------------------------------------------------------
  constant c_CLK_PERIOD : time := 9.92 ns;  -- 100.8 MHz


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
      -- start ADCs' acquisition
      i_adc_start       => i_adc_start,
      -- '1': tx_ready to start an acquisition, '0': busy
      o_adc_ready       => o_adc_ready,
      -- ADC values valid
      o_adc_valid       => o_adc_valid,
      -- ADC7 value
      o_adc7            => o_adc7,
      -- ADC6 value
      o_adc6            => o_adc6,
      -- ADC5 value
      o_adc5            => o_adc5,
      -- ADC4 value
      o_adc4            => o_adc4,
      -- ADC3 value
      o_adc3            => o_adc3,
      -- ADC2 value
      o_adc2            => o_adc2,
      -- ADC1 value
      o_adc1            => o_adc1,
      -- ADC0 value
      o_adc0            => o_adc0,
      ---------------------------------------------------------------------
      -- spi interface
      ---------------------------------------------------------------------
      -- SPI MISO
      i_adc_spi_miso    => i_adc_spi_miso,
      -- SPI MOSI
      o_adc_spi_mosi    => o_adc_spi_mosi,
      -- SPI clock
      o_adc_spi_sclk    => o_adc_spi_sclk,
      -- SPI chip select
      o_adc_spi_cs_n    => o_adc_spi_cs_n,
      ---------------------------------------------------------------------
      -- Status/errors
      ---------------------------------------------------------------------
      -- adc errors
      o_adc_errors      => o_adc_errors,
      -- adc status
      o_adc_status      => o_adc_status
      );


---------------------------------------------------------------------
-- ADC SPI device
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
      SCLK  => o_adc_spi_sclk,
      CSNeg => o_adc_spi_cs_n,
      DIN   => o_adc_spi_mosi,
      VA    => 5.0,
      IN0   => 0.1,
      IN1   => 1.0,
      IN2   => 2.0,
      IN3   => 3.0,
      IN4   => 4.0,
      IN5   => 5.0,
      IN6   => 1.2,
      IN7   => 2.5,
      DOUT  => i_adc_spi_miso
      );


end architecture RTL;
