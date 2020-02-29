-- ReLU --
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

ENTITY relu_conv IS
GENERIC(	N 					: NATURAL:=8);
PORT(	data_in 	 : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			q			 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END relu_conv;

ARCHITECTURE structural OF relu_conv IS

--------- COMPONENTS ---------
COMPONENT mux2to1_nbit IS
GENERIC(	N 					: NATURAL:=8);
PORT(	in_0, in_1 	: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			SEL				    : IN STD_LOGIC;
			q			 		  : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT mux2to1_nbit;

--------- SIGNALS ---------
--SIGNAL zeros : STD_LOGIC_VECTOR(N-1 DOWNTO 0):= (N-1 => '1',OTHERS => '0');
SIGNAL zeros : STD_LOGIC_VECTOR(N-1 DOWNTO 0):= '1' & ( N-2 downto 0 => '0');

--------- BEGIN ---------
BEGIN

Mux_relu: mux2to1_nbit
				GENERIC MAP	(N)
				PORT MAP		(data_in, zeros, data_in(N-1), q);


END structural;