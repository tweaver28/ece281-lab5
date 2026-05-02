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
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;



architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
    component ALU
    port (
        i_A      : in  std_logic_vector(7 downto 0);
        i_B      : in  std_logic_vector(7 downto 0);
        i_op     : in  std_logic_vector(2 downto 0);
        o_result : out std_logic_vector(7 downto 0);
        o_flags  : out std_logic_vector(3 downto 0)   -- N  Z  C  V
    );
    end component;
    
    component controller_fsm
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0)
    );
    end component;
    
    component button_debounce
    Port ( clk    : in STD_LOGIC;
           reset  : in STD_LOGIC;
           button : in STD_LOGIC;
           action : out STD_LOGIC
    );
    end component;
    
    component sevenseg_decoder
    port ( 	i_hex    : in std_logic_vector (3 downto 0);
			o_seg_n  : out std_logic_vector (6 downto 0)	
	);
	end component;
    
    signal cycle   : std_logic_vector (3 downto 0);
    signal op_A    : std_logic_vector (7 downto 0);
    signal op_B    : std_logic_vector (7 downto 0);
    signal result  : std_logic_vector (7 downto 0);
    signal flags   : std_logic_vector (3 downto 0);
    signal db_btnC : std_logic;
    
    signal current_val : std_logic_vector(7 downto 0);
    signal val_signed : signed(7 downto 0);
    signal val_abs : unsigned(7 downto 0);
    signal is_neg : std_logic;
    
    signal ones : std_logic_vector(3 downto 0);
    signal tens : std_logic_vector(3 downto 0);
    
    signal refresh_cnt : unsigned(15 downto 0);
    signal digit_sel : std_logic_vector(1 downto 0);
    signal display : std_logic_vector(3 downto 0);
    signal seg_int : std_logic_vector(6 downto 0);
    
  
begin
	-- PORT MAPS ----------------------------------------
    fsm_inst : controller_fsm
    port map (
        i_reset => btnU,
        i_adv => db_btnC,
        o_cycle => cycle
    );
    
    db_inst : button_debounce
    port map (
        clk    => clk,
        reset  => btnU,
        button => btnC,
        action => db_btnC  
    );
    
    alu_inst : ALU
    port map (
        i_A      => op_A,
        i_B      => op_B,
        i_op     => sw(2 downto 0),
        o_result => result,
        o_flags  => flags
    );
    
    sevenseg_decoder_inst : entity work.sevenseg_decoder
    port map (
        i_hex    => display,
	    o_seg_n  => seg_int  
    );
        
    
    
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
    
    
    current_val <= op_A when cycle = "0010" else 
                   op_B when cycle = "0100" else 
                   result;
       
    val_signed <= signed(current_val);
    is_neg <= val_signed(7);
    
    val_abs <= unsigned(-val_signed) when is_neg = '1'
               else unsigned(val_signed);
    
    ones <= std_logic_vector(to_unsigned(to_integer(val_abs) mod 10, 4));
tens <= std_logic_vector(to_unsigned((to_integer(val_abs) / 10) mod 10, 4));
    
    process(clk)
    begin  
        if rising_edge(clk) then
            if btnU = '1' then
                refresh_cnt <= (others => '0');
            else
                refresh_cnt <= refresh_cnt + 1;
            end if;
        end if;
    end process;
    
    digit_sel <= std_logic_vector(refresh_cnt(15 downto 14));
    
    process(digit_sel, ones, tens, is_neg)
    begin   
        an <= "1111";
        seg <= "1111111";
        display <= (others => '0');
        case digit_sel is
            when "00" =>
                an <= "1110";
                display <= ones;
                seg <= seg_int;
            when "01" =>
                an <= "1101";
                display <= tens;
                seg <= seg_int;
           when "10" =>
                an <= "1011";
                if is_neg = '1' then
                    seg <= "1111110";
                else
                    seg <= "1111111";
                end if;
           when others => 
                an <= "0111";
                seg <= "1111111";
            
    end case;
  end process;              
              
	
	-- CONCURRENT STATEMENTS ----------------------------
	led (3 downto 0) <= cycle;
	led(15 downto 12) <= flags;
	led(11 downto 4) <= (others => '0');
	
	
end top_basys3_arch;
