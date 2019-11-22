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

ENTITY mux2to1_nbit IS
GENERIC(	N 				: NATURAL:=8);
PORT(	in_0, in_1 	: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			SEL				    : IN STD_LOGIC:='0';
			q			 		  : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END mux2to1_nbit;

ARCHITECTURE behavior OF mux2to1_nbit IS
BEGIN
PROCESS(SEL, in_0, in_1)
BEGIN
	IF (SEL='0') THEN
		q <= in_0;
	ELSIF (SEL='1') THEN
		q <= in_1;
	END IF;
END PROCESS;

END behavior;