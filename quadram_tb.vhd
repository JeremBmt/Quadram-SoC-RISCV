library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_std.all;

entity Quadram_TB is
end entity Quadram_TB;

architecture Bench of Quadram_TB is

  -- 1. Définition des paramètres génériques du test
  constant C_N_RAMS     : integer := 4;
  constant C_ADDR_DEC   : integer := 2;
  constant C_ADDR_RAM   : integer := 10;
  constant C_DATA_WIDTH : integer := 8;

  -- 2. Les signaux s'adaptent automatiquement à la taille définie
  signal Address : unsigned(C_ADDR_DEC + C_ADDR_RAM - 1 downto 0);
  signal DataIn, DataOut : unsigned(C_DATA_WIDTH - 1 downto 0);
  
  signal WE : std_logic;
  signal clock : std_logic;
  signal StopClock : boolean := FALSE;
  signal ok: boolean := true;

  -- Constante remplie de '1' pour remplacer le "111111111111" dans les boucles
  constant MAX_ADDR : unsigned(Address'range) := (others => '1');

begin

  -- 3. Instanciation avec le generic map
  UUT: entity work.quadram(Struct)
  generic map (
    N_RAMS     => C_N_RAMS,
    ADDR_DEC   => C_ADDR_DEC,
    ADDR_RAM   => C_ADDR_RAM,
    DATA_WIDTH => C_DATA_WIDTH
  )
  port map (
    clock   => clock,
    we      => WE,
    address => Address,
    datain  => DataIn,
    dataout => DataOut
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
    address <= (others => '0'); -- Initialise à 0
    datain  <= (others => '0');
    we <= '0';
    wait until rising_edge(clock);

    -- 1. Écriture générique dans l'intégralité des adresses
    while address /= MAX_ADDR loop
      we <= '1';
      wait until rising_edge(clock);
      address <= address + 1;
      datain  <= datain + 1;
    end loop;

    -- Arrêt de l'écriture
    address <= (others => '0');
    datain  <= (others => '0');
    we <= '0';
    wait until rising_edge(clock);

    -- 2. Lecture et vérification générique
    while address /= MAX_ADDR loop
      address <= address + 1;
      wait until rising_edge(clock);
      
      -- Vérification : s'adapte à la largeur de la donnée (C_DATA_WIDTH)
      ok <= ok and (dataout = (address(C_DATA_WIDTH - 1 downto 0) - 1)); 
    end loop;

    StopClock <= true;
    wait;
  end process;

end architecture Bench;
