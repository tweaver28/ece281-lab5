--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_basys3 is
    port(
        clk     : in std_logic;
        sw      : in std_logic_vector(7 downto 0);
        btnU    : in std_logic;  -- Master reset
        btnC    : in std_logic;  -- Advance FSM

        led : out std_logic_vector(15 downto 0);
        seg : out std_logic_vector(6 downto 0);
        an  : out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 

    -- COMPONENTS
    component ALU
        port (
            i_A      : in  std_logic_vector(7 downto 0);
            i_B      : in  std_logic_vector(7 downto 0);
            i_op     : in  std_logic_vector(2 downto 0);
            o_result : out std_logic_vector(7 downto 0);
            o_flags  : out std_logic_vector(3 downto 0)
        );
    end component;

    component controller_fsm
        port ( 
            clk     : in std_logic;
            i_reset : in std_logic;
            i_adv   : in std_logic;
            o_cycle : out std_logic_vector (3 downto 0)
        );
    end component;

    component button_debounce
        port (
            clk    : in std_logic;
            reset  : in std_logic;
            button : in std_logic;
            action : out std_logic
        );
    end component;

    component TDM4
        port (
            i_clk   : in std_logic;
            i_reset : in std_logic;
            i_D3    : in std_logic_vector (3 downto 0);
            i_D2    : in std_logic_vector (3 downto 0);
            i_D1    : in std_logic_vector (3 downto 0);
            i_D0    : in std_logic_vector (3 downto 0);
            o_data  : out std_logic_vector (3 downto 0);
            o_sel   : out std_logic_vector (3 downto 0)
        );
    end component;

    component sevenseg_decoder
        port (
            i_hex   : in std_logic_vector (3 downto 0);
            o_seg_n : out std_logic_vector (6 downto 0)
        );
    end component;

    component twos_comp
        port (
            i_bin  : in std_logic_vector(7 downto 0);
            o_sign : out std_logic;
            o_hund : out std_logic_vector(3 downto 0);
            o_tens : out std_logic_vector(3 downto 0);
            o_ones : out std_logic_vector(3 downto 0)
        );
    end component;

    -- SIGNALS
    signal cycle   : std_logic_vector(3 downto 0);
    signal op_A    : std_logic_vector(7 downto 0);
    signal op_B    : std_logic_vector(7 downto 0);
    signal result  : std_logic_vector(7 downto 0);
    signal flags   : std_logic_vector(3 downto 0);
    signal db_btnC : std_logic;

    signal current_val : std_logic_vector(7 downto 0);

    signal sign : std_logic;
    signal ones : std_logic_vector(3 downto 0);
    signal tens : std_logic_vector(3 downto 0);
    signal hund : std_logic_vector(3 downto 0);

    signal mux_digit : std_logic_vector(3 downto 0);
    signal an_tdm    : std_logic_vector(3 downto 0);
    signal seg_real  : std_logic_vector(6 downto 0);

    signal display_en : std_logic;

begin

    -- FSM
    fsm_inst : controller_fsm
        port map (
            clk => clk,
            i_reset => btnU,
            i_adv => db_btnC,
            o_cycle => cycle
        );

    -- Debounce
    db_inst : button_debounce
        port map (
            clk => clk,
            reset => btnU,
            button => btnC,
            action => db_btnC  
        );

    -- ALU
    alu_inst : ALU
        port map (
            i_A => op_A,
            i_B => op_B,
            i_op => sw(2 downto 0),
            o_result => result,
            o_flags => flags
        );

    -- Register load
    process(clk)
    begin
        if rising_edge(clk) then
            if btnU = '1' then
                op_A <= (others => '0');
                op_B <= (others => '0');
            elsif cycle = "0010" then
                op_A <= sw;
            elsif cycle = "0100" then
                op_B <= sw;
            end if;
        end if;
    end process;

    -- Select value to display
    current_val <= op_A when cycle = "0010" else 
                   op_B when cycle = "0100" else 
                   result when cycle = "1000" else
                   (others => '0');

    -- Two's complement conversion
    twos_comp_inst : twos_comp
        port map (
            i_bin => current_val,
            o_sign => sign,
            o_hund => hund,
            o_tens => tens,
            o_ones => ones
        );

    -- Display enable logic
    display_en <= '1' when cycle /= "0001" else '0';

    -- TDM multiplexer
    tdm4_inst : TDM4
        port map (
            i_clk => clk,
            i_reset => btnU,
            i_D3 => "0000",
            i_D2 => hund,
            i_D1 => tens,
            i_D0 => ones,
            o_data => mux_digit,
            o_sel => an_tdm
        );

    -- Anode control
    an <= "1111" when display_en = '0' else an_tdm;

    -- Segment decoder
    sevenseg_decoder_inst : sevenseg_decoder
        port map (
            i_hex => mux_digit,
            o_seg_n => seg_real
        );

    -- Segment control
    seg <= (others => '1') when display_en = '0' else seg_real;

    -- LEDs
    led(3 downto 0) <= cycle;        -- FSM state (one-hot)
    led(15 downto 12) <= flags;      -- ALU flags
    led(11 downto 4) <= (others => '0');

end top_basys3_arch;