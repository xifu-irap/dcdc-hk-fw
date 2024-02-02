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
--    @file                   power_rhrpmicl1a.vhd
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--   @details
--
--   For the power_rhrpmicl1a device, this module generates:
--      . enable pulses for the associated output port and
--      . disables pulses for the the associated output port.
--
--
--   Note:
--     . An error is generated if a new power_valid_on_off command is received during the previous pulses generations.
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.pkg_system_dcdc.all;

entity power_rhrpmicl1a is
  generic (
    -- enable the DEBUG by ILA
    g_DEBUG            : boolean := false;
    -- width of the input/output power value
    g_POWER_WIDTH      : integer := 4
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
    -- power valid (for power_on and power_off)
    i_power_valid : in std_logic;
    -- bitwise power ('1': power_on, '0':power off)
    i_power       : in std_logic_vector(g_POWER_WIDTH - 1 downto 0);

    ---------------------------------------------------------------------
    -- FSM status
    ---------------------------------------------------------------------
    -- '1': ready to configure the power, '0': busy
    o_ready : out std_logic;

    ---------------------------------------------------------------------
    -- ADC outputs
    ---------------------------------------------------------------------
    -- start of frame (pulse)
    o_power_sof   : out std_logic;
    -- end of frame (pulse)
    o_power_eof   : out std_logic;
    -- power_valid
    o_power_valid : out std_logic;
    -- bitwise power_on pulse
    o_power_on    : out std_logic_vector(g_POWER_WIDTH - 1 downto 0);
    -- bitwise power_off pulse
    o_power_off   : out std_logic_vector(g_POWER_WIDTH - 1 downto 0);

    ---------------------------------------------------------------------
    -- Status/errors
    ---------------------------------------------------------------------
    -- errors
    o_errors : out std_logic_vector(15 downto 0);
    -- status
    o_status : out std_logic_vector(7 downto 0)

    );
end entity power_rhrpmicl1a;

architecture RTL of power_rhrpmicl1a is

  -- define the width of the address field.
  constant c_ADDR_WIDTH : integer := integer(ceil(log2(real(pkg_POWER_TC_PULSE_NB_SAMPLES))));

  -- define the max counter
  constant c_CNT_MAX : unsigned(c_ADDR_WIDTH - 1 downto 0) := to_unsigned(pkg_POWER_TC_PULSE_NB_SAMPLES - 1, c_ADDR_WIDTH);

  -- BIT ON
  constant c_BIT_ON  : std_logic := pkg_POWER_BIT_ON;
  -- BIT OFF
  constant c_BIT_OFF : std_logic := not(pkg_POWER_BIT_ON);

  ---------------------------------------------------------------------
  -- state machine
  ---------------------------------------------------------------------
  -- fsm type declaration
  type t_state is (E_RST, E_WAIT, E_RUN);
  -- state
  signal sm_state_next : t_state;
  -- state (registered)
  signal sm_state_r1   : t_state := E_RST;

  -- start of frame (pulse)
  signal sof_next : std_logic;
  -- delayed start of frame (pulse)
  signal sof_r1   : std_logic;

  -- end of frame (pulse)
  signal eof_next : std_logic;
  -- delayed end of frame (pulse)
  signal eof_r1   : std_logic;

  -- data_valid
  signal data_valid_next : std_logic;
  -- delayed data_valid
  signal data_valid_r1   : std_logic;

  -- power
  signal power_next : std_logic_vector(i_power'range);
  -- delayed power
  signal power_r1   : std_logic_vector(i_power'range);

  -- counter of pulse sample
  signal cnt_next : unsigned(c_ADDR_WIDTH - 1 downto 0);
  -- delayed counter of pulse sample
  signal cnt_r1   : unsigned(c_ADDR_WIDTH - 1 downto 0);

  -- fsm ready
  signal ready_next : std_logic;
  -- delayed fsm ready
  signal ready_r1   : std_logic;

  -- error
  signal error_next : std_logic;
  -- delayed error
  signal error_r1   : std_logic;

  ---------------------------------------------------------------------
  -- Select the ADCs
  ---------------------------------------------------------------------
  -- delayed start of frame (pulse)
  signal sof_r2        : std_logic;
  -- delayed end of frame (pulse)
  signal eof_r2        : std_logic;
  -- data_valid
  signal data_valid_r2 : std_logic;
  -- bitwise power_on
  signal power_on_r2   : std_logic_vector(o_power_on'range);
  -- bitwise power_off
  signal power_off_r2  : std_logic_vector(o_power_off'range);

  ---------------------------------------------------------------------
  -- optional pipeline
  ---------------------------------------------------------------------
  -- delayed start of frame (pulse)
  signal sof_rx        : std_logic;
  -- delayed end of frame (pulse)
  signal eof_rx        : std_logic;
  -- data_valid
  signal data_valid_rx : std_logic;
  -- bitwise power_on
  signal power_on_rx   : std_logic_vector(o_power_on'range);
  -- bitwise power_off
  signal power_off_rx  : std_logic_vector(o_power_off'range);

  ---------------------------------------------------------------------
  -- error latching
  ---------------------------------------------------------------------
  -- define the width of the temporary errors signals
  constant c_NB_ERRORS : integer := 1;
  -- temporary input errors
  signal error_tmp     : std_logic_vector(c_NB_ERRORS - 1 downto 0);
  -- temporary output errors
  signal error_tmp_bis : std_logic_vector(c_NB_ERRORS - 1 downto 0);

begin

  ---------------------------------------------------------------------
  -- rhrpmicl1a: For each bit of the received command,
  --    it generate a pulse either on the associated power_on bit or the associated power_off bit
  ---------------------------------------------------------------------
  -- The steps are:
  --
  p_decode_state : process (cnt_r1, i_power, i_power_valid, power_r1, ready_r1,
                            sm_state_r1) is
  begin
    -- default value
    sof_next        <= '0';
    eof_next        <= '0';
    data_valid_next <= '0';
    power_next      <= power_r1;

    cnt_next <= cnt_r1;

    ready_next <= ready_r1;
    error_next <= '0';

    case sm_state_r1 is
      when E_RST =>
        ready_next    <= '0';
        sm_state_next <= E_WAIT;

      when E_WAIT =>                    -- wait the input command
        if i_power_valid = '1' then
          sof_next        <= '1';
          data_valid_next <= '1';
          power_next      <= i_power;
          ready_next      <= '0';
          cnt_next        <= (others => '0');
          sm_state_next   <= E_RUN;
        else
          ready_next    <= '1';
          sm_state_next <= E_WAIT;
        end if;

      when E_RUN =>                     -- generate pulse

        cnt_next        <= cnt_r1 + 1;
        data_valid_next <= '1';

        if cnt_r1 = c_CNT_MAX then
          eof_next      <= '1';
          sm_state_next <= E_WAIT;
        else
          sm_state_next <= E_RUN;
        end if;



      when others =>
        sm_state_next <= E_RST;
    end case;
  end process p_decode_state;

  -- registered state machine signals
  p_state : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      if i_rst = '1' then
        sm_state_r1 <= E_RST;
      else
        sm_state_r1 <= sm_state_next;
      end if;
      sof_r1        <= sof_next;
      eof_r1        <= eof_next;
      data_valid_r1 <= data_valid_next;
      power_r1      <= power_next;

      cnt_r1 <= cnt_next;

      ready_r1 <= ready_next;
      error_r1 <= error_next;

    end if;
  end process p_state;

  -- output
  o_ready <= ready_r1;

  ---------------------------------------------------------------------
  -- generate power pulse
  ---------------------------------------------------------------------
  p_power : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      sof_r2        <= sof_r1;
      eof_r2        <= eof_r1;
      data_valid_r2 <= data_valid_r1;

      ---------------------------------------------------------------------
      -- generate the bitwise power_on signals
      ---------------------------------------------------------------------
      -- for each bit of the input power, if the bit is set to '1' then enable the bit.
      -- otherwise, disable the bit
      for i in i_power'range loop
        if data_valid_r1 = '1' and power_r1(i) = '1' then
          power_on_r2(i) <= c_BIT_ON;
        else
          power_on_r2(i) <= c_BIT_OFF;
        end if;
      end loop;

      ---------------------------------------------------------------------
      -- generate the bitwise power_off signals
      ---------------------------------------------------------------------
      -- for each bit of the input power, if the bit is set to '0' then enable the bit.
      -- otherwise, disable the bit
      for i in i_power'range loop
        if data_valid_r1 = '1' and power_r1(i) = '0' then
          power_off_r2(i) <= c_BIT_ON;
        else
          power_off_r2(i) <= c_BIT_OFF;
        end if;
      end loop;

    end if;
  end process p_power;

  ---------------------------------------------------------------------
  -- optional output pipe
  ---------------------------------------------------------------------
  gen_pipe : if true generate
    -- index0 low
    constant c_IDX0_L : integer := 0;
    -- index0 high
    constant c_IDX0_H : integer := c_IDX0_L + power_off_r2'length - 1;

    -- index1 low
    constant c_IDX1_L : integer := c_IDX0_H + 1;
    -- index1 high
    constant c_IDX1_H : integer := c_IDX1_L + power_on_r2'length - 1;

    -- index2 low
    constant c_IDX2_L : integer := c_IDX1_H + 1;
    -- index2 high
    constant c_IDX2_H : integer := c_IDX2_L + 1 - 1;

    -- index3 low
    constant c_IDX3_L : integer := c_IDX2_H + 1;
    -- index3 high
    constant c_IDX3_H : integer := c_IDX3_L + 1 - 1;

    -- index4 low
    constant c_IDX4_L : integer := c_IDX3_H + 1;
    -- index4 high
    constant c_IDX4_H : integer := c_IDX4_L + 1 - 1;

    -- temporary input pipe
    signal data_tmp0 : std_logic_vector(c_IDX4_H downto 0);
    -- temporary output pipe
    signal data_tmp1 : std_logic_vector(c_IDX4_H downto 0);

  begin

    data_tmp0(c_IDX4_H)                 <= sof_r2;
    data_tmp0(c_IDX3_H)                 <= eof_r2;
    data_tmp0(c_IDX2_H)                 <= data_valid_r2;
    data_tmp0(c_IDX1_H downto c_IDX1_L) <= power_on_r2;
    data_tmp0(c_IDX0_H downto c_IDX0_L) <= power_off_r2;

    inst_pipeliner_with_init_pipe_out : entity work.pipeliner_with_init
      generic map(
        -- register init value
        g_INIT       => c_BIT_OFF,
        -- number of consecutives registers. Possibles values: [0, integer max value[
        g_NB_PIPES   => pkg_POWER_DELAY_OUT,
        -- width of the input/output data.  Possibles values: [1, integer max value[
        g_DATA_WIDTH => data_tmp0'length
        )
      port map(
        -- clock
        i_clk  => i_clk,
        -- input data
        i_data => data_tmp0,
        -- output data with/without delay
        o_data => data_tmp1
        );

    sof_rx        <= data_tmp1(c_IDX4_H);
    eof_rx        <= data_tmp1(c_IDX3_H);
    data_valid_rx <= data_tmp1(c_IDX2_H);
    power_on_rx   <= data_tmp1(c_IDX1_H downto c_IDX1_L);
    power_off_rx  <= data_tmp1(c_IDX0_H downto c_IDX0_L);

  end generate gen_pipe;


  -- outputs
  o_power_sof   <= sof_rx;
  o_power_eof   <= eof_rx;
  o_power_valid <= data_valid_rx;
  o_power_on    <= power_on_rx;
  o_power_off   <= power_off_rx;

  ---------------------------------------------------------------------
  -- errors/status
  ---------------------------------------------------------------------
  error_tmp(0) <= error_r1;  -- error: new received spi tx command during the tx transmission

  gen_errors_latch : for i in error_tmp'range generate

    inst_one_error_latch : entity work.one_error_latch
      port map(
        i_clk         => i_clk,
        i_rst         => i_rst_status,
        i_debug_pulse => i_debug_pulse,
        i_error       => error_tmp(i),
        o_error       => error_tmp_bis(i)
        );
  end generate gen_errors_latch;

  -- outputs
  o_errors(15 downto 1) <= (others => '0');
  o_errors(0)           <= error_tmp_bis(0);

  o_status(7 downto 1) <= (others => '0');
  o_status(0)          <= ready_r1;

  ---------------------------------------------------------------------
  -- for simulation only
  ---------------------------------------------------------------------
  assert not (error_tmp_bis(0) = '1') report "[power_rhrpmicl1a] => new received command during the power pulse generation" severity error;

  ---------------------------------------------------------------------
  -- debugging: ILAs, etc.
  ---------------------------------------------------------------------
  gen_debug : if g_DEBUG generate

  begin

    inst_ila_power_rhrpmicl1a : entity work.ila_power_rhrpmicl1a
      port map (
        clk => i_clk,

        -- probe0
        probe0(8) => data_valid_rx,
        probe0(7) => sof_rx,
        probe0(6) => eof_rx,
        probe0(5) => error_r1,
        probe0(4) => sof_r1,
        probe0(3) => eof_r1,
        probe0(2) => data_valid_r1,
        probe0(1) => ready_r1,
        probe0(0) => i_power_valid,

        -- probe1
        probe1(15 downto 12) => power_off_rx,
        probe1(11 downto 8)  => power_on_rx,
        probe1(7 downto 4)   => power_r1,
        probe1(3 downto 0)   => i_power

        );


  end generate gen_debug;

end architecture RTL;
