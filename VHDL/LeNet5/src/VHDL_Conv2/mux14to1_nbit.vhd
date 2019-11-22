-- MUX 14 to 1 Nbit
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

ENTITY mux14to1_nbit IS
GENERIC(	N 					: NATURAL:=8);
PORT(	data_in	: IN STD_LOGIC_VECTOR(14*N-1 DOWNTO 0);
			SEL				: IN STD_LOGIC_VECTOR(3 DOWNTO 0):=(OTHERS=>'0');
			q			 	: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END mux14to1_nbit;

ARCHITECTURE behavior OF mux14to1_nbit IS
BEGIN

PROCESS(SEL, data_in)
BEGIN
	IF (TO_INTEGER(UNSIGNED(SEL))<14) THEN
		q <= data_in((14-TO_INTEGER(UNSIGNED(SEL)))*N-1 DOWNTO ((14-1-TO_INTEGER(UNSIGNED(SEL)))*N));
	ELSE
		q <= (OTHERS=>'0');
	END IF;
END PROCESS;

END behavior;
