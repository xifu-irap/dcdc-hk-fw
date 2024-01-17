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
    i_hi_in     : in    std_logic_vector(7 downto 0);
    o_hi_out    : out   std_logic_vector(1 downto 0);
    b_hi_inout  : inout std_logic_vector(15 downto 0);
    o_hi_muxsel : out   std_logic;
    o_i2c_sda   : out   std_logic;
    o_i2c_scl   : out   std_logic;

    --Visualisation LED Opal Kelly
    o_led : out std_logic_vector(7 downto 0);

    -- Clock principale OK
    i_clk : in std_logic;

    -- Clock pour ADC
    i_clk_adc : in std_logic;

    -- CWL
    i_cwl_disable : in  std_logic;      --état de la protection & commande
    o_cwl_enable  : out std_logic;
    o_cwl_mod     : out std_logic;
    o_cwl_heater  : out std_logic;

    -- AF PD
    o_af_pd_gain : out std_logic_vector(1 downto 0);

    -- Shutter
    o_shutter_enable : out std_logic;

    -- ADC128S102 HK
    o_adc_sclk : out std_logic;
    i_adc_dout : in  std_logic;
    o_adc_din  : out std_logic;
    o_adc_cs_n : out std_logic;

    --AD7809
    i_hk7809_busy_n : in  std_logic;
    i_hk7809_data   : in  std_logic;
    i_hk7809_sync   : in  std_logic;
    o_hk7809_clk    : out std_logic;
    o_hk7809_cs_n   : out std_logic;
    o_hk7809_pwrd   : out std_logic;
    o_hk7809_rcb    : out std_logic;
    o_hk7809_tag    : out std_logic;

    o_hk7809_sel_0 : out std_logic;
    o_hk7809_sel_1 : out std_logic;
    o_hk7809_sel_2 : out std_logic;

    --Limit switch
    i_af_sw : in std_logic_vector(1 downto 0);  --Butées fin de courses

    -- Stepper motor (driver L6258EX)
    o_L6258_i1        : out std_logic_vector(3 downto 0);  -- Courant phase 1
    o_L6258_i2        : out std_logic_vector(3 downto 0);  -- Courant phase 2
    o_L6258_ph1       : out std_logic;  -- Direction courant phase 1
    o_L6258_ph2       : out std_logic;  -- Direction courant phase 2
    o_L6258_dis       : out std_logic;  -- Désactivation du driver moteur L6258EX
    o_L6258_mod_boost : out std_logic;  --mode Boost

    --Microphone
    o_mic_gain       : out std_logic_vector (1 downto 0);
    o_p5V_mic_on_off : out std_logic;
    o_m5V_mic_on_off : out std_logic;

    --Signaux dupliqués pour compatibilité EGSE
    o_duplicate : out std_logic_vector(2 downto 0);  --Dans l'ordre I10,I11 et PH1

    --Force Motor phases to 0.6A
    i_sw_forced : in std_logic

    );
end OK_AF;

architecture arch of OK_AF is


  --Declaration des composants
  component DCM_20MHz
    port(
      i_clk_in       : in  std_logic;
      o_clk_in_ibufg : out std_logic;
      o_clkK0        : out std_logic;
      o_locked       : out std_logic
      );
  end component;

--Déclaration des signaux

  --DCM (Digital Clock Manager) de Xilinx
  signal reset_n   : std_logic;  --indique si horloge OK (DCM locké) et sert de reset
  signal clk_20MHz : std_logic;  -- Sortie du DCM (tiré de la clock principale Clk)

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
  signal motor_config  : std_logic_vector(15 downto 0);  -- WireIn ep10 Bypass limit switch en bit 12 + vitesse moteur en 1-0 + Boost en bit 2
  signal motor_on_off  : std_logic_vector(15 downto 0);  --WireIn ep13 ON/OFF en bit 0
  signal motor_abort   : std_logic_vector(15 downto 0);  --WireIn ep14 Abort en bit 0
  signal motor_steps   : std_logic_vector(31 downto 0);  --WireIn ep11 MSB ep 12 LSB
  signal ep16wire      : std_logic_vector(15 downto 0);  --WireIN gain proportionel et integral
  alias p_gain         : std_logic_vector(7 downto 0) is ep16wire(15 downto 8);
  alias I_gain         : std_logic_vector(7 downto 0) is ep16wire(7 downto 0);
  signal ep17wire      : std_logic_vector(15 downto 0);  --WireIN gain integral et setpoint
  alias d_Gain         : std_logic_vector(7 downto 0) is ep17wire(15 downto 8);
  alias cwl_setpoint   : std_logic_vector(7 downto 0) is ep17wire(7 downto 0);
  signal on_off_micro  : std_logic_vector(15 downto 0);  --WireIN on off mic en bit 0(ep18)
  signal on_off_heater : std_logic_vector(15 downto 0);  --WireIN on off heater en bit 0(ep19)


  --OK EP sortants
  signal ep20wire             : std_logic_vector(15 downto 0);  --HK ID + status
  alias motor_on_status       : std_logic is ep20wire(15);
  alias Mic_ON_status         : std_logic is ep20wire(14);
  alias heater_on_status      : std_logic is ep20wire(13);
  alias heater_reached_status : std_logic is ep20wire(12);
  alias shutter_on_status     : std_logic is ep20wire(11);
  alias cwl_on_status_r1      : std_logic is ep20wire(10);
  alias cwl_mod_status_r1     : std_logic is ep20wire(9);
  alias hk_id                 : std_logic_vector(2 downto 0) is ep20wire(2 downto 0);
  signal ep21wire             : std_logic_vector(15 downto 0);  --Valeur de HK "prise normale"
  signal ep23wire             : std_logic_vector(15 downto 0);  --Renvoi la version de ce FirmWare codé sur 16 bits
  signal ep33wire             : std_logic_vector(15 downto 0);  --Nombre de data dans la FIFO MIC
  signal ep34wire             : std_logic_vector(15 downto 0);  --Nombre de data dans la FIFO AF
  signal ep6Atrig             : std_logic_vector(15 downto 0);  --Trigger pour dire que les HKs sont prêtes à être envoyées au PC.
  signal motor_status_steps   : std_logic_vector(31 downto 0);  -- WireOut ep31(31 downto 16) et ep32(15 downto 0)
  signal motor_status         : std_logic_vector(15 downto 0);  --WireOut ep30 CF switch bit0, IF switch bit1, displacement done en bit 15
  ---Signaux HK (FIFO)
  signal PipeOut_AF           : std_logic_vector(15 downto 0);
  signal PipeOut_AF_Read      : std_logic;
  signal PipeOut_MIC          : std_logic_vector (15 downto 0);
  signal PipeOut_MIC_Read     : std_logic;


  --Signaux dédiés aux Limit switches
  signal bypass          : std_logic;
  signal stop_motor      : std_logic;
  signal close_limit     : std_logic;
  signal infinite_limit  : std_logic;
  signal limit_switch_ff : std_logic_vector(1 downto 0);  --anti meta-stabilité switch

  --Signaux moteur
  signal motor_start        : std_logic;
  signal motor_direction    : std_logic;
  signal motor_stop         : std_logic;  --vient de l'abort alors que StopMotor vient des limit switchs
  signal motor_speed_r1     : unsigned(7 downto 0);
  signal motor_step_nbr     : std_logic_vector(15 downto 0);
  signal displacement_done  : std_logic;
  signal effective_step_nbr : std_logic_vector(15 downto 0);
  signal L6258_i1           : std_logic_vector(3 downto 0);  --courant phase 1
  signal L6258_i2           : std_logic_vector(3 downto 0);  -- courant phase 2
  signal L6258_dis_r1       : std_logic_vector(1 downto 0);
  signal L6258_ph1          : std_logic;  --direction courant Phase 1
  signal L6258_ph2          : std_logic;  --direction courant Phase 2
  signal count_register_r1  : integer range 0 to 512;  --Compteur permettant de compter 20 us avant de decaler le registre disable (cf B.Quertier)

  --Signaux CWL driver
  signal mod_clock_r1     : std_logic;  --10kHz 50%duty cycle
  signal count_mod_cwl_r1 : integer range 0 to 1024;  --Compteur permettant de creer la modulation a 10kHz


  --signal switch_state: std_logic;

  --Signal AD7809
  signal addr_mux : std_logic_vector(2 downto 0);

  --signaux heaters




begin
  ---signaux Opal kelly i2c et mux
  o_i2c_sda   <= 'Z';
  o_i2c_scl   <= 'Z';
  o_hi_muxsel <= '0';
  ------------------------------------------------------------------------------------------------
  --
  --Affichage LED (1=OFF, 0=ON)
  --
  ------------------------------------------------------------------------------------------------
  o_led(0)    <= not bypass;            --visualisation du bypass switch
  --led(1) <= --not switch_state;--'1';
  o_led(2)    <= i_cwl_disable;   -- si disable à 0 => LED ON et sécu ON
  o_led(3)    <= not stop_motor;
  o_led(4)    <= not close_limit;
  o_led(5)    <= not infinite_limit;
  o_led(6)    <= not i_af_sw(0);        --CF
  o_led(7)    <= not i_af_sw(1);        --IF





------------------------------------------------------------------------------------------------
  --
  -- AF Gain
  --
  ------------------------------------------------------------------------------------------------
  o_af_pd_gain <= ep15wire(15 downto 14);

  ------------------------------------------------------------------------------------------------
  --
  -- Microphone Gain & ON/OFF
  --
  ------------------------------------------------------------------------------------------------
  o_mic_gain       <= ep15wire(13 downto 12);
  o_p5V_mic_on_off <= on_off_micro(0);
  o_m5V_mic_on_off <= on_off_micro(0);
  Mic_ON_status    <= on_off_micro(0);
  ------------------------------------------------------------------------------------------------
  --
  -- CWL
  --
  ------------------------------------------------------------------------------------------------

  o_cwl_heater <= '0';  --Le Heater est désactivé dans ce cas car le contrôle thermique n'est pas disponible.


  o_cwl_mod <= mod_clock_r1;

  p_cwl : process(clk_20MHz, reset_n)
  begin
    if reset_n = '0'
    then
      mod_clock_r1      <= '1';  --Modulation active à 0 (addition de courant quand signal logique à zero)
      o_cwl_enable      <= '0';
      count_mod_cwl_r1  <= 0;
      cwl_mod_status_r1 <= '0';
      cwl_on_status_r1  <= '0';

    elsif clk_20MHz'event and clk_20MHz = '1' then

      if ep05wire(2 downto 0) = "101"  -- La CWL est On et la modulation activée
      then
        o_cwl_enable      <= '1';
        cwl_on_status_r1  <= '1';
        cwl_mod_status_r1 <= '1';
        if count_mod_cwl_r1 < 999  --20MHz/1000 = 20000kHz => permet de créer le 10kHz 50% DC
        then
          count_mod_cwl_r1 <= count_mod_cwl_r1+1;
        else
          mod_clock_r1     <= not mod_clock_r1;
          count_mod_cwl_r1 <= 0;
        end if;

      elsif ep05wire(2 downto 0) = "010"  -- CWL est On sans modulation
      then
        o_cwl_enable      <= '1';
        mod_clock_r1      <= '1';
        cwl_mod_status_r1 <= '0';
        cwl_on_status_r1  <= '1';
      else                                -- On éteint la CWL et la modulation
        o_cwl_enable      <= '0';
        mod_clock_r1      <= '1';
        count_mod_cwl_r1  <= 0;
        cwl_mod_status_r1 <= '0';
        cwl_on_status_r1  <= '0';

      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------------------------
  --
  -- Limit switches
  --
  ------------------------------------------------------------------------------------------------
  bypass          <= motor_config(12);  --Configure le Bypass ou pas des limit switches
  motor_status(0) <= close_limit;       --Renvoit le statut du CF
  motor_status(1) <= infinite_limit;    --Renvoit le statut du IF

  inst_limit_switches : entity work.autofocus_limit_switch_controller
    port map(
      i_Clk               => clk_20MHz,
      i_Reset_n           => reset_n,
      i_MotorDirection    => motor_direction,
      i_LimitSwitchBypass => bypass,
      o_CloseLimit        => close_limit,
      o_InfiniteLimit     => infinite_limit,
      o_LimitSwitch       => limit_switch_ff,
      i_AfLimitSwitch     => i_af_sw,
      o_StopMotor         => stop_motor
      );
  ------------------------------------------------------------------------------------------------
  --
  -- Motor
  --
  ------------------------------------------------------------------------------------------------

  inst_motor_driver : entity work.autofocus_L6258
    port map(
      i_Clk     => clk_20MHz,
      i_Reset_n => reset_n,

      i_MotorStart       => motor_start,
      i_MotorDirection   => motor_direction,
      i_MotorStop        => motor_stop,
      i_MotorSpeed       => motor_speed_r1,
      i_MotorStepNbr     => motor_step_nbr,
      o_DisplacementDone => displacement_done,
      o_EffectiveStepNbr => effective_step_nbr,
      i_StopMotor        => stop_motor,

      o_L6258Ph1 => L6258_ph1,
      o_L6258Ph2 => L6258_ph2,
      o_L6258I1  => L6258_i1,
      o_L6258I2  => L6258_i2
      );

  ------------------------------------------------------------------------------------------------
  --
  -- Configuration driver moteur
  --
  ------------------------------------------------------------------------------------------------

  o_L6258_mod_boost  <= not motor_config(2);  --boost = 0 logique sur hardware et 1 logique software d'o� le not
  motor_start        <= ep40trig(0);  --Ordre de déplacement. Signal synchrone.
  motor_direction    <= motor_steps(31);      -- sens du déplacement
  motor_stop         <= motor_abort(0);  -- Stop directement le moteur en cas d'abort
  motor_step_nbr     <= motor_steps(15 downto 0);      --Nombre de pas à faire
  motor_status_steps <= x"0000" & effective_step_nbr;  --Nombre de pas fait
  motor_status(15)   <= not displacement_done;         -- déplacement fait



  p_motor_speed : process(reset_n, clk_20MHz)
  begin
    if reset_n = '0'
    then
      motor_speed_r1 <= X"10";          -- 150 pas/s
    else
      if clk_20MHz = '1'and clk_20MHz'event
      then
        if motor_config(1 downto 0) = "00"
        then
          motor_speed_r1 <= X"F4";      -- 10 pas/s
        elsif motor_config(1 downto 0) = "01"
        then
          motor_speed_r1 <= X"31";      -- 50 pas/s
        elsif motor_config(1 downto 0) = "10"
        then
          motor_speed_r1 <= X"18";      -- 100 pas/s
        else
          motor_speed_r1 <= X"10";      -- 150 pas/s
        end if;

      end if;

    end if;
  end process;

  motor_on_status <= motor_on_off(0);   -- signal status motor renvoyé

  p_disable_motor : process(reset_n, clk_20MHz)
  begin
    if reset_n = '0' then
         o_L6258_i1  <= (others => '1');  --"1111" = 0 courant
         o_L6258_i2  <= (others => '1');  --"1111" = 0 courant
         o_L6258_ph1 <= '1';            --'1' = sens + (arbitraire)
         o_L6258_ph2 <= '1';            --'1' = sens + (arbitraire)
         o_L6258_dis <= '1';  -- Driver moteur désactivé par défaut
         --signaux moteurs dupliqués
         o_duplicate <= "111";

    else
      if rising_edge(clk_20MHz) then
        o_L6258_dis <= L6258_dis_r1(0);

        if L6258_dis_r1(1) = '1' then  --Si le driver est désactivé, on met tous les signaux en mode reset (0 courant et sens positif)
          o_L6258_i1  <= (others => '1');
          o_L6258_i2  <= (others => '1');
          o_L6258_ph1 <= '1';
          o_L6258_ph2 <= '1';
          --signaux moteurs dupliqués
          o_duplicate <= "111";
        else  --Sinon on reprend les valeurs normales (celle de la table et donc du dernier déplacement)

          if (not i_sw_forced) = '0' then
            o_L6258_i1     <= L6258_i1;
            o_L6258_i2     <= L6258_i2;
            o_L6258_ph1    <= L6258_ph1;
            o_L6258_ph2    <= L6258_ph2;
            --signaux moteurs dupliqués
            o_duplicate(2) <= L6258_i1(0);
            o_duplicate(1) <= L6258_i1(1);
            o_duplicate(0) <= L6258_ph1;
          else
            o_L6258_i1     <= (others => '0');
            o_L6258_i2     <= (others => '0');
            o_L6258_ph1    <= L6258_ph1;
            o_L6258_ph2    <= L6258_ph2;
            --signaux moteurs dupliqués
            o_duplicate(2) <= '0';
            o_duplicate(1) <= '0';
            o_duplicate(0) <= L6258_ph1;
          end if;

        end if;
      end if;
    end if;
  end process;

  p_disable_affectation : process(reset_n, clk_20MHz)  --Process permettant de décaler le On/Off pour permettre au driver L6258EX de démarrer proprement avec 0 courant dans ses phases
  begin
    if reset_n = '0' then
      L6258_dis_r1      <= "11";
      count_register_r1 <= 0;
    else
      if clk_20MHz = '1'and clk_20MHz'event
      then
        if count_register_r1 > 398 then
          L6258_dis_r1(0)   <= not motor_on_off(0);
          L6258_dis_r1(1)   <= L6258_dis_r1(0);
          count_register_r1 <= 0;
        else
          count_register_r1 <= count_register_r1 + 1;
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

  o_shutter_enable  <= ep04wire(0);
  shutter_on_status <= ep04wire(0);



  ------------------------------------------------------------------------------------------------
  --
  -- Housekeepings
  --
  ------------------------------------------------------------------------------------------------
  o_hk7809_sel_0 <= addr_mux(0);
  o_hk7809_sel_1 <= addr_mux(1);
  o_hk7809_sel_2 <= addr_mux(2);

  hk_id <= ep15wire(2 downto 0);        --ID de la HK à sortir


  inst_module_gestion_hk : entity work.HK_Module
    port map(
      -- Clk et Rst à 0
      i_clk_20MHz => clk_20MHz,
      i_reset_n   => reset_n,

      --Clock Host Interface Front Panel
      i_host_clk => ti_clk,

      -- ADC
      i_clk_adc   => i_clk_adc,
      o_adc_sclk  => o_adc_sclk,
      i_adc_dout  => i_adc_dout,
      o_adc_din   => o_adc_din,
      o_adc_css_n => o_adc_cs_n,

      --AD7809
      o_addr_mux => addr_mux,
      o_data_clk => o_hk7809_clk,
      i_sync     => i_hk7809_sync,
      i_data     => i_hk7809_data,
      o_tag      => o_hk7809_tag,
      o_r_c_n    => o_hk7809_rcb,
      o_cs_n     => o_hk7809_cs_n,
      i_busy_n   => i_hk7809_busy_n,
      o_pwrd     => o_hk7809_pwrd,

      --Host Interface
      i_hk_addr => ep15wire(2 downto 0),  --Adresse de la HK à prendre
      i_hk_trig => ep40trig(4 downto 1),  --Trigger venant du PC pour dire ce que l'on veut faire
      o_hk_trig => ep6Atrig(3 downto 0),  --Annonce au PC de ce qui est dispo

      -- Pipe sortie AF
      o_pipe_out_af        => PipeOut_AF,
      i_pipe_out_af_read   => PipeOut_AF_Read,
      o_pipe_af_data_count => ep34wire,

      -- Pipe sortie MIC
      o_pipe_out_mic        => PipeOut_MIC,
      i_pipe_out_mic_read   => PipeOut_MIC_Read,
      o_pipe_mic_data_count => ep33wire,
      --Sortie HK normale
      --DEBUG
      o_tick_hk_dbg         => o_led(1),
      --END DEBUG
      o_hk_value            => ep21wire

      );



  ------------------------------------------------------------------------------------------------
  --
  -- DCM
  --
  ------------------------------------------------------------------------------------------------
  inst_dcm : DCM_20MHz
    port map(
      i_clk_in       => i_clk,
      o_clk_in_ibufg => open,
      o_clkK0        => clk_20MHz,
      o_locked       => reset_n
      );




  ------------------------------------------------------------------------------------------------
  --
  --  OpalKelly endpoints
  --
  ------------------------------------------------------------------------------------------------
  inst_ok_hi : okHost
    port map (
      hi_in    => i_hi_in,
      hi_out   => o_hi_out,
      hi_inout => b_hi_inout,
      ti_clk   => ti_clk,
      ok1      => ok1,
      ok2      => ok2
      );

  inst_ok_wo : okWireOR
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

  inst_ep05 : okWireIn
    port map (
      ok1        => ok1,                -- CWL
      ep_addr    => x"05",
      ep_dataout => ep05wire
      );

  --------------------------------------------------------------------------------------
  -- Shutter
  --------------------------------------------------------------------------------------

  inst_ep04 : okWireIn
    port map (
      ok1        => ok1,                -- Shutter
      ep_addr    => x"04",
      ep_dataout => ep04wire
      );

  --------------------------------------------------------------------------------------
  -- Motor
  --------------------------------------------------------------------------------------

  inst_trig_in40 : okTriggerIn
    port map (
      ok1        => ok1,
      ep_addr    => x"40",
      ep_clk     => clk_20MHz,
      ep_trigger => ep40trig);          --Trigger demande de HK

  inst_ep10 : okWireIn
    port map (
      ok1        => ok1,                -- Motor Config
      ep_addr    => x"10",
      ep_dataout => motor_config
      );

  inst_ep11 : okWireIn
    port map (
      ok1        => ok1,                -- Steps MSB
      ep_addr    => x"11",
      ep_dataout => motor_steps(31 downto 16)
      );

  inst_ep12 : okWireIn
    port map (
      ok1        => ok1,                -- Steps LSB
      ep_addr    => x"12",
      ep_dataout => motor_steps(15 downto 0)
      );

  inst_ep13 : okWireIn
    port map (
      ok1        => ok1,                -- Motor On / Off
      ep_addr    => x"13",
      ep_dataout => motor_on_off
      );

  inst_ep14 : okWireIn
    port map (
      ok1        => ok1,                -- Motor Abort
      ep_addr    => x"14",
      ep_dataout => motor_abort
      );

  inst_ep30 : okWireOut
    port map(
      ok1       => ok1,                 -- Motor Status
      ok2       => ok2s(1*17-1 downto 0*17),
      ep_addr   => x"30",
      ep_datain => motor_status
      );

  inst_ep31 : okWireOut
    port map(
      ok1       => ok1,                 -- Steps status MSB
      ok2       => ok2s(2*17-1 downto 1*17),
      ep_addr   => x"31",
      ep_datain => motor_status_steps(31 downto 16)
      );

  inst_ep32 : okWireOut
    port map(
      ok1       => ok1,                 -- Steps status LSB
      ok2       => ok2s(3*17-1 downto 2*17),
      ep_addr   => x"32",
      ep_datain => motor_status_steps(15 downto 0)
      );


  --------------------------------------------------------------------------------------
  -- HKs
  --------------------------------------------------------------------------------------


  inst_ep15 : okWireIn
    port map(
      ok1        => ok1,                -- HK ID
      ep_addr    => x"15",
      ep_dataout => ep15wire
      );

  inst_ep20 : okWireOut
    port map(
      ok1       => ok1,                       -- HK value (demande normale)
      ok2       => ok2s(4*17-1 downto 3*17),  --reprendre num pour OR
      ep_addr   => x"20",
      ep_datain => ep20wire
      );


  inst_ep33 : okWireOut
    port map(
      ok1       => ok1,                       -- FIFO Data Count MIC
      ok2       => ok2s(5*17-1 downto 4*17),  --reprendre num pour OR
      ep_addr   => x"33",
      ep_datain => ep33wire
      );


  inst_ep34 : okWireOut
    port map(
      ok1       => ok1,                 -- FIFO Data Count AF
      ok2       => ok2s(6*17-1 downto 5*17),
      ep_addr   => x"34",
      ep_datain => ep34wire
      );


  inst_epA0 : okPipeOut
    port map(
      ok1       => ok1,                 --Pipeout HK
      ok2       => ok2s(7*17-1 downto 6*17),
      ep_addr   => x"A0",
      ep_read   => PipeOut_AF_Read,
      ep_datain => PipeOut_AF
      );

  inst_A1 : okPipeOut
    port map(
      ok1       => ok1,                       --Pipeout HK
      ok2       => ok2s(8*17-1 downto 7*17),  --reprendre num pour OR
      ep_addr   => x"A1",
      ep_read   => PipeOut_MIC_Read,
      ep_datain => PipeOut_MIC
      );

  inst_ep21 : okWireOut
    port map(
      ok1       => ok1,                 -- HK value (demande normale)
      ok2       => ok2s(11*17-1 downto 10*17),
      ep_addr   => x"21",
      ep_datain => ep21wire
      );

  --------------------------------------------------------------------------------------
  -- Others
  --------------------------------------------------------------------------------------

  inst_trig_out_6A : okTriggerOut
    port map (
      ok1        => ok1, ok2 => ok2s(9*17-1 downto 8*17),  -- On trig 0x01 pour dire qu'il y a du monde dans le pipeout 0xA0
      ep_addr    => x"6a",
      ep_clk     => clk_20MHz,
      ep_trigger => ep6Atrig
      );

  inst_ep23 : okWireOut
    port map(
      ok1       => ok1,                 -- Version
      ok2       => ok2s(10*17-1 downto 9*17),
      ep_addr   => x"23",
      ep_datain => ep23wire
      );


  --------------------------------------------------------------------------------------
  -- Heater CWL
  --------------------------------------------------------------------------------------
  inst_ep16 : okWireIn
    port map(
      ok1        => ok1,                -- P & I gain
      ep_addr    => x"16",
      ep_dataout => ep16wire
      );

  inst_ep17 : okWireIn
    port map(
      ok1        => ok1,                -- D gain and setpoint
      ep_addr    => x"17",
      ep_dataout => ep17wire
      );

  inst_ep19 : okWireIn
    port map(
      ok1        => ok1,                -- ON/OFF
      ep_addr    => x"19",
      ep_dataout => on_off_heater
      );


  --------------------------------------------------------------------------------------
  -- On/OFF micro
  --------------------------------------------------------------------------------------
  inst_ep18 : okWireIn
    port map(
      ok1        => ok1,                -- ON/OFF
      ep_addr    => x"18",
      ep_dataout => on_off_micro
      );

end arch;
