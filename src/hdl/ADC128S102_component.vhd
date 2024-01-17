-------------------------------------------------------------------------------
-- File Name: adc128s102.vhd
-------------------------------------------------------------------------------
-- Copyright (C) 2012 Free Model Foundry; http://www.FreeModelFoundry.com
-- This program is free software; you can redistribute it and/or modify it
-- under the terms of the GNU General Public License version 2 as published by
-- the Free Software Foundation.
--
-- MODIFICATION HIS TRY:
-- version: |       author:     |  mod date: | changes made:
--   V1.0     D. Randjelovic      12 May 30   Initial release
--
-- Must be compiled with VITAL compliance checking off
-------------------------------------------------------------------------------
-- PART DESCRIPTION:
-- Library:     CONVERTERS_VHDL
-- Technology:  MIXED
-- Part:        ADC128S102
--
-- Description: 8-Channel Sampling 12-bit A/D Converter
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.VITAL_timing.all;
use IEEE.VITAL_primitives.all;
library work;
use work.gen_utils.all;

-------------------------------------------------------------------------------
-- ENTITY DECLARATION
-------------------------------------------------------------------------------
entity adc128s102 is

  generic (
    -- Interconnect path delays
    tipd_SCLK            : VitalDelayType01  := VitalZeroDelay01;
    tipd_CSNeg           : VitalDelayType01  := VitalZeroDelay01;
    tipd_DIN             : VitalDelayType01  := VitalZeroDelay01;
    -- Propagation delays
    tpd_SCLK_DOUT        : VitalDelayType01Z := UnitDelay01Z;
    tpd_CSNeg_DOUT       : VitalDelayType01Z := UnitDelay01Z;
    -- Setup/hold violation
    tsetup_CSNeg_SCLK    : VitalDelayType    := UnitDelay;
    tsetup_DIN_SCLK      : VitalDelayType    := UnitDelay;
    thold_CSNeg_SCLK     : VitalDelayType    := UnitDelay;
    thold_DIN_SCLK       : VitalDelayType    := UnitDelay;
    -- Puls width checks
    tpw_SCLK_posedge     : VitalDelayType    := UnitDelay;
    tpw_SCLK_negedge     : VitalDelayType    := UnitDelay;
    -- Period checks
    tperiod_SCLK_posedge : VitalDelayType    := UnitDelay;
    -- generic control parameters
    InstancePath         : string            := DefaultInstancePath;
    TimingChecksOn       : boolean           := DefaultTimingChecks;
    MsgOn                : boolean           := DefaultMsgOn;
    XOn                  : boolean           := DefaultXon;
    -- For FMF SDF technology file usage
    TimingModel          : string            := DefaultTimingModel
    );

  port (
    SCLK  : in  std_ulogic := 'U';
    CSNeg : in  std_ulogic := 'U';
    DIN   : in  std_ulogic := 'U';
    VA    : in  real       := 5.0;
    IN0   : in  real       := 0.0;
    IN1   : in  real       := 0.0;
    IN2   : in  real       := 0.0;
    IN3   : in  real       := 0.0;
    IN4   : in  real       := 0.0;
    IN5   : in  real       := 0.0;
    IN6   : in  real       := 0.0;
    IN7   : in  real       := 0.0;
    DOUT  : out std_ulogic := 'U'
    );

  attribute VITAL_LEVEL0 of adc128s102 : entity is true;
end entity adc128s102;

-------------------------------------------------------------------------------
-- ARCHITECTURE DECLARATION
-------------------------------------------------------------------------------
architecture vhdl_behavioral of adc128s102 is
  attribute VITAL_LEVEL0 of vhdl_behavioral : architecture is true;

  constant partID  : string     := "adc128s102";
  constant hiBit   : natural    := 12;
  signal SCLK_ipd  : std_ulogic := 'U';
  signal CSNeg_ipd : std_ulogic := 'U';
  signal DIN_ipd   : std_ulogic := 'U';

  signal pom_reg : std_logic_vector((hiBit-1) downto 0) :=
    (others => '0');
  signal ctrl_reg : std_logic_vector(7 downto 0) := (others => '0');

  signal in_channel : std_logic_vector(2 downto 0) := (others => '0');


begin  -- ARCHITECTURE vhdl_behavioral

  ---------------------------------------------------------------------------
  -- Wire delay block
  ---------------------------------------------------------------------------
  WireDelay : block is
  begin  -- BLOCK WireDelay
    w1 : VitalWireDelay(SCLK_ipd, SCLK, tipd_SCLK);
    w2 : VitalWireDelay(CSNeg_ipd, CSNeg, tipd_CSNeg);
    w3 : VitalWireDelay (DIN_ipd, DIN, tipd_DIN);
  end block WireDelay;

  ---------------------------------------------------------------------------
  -- Behavior Process
  ---------------------------------------------------------------------------
  func : process (SCLK_ipd, CSNeg_ipd, DIN_ipd)

    variable counter  : natural    := 0;    -- plain counter
    variable InSample : real       := 0.0;  -- Input selected for conv
    variable DZd      : std_ulogic := 'Z';  -- out data zero delayed

    variable SCLK_nwv  : X01;
    variable CSNeg_nwv : X01;
    variable DIN_nwv   : X01;

    -- Timing check variables
    variable Tviol_CSNeg_SCLK : X01 := '0';  -- setup/hold
                                             --violation flag
    variable TD_CSNeg_SCLK    : VitalTimingDataType;

    variable Tviol_DIN_SCLK : X01 := '0';
    variable TD_DIN_SCLK    : VitalTimingDataType;

    variable PD_SCLK      : VitalPeriodDataType := VitalPeriodDataInit;
    variable Pviol_SCLK   : X01                 := '0';  -- puls width
                                                         -- violation
    variable Violation    : X01                 := '0';
    -- Output Glitch Detection Variable
    variable D_GlitchData : VitalGlitchDataType;

    procedure convert (
      sampl : in real) is               -- in sample
      variable fullscale : real := VA;
      variable midpoint  : real := 0.0;
      variable tmpval    : real := 0.0;
    begin  -- PROCEDURE convert
      tmpval   := sampl;
      midpoint := fullscale/2.0;
      for b in (hiBit-1) downto 0 loop
        if tmpval > midpoint then
          pom_reg(b) <= '1';
          tmpval     := tmpval - midpoint;
        else
          pom_reg(b) <= '0';
        end if;
        tmpval := 2.0*tmpval;
      end loop;
    end procedure convert;

    -- purpose: checking voltage levels
    procedure checkVoltage is
    begin  -- PROCEDURE checkVoltage
      if VA < 2.7 or VA > 5.25 then
        assert false
          report "Reference voltage out of range"
          severity warning;
      end if;
      if IN0 > VA or IN0 < 0.0 or IN1 > VA or IN1 < 0.0
        or IN2 > VA or IN2 < 0.0 or IN3 > VA or IN3 < 0.0
        or IN4 > VA or IN4 < 0.0 or IN5 > VA or IN5 < 0.0
        or IN6 > VA or IN6 < 0.0 or IN7 > VA or IN7 < 0.0 then
        assert false
          report "Voltage range on the input pins is out of the range"
          & LF & "Result of the coversion is undeterminated"
          severity warning;
      end if;

    end procedure checkVoltage;

  begin  -- PROCESS func

    SCLK_nwv  := to_X01(SCLK_ipd);
    CSNeg_nwv := to_X01(CSNeg_ipd);
    DIN_nwv   := to_X01(DIN_ipd);

    -----------------------------------------------------------------------
    -- Timing Check Section
    -----------------------------------------------------------------------
    if TimingChecksOn then

      VitalSetupHoldCheck(
        TestSignal     => CSNeg_ipd,
        TestSignalName => "CSNeg",
        RefSignal      => SCLK_ipd,
        RefSignalName  => "SCLK",
        SetupLow       => tsetup_CSNeg_SCLK,
        HoldHigh       => tsetup_CSNeg_SCLK,
        CheckEnabled   => true,
        RefTransition  => '/',
        HeaderMsg      => InstancePath & partID,
        TimingData     => TD_CSNeg_SCLK,
        XOn            => XOn,
        MsgOn          => MsgOn,
        Violation      => Tviol_CSNeg_SCLK
        );

      VitalSetupHoldCheck (
        TestSignal     => DIN_ipd,
        TestSignalName => "DIN",
        RefSignal      => SCLK_ipd,
        RefSignalName  => "SCLK",
        SetupHigh      => tsetup_DIN_SCLK,
        SetupLow       => tsetup_DIN_SCLK,
        HoldHigh       => thold_DIN_SCLK,
        HoldLow        => thold_DIN_SCLK,
        CheckEnabled   => CSNeg = '0',
        RefTransition  => '/',
        HeaderMsg      => InstancePath & partID,
        TimingData     => TD_DIN_SCLK,
        XOn            => XOn,
        MsgOn          => MsgOn,
        Violation      => Tviol_DIN_SCLK
        );

      VitalPeriodPulseCheck(
        TestSignal     => SCLK_ipd,
        TestSignalName => "SCLK",
        Period         => tperiod_SCLK_posedge,
        PulseWidthHigh => tpw_SCLK_posedge,
        PulseWidthLow  => tpw_SCLK_negedge,
        HeaderMsg      => InstancePath & partID,
        CheckEnabled   => true,
        PeriodData     => PD_SCLK,
        XOn            => XOn,
        MsgOn          => MsgOn,
        Violation      => Pviol_SCLK
        );

      Violation := Tviol_CSNeg_SCLK or Tviol_DIN_SCLK or Pviol_SCLK;

    end if;

    -----------------------------------------------------------------------
    -- Funcional section
    -----------------------------------------------------------------------
    if falling_edge(CSNeg_ipd) then
      counter := 0;
      DZd     := '0';
      if SCLK_ipd = '0' then
        counter := 1;
      end if;
    end if;

    if falling_edge(SCLK_ipd) then
      if CSNeg_nwv = '0' then
        if counter < 16 then
          counter := counter + 1;
        else
          counter := 1;
        end if;
        if counter < 5 then
          case in_channel is
            when "000" =>
              InSample := IN0;
            when "001" =>
              InSample := IN1;
            when "010" =>
              InSample := IN2;
            when "011" =>
              InSample := IN3;
            when "100" =>
              InSample := IN4;
            when "101" =>
              InSample := IN5;
            when "110" =>
              InSample := IN6;
            when "111" =>
              InSample := IN7;
            when others => null;
          end case;
          DZd := '0';
          if counter = 4 then
            convert(InSample);
            checkVoltage;
          end if;
        else
          DZd := pom_reg(hiBit-counter+4);
        end if;
      end if;
    end if;

    if rising_edge(SCLK_ipd) then
      if counter > 0 and counter < 9 then
        ctrl_reg(8-counter) <= DIN_nwv;
      elsif counter = 10 then
        in_channel <= ctrl_reg(5 downto 3);
      end if;
    end if;

    if rising_edge(CSNeg_ipd) then
      DZd := 'Z';
    end if;

    -----------------------------------------------------------------------
    -- Path delay section
    -----------------------------------------------------------------------
    VitalPathDelay01Z(
      OutSignal          => DOUT,
      OutSignalName      => "DOUT",
      OutTemp            => DZd,
      GlitchData         => D_GlitchData,
      XOn                => XOn,
      MsgOn              => MsgOn,
      Paths              => (
        0 =>
        (InputChangeTime => SCLK_ipd'last_event,
         PathDelay       => tpd_SCLK_DOUT,
         PathCondition   => true),
        1 =>
        (InputChangeTime => CSNeg_ipd'last_event,
         PathDelay       => tpd_CSNeg_DOUT,
         PathCondition   => true)
        )
      );
  end process func;
end architecture vhdl_behavioral;
