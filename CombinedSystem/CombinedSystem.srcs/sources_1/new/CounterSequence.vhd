library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CounterSequence is
    Port (
        clk             : in  STD_LOGIC;                -- Slow clock
        flash_clk       : in  STD_LOGIC;                -- Flash clock
        btnu_stable     : in  STD_LOGIC;                -- Debounced button Up
        btnd_stable     : in  STD_LOGIC;                -- Debounced button Down
        btnl_stable     : in  STD_LOGIC;                -- Debounced button Left
        btnr_stable     : in  STD_LOGIC;                -- Debounced button Right
        btnc_stable     : in  STD_LOGIC;                -- Reset button
        led             : out STD_LOGIC_VECTOR(7 downto 0) -- LED output
    );
end CounterSequence;

architecture Behavioral of CounterSequence is
    -- Constants
    constant MAX_ATTEMPTS : integer := 15;
    constant SEQUENCE_LENGTH : integer := 5;

    -- Signals
    signal total_count : INTEGER range 0 to 255 := 0;
    signal stop_flag : STD_LOGIC := '0';
    signal sequence_detected : STD_LOGIC := '0';
    signal flash_pattern : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

    type SymbolArray is array(0 to MAX_ATTEMPTS - 1) of std_logic_vector(1 downto 0);
    signal entered_symbols : SymbolArray := (others => "00");
    signal current_index : integer range 0 to MAX_ATTEMPTS := 0;
    signal match_count : integer := 0;  -- Tracks matching symbols
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if btnc_stable = '1' then
                -- Reset system
                total_count <= 0;
                stop_flag <= '0';
                current_index <= 0;
                entered_symbols <= (others => "00");
                sequence_detected <= '0';
                flash_pattern <= (others => '0');
            elsif sequence_detected = '0' then
                -- Count button presses
                if stop_flag = '0' then
                    if btnu_stable = '1' or btnd_stable = '1' or btnl_stable = '1' or btnr_stable = '1' then
                        total_count <= total_count + 1;
                    end if;
                    if total_count = 11 then
                        stop_flag <= '1';
                    end if;
                end if;

                -- Record button press for sequence detection
                if btnu_stable = '1' then
                    entered_symbols(current_index) <= "00";
                    current_index <= current_index + 1;
                elsif btnd_stable = '1' then
                    entered_symbols(current_index) <= "01";
                    current_index <= current_index + 1;
                elsif btnl_stable = '1' then
                    entered_symbols(current_index) <= "10";
                    current_index <= current_index + 1;
                elsif btnr_stable = '1' then
                    entered_symbols(current_index) <= "11";
                    current_index <= current_index + 1;
                end if;

                -- Check for target sequence in any position
                for i in 0 to MAX_ATTEMPTS - SEQUENCE_LENGTH loop
                    match_count <= 0;
                    if entered_symbols(i) = "00" then
                        match_count <= match_count + 1;
                    end if;
                    if entered_symbols(i + 1) = "01" then
                        match_count <= match_count + 1;
                    end if;
                    if entered_symbols(i + 2) = "01" then
                        match_count <= match_count + 1;
                    end if;
                    if entered_symbols(i + 3) = "10" then
                        match_count <= match_count + 1;
                    end if;
                    if entered_symbols(i + 4) = "11" then
                        match_count <= match_count + 1;
                    end if;

                    if match_count = 5 then
                        sequence_detected <= '1';
                        exit;
                    end if;
                end loop;
            end if;

            -- Set LED blinking patterns
            if sequence_detected = '1' then
                flash_pattern <= (others => flash_clk); -- Blink `11111111` and `00000000`
            elsif stop_flag = '1' then
                if flash_clk = '1' then
                    flash_pattern <= "10101010";
                else
                    flash_pattern <= "01010101";
                end if;
            else
                flash_pattern <= std_logic_vector(to_unsigned(total_count, 8)); -- Default to count
            end if;
        end if;
    end process;

    led <= flash_pattern;
end Behavioral;
