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
--    @file                   HK_Module.vhd
--    reference design        Yann PAROT (IRAP Toulouse)
-- -------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- -------------------------------------------------------------------------------------------------------------
--!   @details
--
--    Gestion des HK de l'EGSE AutoFocus (AF)
--
-- -------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.ADC128S102_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;


entity HK_Module is
  port (
    -- Clk et Rst à 0
    i_clk_20MHz : in std_logic;
    i_reset_n   : in std_logic;

    --Clock Host Interface Front Panel
    i_host_clk : in std_logic;

    -- ADC128S022
    i_clk_adc   : in  std_logic;
    o_adc_sclk  : out std_logic;
    i_adc_dout  : in  std_logic;
    o_adc_din   : out std_logic;
    o_adc_css_n : out std_logic;

    --AD7809
    o_addr_mux : out std_logic_vector(2 downto 0);
    o_data_clk : out std_logic;
    i_sync     : in  std_logic;
    i_data     : in  std_logic;
    o_tag      : out std_logic;
    o_r_c_n    : out std_logic;
    o_cs_n     : out std_logic;
    i_busy_n   : in  std_logic;
    o_pwrd     : out std_logic;

    --Host Interface
    i_hk_addr             : in  std_logic_vector(2 downto 0);  --Adresse de la HK � prendre
    i_hk_trig             : in  std_logic_vector(3 downto 0);  --Trigger venant du PC pour dire ce que l'on veut faire
    o_hk_trig             : out std_logic_vector(3 downto 0);  --Annonce au PC de ce qui est dispo
    -- Pipe sortie AF
    o_pipe_out_af         : out std_logic_vector(15 downto 0);
    i_pipe_out_af_read    : in  std_logic;
    o_pipe_af_data_count  : out std_logic_vector(15 downto 0);
    -- Pipe sortie MIC
    o_pipe_out_mic        : out std_logic_vector (15 downto 0);
    i_pipe_out_mic_read   : in  std_logic;
    o_pipe_mic_data_count : out std_logic_vector(15 downto 0);
    --Sortie HK normale
    --DEBUG
    o_tick_hk_dbg         : out std_logic;
    --END DEBUG
    o_hk_value            : out std_logic_vector(15 downto 0)

    );
end HK_Module;

architecture Arch of HK_Module is

--Alias pour les triggers
  alias hk_request_in : std_logic is i_hk_trig(0);
  alias mic_start_in  : std_logic is i_hk_trig(1);
  alias mic_stop_in   : std_logic is i_hk_trig(2);
  alias af_request_in : std_logic is i_hk_trig(3);

  alias hk_ready_out  : std_logic is o_hk_trig(0);
  alias mic_start_out : std_logic is o_hk_trig(1);
  alias mic_stop_out  : std_logic is o_hk_trig(2);
  alias af_valid_out  : std_logic is o_hk_trig(3);

--Alias pour taille data sur pipeout et HK (ADC 12 bits et transfert sur 16)
  alias pipe_out_af_12bit  : std_logic_vector(11 downto 0) is o_pipe_out_af(11 downto 0);
  alias pipe_out_mic_12bit : std_logic_vector(11 downto 0) is o_pipe_out_mic(11 downto 0);
  alias hk_value_12bit_r1  : std_logic_vector(11 downto 0) is o_hk_value(11 downto 0);
  alias hk_value_high_r1   : std_logic_vector(3 downto 0) is o_hk_value(15 downto 12);

--les datacount sont de 9 et 14 bits
  alias pipe_af_data_count_9   : std_logic_vector(8 downto 0) is o_pipe_af_data_count(8 downto 0);
  alias pipe_mic_data_count_14 : std_logic_vector(13 downto 0) is o_pipe_mic_data_count(13 downto 0);

--Gestion ADC128S102
  signal adc_value    : std_logic_vector(11 downto 0);
  signal adc_start_r1 : std_logic;
  signal adc_done     : std_logic;



--Gestion AD7809
  signal data_updated : std_logic;
  signal data_AD7809  : register_ADC16;

--Alias FIFO
  alias din_fifo_af    : std_logic_vector(11 downto 0) is adc_value;
  alias din_fifo_micro : std_logic_vector(11 downto 0) is adc_value;

--Signaux FIFO
  signal write_af_r1 : std_logic;
  signal full_af     : std_logic;
  signal empty_af    : std_logic;
  signal rst         : std_logic;

  signal write_micro_r1 : std_logic;
  signal full_micro     : std_logic;
  signal empty_micro    : std_logic;


--Compteur pour les AF
  signal af_count_r1 : integer range 0 to 363;

--Declaration Machine � �tat prise HK
  type t_state is (E_INIT, E_WAITING, E_MIC1, E_MIC2, E_MIC20, E_MIC3, E_AF1, E_AF2, E_AF20, E_AF3, E_HK1, E_HK2);
  signal sm_state_r1 : t_state;


begin

--Bit des pipeout ne servant pas : restent à 0:
  o_pipe_out_af (15 downto 12)  <= (others => '0');
  o_pipe_out_mic (15 downto 12) <= (others => '0');

--Bits des datacount FIFO ne servant pas:
  o_pipe_af_data_count(15 downto 9)   <= (others => '0');
  o_pipe_mic_data_count(15 downto 14) <= (others => '0');


--Rest FIFO
  rst <= not i_reset_n;

--Port Map ADC rapide
  inst_ADC128S022 : entity work.ADC128Sxxx
    port map (
      Reset_n => i_reset_n,
      clk     => i_clk_adc,

      Output_value    => adc_value,
      Start           => adc_start_r1,
      Done            => adc_done,
      channel_address => i_hk_addr,
      ADC_Sclk        => o_adc_sclk,
      ADC_Dout        => i_adc_dout,
      ADC_Din         => o_adc_din,
      ADC_Cs_n        => o_adc_css_n
      );

--Port Map ADC lent
  inst_AD7809 : entity work.Slow_HK_Acq
    port map (
      -- Clk et Rst à 0
      Clk_20MHz => i_clk_20MHz,
      reset_n   => i_reset_n,

      --Gestion MUX
      ADDR => o_addr_mux,

      --Gestion ADC
      DATACLK     => o_data_clk,
      SYNC        => i_sync,
      AD7809_DATA => i_data,
      TAG         => o_tag,
      R_C_n       => o_r_c_n,
      CS_n        => o_cs_n,
      BUSY_n      => i_busy_n,
      PWRD        => o_pwrd,

      --Data ouput
      --DEBUG
      tick_HK_DBG  => o_tick_hk_dbg,
      --END DEBUG
      Data_Updated => data_updated,
      Data_out     => data_AD7809

      );


--Port Map FIFO
  inst_fifo_autofocus : entity work.FIFO_AF
    port map(
      rst           => rst,
      wr_clk        => i_clk_20MHz,
      rd_clk        => i_host_clk,
      din           => din_fifo_af,
      wr_en         => write_af_r1,
      rd_en         => i_pipe_out_af_read,
      dout          => pipe_out_af_12bit,
      full          => full_af,
      empty         => empty_af,
      rd_data_count => pipe_af_data_count_9
      );

  inst_fifo_microphone : entity work.FIFO_MICRO
    port map(
      rst           => rst,
      wr_clk        => i_clk_20MHz,
      rd_clk        => i_host_clk,
      din           => din_fifo_micro,
      wr_en         => write_micro_r1,
      rd_en         => i_pipe_out_mic_read,
      dout          => pipe_out_mic_12bit,
      full          => full_micro,
      empty         => empty_micro,
      rd_data_count => pipe_mic_data_count_14
      );

--Process gérant le refresh de l'ADC à 100kHz
--ADC_sampling:process(Reset_n, Clk_20MHz)
--  begin
--  if Reset_n = '0'
--  then
--      ADC_Start <= '0'; --Pas d'acquisition
--      tempo_HK <= 0;
--      ADC_Done_Latched <= '1';
--  else
--      if Clk_20MHz='1'and Clk_20MHz'event
--      then
--          if ADC_Done = '1'
--          then
--              ADC_Done_Latched <= '1'; --les HKs ont étés updatés, on peut latcher pour autoriser de nouvelles prises de HK
--          end if;
--          if tempo_HK<200 --creation tick à 10µs (HK la plus rapide à prendre à 100kHz)
--          then
--              ADC_Start <= '0'; --Pas d'acquisition
--              tempo_HK <= tempo_HK + 1;
--          else
--              if ADC_Done_Latched = '1'
--              then
--                  ADC_Start <= '1'; --acquisition
--                  tempo_HK <= 0;
--                  ADC_Done_Latched <= '0';
--              end if;
--          end if;
--      end if;
--  end if;
--end process;


--Machine à état gérant les HKs
--Machine à état ADC
  Change_state_process : process(clk_20MHz, Reset_n)
  begin
-- partie clockée
    if i_reset_n = '0' then
      --init des états
      sm_state_r1 <= E_INIT;
    elsif rising_edge(i_clk_20MHz) then
      case sm_state_r1 is
        when E_INIT =>
          -- Initialisation des signaux en attente d'un trig.
          hk_ready_out      <= '0';
          mic_start_out     <= '0';
          mic_stop_out      <= '0';
          af_valid_out      <= '0';
          write_af_r1       <= '0';
          write_micro_r1    <= '0';
          hk_value_12bit_r1 <= (others => '0');
          hk_value_high_r1  <= (others => '0');
          af_count_r1       <= 0;
          sm_state_r1       <= E_WAITING;
          adc_start_r1      <= '0';

        when E_WAITING =>
          adc_start_r1 <= '0';
          --Gestion des cas de trig
          if hk_request_in = '1' then
            sm_state_r1 <= E_HK1;
          elsif mic_start_in = '1' then
            sm_state_r1 <= E_MIC1;
          elsif af_request_in = '1' then
            sm_state_r1 <= E_AF1;
            af_count_r1 <= 0;
          end if;

        when E_MIC1 =>                  --On a une demande de prise de son.
          -- Demarrage ADC
          adc_start_r1 <= '1';
          --Verification de l'extinction du micro
          if mic_stop_in = '1' then
            --indiquation que l'on s'arrete
            mic_stop_out <= '1';
            -- On passe a l'etat suivant
            sm_state_r1  <= E_MIC3;
          end if;
          if adc_done = '1' then        --ADC done permet de timer à 100kHz
            --Ecriture dans FIFO
            write_micro_r1 <= '1';
            --On signale que l'on a démarré une acquisition
            mic_start_out  <= '1';
            -- On passe à l'état suivant
            sm_state_r1    <= E_MIC20;
          end if;

        when E_MIC20 =>
          --Fin écriture
          write_micro_r1 <= '0';
          if adc_done = '0' then
            sm_state_r1 <= E_MIC2;
          end if;

        when E_MIC2 =>                  --Doit-on continuer l'acquisition?
          --Fin écriture
          write_micro_r1 <= '0';
          --Fin de Flag
          mic_start_out  <= '0';
          --Vérification de l'extinction du micro
          if mic_stop_in = '1' then
            --indiquation que l'on s'arrête
            mic_stop_out <= '1';
            -- On passe à l'état suivant
            sm_state_r1  <= E_MIC3;
          else
            -- On passe à l'état suivant
            sm_state_r1 <= E_MIC1;
          end if;
        when E_MIC3 =>                  -- le micro a été arrêté
          mic_stop_out <= '0';
          adc_start_r1 <= '0';
          sm_state_r1  <= E_WAITING;

        when E_AF1 =>                   --accumulation de 363 data
          --Démarrage ADC
          adc_start_r1 <= '1';
          if adc_done = '1' then        --ADC done permet de timer à 100kHz
            --Ecriture dans FIFO
            write_af_r1 <= '1';
            af_count_r1 <= af_count_r1 +1;  -- on compte 1 data de plus
            -- On passe a l'etat suivant
            sm_state_r1 <= E_AF20;
          end if;

        when E_AF20 =>
          --Fin Ecriture dans FIFO
          write_af_r1 <= '0';
          if adc_done = '0' then
            sm_state_r1 <= E_AF2;
          end if;

        when E_AF2 =>
          --Fin Ecriture dans FIFO
          write_af_r1 <= '0';
          if af_count_r1 < 363 then
            -- On continue
            sm_state_r1 <= E_AF1;
          else
            -- On passe à l'état suivant
            sm_state_r1  <= E_AF3;
            af_valid_out <= '1';
          end if;
        when E_AF3 =>
          af_valid_out <= '0';
          adc_start_r1 <= '0';
          sm_state_r1  <= E_WAITING;
        when E_HK1 =>
          adc_start_r1 <= '1';
          if adc_done = '1' then
            --Si HK est sur 12 bits
            if (i_hk_addr = "000") or (i_hk_addr = "001") or (i_hk_addr = "100") then
                                        --On place la valeur sur les LSB
              hk_value_12bit_r1 <= adc_value;
              hk_value_high_r1  <= (others => '0');
            else                        --c'est du AD7809 en 16 bits
              --HK_Addr 2= CWL power => ADDR 0 MUX AD7809
              --HK_Addr 3= Mic temp => ADDR 1 MUX AD7809
              --HK_Addr 5= CWL temp => ADDR 2 MUX AD7809
              --HK_Addr 6= temp MP => ADDR 4 MUX AD7809
              --HK_Addr 7= moteor temp => ADDR 3 MUX AD7809
              if i_hk_addr = "010" then
                o_hk_value <= data_AD7809(0);
              elsif i_hk_addr = "011" then
                o_hk_value <= data_AD7809(1);
              elsif i_hk_addr = "101" then
                o_hk_value <= data_AD7809(2);
              elsif i_hk_addr = "110" then
                o_hk_value <= data_AD7809(4);
              elsif i_hk_addr = "111" then
                o_hk_value <= data_AD7809(3);
              end if;
            end if;
            --arret ADC
            adc_start_r1 <= '0';
            --On met à 1 le trig
            hk_ready_out <= '1';
            --etat suivant
            sm_state_r1  <= E_HK2;
          end if;
        when E_HK2 =>
          --deassertion du trig et retour en waiting
          hk_ready_out <= '0';
          --retour en attente
          sm_state_r1  <= E_WAITING;
        when others =>
          sm_state_r1 <= E_WAITING;

      end case;
    end if;
  end process;

end Arch;

