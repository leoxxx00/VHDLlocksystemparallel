library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CombinedSystem is
    Port (
        clk    : in  STD_LOGIC;                -- Clock signal
        btnc   : in  STD_LOGIC;                -- Reset button
        btnu   : in  STD_LOGIC;                -- Button Up
        btnd   : in  STD_LOGIC;                -- Button Down
        btnl   : in  STD_LOGIC;                -- Button Left
        btnr   : in  STD_LOGIC;                -- Button Right
        led    : out STD_LOGIC_VECTOR(7 downto 0) -- LED output
    );
end CombinedSystem;

architecture Behavioral of CombinedSystem is
    -- Constants
    constant MAX_ATTEMPTS      : integer := 15; -- Maximum button presses stored
    constant SEQUENCE_LENGTH   : integer := 5;
    constant CLK_DIVIDER       : integer := 3000000; -- Slow clock frequency divider
    constant FLASH_DIVIDER     : integer := 2000000; -- Flash clock frequency divider

    -- Button Press Counter
    signal total_count : INTEGER range 0 to 255 := 0; -- Total count of button presses
    signal stop_flag   : STD_LOGIC := '0'; -- Stops counting at 11

    -- Sequence Detection
    type SymbolArray is array(0 to MAX_ATTEMPTS - 1) of std_logic_vector(1 downto 0);
    signal entered_symbols : SymbolArray := (others => "00");
    signal current_index   : integer range 0 to MAX_ATTEMPTS := 0; -- Tracks current input position
    signal sequence_detected : STD_LOGIC := '0'; -- Indicates sequence is found

    -- Clock Divider
    signal slow_clk  : STD_LOGIC := '0';
    signal flash_clk : STD_LOGIC := '0'; -- Blinking clock
    signal clk_count : integer := 0;
    signal flash_count : integer := 0;

    -- Debouncer Outputs
    signal btnu_debounced, btnd_debounced, btnl_debounced, btnr_debounced, btnc_debounced : std_logic;

    -- LED Output
    signal led_output    : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal flash_pattern : STD_LOGIC_VECTOR(7 downto 0) := (others => '0'); -- Temporary pattern for blinking
begin
    -- Clock Divider Process
    process(clk)
    begin
        if rising_edge(clk) then
            -- Generate slow clock
            if clk_count = CLK_DIVIDER - 1 then
                slow_clk <= not slow_clk;
                clk_count <= 0;
            else
                clk_count <= clk_count + 1;
            end if;

            -- Generate flash clock for blinking
            if flash_count = FLASH_DIVIDER - 1 then
                flash_clk <= not flash_clk;
                flash_count <= 0;
            else
                flash_count <= flash_count + 1;
            end if;
        end if;
    end process;

    -- Instantiate Debouncer for Each Button
    debounce_btnu: entity work.Debouncer
        Port map (
            clk    => slow_clk, -- Use slow clock
            input  => btnu,
            output => btnu_debounced
        );

    debounce_btnd: entity work.Debouncer
        Port map (
            clk    => slow_clk, -- Use slow clock
            input  => btnd,
            output => btnd_debounced
        );

    debounce_btnl: entity work.Debouncer
        Port map (
            clk    => slow_clk, -- Use slow clock
            input  => btnl,
            output => btnl_debounced
        );

    debounce_btnr: entity work.Debouncer
        Port map (
            clk    => slow_clk, -- Use slow clock
            input  => btnr,
            output => btnr_debounced
        );

    debounce_btnc: entity work.Debouncer
        Port map (
            clk    => slow_clk, -- Use slow clock
            input  => btnc,
            output => btnc_debounced
        );

    -- Counter and Sequence Detection Process
    process(slow_clk)
        variable match_count : integer := 0;  -- Tracks matching symbols
    begin
        if rising_edge(slow_clk) then
            if btnc_debounced = '1' then
                -- Reset system
                total_count <= 0;
                stop_flag <= '0';
                current_index <= 0;
                entered_symbols <= (others => "00");
                sequence_detected <= '0';
                led_output <= (others => '0');
            elsif sequence_detected = '0' then
                -- Count button presses
                if stop_flag = '0' then
                    if btnu_debounced = '1' or btnd_debounced = '1' or btnl_debounced = '1' or btnr_debounced = '1' then
                        total_count <= total_count + 1;
                    end if;

                    -- Stop counting at 11
                    if total_count = 11 then
                        stop_flag <= '1';
                    end if;
                end if;

                -- Record button press for sequence detection
                if btnu_debounced = '1' then
                    entered_symbols(current_index) <= "00";
                    current_index <= current_index + 1;
                elsif btnd_debounced = '1' then
                    entered_symbols(current_index) <= "01";
                    current_index <= current_index + 1;
                elsif btnl_debounced = '1' then
                    entered_symbols(current_index) <= "10";
                    current_index <= current_index + 1;
                elsif btnr_debounced = '1' then
                    entered_symbols(current_index) <= "11";
                    current_index <= current_index + 1;
                end if;

                -- Check for target sequence in any position
                for i in 0 to MAX_ATTEMPTS - SEQUENCE_LENGTH loop
                    match_count := 0;
                    if entered_symbols(i) = "00" then
                        match_count := match_count + 1;
                    end if;
                    if entered_symbols(i + 1) = "01" then
                        match_count := match_count + 1;
                    end if;
                    if entered_symbols(i + 2) = "01" then
                        match_count := match_count + 1;
                    end if;
                    if entered_symbols(i + 3) = "10" then
                        match_count := match_count + 1;
                    end if;
                    if entered_symbols(i + 4) = "11" then
                        match_count := match_count + 1;
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

            led_output <= flash_pattern;
        end if;
    end process;

    -- Assign LED output
    led <= led_output;

end Behavioral;