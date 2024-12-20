library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Debouncer is
    Port (
        clk    : in std_logic;
        input  : in std_logic;
        output : out std_logic
    );
end Debouncer;

architecture Behavioral of Debouncer is
    signal delay1, delay2, delay3 : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            delay1 <= input;
            delay2 <= delay1;
            delay3 <= delay2;
        end if;
    end process;

    output <= delay2 and not delay3; -- Detect stable rising edge
end Behavioral;