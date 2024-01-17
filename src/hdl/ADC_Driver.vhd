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
--    @file                   ADC_Driver.vhd
--    reference design        Yann PAROT (IRAP Toulouse)
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--      the controller for adc128S102
--       La datasheet indique que le premier echantillonage est IN0 et après on a les valeurs programmées
--       tant que CS est actif
--      Quand Start passe à 1, l'ADC échantillonne les 8 voies et stocke le resultat dans output register.
--      Output_register(0) <= IN0
--      Output_register(1) <= IN1
--      Output_register(2) <= IN2
--      Output_register(3) <= IN3
--      Output_register(4) <= IN4
--      Output_register(5) <= IN5
--      Output_register(6) <= IN6
--      Output_register(7) <= IN7
--
-- -------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ADC128S102_pkg.all;

entity ADC128S102_Driver is
  port (
    i_reset_n   : in std_logic;
    i_clk_20MHz : in std_logic;

    -- Control

    o_output_register : out register_ADC;  -- array de 8 std_logic_vector (max de channel qu'on peut acqu�rir)
    i_start           : in  std_logic;
    o_one             : out std_logic;  -- indique que le registre est à jour (toutes les valeurs demandées sont updat�es)

    -- ADC

    o_adc_sclk : out std_logic;
    i_adc_dout : in  std_logic;
    o_adc_din  : out std_logic;
    o_adc_cs_n : out std_logic

    );
end ADC128S102_Driver;

architecture A1 of ADC128S102_Driver is


--Déclaration des signaux internes

--ADC control register
  signal adc_control_r1    : std_logic_vector(15 downto 0);
  alias channel_address_r1 : std_logic_vector(2 downto 0) is adc_control_r1 (13 downto 11);

--indices de tableaux
  signal channel_val    : unsigned(2 downto 0);
  signal output_reg_ind : unsigned(2 downto 0);
  signal din_ind        : unsigned(3 downto 0);

--Machine à état
  type t_state is (E_WAITING, E_S1, E_S2, E_S3, E_S4, E_S5, E_S6, E_S7, E_S8, E_S9, E_S10);
  signal sm_state_r1 : t_state;

--Generation Sclk
  signal sclk_r1 : std_logic;

--Compteur
  signal count_dout_din_r1 : unsigned(3 downto 0);
  signal count_nb_acq_r1   : unsigned(2 downto 0);

--Autres
  signal dout_r1    : std_logic_vector(15 downto 0);
  alias dout_utile  : std_logic_vector(11 downto 0) is dout_r1(11 downto 0);
  signal s5_flag_r1 : std_logic;



begin

--Combinatoire
  channel_val    <= count_nb_acq_r1 +2;
  output_reg_ind <= count_nb_acq_r1 -1;
  din_ind        <= count_dout_din_r1 +1;

  o_adc_sclk <= sclk_r1;

--Machine à état ADC
  p_change_state : process(i_clk_20MHz, i_reset_n)
  begin
-- partie clockée
    if i_reset_n = '0' then
      --init des etats
      sm_state_r1 <= E_WAITING;
    elsif rising_edge(i_clk_20MHz) then
      case sm_state_r1 is

        when E_WAITING =>

          --On est dans le cas ou on reset tout
          --init des signaux internes
          sclk_r1           <= '1';
          count_dout_din_r1 <= to_unsigned(15, 4);  --(others =>'1');
          count_nb_acq_r1   <= (others => '0');
          dout_r1           <= (others => '0');
          adc_control_r1    <= (others => '0');
          --init des sorties
          o_one             <= '0';
          o_adc_cs_n        <= '1';
          o_adc_din         <= '0';

          --Flag pour l'actualisation première valeur après un start
          s5_flag_r1 <= '0';

          --L'état suivant n'est atteint que si le start passe à  1
          if i_start = '1' then
            sm_state_r1 <= E_S1;
          else
            sm_state_r1 <= E_WAITING;
          end if;

        when E_S1 =>

          --On prepare le registre de control
          channel_address_r1 <= "001";
          sm_state_r1        <= E_S2;

        when E_S2 =>
          --On active l'ADC en on commence l'envoi du registre de control
          sclk_r1    <= '0';
          o_adc_cs_n <= '0';
          o_adc_din  <= adc_control_r1(15);

          sm_state_r1 <= E_S3;

        when E_S3 =>
          --Changement etat SClk
          sclk_r1 <= '1';               --not i_Sclk; --(Sclk passe à 1)

          --On décrémente le compteur de Dout
          count_dout_din_r1 <= count_dout_din_r1 -1;

          sm_state_r1 <= E_S4;

        when E_S4 =>

          --Changement état SClk
          sclk_r1 <= '0';               --not i_Sclk; --(Sclk passe a 0)

          --on envoie le registre
          o_adc_din <= adc_control_r1(to_integer(count_dout_din_r1));

          --on lit Dout
          dout_r1(to_integer(din_ind)) <= i_adc_dout;


          --On stocke dans le registre Dout qui est complet
          if (count_dout_din_r1 = to_unsigned(14, 4) and s5_flag_r1 = '1') then  --on a capturé un mot en entier donc on peut le mettre en registre
            o_output_register(to_integer(output_reg_ind)) <= dout_utile;
          end if;
          --On regarde si on doit recevoir d'autres dout
          if count_dout_din_r1 = 1 then
            sm_state_r1 <= E_S5;
          else
            sm_state_r1 <= E_S3;
          end if;

        when E_S5 =>
          --On est passé par s5 on met le flag à 1
          s5_flag_r1 <= '1';

          --Changement état SClk
          sclk_r1 <= '1';               --not i_Sclk; --(Sclk passe a 1)

          --On décrémente le compteur de Dout
          count_dout_din_r1 <= count_dout_din_r1 -1;

          --On incrémente le compteur de channel
          count_nb_acq_r1 <= count_nb_acq_r1 +1;

          --On prepare le registre de control
          channel_address_r1 <= std_logic_vector(channel_val);

          sm_state_r1 <= E_S6;

        when E_S6 =>

          --Changement état SClk
          sclk_r1 <= '0';               --(Sclk passe a 0)

          --on envoie le registre
          o_adc_din <= adc_control_r1(to_integer(count_dout_din_r1));

          --on lit Dout
          dout_r1(to_integer(din_ind)) <= i_adc_dout;

          --On regarde si on boucle
          if count_nb_acq_r1 = 0 then
            sm_state_r1 <= E_S7;
          else
            sm_state_r1 <= E_S3;
          end if;

        when E_S7 =>

          --Changement état SClk
          sclk_r1 <= '1';               --(Sclk passe a 1)

          --On décrémente le compteur de Dout
          count_dout_din_r1 <= count_dout_din_r1 -1;

          sm_state_r1 <= E_S8;

        when E_S8 =>
          --on lit Dout
          dout_r1(to_integer(din_ind)) <= i_adc_dout;

          sm_state_r1 <= E_S9;

        when E_S9 =>
          --On a fini
          o_one                                         <= '1';
          o_output_register(to_integer(output_reg_ind)) <= dout_utile;

          sm_state_r1 <= E_S10;

        when E_S10 =>
          --On a fini
          o_one <= '1';

          sm_state_r1 <= E_WAITING;

        when others =>
          sm_state_r1 <= E_WAITING;

      end case;

    end if;

  end process;


end A1;

