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
    Port ( 
           clk : in std_logic;
           i_reset : in STD_LOGIC;
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
    
    component TDM4
        port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (3 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (3 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (3 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (3 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (3 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	);
    end component;
    
    component sevenseg_decoder
    port ( 	i_hex    : in std_logic_vector (3 downto 0);
			o_seg_n  : out std_logic_vector (6 downto 0)	
	);
	end component;
	
	component twos_comp
	port (
        i_bin: in std_logic_vector(7 downto 0);
        o_sign: out std_logic;
        o_hund: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
    );
end component;
    
    signal cycle   : std_logic_vector (3 downto 0);
    signal op_A    : std_logic_vector (7 downto 0);
    signal op_B    : std_logic_vector (7 downto 0);
    signal result  : std_logic_vector (7 downto 0);
    signal flags   : std_logic_vector (3 downto 0);
    signal db_btnC : std_logic;
    
    signal current_val : std_logic_vector(7 downto 0);
    
    signal sign : std_logic;
    signal ones : std_logic_vector(3 downto 0);
    signal tens : std_logic_vector(3 downto 0);
    signal hund : std_logic_vector(3 downto 0);
    
    signal sign_digit : std_logic_vector(3 downto 0);
    signal mux_digit : std_logic_vector(3 downto 0);
    signal an_tdm : std_logic_vector(3 downto 0);
    signal seg_real : std_logic_vector(6 downto 0);
  
begin
	-- PORT MAPS ----------------------------------------
    fsm_inst : controller_fsm
    port map (
        clk => clk,
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
           
      
	twos_comp_inst : twos_comp
	port map (
        i_bin => current_val,
        o_sign => sign,
        o_hund => hund,
        o_tens => tens,
        o_ones => ones
    );
           
  sign_digit <= x"A" when sign = '1' else x"F";               
  tdm4_inst : TDM4
        port map (
           i_clk => clk,
           i_reset	=> btnU,
           i_D3  => sign_digit,
		   i_D2 	=> hund,
		   i_D1 	=> tens,
		   i_D0 	=> ones,
		   o_data	=> mux_digit,
		   o_sel	=> an_tdm
	);

    sevenseg_decoder_inst : sevenseg_decoder
    port map (
        i_hex    => mux_digit,
	    o_seg_n  => seg_real
    );
    
    seg <= seg_real;
    
 
   
	
	-- CONCURRENT STATEMENTS ----------------------------
	led (3 downto 0) <= cycle;
	led(15 downto 12) <= flags;
	led(11 downto 4) <= (others => '0');
	
	
end top_basys3_arch;
