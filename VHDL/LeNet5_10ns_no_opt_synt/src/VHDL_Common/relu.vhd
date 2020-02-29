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

ENTITY relu IS
GENERIC(	N 					: NATURAL:=8);
PORT(	data_in 			: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
      enable    : IN STD_LOGIC;
			q			 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END relu;

ARCHITECTURE behavior OF relu IS

--------- COMPONENTS ---------
COMPONENT mux2to1_nbit IS
GENERIC(	N 					: NATURAL:=8);
PORT(		in_0, in_1 		: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			SEL				: IN STD_LOGIC;
			q			 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT mux2to1_nbit;

--------- SIGNALS ---------
SIGNAL zeros : STD_LOGIC_VECTOR(N-1 DOWNTO 0):= (OTHERS => '0');
SIGNAL SEL: STD_LOGIC;

--------- BEGIN ---------
BEGIN

zeros <= (OTHERS => '0');

SEL <= NOT(data_in(N-1)) and enable;

Mux_relu: mux2to1_nbit
				GENERIC MAP	(N)
				PORT MAP		(zeros, data_in, SEL, q);

END behavior;