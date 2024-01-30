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
--    @file                   system_dcdc_top.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--    Top level architecture
--
-- -------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_regdecode.all;
use work.pkg_system_dcdc_debug.all;
use work.pkg_system_dcdc.all;

entity system_dcdc_top is
  port (
    ---------------------------------------------------------------------
    -- Opal Kelly inouts
    ---------------------------------------------------------------------
    -- usb interface signal
    i_okUH  : in    std_logic_vector(4 downto 0);
    -- usb interface signal
    o_okHU  : out   std_logic_vector(2 downto 0);
    -- usb interface signal
    b_okUHU : inout std_logic_vector(31 downto 0);
    -- usb interface signal
    b_okAA  : inout std_logic;

    ---------------------------------------------------------------------
    --
    ---------------------------------------------------------------------
    -- hardware id register (reading)
    --i_hardware_id : in std_logic_vector(7 downto 0);

    ---------------------------------------------------------------------
    -- ADC128S102 HK
    ---------------------------------------------------------------------
    -- adc SPI MISO
    i_dcdc_hk_adc_miso_a : in  std_logic;
    -- adc SPI MOSI
    o_dcdc_hk_adc_mosi_a : out std_logic;
    -- adc SPI clock
    o_dcdc_hk_adc_sclk_a : out std_logic;
    -- adc SPI chip select
    o_dcdc_hk_adc_cs_n_a : out std_logic;

    ---------------------------------------------------------------------
    -- power
    ---------------------------------------------------------------------
    -- power on
    o_en_wfee : out std_logic;
    o_en_ras  : out std_logic;
    o_en_dmx1 : out std_logic;
    o_en_dmx0 : out std_logic;

    -- power off
    o_dis_wfee : out std_logic;
    o_dis_ras  : out std_logic;
    o_dis_dmx1 : out std_logic;
    o_dis_dmx0 : out std_logic;
    ---------------------------------------------------------------------
    -- LEDS
    ---------------------------------------------------------------------
    -- fpga board leds ('0': ON, 'Z': OFF )
    o_leds     : out std_logic_vector(7 downto 0)

    );
end system_dcdc_top;

architecture RTL of system_dcdc_top is
  ---------------------------------------------------------------------
  -- regdecode_top
  ---------------------------------------------------------------------
  -- hardware id register (reading)
  -- signal hardware_id : std_logic_vector(i_hardware_id'range);
  signal hardware_id : std_logic_vector(7 downto 0);

  -- usb clock
  signal usb_clk : std_logic;

  -- ctrl register (writting)
  signal reg_ctrl : std_logic_vector(31 downto 0);

  -- power_ctrl valid
  signal reg_power_ctrl_valid : std_logic;

  -- power_ctrl register (writting)
  signal reg_power_ctrl : std_logic_vector(31 downto 0);

  -- adc_ctrl valid
  signal reg_adc_ctrl_valid : std_logic;
  -- adc_ctrl register (reading)
  signal reg_adc_ctrl       : std_logic_vector(31 downto 0);

  -- adc_status register (reading)
  signal reg_adc_status : std_logic_vector(31 downto 0);

  -- adc0 register (reading)
  signal reg_adc0 : std_logic_vector(31 downto 0);
  -- adc1 register (reading)
  signal reg_adc1 : std_logic_vector(31 downto 0);
  -- adc2 register (reading)
  signal reg_adc2 : std_logic_vector(31 downto 0);
  -- adc3 register (reading)
  signal reg_adc3 : std_logic_vector(31 downto 0);
  -- adc4 register (reading)
  signal reg_adc4 : std_logic_vector(31 downto 0);
  -- adc5 register (reading)
  signal reg_adc5 : std_logic_vector(31 downto 0);
  -- adc6 register (reading)
  signal reg_adc6 : std_logic_vector(31 downto 0);
  -- adc7 register (reading)
  signal reg_adc7 : std_logic_vector(31 downto 0);

  -- debug_ctrl data valid
  -- signal reg_debug_ctrl_valid : std_logic;
  -- debug_ctrl register value
  signal reg_debug_ctrl : std_logic_vector(31 downto 0);

  -- status register: errors1
  -- signal reg_wire_errors1 : std_logic_vector(31 downto 0);
  -- status register: errors0
  signal reg_wire_errors0 : std_logic_vector(31 downto 0);

  -- status register: status1
  -- signal reg_wire_status1 : std_logic_vector(31 downto 0);
  -- status register: status0
  signal reg_wire_status0 : std_logic_vector(31 downto 0);

  -- software reset @usb_clk
  signal rst         : std_logic;
  -- reset error flag(s)
  signal rst_status  : std_logic;
  -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s)
  signal debug_pulse : std_logic;

  -- adc_start valid
  signal adc_start_valid : std_logic;
  -- adc_start (start ADCs' acquisition)
  signal adc_start       : std_logic;

  -- power_on_off valid
  signal power_on_off_valid : std_logic;
  -- power the signals
  signal power_on_off       : std_logic_vector(3 downto 0);

  ---------------------------------------------------------------------
  -- adc_top
  ---------------------------------------------------------------------
  -- status of the ADCs' acquisition engine.
  signal adc_ready : std_logic;

  -- adcs' value valid
  signal adc_valid : std_logic;
  -- adc7 value
  signal adc7      : std_logic_vector(15 downto 0);
  -- adc6 value
  signal adc6      : std_logic_vector(15 downto 0);
  -- adc5 value
  signal adc5      : std_logic_vector(15 downto 0);
  -- adc4 value
  signal adc4      : std_logic_vector(15 downto 0);
  -- adc3 value
  signal adc3      : std_logic_vector(15 downto 0);
  -- adc2 value
  signal adc2      : std_logic_vector(15 downto 0);
  -- adc1 value
  signal adc1      : std_logic_vector(15 downto 0);
  -- adc0 value
  signal adc0      : std_logic_vector(15 downto 0);

  -- adc SPI MISO
  signal adc_spi_miso : std_logic;
  -- adc SPI MOSI
  signal adc_spi_mosi : std_logic;
  -- adc SPI CLK
  signal adc_spi_sclk : std_logic;
  -- adc SPI Chip Select
  signal adc_spi_cs_n : std_logic;

  -- adc status register: errors0
  signal adc_errors : std_logic_vector(15 downto 0);
  -- adc status register: status0
  signal adc_status : std_logic_vector(7 downto 0);

  ---------------------------------------------------------------------
  -- power_top
  ---------------------------------------------------------------------
  -- power ready (FSM)
  signal power_ready  : std_logic;
  -- bitwise power_on pulse
  signal power_on     : std_logic_vector(3 downto 0);
  -- bitwise power_off pulse
  signal power_off    : std_logic_vector(3 downto 0);
  -- power status register: errors0
  signal power_errors : std_logic_vector(15 downto 0);
  -- power status register: status0
  signal power_status : std_logic_vector(7 downto 0);

begin

  --hardware_id <= i_hardware_id;
  hardware_id <= (others => '0');       -- TODO

  ---------------------------------------------------------------------
  -- regdecode_top
  ---------------------------------------------------------------------
  inst_regdecode_top : entity work.regdecode_top
    generic map(
      g_DEBUG => pkg_REGDECODE_TOP_DEBUG
      )
    port map(
      --  Opal Kelly inouts --
      -- usb interface signal
      i_okUH  => i_okUH,
      -- usb interface signal
      o_okHU  => o_okHU,
      -- usb interface signal
      b_okUHU => b_okUHU,
      -- usb interface signal
      b_okAA  => b_okAA,

      ---------------------------------------------------------------------
      -- From IO
      ---------------------------------------------------------------------
      -- hardware id register (reading)
      i_hardware_id => hardware_id,

      ---------------------------------------------------------------------
      -- to the user @o_usb_clk
      ---------------------------------------------------------------------
      -- usb clock
      o_usb_clk => usb_clk,

      -- wire
      -- ctrl register (writting)
      o_reg_ctrl             => reg_ctrl,
      -- power_ctrl valid
      o_reg_power_ctrl_valid => reg_power_ctrl_valid,
      -- power_ctrl register (writting)
      o_reg_power_ctrl       => reg_power_ctrl,

      -- ADC @o_usb_clk
      ---------------------------------------------------------------------
      -- adc_ctrl valid (reading)
      o_reg_adc_ctrl_valid => reg_adc_ctrl_valid,
      -- adc_ctrl register (reading)
      o_reg_adc_ctrl       => reg_adc_ctrl,
      -- adc_status register (reading)
      i_reg_adc_status     => reg_adc_status,
      -- adc0 register (reading)
      i_reg_adc0           => reg_adc0,
      -- adc1 register (reading)
      i_reg_adc1           => reg_adc1,
      -- adc2 register (reading)
      i_reg_adc2           => reg_adc2,
      -- adc3 register (reading)
      i_reg_adc3           => reg_adc3,
      -- adc4 register (reading)
      i_reg_adc4           => reg_adc4,
      -- adc5 register (reading)
      i_reg_adc5           => reg_adc5,
      -- adc6 register (reading)
      i_reg_adc6           => reg_adc6,
      -- adc7 register (reading)
      i_reg_adc7           => reg_adc7,

      -- debug_ctrl @o_usb_clk
      ---------------------------------------------------------------------
      -- debug_ctrl data valid
      o_reg_debug_ctrl_valid => open,
      -- debug_ctrl register value
      o_reg_debug_ctrl       => reg_debug_ctrl,

      -- errors/status
      ---------------------------------------------------------------------
      -- status register: errors0
      i_reg_wire_errors0 => reg_wire_errors0,
      -- status register: status0
      i_reg_wire_status0 => reg_wire_status0
      );


  -- extract bits from register
  ---------------------------------------------------------------------
  -- ctrl register
  rst                <= reg_ctrl(pkg_CTRL_RST_IDX_H);
  -- debug_ctrl register
  rst_status         <= reg_debug_ctrl(pkg_DEBUG_CTRL_RST_STATUS_IDX_H);
  debug_pulse        <= reg_debug_ctrl(pkg_DEBUG_CTRL_DEBUG_PULSE_IDX_H);
  -- adc_ctrl register
  adc_start_valid    <= reg_adc_ctrl_valid;
  adc_start          <= reg_adc_ctrl(pkg_ADC_CTRL_ADC_SPI_START_IDX_H);
  -- power_ctrl register
  power_on_off_valid <= reg_power_ctrl_valid;
  power_on_off       <= reg_power_ctrl(pkg_POWER_CTRL_POWER_IDX_H downto pkg_POWER_CTRL_POWER_IDX_L);

  -- to register
  ---------------------------------------------------------------------
  reg_adc_status(31 downto 1) <= (others => '0');
  reg_adc_status(0)           <= adc_ready;

  -- by considering positive analog voltage
  reg_adc7 <= std_logic_vector(resize(unsigned(adc7), reg_adc7'length));
  reg_adc6 <= std_logic_vector(resize(unsigned(adc6), reg_adc6'length));
  reg_adc5 <= std_logic_vector(resize(unsigned(adc5), reg_adc5'length));
  reg_adc4 <= std_logic_vector(resize(unsigned(adc4), reg_adc4'length));
  reg_adc3 <= std_logic_vector(resize(unsigned(adc3), reg_adc3'length));
  reg_adc2 <= std_logic_vector(resize(unsigned(adc2), reg_adc2'length));
  reg_adc1 <= std_logic_vector(resize(unsigned(adc1), reg_adc1'length));
  reg_adc0 <= std_logic_vector(resize(unsigned(adc0), reg_adc1'length));

  -- errors0
  reg_wire_errors0(31 downto 16) <= power_errors;
  reg_wire_errors0(15 downto 0)  <= adc_errors;

  -- status0
  reg_wire_status0(31 downto 24) <= (others => '0');
  reg_wire_status0(23 downto 16) <= power_status;
  reg_wire_status0(15 downto 8)  <= (others => '0');
  reg_wire_status0(7 downto 0)   <= adc_status;


  ---------------------------------------------------------------------
  -- dcdc_top
  ---------------------------------------------------------------------
  inst_dcdc_top : entity work.dcdc_top
    generic map(
      -- enable the DEBUG by ILA
      g_DEBUG => pkg_DCDC_ADC128S102_DEBUG
      )
    port map(
      -- clock
      i_clk         => usb_clk,
      -- reset
      i_rst         => rst,
      -- reset error flag(s)
      i_rst_status  => rst_status,
      -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s)
      i_debug_pulse => debug_pulse,

      ---------------------------------------------------------------------
      -- inputs
      ---------------------------------------------------------------------
      -- Valid start ADCs' acquisition
      i_adc_start_valid => adc_start_valid,
      -- start ADCs' acquisition
      i_adc_start       => adc_start,

      ---------------------------------------------------------------------
      -- outputs
      ---------------------------------------------------------------------
      -- '1': ready to start an acquisition, '0': busy
      o_adc_ready    => adc_ready,
      -- ADC values valid
      o_adc_valid    => adc_valid,
      -- ADC7 value
      o_adc7         => adc7,
      -- ADC6 value
      o_adc6         => adc6,
      -- ADC5 value
      o_adc5         => adc5,
      -- ADC4 value
      o_adc4         => adc4,
      -- ADC3 value
      o_adc3         => adc3,
      -- ADC2 value
      o_adc2         => adc2,
      -- ADC1 value
      o_adc1         => adc1,
      -- ADC0 value
      o_adc0         => adc0,
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
      o_adc_errors   => adc_errors,
      o_adc_status   => adc_status
      );


  ---------------------------------------------------------------------
  -- io_top
  ---------------------------------------------------------------------
  inst_io_top : entity work.io_top
    port map(
      ---------------------------------------------------------------------
      -- from/to FPGA io: spi @i_sys_spi_clk
      ---------------------------------------------------------------------
      -- system spi clock
      i_sys_spi_clk => usb_clk,
      -- SPI --
      -- Shared SPI MISO
      i_spi_miso    => i_dcdc_hk_adc_miso_a,
      -- Shared SPI MOSI
      o_spi_mosi    => o_dcdc_hk_adc_mosi_a,
      -- Shared SPI clock line
      o_spi_sclk    => o_dcdc_hk_adc_sclk_a,
      -- SPI chip select
      o_spi_cs_n    => o_dcdc_hk_adc_cs_n_a,

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
      i_ui_spi_cs_n => adc_spi_cs_n
      );

  ---------------------------------------------------------------------
  -- power_top
  ---------------------------------------------------------------------
  inst_power_top : entity work.power_top
    generic map(
      -- enable the DEBUG by ILA
      g_DEBUG            => pkg_POWER_RHRPMICL1A_DEBUG,
      -- width of the input/output power value
      g_POWER_WIDTH      => power_on_off'length,
      -- duration of the TC pulse (number of samples). Range: [1;max integer[
      g_PULSE_NB_SAMPLES => pkg_POWER_TC_PULSE_NB_SAMPLES
      )
    port map(
      -- clock
      i_clk         => usb_clk,
      -- reset
      i_rst         => rst,
      -- reset error flag(s)
      i_rst_status  => rst_status,
      -- error mode (transparent vs capture). Possible values: '1': delay the error(s), '0': capture the error(s)
      i_debug_pulse => debug_pulse,
      ---------------------------------------------------------------------
      -- inputs
      ---------------------------------------------------------------------
      -- power_valid (for power on and power off)
      i_power_valid => power_on_off_valid,
      -- bitwise power ('1': power on, '0':power off)
      i_power       => power_on_off,
      ---------------------------------------------------------------------
      -- outputs
      ---------------------------------------------------------------------
      -- '1': ready to configure the power, '0': busy
      o_ready       => power_ready,     -- TODO: to connect
      -- start of frame (pulse)
      o_power_sof   => open,
      -- end of frame (pulse)
      o_power_eof   => open,
      -- output power valid
      o_power_valid => open,
      -- bitwise power_on pulse
      o_power_on    => power_on,
      -- bitwise power_off pulse
      o_power_off   => power_off,
      ---------------------------------------------------------------------
      -- Status/errors
      ---------------------------------------------------------------------
      --  errors
      o_errors      => power_errors,
      -- status
      o_status      => power_status
      );

  -- output
  -- power on
  o_en_wfee <= power_on(3);
  o_en_ras  <= power_on(2);
  o_en_dmx1 <= power_on(1);
  o_en_dmx0 <= power_on(0);

  -- power off
  o_dis_wfee <= power_off(3);
  o_dis_ras  <= power_off(2);
  o_dis_dmx1 <= power_off(1);
  o_dis_dmx0 <= power_off(0);

  ---------------------------------------------------------------------
  -- leds
  ---------------------------------------------------------------------
  inst_leds_top : entity work.leds_top
    port map(
      ---------------------------------------------------------------------
      -- input @i_clk
      ---------------------------------------------------------------------
      -- clock
      i_clk => usb_clk,
      -- reset  @i_clk
      i_rst => rst,

      ---------------------------------------------------------------------
      -- from science @i_clk
      ---------------------------------------------------------------------
      -- -- Valid start ADCs' acquisition
      i_adc_start_valid => adc_start_valid,
      -- start ADCs' acquisition
      i_adc_start       => adc_start,

      ---------------------------------------------------------------------
      -- output @i_clk
      ---------------------------------------------------------------------
      -- FPGA board: status leds ('1':ON, 'Z':OFF)
      o_leds => o_leds
      );


end RTL;
