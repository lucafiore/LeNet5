-- Generic Mux M to 1
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

ENTITY muxMto1_nbit IS
GENERIC(P   : NATURAL:=4;  -- Parallelism of input
        M   : NATURAL:=4; -- Number of input elements
        S   : NATURAL:=2);  -- Parallelism of selector ( ceil(log2(M)) )
PORT(	data_in   : IN STD_LOGIC_VECTOR(M*P-1 DOWNTO 0);
			SEL				  : IN STD_LOGIC_VECTOR(S-1 DOWNTO 0):= (OTHERS => '0');
			q			 		: OUT STD_LOGIC_VECTOR(P-1 DOWNTO 0));
END muxMto1_nbit;

ARCHITECTURE behavior OF muxMto1_nbit IS
BEGIN


PROCESS(SEL,data_in)
BEGIN
	IF (TO_INTEGER(UNSIGNED(SEL))> M) THEN
		q <= (OTHERS=>'0');
	ELSE
		q <= data_in((TO_INTEGER(UNSIGNED(SEL))+1)*P-1 DOWNTO TO_INTEGER(UNSIGNED(SEL))*P);
	END IF;
END PROCESS;

END behavior;