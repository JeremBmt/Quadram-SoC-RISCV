library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Decodeur is
    generic (
        N_IN  : integer := 2; -- Nombre de bits d'adresse en entrée
        N_OUT : integer := 4  -- Nombre de signaux CS en sortie (généralement 2^N_IN)
    );
    port (
        addr_in : in  unsigned(N_IN - 1 downto 0);
        cs_out  : out unsigned(N_OUT - 1 downto 0)
    );
end entity Decodeur;

architecture RTL of Decodeur is
begin
    process(addr_in)
    begin
        -- On initialise toutes les sorties à '0' par défaut
        cs_out <= (others => '0'); 
        -- On met à '1' uniquement le bit correspondant à la valeur de l'adresse
        cs_out(to_integer(addr_in)) <= '1'; 
    end process;
end architecture RTL;
