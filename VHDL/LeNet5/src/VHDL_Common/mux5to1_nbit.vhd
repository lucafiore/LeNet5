-- Generic Mux 5 to 1
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

ENTITY mux5to1_nbit IS
GENERIC(P   : NATURAL:=8;  -- Parallelism of input
        --M   : NATURAL:=4; -- Number of input elements
        S   : NATURAL:=3);  -- Parallelism of selector ( ceil(log2(M)) )
PORT(	data_in_1   : IN STD_LOGIC_VECTOR(P-1 DOWNTO 0);
		data_in_2   : IN STD_LOGIC_VECTOR(P-1 DOWNTO 0);
		data_in_3   : IN STD_LOGIC_VECTOR(P-1 DOWNTO 0);
		data_in_4   : IN STD_LOGIC_VECTOR(P-1 DOWNTO 0);
		data_in_5   : IN STD_LOGIC_VECTOR(P-1 DOWNTO 0);
		
		SEL			: IN STD_LOGIC_VECTOR(S-1 DOWNTO 0):= (OTHERS => '0');
		q		 		: OUT STD_LOGIC_VECTOR(P-1 DOWNTO 0));
END mux5to1_nbit;

ARCHITECTURE behavior OF mux5to1_nbit IS
BEGIN


PROCESS(SEL,data_in_1,data_in_2,data_in_3,data_in_4,data_in_5)
BEGIN
		CASE TO_INTEGER(UNSIGNED(SEL)) IS
			WHEN 0 => q <= data_in_1;
			WHEN 1 => q <= data_in_2;
			WHEN 2 => q <= data_in_3;
			WHEN 3 => q <= data_in_4;
			WHEN 4 => q <= data_in_5;
			WHEN OTHERS => q <= (OTHERS => '0');  
		END CASE;
END PROCESS;

END behavior;