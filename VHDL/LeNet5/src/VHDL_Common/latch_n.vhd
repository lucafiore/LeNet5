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

ENTITY latch_n IS
-- Gated D latch
PORT
 (		data_in: IN STD_LOGIC;
		LATCH_ENABLE : IN STD_LOGIC;
		data_out  : OUT STD_LOGIC
 );
END latch_n;

ARCHITECTURE Behavior OF latch_n IS
BEGIN
	PROCESS(data_in, LATCH_ENABLE)
	BEGIN
		IF LATCH_ENABLE = '0' THEN
			data_out<=data_in;
		END IF;
	END PROCESS;
END Behavior;