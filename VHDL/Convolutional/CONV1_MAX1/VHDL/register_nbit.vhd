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
USE work.all;
USE work.data_for_mac_pkg.all;

ENTITY register_nbit IS
GENERIC(	N 					: NATURAL:=160);
PORT(		data_in 			: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			EN, CLK, RST 	: IN STD_LOGIC;
			data_out 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END register_nbit;

ARCHITECTURE behavior OF register_nbit IS
BEGIN

PROCESS(CLK)
BEGIN
	IF (CLK'EVENT AND CLK = '1') THEN
		IF RST='1' THEN 
			data_out <= (OTHERS => '0');
		ELSE
			IF EN='1' THEN
				data_out <= data_in;
			ELSIF EN='0' THEN
				NULL;
			END IF;
		END IF;
	ELSE NULL;
	END IF;

END PROCESS;

END behavior;
