library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity soc_top is
    port (
        clk   : in std_logic;
        reset : in std_logic
    );
end entity soc_top;

architecture Structural of soc_top is

    -- Signaux d'interconnexion processeur <-> quadram
    signal s_data_addr : std_logic_vector(11 downto 0);
    signal s_data_out  : std_logic_vector(7 downto 0);
    signal s_data_in   : std_logic_vector(7 downto 0);
    signal s_we        : std_logic;

    -- Conversion de type pour la QuadRAM (unsigned)
    signal quad_addr    : unsigned(11 downto 0);
    signal quad_datain  : unsigned(7 downto 0);
    signal quad_dataout : unsigned(7 downto 0);

    -- Déclaration du module Verilog
    component system is
        generic (
            DataWidth : integer := 32;
            AddrWidth : integer := 12;
            MemSize   : integer := 4096
        );
        port (
            clk       : in  std_logic;
            reset     : in  std_logic;
            data_addr : out std_logic_vector(11 downto 0);
            data_out  : out std_logic_vector(7 downto 0);
            data_in   : in  std_logic_vector(7 downto 0);
            we        : out std_logic
        );
    end component system;

begin

    -- Adaptations std_logic_vector <-> unsigned
    quad_addr   <= unsigned(s_data_addr);
    quad_datain <= unsigned(s_data_out);
    s_data_in   <= std_logic_vector(quad_dataout);

    -- Instanciation du processeur RISC-V Verilog
    U_PROC : system
        generic map (
            DataWidth => 32,
            AddrWidth => 12,
            MemSize   => 4096
        )
        port map (
            clk       => clk,
            reset     => reset,
            data_addr => s_data_addr,
            data_out  => s_data_out,
            data_in   => s_data_in,
            we        => s_we
        );

    -- Instanciation de la QuadRAM VHDL
    U_RAM : entity work.quadram(Struct)
        generic map (
            N_RAMS     => 4,
            ADDR_DEC   => 2,
            ADDR_RAM   => 10,
            DATA_WIDTH => 8
        )
        port map (
            clock   => clk,
            we      => s_we,
            address => quad_addr,
            datain  => quad_datain,
            dataout => quad_dataout
        );

end architecture Structural;
