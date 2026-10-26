-- Test bench corrigé pour la RAM synchrone générique

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_std.all;

entity Ram_TB is
end entity Ram_TB;

-------------------------------------------------------------------------------
-- Architecture 1 : Test pas-à-pas manuel
-------------------------------------------------------------------------------
architecture Bench of Ram_TB is 

  signal Address : unsigned(9 downto 0);
  signal DataIn, DataOut : unsigned(7 downto 0);
  signal WE : std_logic;
  signal clock : std_logic;
  signal StopClock : boolean := FALSE;
  signal CS : std_logic := '1'; -- Initialisé actif à '1'

begin

  UUT: entity work.sync_ram(RTL)
  generic map (
    Nbbits_addr => 10,
    Nbbits_data => 8
  )
  port map (
    clock   => clock,
    we      => WE,
    address => Address,
    datain  => DataIn,
    dataOut => DataOut,
    cs      => CS
  );

  ClockGen: process is
  begin
    while not StopClock loop
      clock <= '0';
      wait for 5 ns;
      clock <= '1';
      wait for 5 ns;
    end loop;
    wait;
  end process ClockGen;

  Stim: process is
  begin
    -- Sélection de la mémoire active
    CS <= '1';

    wait until rising_edge(clock); -- cycle 1
    datain  <= "00000000";
    address <= "0000000001";
    we      <= '0';

    wait until rising_edge(clock); -- cycle 2 : écriture de 4 à l'adresse 1
    we      <= '1';
    datain  <= "00000100";

    wait until rising_edge(clock); -- cycle 3 : écriture de 7 à l'adresse 2
    datain  <= "00000111";
    address <= "0000000010";

    wait until rising_edge(clock); -- cycle 4 : fin écriture
    we      <= '0';

    wait until rising_edge(clock); -- cycle 5 : lecture adresse 1 (doit sortir 4 au cycle suivant)
    address <= "0000000001";

    wait until rising_edge(clock); -- cycle 6 : lecture adresse 2 (doit sortir 7 au cycle suivant)
    address <= "0000000010";

    wait until rising_edge(clock); -- cycle 7
    -- Test du signal CS : désactivation pour vérifier le passage à haute impédance ('Z')
    CS <= '0';

    wait until rising_edge(clock); -- cycle 8 : DataOut doit passer immédiatement à 'Z'
    wait until rising_edge(clock);

    StopClock <= true;
    wait;
  end process;

end architecture Bench;

-------------------------------------------------------------------------------
-- Architecture 2 : Test automatique exhaustif
-------------------------------------------------------------------------------
architecture Bench2 of Ram_TB is

  signal Address : unsigned(9 downto 0);
  signal DataIn, DataOut : unsigned(7 downto 0);
  signal WE : std_logic;
  signal clock : std_logic;
  signal StopClock : boolean := FALSE;
  signal CS : std_logic := '1'; -- Initialisé actif à '1'

  signal ok: boolean := true;

begin

  UUT: entity work.sync_ram(RTL)
  generic map (
    Nbbits_addr => 10,
    Nbbits_data => 8
  )
  port map (
    clock   => clock,
    we      => WE,
    address => Address,
    datain  => DataIn,
    DataOut => DataOut,
    cs      => CS
  );

  ClockGen: process is
  begin
    while not StopClock loop
      clock <= '0';
      wait for 5 ns;
      clock <= '1';
      wait for 5 ns;
    end loop;
    wait;
  end process ClockGen;

  Stim: process is
  begin
    -- Initialisation des signaux d'entrée
    CS      <= '1';
    address <= "0000000000";
    datain  <= "00000000";
    we      <= '0';
    wait until rising_edge(clock);

    -- 1. Écriture sur toutes les adresses
    while address /= "1111111111" loop
      we <= '1';
      wait until rising_edge(clock);
      address <= address + 1;
      datain  <= datain + 1;
    end loop;

    -- Arrêt de l'écriture
    address <= "0000000000";
    datain  <= "00000000";
    we      <= '0';
    wait until rising_edge(clock);

    -- 2. Relecture et vérification automatique
    while address /= "1111111111" loop
      address <= address + 1;
      wait until rising_edge(clock);
      -- Parenthèses ajoutées pour sécuriser la précédence des opérateurs
      ok <= ok and (dataout = (address(7 downto 0) - 1));
    end loop;

    StopClock <= true;
    wait;
  end process;

end architecture Bench2;
