library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity soc_top_tb is
end entity soc_top_tb;

architecture Bench of soc_top_tb is

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';
    signal stop  : boolean := false;

begin

    -- Instanciation du système complet
    UUT : entity work.soc_top(Structural)
        port map (
            clk   => clk,
            reset => reset
        );

    -- Générateur d'horloge (période = 10 ns)
    ClockGen : process
    begin
        while not stop loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
        wait;
    end process ClockGen;

    -- Séquence de test
    Stim : process
    begin
        -- 1. Maintien du reset pendant 2 cycles
        reset <= '1';
        wait for 20 ns;

        -- 2. Libération du reset : le processeur commence l'exécution
        wait until rising_edge(clk);
        reset <= '0';

        -- 3. Attente de l'exécution complète du programme
        wait for 1000 ns;

        stop <= true;
        wait;
    end process Stim;

end architecture Bench;
