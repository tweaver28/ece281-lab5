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

    variable A : signed(7 downto 0);
    variable B : signed(7 downto 0);
    variable R : signed(8 downto 0);
    variable F : std_logic_vector(3 downto 0);


begin

    A := signed(i_A);
    B := signed(i_B);
    F := (others => '0');
    
    F(0) := '0';
    case i_op is
        when "000" => --add
            R := resize(A,9) + resize(B,9);
            if (A(7)=B(7)) and (R(7)/=A(7)) then
                F(0) := '1';
            else
                F(0) := '0';
            end if;
        
        when "001" => --sub
            R := resize(A,9) - resize(B,9);
            if (A(7) /= B(7)) and (R(7) /= A(7)) then
                F(0) := '1';
            else
                F(0) := '0';
            end if;

        
        when "010" => --and
            R := resize(signed(i_A and i_B), 9);
            F(0) := '0';
        
        when "011" => --or
            R := resize(signed(i_A or i_B), 9);
            F(0) := '0';
        
        when others =>
            R := (others => '0');

            
    end case;
    
    F(3) := R(7);
    if R = to_signed(0, 9) then
        F(2) := '1';
    else
        F(2) := '0';
    end if;
    F(1) := R(8); 
    
    

    o_result <= std_logic_vector(R(7 downto 0));
    o_flags <= F;

end process;
end Behavioral;
