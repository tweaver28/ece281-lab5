----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;v
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

begin

process(i_A,i_B,i_op)

    variable A_u : unsigned(7 downto 0);
    variable B_u : unsigned(7 downto 0);
    variable R_u : unsigned(8 downto 0);
    variable A_s : signed(7 downto 0);
    variable B_s : signed(7 downto 0);
    variable R_s : signed(8 downto 0);
    variable F : std_logic_vector(3 downto 0);


begin

    A_s := signed(i_A);
    B_s := signed(i_B);
    A_u := unsigned(i_A);
    B_u := unsigned(i_B);
    F := (others => '0');

    case i_op is
        when "000" => --add
            R_u := ('0' & A_u) + ('0' & B_u);
            R_s := resize(A_s,9) + resize(B_s,9);
            F(1) := R_u(8);
            if (A_s(7) = B_s(7)) and (R_s(8) /= A_s(7)) then
                F(0) := '1';
            else
                F(0) := '0';
            end if;
           
        when "001" => --sub
            R_u := ('0' & A_u) - ('0' & B_u);
            R_s := resize(A_s, 9) - resize(B_s, 9);
            if A_u >= B_u then 
                F(1) := '1';
            else
                F(1) := '0';
           end if;
            if (A_s(7) /= B_s(7)) and ((R_u(7) xor A_s(7)) = '1') then
                F(0) := '1';
            else
                F(0) := '0';
            end if;
            

        
        when "010" => --and
            R_u := '0' & (A_u and B_u);
            F(1) := '0';
            F(0) := '0';
        
        when "011" => --or
            R_u := '0' & (A_u or B_u);
            F(1) := '0';
            F(0) := '0';
        
        when others =>
            R_u := (others => '0');
            F := (others => '0');

            
    end case;
    
    F(3) := R_u(7);
    
    if R_u(7 downto 0) = "00000000" then
        F(2) := '1';
    else
        F(2) := '0';
    end if;    

    o_result <= std_logic_vector(R_u(7 downto 0));
    o_flags <= F;

end process;
end Behavioral;
