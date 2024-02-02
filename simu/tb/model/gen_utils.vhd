--------------------------------------------------------------------------------
--  File name: gen_utils.vhd
--------------------------------------------------------------------------------
--  Copyright (C) 1996-2003 Free Model Foundry; http://www.FreeModelFoundry.com/
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License version 2 as
--  published by the Free Software Foundation.
--
--  MODIFICATION HISTORY:
--
--  version: |  author:  | mod date: | changes made:
--    V1.0     R. Steele   96 SEP 26   Initial release
--    V1.1     REV3        97 Feb 27   Added Xon and MsgOn generics
--    V1.2     R. Steele   97 APR 16   Changed wired-or to wired-and
--    V1.3     R. Steele   97 APR 16   Added diff. receiver table
--    V1.4     R. Munden   98 APR 13   Added GenParity and CheckParity
--    V1.5     R. Munden   01 NOV 24   Added UnitDelay01ZX
--    V1.6     R. Munden   03 FEB 07   Added To_UXLHZ
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_Logic_1164.all;
use IEEE.VITAL_primitives.all;
use IEEE.VITAL_timing.all;

package gen_utils is

  ----------------------------------------------------------------------------
  -- Result map for Wired-and output values (open collector)
  ----------------------------------------------------------------------------
  constant STD_wired_and_rmap : VitalResultMapType := ('U', 'X', '0', 'Z');

  ----------------------------------------------------------------------------
  -- Table for computing a single signal from a differential receiver input
  -- pair.
  ----------------------------------------------------------------------------
  constant diff_rec_tab : VitalStateTableType := (

    ------INPUTS--|-PREV-|-OUTPUT----
    --   A   ANeg | Aint |  Aint'  --
    --------------|------|-----------
    ('X', '-', '-', 'X'),               -- A unknown
    ('-', 'X', '-', 'X'),               -- A unknown
    ('1', '-', 'X', '1'),               -- Recover from 'X'
    ('0', '-', 'X', '0'),               -- Recover from 'X'
    ('/', '0', '0', '1'),               -- valid diff. rising edge
    ('1', '\', '0', '1'),               -- valid diff. rising edge
    ('\', '1', '1', '0'),               -- valid diff. falling edge
    ('0', '/', '1', '0'),               -- valid diff. falling edge
    ('-', '-', '-', 'S')                -- default
    );                     -- end of VitalStateTableType definition


  ----------------------------------------------------------------------------
  -- Default Constants
  ----------------------------------------------------------------------------
  constant UnitDelay     : VitalDelayType     := 1 ns;
  constant UnitDelay01   : VitalDelayType01   := (1 ns, 1 ns);
  constant UnitDelay01Z  : VitalDelayType01Z  := (others => 1 ns);
  constant UnitDelay01ZX : VitalDelayType01ZX := (others => 1 ns);

  constant DefaultInstancePath : string  := "*";
  constant DefaultTimingChecks : boolean := false;
  constant DefaultTimingModel  : string  := "UNIT";
  constant DefaultXon          : boolean := true;
  constant DefaultMsgOn        : boolean := true;

  -- Older VITAL generic being phased out
  constant DefaultXGeneration : boolean := true;

  -------------------------------------------------------------------
  -- Generate Parity for each 8-bit in 9th bit
  -------------------------------------------------------------------
  function GenParity
    (Data    : in std_logic_vector;     -- Data
     ODDEVEN : in std_logic;            -- ODD (1) / EVEN(0)
     SIZE    : in positive)             -- Bit Size
    return std_logic_vector;

  -------------------------------------------------------------------
  -- Check Parity for each 8-bit in 9th bit
  -------------------------------------------------------------------
  function CheckParity
    (Data    : in std_logic_vector;     -- Data
     ODDEVEN : in std_logic;            -- ODD (1) / EVEN(0)
     SIZE    : in positive)             -- Bit Size
    return std_logic;                   -- '0' - Parity Error

  -------------------------------------------------------------------
  -- strength strippers
  -------------------------------------------------------------------
  function To_UXLHZ (s : std_ulogic) return std_ulogic;

end gen_utils;

package body gen_utils is

  function XOR_REDUCE(ARG : std_logic_vector) return UX01 is
    -- pragma subpgm_id 403
    variable result : std_logic;
  begin
    result := '0';
    for i in ARG'range loop
      result := result xor ARG(i);
    end loop;
    return result;
  end;
  -------------------------------------------------------------------
  -- Generate Parity for each 8-bit in 9th bit
  -------------------------------------------------------------------
  function GenParity
    (Data    : in std_logic_vector;     -- Data
     ODDEVEN : in std_logic;            -- ODD (1) / EVEN(0)
     SIZE    : in positive)             -- Bit Size
    return std_logic_vector
  is
    variable I      : natural;
    variable Result : std_logic_vector (Data'length - 1 downto 0);
  begin
    I := 0;
    while (I < SIZE) loop
      Result(I+7 downto I) := Data(I+7 downto I);
      Result(I+8)          := XOR_REDUCE(Data(I+7 downto I)) xor ODDEVEN;
      I                    := I + 9;
    end loop;
    return Result;
  end GenParity;

  -------------------------------------------------------------------
  -- Check Parity for each 8-bit in 9th bit
  -------------------------------------------------------------------
  function CheckParity
    (Data    : in std_logic_vector;     -- Data
     ODDEVEN : in std_logic;            -- ODD (1) / EVEN(0)
     SIZE    : in positive)             -- Bit Size
    return std_logic                    -- '0' - Parity Error
  is
    variable I      : natural;
    variable Result : std_logic;
  begin
    I := 0; Result := '1';
    while (I < SIZE) loop
      Result := Result and
                not (XOR_REDUCE(Data(I+8 downto I)) xor ODDEVEN);
      I := I + 9;
    end loop;
    return Result;
  end CheckParity;

  -------------------------------------------------------------------
  -- conversion tables
  -------------------------------------------------------------------
  type logic_UXLHZ_table is array (std_ulogic'low to std_ulogic'high) of
    std_ulogic;
  ----------------------------------------------------------
  -- table name : cvt_to_UXLHZ
  --
  -- parameters :
  --        in  :  std_ulogic  -- some logic value
  -- returns    :  std_ulogic  -- weak state of logic value
  -- purpose    :  to convert strong-strength to weak-strength only
  --
  -- example    : if (cvt_to_UXLHZ (input_signal) = '1' ) then ...
  --
  ----------------------------------------------------------
  constant cvt_to_UXLHZ : logic_UXLHZ_table := (
    'U',                                -- 'U'
    'X',                                -- 'X'
    'L',                                -- '0'
    'H',                                -- '1'
    'Z',                                -- 'Z'
    'W',                                -- 'W'
    'L',                                -- 'L'
    'H',                                -- 'H'
    '-'                                 -- '-'
    );

  -------------------------------------------------------------------
  -- strength strippers
  -------------------------------------------------------------------
  function To_UXLHZ (s : std_ulogic) return std_ulogic is
  begin
    return (cvt_to_UXLHZ(s));
  end;

end gen_utils;
