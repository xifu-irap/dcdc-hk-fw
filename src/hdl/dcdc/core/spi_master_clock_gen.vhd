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
--    @file                    spi_master_clock_gen.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--   @details
--   This module generates the SPI frequency (lower frequency) from a system frequency.
--   In particular, the following signals are generated:
--     . the SPI clock (optionnally inverted)
--     . pulse to tag when a data can be sampled
--     . pulse to tag when a data can be shifted
--
--   Note: To generate the SPI clock, the counter "frequency" = 2*g_SPI_FREQUENCY_MAX_HZ
--   Note: (see: https://www.analog.com/en/analog-dialogue/articles/introduction-to-spi-interface.html)
--    SPI_MODE |CPOL|CPHA| clock polarity (idle state)| clock data sampling | clock data shift out
--    0        |  0 | 0  | 0                          | rising_edge         | falling_edge
--    1        |  0 | 1  | 0                          | falling_edge        | rising_edge
--    2        |  1 | 0  | 1                          | rising_edge         | falling_edge
--    3        |  1 | 1  | 1                          | falling_edge        | rising_edge
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity spi_master_clock_gen is
  generic
    (
       -- clock polarity
      g_CPOL                 : std_logic := '0';
      -- clock phase
      g_CPHA                 : std_logic := '0';
      -- input system clock frequency (expressed in Hz). The range is ]2*g_SPI_FREQUENCY_MAX_HZ: max_integer_value]
      g_SYSTEM_FREQUENCY_HZ  : integer   := 128_000_000;
      -- output max spi clock frequency (expressed in Hz).
      g_SPI_FREQUENCY_MAX_HZ : integer   := 20_000_000

      );
  port (
    -- Clock
    i_clk : in std_logic;
    -- Reset
    i_rst : in std_logic;

    ---------------------------------------------------------------------
    -- output
    ---------------------------------------------------------------------
    -- output clock
    o_sclk              : out std_logic;
    -- output pulse when the data can be sampled
    o_pulse_data_sample : out std_logic;
    -- output pulse when the data can be shifted
    o_pulse_data_shift  : out std_logic
    );
end entity spi_master_clock_gen;

architecture RTL of spi_master_clock_gen is
  -- max sample counter value. This value is linked to the spi clock frequency.
  constant c_CNT_FREQ_MAX   : integer := integer(ceil(real(g_SYSTEM_FREQUENCY_HZ)/real(2*g_SPI_FREQUENCY_MAX_HZ)));
  -- sample counter width (expressed in bits)
  constant c_CNT_FREQ_WIDTH : integer := integer(ceil(log2(real(c_CNT_FREQ_MAX))));

  ---------------------------------------------------------------------
  -- pulse generator
  ---------------------------------------------------------------------
  -- step0
  -- spi: clock
  signal sclk_r0 : std_logic;
  -- sample counter
  signal cnt_r0  : unsigned(c_CNT_FREQ_WIDTH - 1 downto 0) := (others => '0');

  -- step1:
  -- spi: clock
  signal sclk_r1 : std_logic;

  -- step2
  -- spi: clock
  signal sclk_r2              : std_logic;
  -- detect the rising_edge of the spi clock
  signal pulse_re2            : std_logic;
  -- detect the falling_edge of the spi clock
  signal pulse_fe2            : std_logic;
  -- step3
  -- spi: clock
  signal sclk_r3              : std_logic;
  -- generate a pulse when the spi data needs to be shifted
  signal pulse_data_shift_r3  : std_logic;
  -- generate a pulse when the spi data needs to be sampled
  signal pulse_data_sample_r3 : std_logic;

begin

  ---------------------------------------------------------------------
  -- pulse generator
  ---------------------------------------------------------------------
  -- generate pulses
  p_pulse : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      ---------------------------------------------------------------------
      -- step0 : generate the clock
      ---------------------------------------------------------------------
      if i_rst = '1' then
        sclk_r0 <= '0';
        cnt_r0  <= (others => '0');
      else
        if cnt_r0 = to_unsigned(c_CNT_FREQ_MAX - 1, cnt_r0'length) then
          sclk_r0 <= not(sclk_r0);      -- frequency divided by 2
          cnt_r0  <= (others => '0');
        else
          cnt_r0 <= cnt_r0 + 1;
        end if;
      end if;

      ---------------------------------------------------------------------
      -- step1: invert the clock if needed
      ---------------------------------------------------------------------
      if g_CPOL = '1' then
        sclk_r1 <= not(sclk_r0);
      else
        sclk_r1 <= sclk_r0;
      end if;

      ---------------------------------------------------------------------
      -- step2
      ---------------------------------------------------------------------
      -- pipe
      sclk_r2 <= sclk_r1;

      -- compute the clock rising_edge
      if sclk_r1 = '1' and sclk_r2 = '0' then
        pulse_re2 <= '1';
      else
        pulse_re2 <= '0';
      end if;

      -- compute the clock falling_edge
      if sclk_r1 = '0' and sclk_r2 = '1' then
        pulse_fe2 <= '1';
      else
        pulse_fe2 <= '0';
      end if;
      ---------------------------------------------------------------------
      -- step3
      ---------------------------------------------------------------------
      -- pipe
      sclk_r3 <= sclk_r2;

      -- generate pulse when data can be sampled
      --   g_CPHA=1: falling_edge data sampling => cs change will be change on the rising_edge
      --   g_CPHA=0: rising_edge data sampling  => cs change will be change on the falling_edge
      ---------------------------------------------------------------------
      if (g_CPHA = '0') and (pulse_re2 = '1') then
        pulse_data_sample_r3 <= '1';
      elsif (g_CPHA = '1') and (pulse_fe2 = '1') then
        pulse_data_sample_r3 <= '1';
      else
        pulse_data_sample_r3 <= '0';
      end if;

      -- generate pulse when data can be shift out
      --    g_CPHA = 1 => data shifts on the rising edge
      --    g_CPHA = 0 => data shifts on the falling edge
      ---------------------------------------------------------------------
      if (g_CPHA = '0' and pulse_fe2 = '1') then
        pulse_data_shift_r3 <= '1';
      elsif (g_CPHA = '1' and pulse_re2 = '1') then
        pulse_data_shift_r3 <= '1';
      else
        pulse_data_shift_r3 <= '0';
      end if;

    end if;
  end process p_pulse;

  ---------------------------------------------------------------------
  -- output
  ---------------------------------------------------------------------
  o_sclk              <= sclk_r3;
  o_pulse_data_sample <= pulse_data_sample_r3;
  o_pulse_data_shift  <= pulse_data_shift_r3;

end architecture RTL;
