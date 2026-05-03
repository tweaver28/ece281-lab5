----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( 
           clk : in std_logic;
           i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

signal state : std_logic_vector (3 downto 0) := "0001";



begin

process(clk)

begin

    if rising_edge(clk) then

    if i_reset = '1' then
        state <= "0001";
    
    elsif i_adv = '1' then
        case state is 
            when "0001" => state <= "0010";
            when "0010" => state <= "0100";
            when "0100" => state <= "1000";
            when "1000" => state <= "0001";
            when others => state <= "0001";
        end case;

   end if;
        
   end if;
end process;

o_cycle <= state;

end FSM;
