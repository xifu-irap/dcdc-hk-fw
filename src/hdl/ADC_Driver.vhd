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
    Reset_n   : in std_logic;
    clk_20MHz : in std_logic;

    -- Control

    Output_register : out register_ADC;  -- array de 8 std_logic_vector (max de channel qu'on peut acquérir)
    Start           : in  std_logic;
    Done            : out std_logic;  -- indique que le registre est à  jour (toutes les valeurs demandées sont updatées)

    -- ADC

    ADC_Sclk : out std_logic;
    ADC_Dout : in  std_logic;
    ADC_Din  : out std_logic;
    ADC_Cs_n : out std_logic

    );
end ADC128S102_Driver;

architecture A1 of ADC128S102_Driver is


--Déclaration des signaux internes

--ADC control register
  signal i_ADC_control_register : std_logic_vector(15 downto 0);
  alias i_channel_address       : std_logic_vector(2 downto 0) is i_ADC_control_register (13 downto 11);

--indices de tableaux
  signal i_channel_val    : unsigned(2 downto 0);
  signal i_output_reg_ind : unsigned(2 downto 0);
  signal i_din_ind        : unsigned(3 downto 0);

--Machine à  état
  type FSM_state is (waiting, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10);
  signal state : FSM_state;

--Generation Sclk
  signal i_Sclk : std_logic;

--Compteur
  signal i_count_Dout_Din : unsigned(3 downto 0);
  signal i_count_nb_acq   : unsigned(2 downto 0);

--Autres
  signal i_Dout      : std_logic_vector (15 downto 0);
  alias i_Dout_utile : std_logic_vector (11 downto 0) is i_Dout(11 downto 0);
  signal s5_flag     : std_logic;



begin

--Combinatoire
  i_channel_val    <= i_count_nb_acq +2;
  i_output_reg_ind <= i_count_nb_acq -1;
  i_din_ind        <= i_count_Dout_Din +1;

  ADC_Sclk <= i_Sclk;

--Machine à état ADC
  Change_state_process : process(clk_20MHz, Reset_n)
  begin
-- partie clockée
    if Reset_n = '0' then
      --init des états
      state <= waiting;
    elsif rising_edge(clk_20MHz) then
      case state is

        when waiting =>

          --On est dans le cas ou on reset tout
          --init des signaux internes
          i_Sclk                 <= '1';
          i_count_Dout_Din       <= to_unsigned(15, 4);  --(others =>'1');
          i_count_nb_acq         <= (others => '0');
          i_Dout                 <= (others => '0');
          i_ADC_control_register <= (others => '0');
          --init des sorties
          Done                   <= '0';
          ADC_Cs_n               <= '1';
          ADC_Din                <= '0';

          --Flag pour l'actualisation première valeur après un start
          s5_flag <= '0';

          --L'état suivant n'est atteint que si le start passe à  1
          if Start = '1' then
            state <= s1;
          else
            state <= waiting;
          end if;

        when s1 =>

          --On prepare le registre de control
          i_channel_address <= "001";
          state             <= s2;

        when s2 =>
          --On active l'ADC en on commence l'envoi du registre de control
          i_Sclk   <= '0';
          ADC_Cs_n <= '0';
          ADC_Din  <= i_ADC_control_register(15);

          state <= s3;

        when s3 =>
          --Changement état SClk
          i_Sclk <= '1';                --not i_Sclk; --(Sclk passe à 1)

          --On décrémente le compteur de Dout
          i_count_Dout_Din <= i_count_Dout_Din -1;

          state <= s4;

        when s4 =>

          --Changement état SClk
          i_Sclk <= '0';                --not i_Sclk; --(Sclk passe à 0)

          --on envoie le registre
          ADC_Din <= i_ADC_control_register(to_integer(i_count_Dout_Din));

          --on lit Dout
          i_Dout(to_integer(i_din_ind)) <= ADC_Dout;


          --On stocke dans le registre Dout qui est complet
          if (i_count_Dout_Din = to_unsigned(14, 4) and s5_flag = '1') then  --on a capturé un mot en entier donc on peut le mettre en registre
            Output_register(to_integer(i_output_reg_ind)) <= i_Dout_utile;
          end if;
          --On regarde si on doit recevoir d'autres dout
          if i_count_Dout_Din = 1 then
            state <= s5;
          else
            state <= s3;
          end if;

        when s5 =>
          --On est passé par s5 on met le flag à 1
          s5_flag <= '1';

          --Changement état SClk
          i_Sclk <= '1';                --not i_Sclk; --(Sclk passe à 1)

          --On décrémente le compteur de Dout
          i_count_Dout_Din <= i_count_Dout_Din -1;

          --On incrémente le compteur de channel
          i_count_nb_acq <= i_count_nb_acq +1;

          --On prepare le registre de control
          i_channel_address <= std_logic_vector(i_channel_val);

          state <= s6;

        when s6 =>

          --Changement état SClk
          i_Sclk <= '0';                --(Sclk passe à 0)

          --on envoie le registre
          ADC_Din <= i_ADC_control_register(to_integer(i_count_Dout_Din));

          --on lit Dout
          i_Dout(to_integer(i_din_ind)) <= ADC_Dout;

          --On regarde si on boucle
          if i_count_nb_acq = 0 then
            state <= s7;
          else
            state <= s3;
          end if;

        when s7 =>

          --Changement état SClk
          i_Sclk <= '1';                --(Sclk passe à 1)

          --On décrémente le compteur de Dout
          i_count_Dout_Din <= i_count_Dout_Din -1;

          state <= s8;

        when s8 =>
          --on lit Dout
          i_Dout(to_integer(i_din_ind)) <= ADC_Dout;

          state <= s9;

        when s9 =>
          --On a fini
          Done                                          <= '1';
          Output_register(to_integer(i_output_reg_ind)) <= i_Dout_utile;

          state <= s10;

        when s10 =>
          --On a fini
          Done <= '1';

          state <= waiting;

        when others =>
          state <= waiting;

      end case;

    end if;

  end process;




end A1;
