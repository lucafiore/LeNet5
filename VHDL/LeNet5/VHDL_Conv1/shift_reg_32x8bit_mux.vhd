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

--------------- VERSION PRECOMPUTATION OPTIMIZED
-- 6 rows x 32 columns (top-left is 0,0   bottom-right is 5,31)
-- outputs for convolutions (0,31) (0,30) (1,31) (1,30)
-- outputs for precomputation are the MSB of the previous outputs, and the MSB of the next 2 columns
-- data shift with a stride of 2 in horizontal, and with a stride of 2 in vertical too

ENTITY shift_reg_32x8bit_mux IS
GENERIC(  N_in    : NATURAL:=32; -- is the width of the input image
			    M 						: NATURAL:=8);  -- is the parallelism of each pixel
PORT(	parallel_in		  : IN STD_LOGIC_VECTOR(N_in*M-1 DOWNTO 0);
			serial_in_1    : IN STD_LOGIC_VECTOR(M-1 DOWNTO 0);
			serial_in_2    : IN STD_LOGIC_VECTOR(M-1 DOWNTO 0);
			EN, CLK, RST   : IN STD_LOGIC;
			EN_SHIFT			: IN STD_LOGIC; -- if '0' -> shift, if '1' -> parallel load (it's the selector of mux)
			parallel_out	  : OUT STD_LOGIC_VECTOR(N_in*M-1 DOWNTO 0));
END shift_reg_32x8bit_mux;

ARCHITECTURE structural OF shift_reg_32x8bit_mux IS

--------- COMPONENTS ---------
COMPONENT register_nbit IS
GENERIC(	N 					: NATURAL:=8);
PORT(	data_in 			    : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			EN, CLK, RST   : IN STD_LOGIC;
			data_out 		    : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT register_nbit;

COMPONENT mux2to1_nbit IS
GENERIC(	N 					: NATURAL:=8);
PORT(	in_0, in_1 	: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			SEL				    : IN STD_LOGIC;
			q			 		  : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT mux2to1_nbit;

--------- SIGNALS ---------
TYPE array_std_logic_vector IS ARRAY(N_in DOWNTO 0) OF STD_LOGIC_VECTOR(M-1 DOWNTO 0); 
SIGNAL out_mux : array_std_logic_vector; -- output of each mux between 2 registers
SIGNAL out_reg : array_std_logic_vector; -- output of each register


--------- BEGIN ---------
BEGIN

-- first 2 mux bottom-dx (0th to 1st)
Mux_shreg0 : mux2to1_nbit 
				GENERIC MAP (M)
				PORT MAP 	(serial_in_1, parallel_in(M-1 DOWNTO 0), EN_SHIFT, out_mux(0));
Mux_shreg1 : mux2to1_nbit 
				GENERIC MAP (M)
				PORT MAP 	(serial_in_2, parallel_in(2*M-1 DOWNTO M), EN_SHIFT, out_mux(1));
	
GEN_MUX: 
   FOR i IN 2 TO 31 GENERATE
      Mux_shreg : mux2to1_nbit 
				GENERIC MAP (M)
				PORT MAP 	(out_reg(i-2), parallel_in((i+1)*M-1 DOWNTO i*M), EN_SHIFT, out_mux(i)); -- nel mux entra o il dato parallelo o l'uscita del registro 4 posizioni prima
END GENERATE GEN_MUX;

-- all registers
GEN_SHIFT_REG: 
   FOR i IN 0 TO 31 GENERATE
      Reg_shreg : register_nbit 
				GENERIC MAP (M)
				PORT MAP 	(out_mux(i), EN, CLK, RST, out_reg(i));
END GENERATE GEN_SHIFT_REG;

--------- OUTPUT ---------
Concatenation:	FOR i IN 0 TO 31 GENERATE
		parallel_out((i+1)*M-1 DOWNTO i*M) <= out_reg(i);
END GENERATE;


END structural;