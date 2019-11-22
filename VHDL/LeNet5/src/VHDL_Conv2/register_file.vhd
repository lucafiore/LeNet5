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


ENTITY register_file IS
GENERIC(	N: NATURAL:=8; -- parallelism of a single register
	 M: NATURAL:=5; -- number of the registers
	 L: NATURAL:=3 -- parallelism of the address(log2(M))
	 );
    port
    (
    input         : IN  STD_LOGIC_VECTOR(N-1 downto 0);
    W_R          : IN STD_LOGIC;
    ADD       : IN STD_LOGIC_VECTOR(L-1 downto 0);
    CLK           : IN STD_LOGIC;
    output          : OUT STD_LOGIC_VECTOR(N-1 downto 0)
 );
END register_file;



ARCHITECTURE behavioral OF register_file IS
TYPE registerFile IS ARRAY(0 to M-1) OF STD_LOGIC_VECTOR(N-1 downto 0);
SIGNAL registers : registerFile;
BEGIN
  PROCESS(CLK)
  BEGIN
     IF CLK'EVENT AND CLK='1' THEN 
        IF(W_R = '1') THEN
            registers(to_integer(unsigned(ADD))) <= input;
        ELSE
				output <= registers(to_integer(unsigned(ADD)));
		  END IF;
     END IF;
  END PROCESS;
END behavioral;  