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


ENTITY shift_reg_14xNbit IS
GENERIC(N : NATURAL:=8);
PORT(		parallel_in		: IN STD_LOGIC_VECTOR(14*N-1 DOWNTO 0); -- 
			serial_in		: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			EN, CLK, RST  : IN STD_LOGIC;
			EN_SHIFT			: IN STD_LOGIC; -- if '0' -> shift, if '1' -> parallel load (it's the selector of mux)
			parallel_out	: OUT STD_LOGIC_VECTOR(14*N-1 DOWNTO 0);
			serial_out 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END shift_reg_14xNbit;

ARCHITECTURE behavior OF shift_reg_14xNbit IS

--------- COMPONENTS ---------
COMPONENT register_nbit IS
GENERIC(	N 					: NATURAL:=8);
PORT(		data_in 			: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			EN, CLK, RST   : IN STD_LOGIC;
			data_out 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT register_nbit;

COMPONENT mux2to1_nbit IS
GENERIC(	N 					: NATURAL:=8);
PORT(		in_0, in_1 		: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			SEL				: IN STD_LOGIC;
			q			 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT mux2to1_nbit;

--------- SIGNALS ---------
TYPE array_std_logic_vector IS ARRAY(13 DOWNTO 0) OF STD_LOGIC_VECTOR(N-1 DOWNTO 0); 
SIGNAL out_mux : array_std_logic_vector; -- output of each mux between 2 registers
SIGNAL out_reg : array_std_logic_vector; -- output of each register


--------- BEGIN ---------
BEGIN

-- first mux from right
Mux_shreg0 : mux2to1_nbit 
				GENERIC MAP (N)
				PORT MAP 	(serial_in, parallel_in(N-1 DOWNTO 0), EN_SHIFT, out_mux(0));

-- from second to last mux		
GEN_MUX: 
   FOR i IN 1 TO 13 GENERATE
      Mux_shreg : mux2to1_nbit 
				GENERIC MAP (N)
				PORT MAP 	(out_reg(i-1), parallel_in((1+i)*N-1 DOWNTO (i)*N), EN_SHIFT, out_mux(i));
END GENERATE GEN_MUX;

-- all registers
GEN_SHIFT_REG: 
   FOR i IN 0 TO 13 GENERATE
      Reg_shreg : register_nbit 
				GENERIC MAP (N)
				PORT MAP 	(out_mux(i), EN, CLK, RST, out_reg(i));
END GENERATE GEN_SHIFT_REG;


--------- OUTPUT ---------
CONCATENATION_PARALLEL_OUT: PROCESS(out_reg)
BEGIN
	FOR i IN 0 TO 13 LOOP
		parallel_out((14-i)*N-1 DOWNTO (13-i)*N) <= out_reg(13-i);
	END LOOP;
END PROCESS;

serial_out <= out_reg(13);

END behavior;