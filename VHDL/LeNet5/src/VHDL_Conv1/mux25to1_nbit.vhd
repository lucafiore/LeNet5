-- LeNet5 top file
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

ENTITY mux25to1_nbit IS
GENERIC(	N 					: NATURAL:=8);
PORT(	data_in	: IN STD_LOGIC_VECTOR(25*N-1 DOWNTO 0);
			SEL				: IN STD_LOGIC_VECTOR(4 DOWNTO 0):=(OTHERS=>'0');
			q			 	: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END mux25to1_nbit;

ARCHITECTURE behavior OF mux25to1_nbit IS
BEGIN

PROCESS(SEL, data_in)
BEGIN
	IF (TO_INTEGER(UNSIGNED(SEL))<25) THEN
		q <= data_in((25-TO_INTEGER(UNSIGNED(SEL)))*N-1 DOWNTO ((25-1-TO_INTEGER(UNSIGNED(SEL)))*N));
	ELSE
		q <= (OTHERS=>'0');
	END IF;
END PROCESS;

END behavior;