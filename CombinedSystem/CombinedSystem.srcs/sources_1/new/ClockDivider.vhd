library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ClockDivider is
    Port (
        clk          : in  STD_LOGIC; -- Input clock
        slow_clk     : out STD_LOGIC; -- Slow clock
        flash_clk    : out STD_LOGIC  -- Flashing clock
    );
end ClockDivider;

architecture Behavioral of ClockDivider is
    constant CLK_DIVIDER : integer := 12000000;
    constant FLASH_DIVIDER : integer := 8000000;
    signal clk_count : integer := 0;
    signal flash_count : integer := 0;
    signal slow_clk_reg : STD_LOGIC := '0';
    signal flash_clk_reg : STD_LOGIC := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if clk_count = CLK_DIVIDER then
                slow_clk_reg <= not slow_clk_reg;
                clk_count <= 0;
            else
                clk_count <= clk_count + 1;
            end if;

            if flash_count = FLASH_DIVIDER then
                flash_clk_reg <= not flash_clk_reg;
                flash_count <= 0;
            else
                flash_count <= flash_count + 1;
            end if;
        end if;
    end process;

    slow_clk <= slow_clk_reg;
    flash_clk <= flash_clk_reg;
end Behavioral;
