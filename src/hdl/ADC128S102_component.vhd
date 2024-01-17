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

LIBRARY IEEE;   USE IEEE.std_logic_1164.ALL;
                USE IEEE.VITAL_timing.ALL;
                USE IEEE.VITAL_primitives.ALL;
LIBRARY work;    USE work.gen_utils.ALL;

-------------------------------------------------------------------------------
-- ENTITY DECLARATION
-------------------------------------------------------------------------------
ENTITY adc128s102 IS

    GENERIC (
        -- Interconnect path delays
        tipd_SCLK           : VitalDelayType01  := VitalZeroDelay01;
        tipd_CSNeg          : VitalDelayType01  := VitalZeroDelay01;
        tipd_DIN            : VitalDelayType01  := VitalZeroDelay01;
        -- Propagation delays
        tpd_SCLK_DOUT       : VitalDelayType01Z := UnitDelay01Z;
        tpd_CSNeg_DOUT      : VitalDelayType01Z := UnitDelay01Z;
        -- Setup/hold violation
        tsetup_CSNeg_SCLK   : VitalDelayType    := UnitDelay;
        tsetup_DIN_SCLK     : VitalDelayType    := UnitDelay;
        thold_CSNeg_SCLK    : VitalDelayType    := UnitDelay;
        thold_DIN_SCLK      : VitalDelayType    := UnitDelay;
        -- Puls width checks
        tpw_SCLK_posedge    : VitalDelayType    := UnitDelay;
        tpw_SCLK_negedge    : VitalDelayType    := UnitDelay;
        -- Period checks
        tperiod_SCLK_posedge: VitalDelayType    := UnitDelay;
        -- generic control parameters
        InstancePath        : STRING            := DefaultInstancePath;
        TimingChecksOn      : BOOLEAN           := DefaultTimingChecks;
        MsgOn               : BOOLEAN           := DefaultMsgOn;
        XOn                 : BOOLEAN           := DefaultXon;
        -- For FMF SDF technology file usage
        TimingModel         : STRING            := DefaultTimingModel
        );

    PORT (
        SCLK  : IN  std_ulogic := 'U';
        CSNeg : IN  std_ulogic := 'U';
        DIN   : IN  std_ulogic := 'U';
        VA    : IN  real       := 5.0;
        IN0   : IN  real       := 0.0;
        IN1   : IN  real       := 0.0;
        IN2   : IN  real       := 0.0;
        IN3   : IN  real       := 0.0;
        IN4   : IN  real       := 0.0;
        IN5   : IN  real       := 0.0;
        IN6   : IN  real       := 0.0;
        IN7   : IN  real       := 0.0;
        DOUT  : OUT std_ulogic := 'U'
        );

    ATTRIBUTE VITAL_LEVEL0 OF adc128s102 : ENTITY IS true;
END ENTITY adc128s102;

-------------------------------------------------------------------------------
-- ARCHITECTURE DECLARATION
-------------------------------------------------------------------------------
ARCHITECTURE vhdl_behavioral OF adc128s102 IS
    ATTRIBUTE VITAL_LEVEL0 OF vhdl_behavioral : ARCHITECTURE IS true;

    CONSTANT partID     : STRING                        := "adc128s102";
    CONSTANT hiBit      : natural                       := 12;
    SIGNAL   SCLK_ipd   : std_ulogic                    := 'U';
    SIGNAL   CSNeg_ipd  : std_ulogic                    := 'U';
    SIGNAL   DIN_ipd    : std_ulogic                    := 'U';

    SIGNAL   pom_reg    : std_logic_vector((hiBit-1) DOWNTO 0) :=
    (OTHERS => '0');
    SIGNAL   ctrl_reg   : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');

    SIGNAL   in_channel : std_logic_vector(2 DOWNTO 0) := (OTHERS => '0');


BEGIN  -- ARCHITECTURE vhdl_behavioral

    ---------------------------------------------------------------------------
    -- Wire delay block
    ---------------------------------------------------------------------------
    WireDelay : BLOCK IS
    BEGIN  -- BLOCK WireDelay
        w1    : VitalWireDelay(SCLK_ipd, SCLK,tipd_SCLK);
        w2    : VitalWireDelay(CSNeg_ipd, CSNeg,tipd_CSNeg);
        w3    : VitalWireDelay (DIN_ipd, DIN, tipd_DIN);
    END BLOCK WireDelay;

    ---------------------------------------------------------------------------
    -- Behavior Process
    ---------------------------------------------------------------------------
    func : PROCESS (SCLK_ipd, CSNeg_ipd, DIN_ipd)

        VARIABLE counter     : natural    := 0;      -- plain counter
        VARIABLE InSample    : real       := 0.0;    -- Input selected for conv
        VARIABLE DZd         : std_ulogic := 'Z';    -- out data zero delayed

        VARIABLE SCLK_nwv    : X01;
        VARIABLE CSNeg_nwv   : X01;
        VARIABLE DIN_nwv     : X01;

        -- Timing check variables
        VARIABLE Tviol_CSNeg_SCLK : X01                 := '0';  -- setup/hold
                                                                 --violation flag
        VARIABLE TD_CSNeg_SCLK    : VitalTimingDataType;

        VARIABLE Tviol_DIN_SCLK   : X01 := '0';
        VARIABLE TD_DIN_SCLK      : VitalTimingDataType;

        VARIABLE PD_SCLK          : VitalPeriodDataType := VitalPeriodDataInit;
        VARIABLE Pviol_SCLK       : X01                 := '0';  -- puls width
                                                                 -- violation
        VARIABLE Violation        : X01                 := '0';
        -- Output Glitch Detection Variable
        VARIABLE D_GlitchData     : VitalGlitchDataType;

        PROCEDURE convert (
            sampl              : IN real) IS  -- in sample
            VARIABLE fullscale :    real := VA;
            VARIABLE midpoint  :    real := 0.0;
            VARIABLE tmpval    :    real := 0.0;
        BEGIN  -- PROCEDURE convert
            tmpval   := sampl;
            midpoint := fullscale/2.0;
            FOR b IN (hiBit-1) DOWNTO 0 LOOP
                IF tmpval > midpoint THEN
                    pom_reg(b) <= '1';
                    tmpval := tmpval - midpoint;
                ELSE
                    pom_reg(b) <= '0';
                END IF;
                tmpval := 2.0*tmpval;
            END LOOP;
        END PROCEDURE convert;

        -- purpose: checking voltage levels
        PROCEDURE checkVoltage IS
        BEGIN  -- PROCEDURE checkVoltage
            IF VA < 2.7 OR VA > 5.25 THEN
                ASSERT false
                    REPORT "Reference voltage out of range"
                    SEVERITY WARNING;
            END IF;
            IF IN0 > VA OR IN0 < 0.0 OR IN1 > VA OR IN1 < 0.0
                OR IN2 > VA OR IN2 < 0.0 OR IN3 > VA OR IN3 < 0.0
                OR IN4 > VA OR IN4 < 0.0 OR IN5 > VA OR IN5 < 0.0
                OR IN6 > VA OR IN6 < 0.0 OR IN7 > VA OR IN7 < 0.0 THEN
                ASSERT false
                    REPORT "Voltage range on the input pins is out of the range"
                    & LF & "Result of the coversion is undeterminated"
                    SEVERITY WARNING;
            END IF;

        END PROCEDURE checkVoltage;

    BEGIN  -- PROCESS func

        SCLK_nwv    := to_X01(SCLK_ipd);
        CSNeg_nwv   := to_X01(CSNeg_ipd);
        DIN_nwv     := to_X01(DIN_ipd);

        -----------------------------------------------------------------------
        -- Timing Check Section
        -----------------------------------------------------------------------
        IF TimingChecksOn THEN

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

            Violation := Tviol_CSNeg_SCLK OR Tviol_DIN_SCLK OR Pviol_SCLK;

        END IF;

        -----------------------------------------------------------------------
        -- Funcional section
        -----------------------------------------------------------------------
        IF falling_edge(CSNeg_ipd) THEN
            counter := 0;
            DZd := '0';
            IF SCLK_ipd = '0' THEN
                counter := 1;
            END IF;
        END IF;

        IF falling_edge(SCLK_ipd) THEN
            IF CSNeg_nwv = '0' THEN
                IF counter < 16 THEN
                    counter := counter + 1;
                ELSE
                    counter := 1;
                END IF;
                IF counter < 5 THEN
                    CASE in_channel IS
                        WHEN "000" =>
                            InSample := IN0;
                        WHEN "001" =>
                            InSample := IN1;
                        WHEN "010" =>
                            InSample := IN2;
                        WHEN "011" =>
                            InSample := IN3;
                        WHEN "100" =>
                            InSample := IN4;
                        WHEN "101" =>
                            InSample := IN5;
                        WHEN "110" =>
                            InSample := IN6;
                        WHEN "111" =>
                            InSample := IN7;
                        WHEN OTHERS =>  null;
                    END CASE;
                    DZd := '0';
                    IF counter = 4 THEN
                        convert(InSample);
                        checkVoltage;
                    END IF;
                ELSE
                    DZd := pom_reg(hiBit-counter+4);
                END IF;
            END IF;
        END IF;

        IF rising_edge(SCLK_ipd) THEN
            IF counter > 0 AND counter < 9 THEN
                ctrl_reg(8-counter) <= DIN_nwv;
            ELSIF counter = 10 THEN
                in_channel <= ctrl_reg(5 downto 3);
            END IF;
        END IF;

        IF rising_edge(CSNeg_ipd) THEN
            DZd := 'Z';
        END IF;

        -----------------------------------------------------------------------
        -- Path delay section
        -----------------------------------------------------------------------
        VitalPathDelay01Z(
            OutSignal               => DOUT,
            OutSignalName           => "DOUT",
            OutTemp                 => DZd,
            GlitchData              => D_GlitchData,
            XOn                     => XOn,
            MsgOn                   => MsgOn,
            Paths                   => (
                0 =>
                (InputChangeTime => SCLK_ipd'LAST_EVENT,
                PathDelay     => tpd_SCLK_DOUT,
                PathCondition => true),
                1 =>
                (InputChangeTime => CSNeg_ipd'LAST_EVENT,
                PathDelay     => tpd_CSNeg_DOUT,
                PathCondition => true)
                )
            );
    END PROCESS func;
END ARCHITECTURE vhdl_behavioral;
