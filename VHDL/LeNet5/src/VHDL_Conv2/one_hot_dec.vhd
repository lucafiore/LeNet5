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



ENTITY one_hot_dec IS
  GENERIC( N                    : NATURAL:=25); -- numero di stati
    PORT(	
        ENABLE, RST: IN STD_LOGIC;
        data_out: OUT STD_LOGIC_VECTOR(0 to N-1)
		);
END one_hot_dec;



ARCHITECTURE structural OF one_hot_dec IS
--------------------------------------- COMPONENTS --------------------------------------------

COMPONENT flipflop_rst IS 
PORT( 
        Clock, RST: IN STD_LOGIC;
        input: IN STD_LOGIC;
        output: OUT STD_LOGIC 
        );
END COMPONENT;

------------------------------------SIGNAL------------------------------------------
SIGNAL dato_intermedio: STD_LOGIC_VECTOR(0 TO N); 


BEGIN


One_hot_ff0: flipflop_rst
PORT MAP(Clock=>RST, RST=>ENABLE, input=>'1', output=>dato_intermedio(0));

ff_gen: FOR i IN 1 TO N GENERATE
  One_hot_ff: flipflop_rst
  PORT MAP(Clock=>ENABLE, RST=>RST, input=>dato_intermedio(i-1), output=>dato_intermedio(i));
  data_out(i-1)<=ENABLE AND dato_intermedio(i);
END GENERATE;
  
END structural;
  
