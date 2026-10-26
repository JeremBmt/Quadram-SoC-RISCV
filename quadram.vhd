library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity quadram is
    generic (
        N_RAMS     : integer := 4;  -- Nombre d'instances de RAM
        ADDR_DEC   : integer := 2;  -- Nombre de bits pour le décodeur (2 bits = 4 RAMs)
        ADDR_RAM   : integer := 10; -- Nombre de bits d'adresse pour une RAM (Correspond à Nbbits_addr)
        DATA_WIDTH : integer := 8   -- Largeur du bus de données (Correspond à Nbbits_data)
    );
    port (
        clock   : in  std_logic;
        we      : in  std_logic;
        -- L'adresse globale combine les bits du décodeur (MSB) et ceux des RAMs (LSB)
        address : in  unsigned(ADDR_DEC + ADDR_RAM - 1 downto 0);
        datain  : in  unsigned(DATA_WIDTH - 1 downto 0);
        dataout : out unsigned(DATA_WIDTH - 1 downto 0)
    );
end entity quadram;

architecture Struct of quadram is

    -- Bus interne reliant les sorties du décodeur aux entrées CS des RAMs
    signal cs_bus : unsigned(N_RAMS - 1 downto 0);

begin

    -- Instanciation du décodeur
    U_DECODER : entity work.Decodeur
        generic map (
            N_IN  => ADDR_DEC,
            N_OUT => N_RAMS
        )
        port map (
            -- On envoie les 2 bits de poids fort (MSB) au décodeur
            addr_in => address(ADDR_DEC + ADDR_RAM - 1 downto ADDR_RAM),
            cs_out  => cs_bus
        );

    -- Instanciation des N blocs RAM avec la boucle for...generate
    G_RAMS : for i in 0 to N_RAMS - 1 generate
        RAM_INST : entity work.sync_ram
            generic map (
                -- On mappe ici avec les noms exacts de ton fichier sync_ram
                Nbbits_addr => ADDR_RAM,
                Nbbits_data => DATA_WIDTH
            )
            port map (
                cs      => cs_bus(i),  -- Chaque instance reçoit son bit CS dédié
                clock   => clock,
                we      => we,
                -- On envoie les 10 bits de poids faible (LSB) à chaque RAM en parallèle
                address => address(ADDR_RAM - 1 downto 0),
                datain  => datain,
                dataout => dataout
            );
    end generate G_RAMS;

end architecture Struct;