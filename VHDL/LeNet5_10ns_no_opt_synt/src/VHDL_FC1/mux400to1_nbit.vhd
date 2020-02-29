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

ENTITY mux400to1_nbit IS
GENERIC(	N 					: NATURAL:=8);
PORT(	data_in	: IN STD_LOGIC_VECTOR(400*N-1 DOWNTO 0);
			SEL				: IN STD_LOGIC_VECTOR(8 DOWNTO 0):=(OTHERS=>'0');
			q			 	: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END mux400to1_nbit;

ARCHITECTURE behavior OF mux400to1_nbit IS

SIGNAL data_invert : STD_LOGIC_VECTOR(400*N-1 DOWNTO 0);

BEGIN

Invert_data_in:  FOR i IN 0 TO 399 GENERATE
	data_invert((1+i)*N-1 DOWNTO i*N) <= data_in((400-i)*N-1 DOWNTO ((400-1-i)*N));
END GENERATE;

PROCESS(SEL, data_in)
BEGIN
	IF (TO_INTEGER(UNSIGNED(SEL))<400) THEN
		--q <= data_in((1+TO_INTEGER(UNSIGNED(SEL)))*N-1 DOWNTO ((TO_INTEGER(UNSIGNED(SEL)))*N));
		q <= data_invert((400-TO_INTEGER(UNSIGNED(SEL)))*N-1 DOWNTO ((400-1-TO_INTEGER(UNSIGNED(SEL)))*N));
	ELSE
		q <= (OTHERS=>'0');
	END IF;
END PROCESS;

END behavior;

