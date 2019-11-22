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

ENTITY shift_reg_5x14xNbit IS
GENERIC(N : NATURAL := 8); 
PORT(		parallel_in		: IN STD_LOGIC_VECTOR(14*N-1 DOWNTO 0);
			serial_in		: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			EN : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			CLK, RST   : IN STD_LOGIC;
			EN_SHIFT			: IN STD_LOGIC; -- if '0' -> shift, if '1' -> parallel load (it's the selector of mux)
			matrix_out_0	: OUT STD_LOGIC_VECTOR(5*N-1 DOWNTO 0);
			matrix_out_1	: OUT STD_LOGIC_VECTOR(5*N-1 DOWNTO 0);
			matrix_out_2	: OUT STD_LOGIC_VECTOR(5*N-1 DOWNTO 0);
			matrix_out_3	: OUT STD_LOGIC_VECTOR(5*N-1 DOWNTO 0);
			matrix_out_4	: OUT STD_LOGIC_VECTOR(5*N-1 DOWNTO 0));
END shift_reg_5x14xNbit;

ARCHITECTURE behavior OF shift_reg_5x14xNbit IS
--------- COMPONENTS ---------
COMPONENT shift_reg_14xNbit IS
GENERIC(N : NATURAL:=8);
PORT(		parallel_in		: IN STD_LOGIC_VECTOR(14*N-1 DOWNTO 0); -- 
			serial_in		: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			EN, CLK, RST  : IN STD_LOGIC;
			EN_SHIFT			: IN STD_LOGIC; -- if '0' -> shift, if '1' -> parallel load (it's the selector of mux)
			parallel_out	: OUT STD_LOGIC_VECTOR(14*N-1 DOWNTO 0);
			serial_out 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT shift_reg_14xNbit;

--------- SIGNALS ---------
TYPE matrix_5x14	IS ARRAY(5 DOWNTO 0) OF STD_LOGIC_VECTOR(14*N-1 DOWNTO 0);
TYPE array_18bit	IS ARRAY(5 DOWNTO 0) OF STD_LOGIC_VECTOR(N-1 DOWNTO 0);
SIGNAL out_sh_regs 			: matrix_5x14;
SIGNAL 	out_serial_shreg	: array_18bit;

--------- BEGIN ---------
BEGIN

out_sh_regs(5) <= parallel_in;
out_serial_shreg(5) <= serial_in;

-- generation of 5x32 shift registers 8 bit
Sh_reg : shift_reg_14xNbit
				GENERIC MAP(N)
				PORT MAP(	out_sh_regs(5), 
								out_serial_shreg(5), 
								EN(1), CLK, RST, EN_SHIFT, 
								out_sh_regs(4), 
								out_serial_shreg(4));
								
GEN_SHIFT_REG: 
	FOR i IN 3 DOWNTO 0 GENERATE
		Sh_reg : shift_reg_14xNbit
				GENERIC MAP(N)
				PORT MAP(	out_sh_regs(i+1), 
								out_serial_shreg(i+1), 
								EN(0), CLK, RST, EN_SHIFT, 
								out_sh_regs(i), 
								out_serial_shreg(i));
END GENERATE GEN_SHIFT_REG;

--------- OUTPUT ---------
matrix_out_0 <= out_sh_regs(0)(14*N-1 DOWNTO 9*N);
matrix_out_1 <= out_sh_regs(1)(14*N-1 DOWNTO 9*N);
matrix_out_2 <= out_sh_regs(2)(14*N-1 DOWNTO 9*N);
matrix_out_3 <= out_sh_regs(3)(14*N-1 DOWNTO 9*N);
matrix_out_4 <= out_sh_regs(4)(14*N-1 DOWNTO 9*N);			


END behavior;