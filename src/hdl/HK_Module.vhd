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
    Clk_20MHz : in std_logic;
    Reset_n   : in std_logic;

    --Clock Host Interface Front Panel
    HostClk : in std_logic;

    -- ADC128S022
    Clk_ADC  : in  std_logic;
    ADC_Sclk : out std_logic;
    ADC_Dout : in  std_logic;
    ADC_Din  : out std_logic;
    ADC_Cs_n : out std_logic;

    --AD7809
    ADDR_MUX : out std_logic_vector(2 downto 0);
    DATACLK  : out std_logic;
    SYNC     : in  std_logic;
    DATA     : in  std_logic;
    TAG      : out std_logic;
    R_C_n    : out std_logic;
    CS_n     : out std_logic;
    BUSY_n   : in  std_logic;
    PWRD     : out std_logic;

    --Host Interface
    HK_Addr          : in  std_logic_vector(2 downto 0);  --Adresse de la HK à prendre
    HK_Trig_in       : in  std_logic_vector(3 downto 0);  --Trigger venant du PC pour dire ce que l'on veut faire
    HK_Trig_out      : out std_logic_vector(3 downto 0);  --Annonce au PC de ce qui est dispo
    -- Pipe sortie AF
    PipeOut_AF       : out std_logic_vector(15 downto 0);
    PipeOut_AF_Read  : in  std_logic;
    PipeAFDataCount  : out std_logic_vector(15 downto 0);
    -- Pipe sortie MIC
    PipeOut_MIC      : out std_logic_vector (15 downto 0);
    PipeOut_MIC_Read : in  std_logic;
    PipeMICDataCount : out std_logic_vector(15 downto 0);
    --Sortie HK normale
    --DEBUG
    tick_HK_DBG      : out std_logic;
    --END DEBUG
    HK_Value         : out std_logic_vector(15 downto 0)

    );
end HK_Module;

architecture Arch of HK_Module is

--Alias pour les triggers
  alias HK_request_in : std_logic is HK_Trig_in(0);
  alias MicStart_in   : std_logic is HK_Trig_in(1);
  alias MicStop_in    : std_logic is HK_Trig_in(2);
  alias AF_request_in : std_logic is HK_Trig_in(3);

  alias HK_ready_out : std_logic is HK_Trig_out(0);
  alias MicStart_out : std_logic is HK_Trig_out(1);
  alias MicStop_out  : std_logic is HK_Trig_out(2);
  alias AF_valid_out : std_logic is HK_Trig_out(3);

--Alias pour taille data sur pipeout et HK (ADC 12 bits et transfert sur 16)
  alias PipeOut_AF_12bit  : std_logic_vector(11 downto 0) is PipeOut_AF(11 downto 0);
  alias PipeOut_MIC_12bit : std_logic_vector(11 downto 0) is PipeOut_MIC(11 downto 0);
  alias HK_Value_12bit    : std_logic_vector(11 downto 0) is HK_Value(11 downto 0);
  alias HK_Value_High     : std_logic_vector(3 downto 0) is HK_Value(15 downto 12);

--les datacount sont de 9 et 14 bits
  alias PipeAFDataCount_9   : std_logic_vector(8 downto 0) is PipeAFDataCount(8 downto 0);
  alias PipeMICDataCount_14 : std_logic_vector(13 downto 0) is PipeMICDataCount(13 downto 0);

--Gestion ADC128S102
  signal ADC_Value        : std_logic_vector(11 downto 0);
  signal ADC_Start        : std_logic;
  signal ADC_Done         : std_logic;
  signal ADC_Done_Latched : std_logic;
  signal tempo_HK         : integer range 0 to 200;


--Gestion AD7809
  signal Data_Updated : std_logic;
  signal Data_AD7809  : register_ADC16;

--Alias FIFO
  alias Din_FIFO_AF    : std_logic_vector(11 downto 0) is ADC_Value;
  alias Din_FIFO_MICRO : std_logic_vector(11 downto 0) is ADC_Value;

--Signaux FIFO
  signal write_AF : std_logic;
  signal full_AF  : std_logic;
  signal empty_AF : std_logic;
  signal rst      : std_logic;

  signal write_MICRO : std_logic;
  signal full_MICRO  : std_logic;
  signal empty_MICRO : std_logic;


--Compteur pour les AF
  signal AF_count : integer range 0 to 363;

--Declaration Machine à état prise HK
  type FSM_state is (Init, waiting, MIC1, MIC2, MIC20, MIC3, AF1, AF2, AF20, AF3, HK1, HK2);
  signal state : FSM_state;


begin

--Bit des pipeout ne servant pas : restent à 0:
  PipeOut_AF (15 downto 12)  <= (others => '0');
  PipeOut_MIC (15 downto 12) <= (others => '0');

--Bits des datacount FIFO ne servant pas:
  PipeAFDataCount(15 downto 9)   <= (others => '0');
  PipeMICDataCount(15 downto 14) <= (others => '0');


--Rest FIFO
  rst <= not Reset_n;

--Port Map ADC rapide
  ADC128S022 : entity work.ADC128Sxxx
    port map (
      Reset_n => Reset_n,
      clk     => Clk_ADC,

      Output_value    => ADC_Value,
      Start           => ADC_Start,
      Done            => ADC_Done,
      channel_address => HK_Addr,
      ADC_Sclk        => ADC_Sclk,
      ADC_Dout        => ADC_Dout,
      ADC_Din         => ADC_Din,
      ADC_Cs_n        => ADC_Cs_n
      );

--Port Map ADC lent
  AD7809 : entity work.Slow_HK_Acq
    port map (
      -- Clk et Rst à 0
      Clk_20MHz => Clk_20MHz,
      reset_n   => Reset_n,

      --Gestion MUX
      ADDR => ADDR_MUX,

      --Gestion ADC
      DATACLK     => DATACLK,
      SYNC        => SYNC,
      AD7809_DATA => DATA,
      TAG         => TAG,
      R_C_n       => R_C_n,
      CS_n        => CS_n,
      BUSY_n      => BUSY_n,
      PWRD        => PWRD,

      --Data ouput
      --DEBUG
      tick_HK_DBG  => tick_HK_DBG,
      --END DEBUG
      Data_Updated => Data_Updated,
      Data_out     => Data_AD7809

      );


--Port Map FIFO
  FIFO_autofocus : entity work.FIFO_AF
    port map(
      rst           => rst,
      wr_clk        => Clk_20MHz,
      rd_clk        => HostClk,
      din           => Din_FIFO_AF,
      wr_en         => write_AF,
      rd_en         => PipeOut_AF_Read,
      dout          => PipeOut_AF_12bit,
      full          => full_AF,
      empty         => empty_AF,
      rd_data_count => PipeAFDataCount_9
      );

  FIFO_Microphone : entity work.FIFO_MICRO
    port map(
      rst           => rst,
      wr_clk        => Clk_20MHz,
      rd_clk        => HostClk,
      din           => Din_FIFO_MICRO,
      wr_en         => write_MICRO,
      rd_en         => PipeOut_MIC_Read,
      dout          => PipeOut_MIC_12bit,
      full          => full_MICRO,
      empty         => empty_MICRO,
      rd_data_count => PipeMICDataCount_14
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
    if Reset_n = '0' then
      --init des états
      state <= Init;
    elsif rising_edge(clk_20MHz) then
      case state is
        when Init =>
          -- Initialisation des signaux en attente d'un trig.
          HK_ready_out   <= '0';
          MicStart_out   <= '0';
          MicStop_out    <= '0';
          AF_valid_out   <= '0';
          write_AF       <= '0';
          write_MICRO    <= '0';
          HK_Value_12bit <= (others => '0');
          HK_Value_High  <= (others => '0');
          AF_count       <= 0;
          state          <= waiting;
          ADC_Start      <= '0';

        when waiting =>
          ADC_Start <= '0';
          --Gestion des cas de trig
          if HK_request_in = '1' then
            state <= HK1;
          elsif MicStart_in = '1' then
            state <= MIC1;
          elsif AF_request_in = '1' then
            state    <= AF1;
            AF_count <= 0;
          end if;

        when MIC1 =>                    --On a une demande de prise de son.
          -- Démarrage ADC
          ADC_Start <= '1';
          --Vérification de l'extinction du micro
          if MicStop_in = '1' then
            --indiquation que l'on s'arrête
            MicStop_out <= '1';
            -- On passe à l'état suivant
            state       <= MIC3;
          end if;
          if ADC_Done = '1' then        --ADC done permet de timer à 100kHz
            --Ecriture dans FIFO
            write_MICRO  <= '1';
            --On signale que l'on a démarré une acquisition
            MicStart_out <= '1';
            -- On passe à l'état suivant
            state        <= MIC20;
          end if;

        when MIC20 =>
          --Fin écriture
          write_MICRO <= '0';
          if ADC_Done = '0' then
            state <= MIC2;
          end if;

        when MIC2 =>                    --Doit-on continuer l'acquisition?
          --Fin écriture
          write_MICRO  <= '0';
          --Fin de Flag
          MicStart_out <= '0';
          --Vérification de l'extinction du micro
          if MicStop_in = '1' then
            --indiquation que l'on s'arrête
            MicStop_out <= '1';
            -- On passe à l'état suivant
            state       <= MIC3;
          else
            -- On passe à l'état suivant
            state <= MIC1;
          end if;
        when MIC3 =>                    -- le micro a été arrêté
          MicStop_out <= '0';
          ADC_Start   <= '0';
          state       <= waiting;

        when AF1 =>                     --accumulation de 363 data
          --Démarrage ADC
          ADC_Start <= '1';
          if ADC_Done = '1' then        --ADC done permet de timer à 100kHz
            --Ecriture dans FIFO
            write_AF <= '1';
            AF_count <= AF_count +1;    -- on compte 1 data de plus
            -- On passe à l'état suivant
            state    <= AF20;
          end if;

        when AF20 =>
          --Fin Ecriture dans FIFO
          write_AF <= '0';
          if ADC_Done = '0' then
            state <= AF2;
          end if;

        when AF2 =>
          --Fin Ecriture dans FIFO
          write_AF <= '0';
          if AF_count < 363 then
            -- On continue
            state <= AF1;
          else
            -- On passe à l'état suivant
            state        <= AF3;
            AF_valid_out <= '1';
          end if;
        when AF3 =>
          AF_valid_out <= '0';
          ADC_Start    <= '0';
          state        <= waiting;
        when HK1 =>
          ADC_Start <= '1';
          if ADC_Done = '1' then
            --Si HK est sur 12 bits
            if (HK_Addr = "000") or (HK_Addr = "001") or (HK_Addr = "100") then
              --On place la valeur sur les LSB
              HK_Value_12bit <= ADC_Value;
              HK_Value_High  <= (others => '0');
            else                        --c'est du AD7809 en 16 bits
              --HK_Addr 2= CWL power => ADDR 0 MUX AD7809
              --HK_Addr 3= Mic temp => ADDR 1 MUX AD7809
              --HK_Addr 5= CWL temp => ADDR 2 MUX AD7809
              --HK_Addr 6= temp MP => ADDR 4 MUX AD7809
              --HK_Addr 7= moteor temp => ADDR 3 MUX AD7809
              if HK_Addr = "010" then
                HK_Value <= Data_AD7809(0);
              elsif HK_Addr = "011" then
                HK_Value <= Data_AD7809(1);
              elsif HK_Addr = "101" then
                HK_Value <= Data_AD7809(2);
              elsif HK_Addr = "110" then
                HK_Value <= Data_AD7809(4);
              elsif HK_Addr = "111" then
                HK_Value <= Data_AD7809(3);
              end if;
            end if;
            --arret ADC
            ADC_Start    <= '0';
            --On met à 1 le trig
            HK_ready_out <= '1';
            --etat suivant
            state        <= HK2;
          end if;
        when HK2 =>
          --deassertion du trig et retour en waiting
          HK_ready_out <= '0';
          --retour en attente
          state        <= waiting;
        when others =>
          state <= waiting;

      end case;
    end if;
  end process;

end Arch;

