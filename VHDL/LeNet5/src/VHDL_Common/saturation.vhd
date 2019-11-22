-- Saturation block --
-- high-speed/low-power group
-- Fiore, Neri, Zheng
-- 
-- keyword in MAIUSCOLO (es: STD_LOGIC)
-- dati in minuscolo (es: data_in)
-- segnali di controllo in MAIUSCOLO (es: EN)
-- componenti instanziati con l'iniziale maiuscola (es: Shift_register_1)
-- i segnali attivi bassi con _n finale (es: RST_n)

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;


ENTITY saturation IS
GENERIC(  N : NATURAL := 8);
PORT(     --CARRY_OUT   			: IN STD_LOGIC;
			 data_in     			: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
          in_add_1, in_add_2 	: IN STD_LOGIC; -- are MSB of the two adder operands to detect OVERLFLOW
			 data_out   			: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END saturation;

ARCHITECTURE structural OF saturation IS

SIGNAL OVERFLOW : STD_LOGIC;
SIGNAL SEL_MUX  : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL max, min : STD_LOGIC_VECTOR(N-1 DOWNTO 0);
  
BEGIN

max <= '0' & (N-2 DOWNTO 0 => '1');
min <='1' & (N-2 DOWNTO 0 => '0');

--OVERFLOW <= CARRY_OUT XOR data_in(N-1);
OVERFLOW <= (in_add_1 XOR data_in(N-1)) AND (in_add_1 XNOR in_add_2);
SEL_MUX <= OVERFLOW & data_in(N-1);

-- mux4to1
WITH SEL_MUX SELECT
 data_out <= 	max WHEN "11",
					min WHEN "10",
					data_in WHEN OTHERS; 


END ARCHITECTURE;
  
