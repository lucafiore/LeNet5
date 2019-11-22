-- Master CU

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


ENTITY clock_gating IS
PORT(    
		CLK       : IN STD_LOGIC;
      EN        : IN STD_LOGIC;
		GCLK	    : OUT STD_LOGIC);		
END clock_gating;

ARCHITECTURE structural OF clock_gating IS

COMPONENT latch_n IS
-- Gated D latch
PORT
 (		data_in: IN STD_LOGIC;
		LATCH_ENABLE : IN STD_LOGIC;
		data_out  : OUT STD_LOGIC);
END COMPONENT latch_n;

SIGNAL out_latch : STD_LOGIC;
  
BEGIN

Latch: latch_n 
			PORT MAP( EN, CLK, out_latch );
			
GCLK <= out_latch AND CLK;

END structural;