-- Generic Mux 5 to 1, 1bit --
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

ENTITY mux5to1_1bit IS
GENERIC(S   : NATURAL:=3);  -- Parallelism of selector ( ceil(log2(M)) )
PORT(	data_in_1   : IN STD_LOGIC;
		data_in_2   : IN STD_LOGIC;
		data_in_3   : IN STD_LOGIC;
		data_in_4   : IN STD_LOGIC;
		data_in_5   : IN STD_LOGIC;
		
		SEL			: IN STD_LOGIC_VECTOR(S-1 DOWNTO 0):= (OTHERS => '0');
		q		 		: OUT STD_LOGIC);
END mux5to1_1bit;

ARCHITECTURE behavior OF mux5to1_1bit IS
BEGIN


PROCESS(SEL,data_in_1,data_in_2,data_in_3,data_in_4,data_in_5)
BEGIN
		CASE TO_INTEGER(UNSIGNED(SEL)) IS
			WHEN 0 => q <= data_in_1;
			WHEN 1 => q <= data_in_2;
			WHEN 2 => q <= data_in_3;
			WHEN 3 => q <= data_in_4;
			WHEN 4 => q <= data_in_5;
			WHEN OTHERS => q <= '0';  
		END CASE;
END PROCESS;

END behavior;