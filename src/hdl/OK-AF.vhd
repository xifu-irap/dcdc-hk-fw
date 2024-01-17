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
--    @file                   OK-AF.vhd
--    reference design        Yann PAROT (IRAP Toulouse)
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--    Architecture Top de l'Opal Kelly AF (AutoFocus) FM.
--
-- -------------------------------------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

use work.FRONTPANEL.all;
use work.ADC128S102_pkg.all;

entity OK_AF is
  port (
    --Opal Kelly Host Interface
    hi_in     : in    std_logic_vector(7 downto 0);
    hi_out    : out   std_logic_vector(1 downto 0);
    hi_inout  : inout std_logic_vector(15 downto 0);
    hi_muxsel : out   std_logic;
    i2c_sda   : out   std_logic;
    i2c_scl   : out   std_logic;

    --Visualisation LED Opal Kelly
    led : out std_logic_vector(7 downto 0);

    -- Clock principale OK
    Clk : in std_logic;

    -- Clock pour ADC
    Clk_ADC : in std_logic;

    -- CWL
    i_CWL_Disable : in  std_logic;      --�tat de la protection & commande
    CWL_Enable    : out std_logic;
    CWL_Mod       : out std_logic;
    CWL_Heater    : out std_logic;

    -- AF PD
    AF_PD_Gain : out std_logic_vector(1 downto 0);

    -- Shutter
    SHUTTER_Enable : out std_logic;

    -- ADC128S102 HK
    o_ADC_Sclk : out std_logic;
    i_ADC_Dout : in  std_logic;
    o_ADC_Din  : out std_logic;
    o_ADC_Cs_n : out std_logic;

    --AD7809
    i_Hk7809Busy_n : in  std_logic;
    i_Hk7809Data   : in  std_logic;
    i_Hk7809Sync   : in  std_logic;
    o_Hk7809Clk    : out std_logic;
    o_Hk7809CS_n   : out std_logic;
    o_Hk7809Pwrd   : out std_logic;
    o_Hk7809RCb    : out std_logic;
    o_Hk7809Tag    : out std_logic;

    o_Hk7809Sel_0 : out std_logic;
    o_Hk7809Sel_1 : out std_logic;
    o_Hk7809Sel_2 : out std_logic;

    --Limit switch
    AF_SW : in std_logic_vector(1 downto 0);  --Butées fin de courses

    -- Stepper motor (driver L6258EX)
    o_L6258_I1      : out std_logic_vector(3 downto 0);  -- Courant phase 1
    o_L6258_I2      : out std_logic_vector(3 downto 0);  -- Courant phase 2
    o_L6258_PH1     : out std_logic;    -- Direction courant phase 1
    o_L6258_PH2     : out std_logic;    -- Direction courant phase 2
    o_L6258_Dis     : out std_logic;  -- Désactivation du driver moteur L6258EX
    o_L6258ModBoost : out std_logic;    --mode Boost

    --Microphone
    MIC_Gain      : out std_logic_vector (1 downto 0);
    o_p5VMicOnOff : out std_logic;
    o_m5VMicOnOff : out std_logic;

    --Signaux dupliqu�s pour compatibilit� EGSE
    o_duplicate : out std_logic_vector(2 downto 0);  --Dans l'ordre I10,I11 et PH1

    --Force Motor phases to 0.6A
    i_SW_forced : in std_logic

    );
end OK_AF;

architecture arch of OK_AF is


  --Declaration des composants
  component DCM_20MHz
    port(
      CLKIN_IN        : in  std_logic;
      CLKIN_IBUFG_OUT : out std_logic;
      CLK0_OUT        : out std_logic;
      LOCKED_OUT      : out std_logic
      );
  end component;

--Déclaration des signaux

  --DCM (Digital Clock Manager) de Xilinx
  signal Reset_n   : std_logic;  --indique si horloge OK (DCM locké) et sert de reset
  signal Clk_20MHz : std_logic;  -- Sortie du DCM (tiré de la clock principale Clk)

  ---- OK ----
  signal ti_clk : std_logic;  --Clock du Bus Host (USB) sert aussi à la lecture des FIFOs

  signal ok1  : std_logic_vector(30 downto 0);       -- Bus entrant
  signal ok2  : std_logic_vector(16 downto 0);       -- Bus sortant
  signal ok2s : std_logic_vector(17*11-1 downto 0);  -- Bus sortant avant OR. Permet de mapper tous les EndPoint de l'Opal Kelly (11 bus en 1)

  --OK EP entrants
  signal ep04wire      : std_logic_vector(15 downto 0);  -- On/Off Shutter en bit 0
  signal ep05wire      : std_logic_vector(15 downto 0);  -- On/Off CWL (enable/modulation et Heater) Heater en bit 6, Enable et modulation sur les 3 derniers bits: off=000/enable=010/enable+modulation=101
  signal ep15wire      : std_logic_vector(15 downto 0);  -- Gain Autofocus bits 15 et 14 et HK ID en bits 2 à 0. 13 et 14 pour gain microphone
  signal ep40trig      : std_logic_vector(15 downto 0);  -- Trigger de demande de HK et déplacement moteur
  signal Motor_Config  : std_logic_vector(15 downto 0);  -- WireIn ep10 Bypass limit switch en bit 12 + vitesse moteur en 1-0 + Boost en bit 2
  signal Motor_OnOff   : std_logic_vector(15 downto 0);  --WireIn ep13 ON/OFF en bit 0
  signal Motor_Abort   : std_logic_vector(15 downto 0);  --WireIn ep14 Abort en bit 0
  signal Motor_Steps   : std_logic_vector(31 downto 0);  --WireIn ep11 MSB ep 12 LSB
  signal ep16wire      : std_logic_vector(15 downto 0);  --WireIN gain proportionel et integral
  alias P_Gain         : std_logic_vector(7 downto 0) is ep16wire(15 downto 8);
  alias I_Gain         : std_logic_vector(7 downto 0) is ep16wire(7 downto 0);
  signal ep17wire      : std_logic_vector(15 downto 0);  --WireIN gain integral et setpoint
  alias D_Gain         : std_logic_vector(7 downto 0) is ep17wire(15 downto 8);
  alias CWL_setpoint   : std_logic_vector(7 downto 0) is ep17wire(7 downto 0);
  signal On_Off_Micro  : std_logic_vector(15 downto 0);  --WireIN on off mic en bit 0(ep18)
  signal On_Off_Heater : std_logic_vector(15 downto 0);  --WireIN on off heater en bit 0(ep19)


  --OK EP sortants
  signal ep20wire             : std_logic_vector(15 downto 0);  --HK ID + status
  alias Motor_ON_status       : std_logic is ep20wire(15);
  alias Mic_ON_status         : std_logic is ep20wire(14);
  alias Heater_ON_status      : std_logic is ep20wire(13);
  alias Heater_reached_status : std_logic is ep20wire(12);
  alias Shutter_ON_status     : std_logic is ep20wire(11);
  alias CWL_ON_status         : std_logic is ep20wire(10);
  alias CWL_Mod_status        : std_logic is ep20wire(9);
  alias HK_ID                 : std_logic_vector(2 downto 0) is ep20wire(2 downto 0);
  signal ep21wire             : std_logic_vector(15 downto 0);  --Valeur de HK "prise normale"
  signal ep23wire             : std_logic_vector(15 downto 0);  --Renvoi la version de ce FirmWare codé sur 16 bits
  signal ep33wire             : std_logic_vector(15 downto 0);  --Nombre de data dans la FIFO MIC
  signal ep34wire             : std_logic_vector(15 downto 0);  --Nombre de data dans la FIFO AF
  signal ep6Atrig             : std_logic_vector(15 downto 0);  --Trigger pour dire que les HKs sont prêtes à être envoyées au PC.
  signal Motor_Status_Steps   : std_logic_vector(31 downto 0);  -- WireOut ep31(31 downto 16) et ep32(15 downto 0)
  signal Motor_Status         : std_logic_vector(15 downto 0);  --WireOut ep30 CF switch bit0, IF switch bit1, displacement done en bit 15
  ---Signaux HK (FIFO)
  signal PipeOut_AF           : std_logic_vector(15 downto 0);
  signal PipeOut_AF_Read      : std_logic;
  signal PipeOut_MIC          : std_logic_vector (15 downto 0);
  signal PipeOut_MIC_Read     : std_logic;


  --Signaux dédiés aux Limit switches
  signal Bypass          : std_logic;
  signal StopMotor       : std_logic;
  signal o_CloseLimit    : std_logic;
  signal o_InfiniteLimit : std_logic;
  signal Limit_switch_ff : std_logic_vector(1 downto 0);  --anti meta-stabilité switch

  --Signaux moteur
  signal MotorStart       : std_logic;
  signal MotorDirection   : std_logic;
  signal MotorStop        : std_logic;  --vient de l'abort alors que StopMotor vient des limit switchs
  signal MotorSpeed       : unsigned(7 downto 0);
  signal MotorStepNbr     : std_logic_vector(15 downto 0);
  signal DisplacementDone : std_logic;
  signal EffectiveStepNbr : std_logic_vector(15 downto 0);
  signal L6258_I1         : std_logic_vector(3 downto 0);  --courant phase 1
  signal L6258_I2         : std_logic_vector(3 downto 0);  -- courant phase 2
  signal L6258Dis         : std_logic_vector(1 downto 0);
  signal L6258_PH1        : std_logic;  --direction courant Phase 1
  signal L6258_PH2        : std_logic;  --direction courant Phase 2
  signal count_register   : integer range 0 to 512;  --Compteur permettant de compter 20�s avant de d�caler le registre disable (cf B.Quertier)

  --Signaux CWL driver
  signal mod_clock     : std_logic;     --10kHz 50%duty cycle
  signal count_Mod_CWL : integer range 0 to 1024;  --Compteur permettant de créer la modulation à 10kHz


  --signal switch_state: std_logic;

  --Signal AD7809
  signal int_ADDR_MUX : std_logic_vector(2 downto 0);

  --signaux heaters




begin
  ---signaux Opal kelly i2c et mux
  i2c_sda   <= 'Z';
  i2c_scl   <= 'Z';
  hi_muxsel <= '0';
  ------------------------------------------------------------------------------------------------
  --
  --Affichage LED (1=OFF, 0=ON)
  --
  ------------------------------------------------------------------------------------------------
  led(0)    <= not Bypass;              --visualisation du bypass switch
  --led(1) <= --not switch_state;--'1';
  led(2)    <= i_CWL_Disable;           --si disable � 0 => LED ON et s�cu ON
  led(3)    <= not StopMotor;
  led(4)    <= not o_CloseLimit;
  led(5)    <= not o_InfiniteLimit;
  led(6)    <= not AF_SW(0);            --CF
  led(7)    <= not AF_SW(1);            --IF





------------------------------------------------------------------------------------------------
  --
  -- AF Gain
  --
  ------------------------------------------------------------------------------------------------
  AF_PD_Gain <= ep15wire(15 downto 14);

  ------------------------------------------------------------------------------------------------
  --
  -- Microphone Gain & ON/OFF
  --
  ------------------------------------------------------------------------------------------------
  MIC_Gain      <= ep15wire(13 downto 12);
  o_p5VMicOnOff <= On_Off_Micro(0);
  o_m5VMicOnOff <= On_Off_Micro(0);
  Mic_ON_status <= On_Off_Micro(0);
  ------------------------------------------------------------------------------------------------
  --
  -- CWL
  --
  ------------------------------------------------------------------------------------------------

  CWL_Heater <= '0';  --Le Heater est désactivé dans ce cas car le contrôle thermique n'est pas disponible.


  CWL_Mod <= mod_clock;
  CWL_Process : process(Clk_20MHz, Reset_n)
  begin
    if Reset_n = '0'
    then
      mod_clock      <= '1';  --Modulation active à 0 (addition de courant quand signal logique à zero)
      CWL_Enable     <= '0';
      count_Mod_CWL  <= 0;
      CWL_Mod_status <= '0';
      CWL_ON_status  <= '0';

    elsif Clk_20MHz'event and Clk_20MHz = '1' then

      if ep05wire(2 downto 0) = "101"  -- La CWL est On et la modulation activée
      then
        CWL_Enable     <= '1';
        CWL_ON_status  <= '1';
        CWL_Mod_status <= '1';
        if count_Mod_CWL < 999  --20MHz/1000 = 20000kHz => permet de créer le 10kHz 50% DC
        then
          count_Mod_CWL <= count_Mod_CWL+1;
        else
          mod_clock     <= not mod_clock;
          count_Mod_CWL <= 0;
        end if;

      elsif ep05wire(2 downto 0) = "010"  -- CWL est On sans modulation
      then
        CWL_Enable     <= '1';
        mod_clock      <= '1';
        CWL_Mod_status <= '0';
        CWL_ON_status  <= '1';
      else                                -- On éteint la CWL et la modulation
        CWL_Enable     <= '0';
        mod_clock      <= '1';
        count_Mod_CWL  <= 0;
        CWL_Mod_status <= '0';
        CWL_ON_status  <= '0';

      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------------------------
  --
  -- Limit switches
  --
  ------------------------------------------------------------------------------------------------
  Bypass          <= Motor_Config(12);  --Configure le Bypass ou pas des limit switches
  Motor_Status(0) <= o_CloseLimit;      --Renvoit le statut du CF
  Motor_Status(1) <= o_InfiniteLimit;   --Renvoit le statut du IF
  Limit_Switches : entity work.autofocus_limit_switch_controller
    port map(
      i_Clk               => Clk_20MHz,
      i_Reset_n           => Reset_n,
      i_MotorDirection    => MotorDirection,
      i_LimitSwitchBypass => Bypass,
      o_CloseLimit        => o_CloseLimit,
      o_InfiniteLimit     => o_InfiniteLimit,
      o_LimitSwitch       => Limit_switch_ff,
      i_AfLimitSwitch     => AF_SW,
      o_StopMotor         => StopMotor
      );
  ------------------------------------------------------------------------------------------------
  --
  -- Motor
  --
  ------------------------------------------------------------------------------------------------

  Motor_Driver : entity work.autofocus_L6258
    port map(
      i_Clk     => Clk_20MHz,
      i_Reset_n => Reset_n,

      i_MotorStart       => MotorStart,
      i_MotorDirection   => MotorDirection,
      i_MotorStop        => MotorStop,
      i_MotorSpeed       => MotorSpeed,
      i_MotorStepNbr     => MotorStepNbr,
      o_DisplacementDone => DisplacementDone,
      o_EffectiveStepNbr => EffectiveStepNbr,
      i_StopMotor        => StopMotor,

      o_L6258Ph1 => L6258_PH1,
      o_L6258Ph2 => L6258_PH2,
      o_L6258I1  => L6258_I1,
      o_L6258I2  => L6258_I2
      );

  ------------------------------------------------------------------------------------------------
  --
  -- Configuration driver moteur
  --
  ------------------------------------------------------------------------------------------------

  o_L6258ModBoost    <= not Motor_Config(2);  --boost = 0 logique sur hardware et 1 logique software d'o� le not
  MotorStart         <= ep40trig(0);  --Ordre de déplacement. Signal synchrone.
  MotorDirection     <= Motor_Steps(31);      -- sens du déplacement
  MotorStop          <= Motor_Abort(0);  -- Stop directement le moteur en cas d'abort
  MotorStepNbr       <= Motor_Steps(15 downto 0);    --Nombre de pas à faire
  Motor_Status_Steps <= x"0000" & EffectiveStepNbr;  --Nombre de pas fait
  Motor_Status(15)   <= not DisplacementDone;        -- déplacement fait



  Motor_speed_process : process(Reset_n, Clk_20MHz)
  begin
    if Reset_n = '0'
    then
      MotorSpeed <= X"10";              -- 150 pas/s
    else
      if Clk_20MHz = '1'and Clk_20MHz'event
      then
        if Motor_Config(1 downto 0) = "00"
        then
          MotorSpeed <= X"F4";          -- 10 pas/s
        elsif Motor_Config(1 downto 0) = "01"
        then
          MotorSpeed <= X"31";          -- 50 pas/s
        elsif Motor_Config(1 downto 0) = "10"
        then
          MotorSpeed <= X"18";          -- 100 pas/s
        else
          MotorSpeed <= X"10";          -- 150 pas/s
        end if;

      end if;

    end if;
  end process;

  Motor_ON_status <= Motor_OnOff(0);    -- signal status motor renvoy�

  Disable_Motor : process(Reset_n, Clk_20MHz)
  begin
    if Reset_n = '0'
    then o_L6258_I1 <= (others => '1');   --"1111" = 0 courant
         o_L6258_I2  <= (others => '1');  --"1111" = 0 courant
         o_L6258_PH1 <= '1';            --'1' = sens + (arbitraire)
         o_L6258_PH2 <= '1';            --'1' = sens + (arbitraire)
         o_L6258_Dis <= '1';  -- Driver moteur désactivé par défaut
         --signaux moteurs dupliqu�s
         o_duplicate <= "111";

    else
      if Clk_20MHz = '1'and Clk_20MHz'event
      then
        o_L6258_Dis <= L6258Dis(0);

        if L6258Dis(1) = '1'  --Si le driver est désactivé, on met tous les signaux en mode reset (0 courant et sens positif)
        then
          o_L6258_I1  <= (others => '1');
          o_L6258_I2  <= (others => '1');
          o_L6258_PH1 <= '1';
          o_L6258_PH2 <= '1';
          --signaux moteurs dupliqu�s
          o_duplicate <= "111";
        else  --Sinon on reprend les valeurs normales (celle de la table et donc du dernier déplacement)
          if (not i_SW_forced) = '0'
          then
            o_L6258_I1     <= L6258_I1;
            o_L6258_I2     <= L6258_I2;
            o_L6258_PH1    <= L6258_PH1;
            o_L6258_PH2    <= L6258_PH2;
            --signaux moteurs dupliqu�s
            o_duplicate(2) <= L6258_I1(0);
            o_duplicate(1) <= L6258_I1(1);
            o_duplicate(0) <= L6258_PH1;
          else
            o_L6258_I1     <= (others => '0');
            o_L6258_I2     <= (others => '0');
            o_L6258_PH1    <= L6258_PH1;
            o_L6258_PH2    <= L6258_PH2;
            --signaux moteurs dupliqu�s
            o_duplicate(2) <= '0';
            o_duplicate(1) <= '0';
            o_duplicate(0) <= L6258_PH1;
          end if;

        end if;
      end if;
    end if;
  end process;

  Disable_affectation : process(Reset_n, Clk_20MHz)  --Process permettant de décaler le On/Off pour permettre au driver L6258EX de démarrer proprement avec 0 courant dans ses phases
  begin
    if Reset_n = '0'
    then L6258Dis <= "11";
         count_register <= 0;
    else
      if Clk_20MHz = '1'and Clk_20MHz'event
      then
        if count_register > 398 then
          L6258Dis(0)    <= not Motor_OnOff(0);
          L6258Dis(1)    <= L6258Dis(0);
          count_register <= 0;
        else
          count_register <= count_register + 1;
        end if;
      end if;
    end if;
  end process;


  ------------------------------------------------------------------------------------------------
  --
  -- Version
  --
  ------------------------------------------------------------------------------------------------

  ep23wire <= X"AFF2";                  --AF Flight 2

  ------------------------------------------------------------------------------------------------
  --
  -- Shutter
  --
  ------------------------------------------------------------------------------------------------

  SHUTTER_Enable    <= ep04wire(0);
  Shutter_ON_status <= ep04wire(0);



  ------------------------------------------------------------------------------------------------
  --
  -- Housekeepings
  --
  ------------------------------------------------------------------------------------------------
  o_Hk7809Sel_0 <= int_ADDR_MUX(0);
  o_Hk7809Sel_1 <= int_ADDR_MUX(1);
  o_Hk7809Sel_2 <= int_ADDR_MUX(2);

  HK_ID <= ep15wire(2 downto 0);        --ID de la HK � sortir


  Module_gestion_HK : entity work.HK_Module
    port map(
      -- Clk et Rst � 0
      Clk_20MHz => Clk_20MHz,
      Reset_n   => Reset_n,

      --Clock Host Interface Front Panel
      HostClk => ti_clk,

      -- ADC
      Clk_ADC  => Clk_ADC,
      ADC_Sclk => o_ADC_Sclk,
      ADC_Dout => i_ADC_Dout,
      ADC_Din  => o_ADC_Din,
      ADC_Cs_n => o_ADC_Cs_n,

      --AD7809
      ADDR_MUX => int_ADDR_MUX,
      DATACLK  => o_Hk7809Clk,
      SYNC     => i_Hk7809Sync,
      DATA     => i_Hk7809Data,
      TAG      => o_Hk7809Tag,
      R_C_n    => o_Hk7809RCb,
      CS_n     => o_Hk7809CS_n,
      BUSY_n   => i_Hk7809Busy_n,
      PWRD     => o_Hk7809Pwrd,

      --Host Interface
      HK_Addr     => ep15wire(2 downto 0),  --Adresse de la HK � prendre
      HK_Trig_in  => ep40trig(4 downto 1),  --Trigger venant du PC pour dire ce que l'on veut faire
      HK_Trig_out => ep6Atrig(3 downto 0),  --Annonce au PC de ce qui est dispo

      -- Pipe sortie AF
      PipeOut_AF      => PipeOut_AF,
      PipeOut_AF_Read => PipeOut_AF_Read,
      PipeAFDataCount => ep34wire,

      -- Pipe sortie MIC
      PipeOut_MIC      => PipeOut_MIC,
      PipeOut_MIC_Read => PipeOut_MIC_Read,
      PipeMICDataCount => ep33wire,
      --Sortie HK normale
      --DEBUG
      tick_HK_DBG      => led(1),
      --END DEBUG
      HK_Value         => ep21wire

      );



  ------------------------------------------------------------------------------------------------
  --
  -- DCM
  --
  ------------------------------------------------------------------------------------------------
  DCM : DCM_20MHz
    port map(
      CLKIN_IN        => Clk,
      CLKIN_IBUFG_OUT => open,
      CLK0_OUT        => Clk_20MHz,
      LOCKED_OUT      => Reset_n
      );




  ------------------------------------------------------------------------------------------------
  --
  --  OpalKelly endpoints
  --
  ------------------------------------------------------------------------------------------------
  okHI : okHost
    port map (
      hi_in    => hi_in,
      hi_out   => hi_out,
      hi_inout => hi_inout,
      ti_clk   => ti_clk,
      ok1      => ok1,
      ok2      => ok2
      );

  okWO : okWireOR
    generic map (
      N => 11
      )
    port map (
      ok2  => ok2,
      ok2s => ok2s
      );

  --------------------------------------------------------------------------------------
  -- CWL
  --------------------------------------------------------------------------------------

  ep05 : okWireIn
    port map (
      ok1        => ok1,                -- CWL
      ep_addr    => x"05",
      ep_dataout => ep05wire
      );

  --------------------------------------------------------------------------------------
  -- Shutter
  --------------------------------------------------------------------------------------

  ep04 : okWireIn
    port map (
      ok1        => ok1,                -- Shutter
      ep_addr    => x"04",
      ep_dataout => ep04wire
      );

  --------------------------------------------------------------------------------------
  -- Motor
  --------------------------------------------------------------------------------------

  trigIn40 : okTriggerIn
    port map (
      ok1        => ok1,
      ep_addr    => x"40",
      ep_clk     => Clk_20MHz,
      ep_trigger => ep40trig);          --Trigger demande de HK

  ep10 : okWireIn
    port map (
      ok1        => ok1,                -- Motor Config
      ep_addr    => x"10",
      ep_dataout => Motor_Config
      );

  ep11 : okWireIn
    port map (
      ok1        => ok1,                -- Steps MSB
      ep_addr    => x"11",
      ep_dataout => Motor_Steps(31 downto 16)
      );

  ep12 : okWireIn
    port map (
      ok1        => ok1,                -- Steps LSB
      ep_addr    => x"12",
      ep_dataout => Motor_Steps(15 downto 0)
      );

  ep13 : okWireIn
    port map (
      ok1        => ok1,                -- Motor On / Off
      ep_addr    => x"13",
      ep_dataout => Motor_OnOff
      );

  ep14 : okWireIn
    port map (
      ok1        => ok1,                -- Motor Abort
      ep_addr    => x"14",
      ep_dataout => Motor_Abort
      );

  ep30 : okWireOut
    port map(
      ok1       => ok1,                 -- Motor Status
      ok2       => ok2s(1*17-1 downto 0*17),
      ep_addr   => x"30",
      ep_datain => Motor_Status
      );

  ep31 : okWireOut
    port map(
      ok1       => ok1,                 -- Steps status MSB
      ok2       => ok2s(2*17-1 downto 1*17),
      ep_addr   => x"31",
      ep_datain => Motor_Status_Steps(31 downto 16)
      );

  ep32 : okWireOut
    port map(
      ok1       => ok1,                 -- Steps status LSB
      ok2       => ok2s(3*17-1 downto 2*17),
      ep_addr   => x"32",
      ep_datain => Motor_Status_Steps(15 downto 0)
      );


  --------------------------------------------------------------------------------------
  -- HKs
  --------------------------------------------------------------------------------------


  ep15 : okWireIn
    port map(
      ok1        => ok1,                -- HK ID
      ep_addr    => x"15",
      ep_dataout => ep15wire
      );

  ep20 : okWireOut
    port map(
      ok1       => ok1,                       -- HK value (demande normale)
      ok2       => ok2s(4*17-1 downto 3*17),  --reprendre num pour OR
      ep_addr   => x"20",
      ep_datain => ep20wire
      );


  ep33 : okWireOut
    port map(
      ok1       => ok1,                       -- FIFO Data Count MIC
      ok2       => ok2s(5*17-1 downto 4*17),  --reprendre num pour OR
      ep_addr   => x"33",
      ep_datain => ep33wire
      );


  ep34 : okWireOut
    port map(
      ok1       => ok1,                 -- FIFO Data Count AF
      ok2       => ok2s(6*17-1 downto 5*17),
      ep_addr   => x"34",
      ep_datain => ep34wire
      );


  epA0 : okPipeOut
    port map(
      ok1       => ok1,                 --Pipeout HK
      ok2       => ok2s(7*17-1 downto 6*17),
      ep_addr   => x"A0",
      ep_read   => PipeOut_AF_Read,
      ep_datain => PipeOut_AF
      );

  epA1 : okPipeOut
    port map(
      ok1       => ok1,                       --Pipeout HK
      ok2       => ok2s(8*17-1 downto 7*17),  --reprendre num pour OR
      ep_addr   => x"A1",
      ep_read   => PipeOut_MIC_Read,
      ep_datain => PipeOut_MIC
      );

  ep21 : okWireOut
    port map(
      ok1       => ok1,                 -- HK value (demande normale)
      ok2       => ok2s(11*17-1 downto 10*17),
      ep_addr   => x"21",
      ep_datain => ep21wire
      );

  --------------------------------------------------------------------------------------
  -- Others
  --------------------------------------------------------------------------------------

  trigOut6A : okTriggerOut
    port map (
      ok1        => ok1, ok2 => ok2s(9*17-1 downto 8*17),  -- On trig 0x01 pour dire qu'il y a du monde dans le pipeout 0xA0
      ep_addr    => x"6a",
      ep_clk     => Clk_20MHz,
      ep_trigger => ep6Atrig
      );

  ep23 : okWireOut
    port map(
      ok1       => ok1,                 -- Version
      ok2       => ok2s(10*17-1 downto 9*17),
      ep_addr   => x"23",
      ep_datain => ep23wire
      );


  --------------------------------------------------------------------------------------
  -- Heater CWL
  --------------------------------------------------------------------------------------
  ep16 : okWireIn
    port map(
      ok1        => ok1,                -- P & I gain
      ep_addr    => x"16",
      ep_dataout => ep16wire
      );

  ep17 : okWireIn
    port map(
      ok1        => ok1,                -- D gain and setpoint
      ep_addr    => x"17",
      ep_dataout => ep17wire
      );

  ep19 : okWireIn
    port map(
      ok1        => ok1,                -- ON/OFF
      ep_addr    => x"19",
      ep_dataout => On_Off_Heater
      );


  --------------------------------------------------------------------------------------
  -- On/OFF micro
  --------------------------------------------------------------------------------------
  ep18 : okWireIn
    port map(
      ok1        => ok1,                -- ON/OFF
      ep_addr    => x"18",
      ep_dataout => On_Off_Micro
      );

end arch;
