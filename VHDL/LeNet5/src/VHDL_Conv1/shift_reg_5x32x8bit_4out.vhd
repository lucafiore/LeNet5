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

ENTITY shift_reg_5x32x8bit_4out IS
GENERIC(  N_in    : NATURAL:=32; -- is the width of the input image
          N_w 				: NATURAL:=5; -- is the width of the weight matrix
			    M 						: NATURAL:=8);  -- is the parallelism of each pixel
PORT(	parallel_in1	: IN STD_LOGIC_VECTOR(N_in*M-1 DOWNTO 0);
      parallel_in2	: IN STD_LOGIC_VECTOR(N_in*M-1 DOWNTO 0);
			EN           : IN STD_LOGIC_VECTOR(1 DOWNTO 0); --1 INPUT REGS, 0 OTHERS REGS
			CLK, RST   : IN STD_LOGIC;
			EN_SHIFT			  : IN STD_LOGIC; -- if '0' -> shift, if '1' -> parallel load (it's the selector of mux)
			matrix_out_1	: OUT STD_LOGIC_VECTOR(N_w*N_w*M-1 DOWNTO 0); -- prima sub_matrix 
			matrix_out_2	: OUT STD_LOGIC_VECTOR(N_w*N_w*M-1 DOWNTO 0);
			matrix_out_3	: OUT STD_LOGIC_VECTOR(N_w*N_w*M-1 DOWNTO 0);
			matrix_out_4	: OUT STD_LOGIC_VECTOR(N_w*N_w*M-1 DOWNTO 0);
			out_precomp1 : OUT STD_LOGIC_VECTOR(N_w*N_w-1 DOWNTO 0);
			out_precomp2 : OUT STD_LOGIC_VECTOR(N_w*N_w-1 DOWNTO 0);
			out_precomp3 : OUT STD_LOGIC_VECTOR(N_w*N_w-1 DOWNTO 0);
			out_precomp4 : OUT STD_LOGIC_VECTOR(N_w*N_w-1 DOWNTO 0)); -- devo prendere i MSB delle 4 submatrix per la precomputation
END shift_reg_5x32x8bit_4out;

ARCHITECTURE structural OF shift_reg_5x32x8bit_4out IS

--------- COMPONENTS ---------
COMPONENT shift_reg_32x8bit_mux IS
GENERIC(  N_in    : NATURAL:=32; -- is the width of the input image
			    M 						: NATURAL:=8);  -- is the parallelism of each pixel
PORT(	parallel_in		  : IN STD_LOGIC_VECTOR(N_in*M-1 DOWNTO 0);
			serial_in_1    : IN STD_LOGIC_VECTOR(M-1 DOWNTO 0);
			serial_in_2    : IN STD_LOGIC_VECTOR(M-1 DOWNTO 0);
			EN, CLK, RST : IN STD_LOGIC;
			EN_SHIFT			    : IN STD_LOGIC; -- if '0' -> shift, if '1' -> parallel load (it's the selector of mux)
			parallel_out	  : OUT STD_LOGIC_VECTOR(N_in*M-1 DOWNTO 0));
END COMPONENT shift_reg_32x8bit_mux;

--------- SIGNALS ---------
TYPE matrix_6x32	 IS ARRAY(6-1 DOWNTO 0) OF STD_LOGIC_VECTOR(N_in*M-1 DOWNTO 0);
TYPE array_8bit	  IS ARRAY(6-1 DOWNTO 0, 1 DOWNTO 0) OF STD_LOGIC_VECTOR(M-1 DOWNTO 0);
SIGNAL out_sh_regs 			  : matrix_6x32;
SIGNAL out_serial_shreg	: array_8bit;

--------- BEGIN ---------
BEGIN
-- generation of 6x32 shift registers 8 bit

								  
Sh_reg_IN_5 : shift_reg_32x8bit_mux -- first (bottom) row of shift_regs
        GENERIC MAP(  N_in, -- is the width of the input image
			                M)  -- is the parallelism of each pixel
				PORT MAP(	parallel_in2, 
								  parallel_in2(M-1 DOWNTO 0),
								  parallel_in2(2*M-1 DOWNTO M), 
								  EN(1), CLK, RST, EN_SHIFT, 
								  out_sh_regs(5));
								
Sh_reg_IN_4 : shift_reg_32x8bit_mux -- second (bottom) row of shift_regs
        GENERIC MAP(  N_in, -- is the width of the input image
			                M)  -- is the parallelism of each pixel
				PORT MAP(	parallel_in1, 
								  parallel_in1(M-1 DOWNTO 0), -- faccio passare lo stesso dato entrato prima così non commutano i bit
								  parallel_in1(2*M-1 DOWNTO M), -- faccio passare lo stesso dato così non commutano i bit
								  EN(1), CLK, RST, EN_SHIFT, 
								  out_sh_regs(4));

GEN_SHIFT_REG: FOR i IN 3 DOWNTO 0 GENERATE
		Sh_reg : shift_reg_32x8bit_mux
				PORT MAP(	out_sh_regs(i+2), 
								  out_sh_regs(i+2)((N_in-1)*M-1 DOWNTO (N_in-2)*M),
								  out_sh_regs(i+2)(N_in*M-1 DOWNTO (N_in-1)*M),
								  EN(0), CLK, RST, EN_SHIFT, 
								  out_sh_regs(i));
END GENERATE GEN_SHIFT_REG;

--------- OUTPUT ---------
GEN_OUT: FOR i IN 0 TO 4 GENERATE
  matrix_out_1(N_w*(N_w-i)*M-1 DOWNTO N_w*(N_w-i-1)*M) <= out_sh_regs(i)((N_in)*M-1 DOWNTO (N_in-N_w)*M); --top-sx
  matrix_out_2(N_w*(N_w-i)*M-1 DOWNTO N_w*(N_w-i-1)*M) <= out_sh_regs(i)((N_in-1)*M-1 DOWNTO (N_in-N_w-1)*M); --top-dx
  matrix_out_3(N_w*(N_w-i)*M-1 DOWNTO N_w*(N_w-i-1)*M) <= out_sh_regs(i+1)((N_in)*M-1 DOWNTO (N_in-N_w)*M); --bot-sx
  matrix_out_4(N_w*(N_w-i)*M-1 DOWNTO N_w*(N_w-i-1)*M) <= out_sh_regs(i+1)((N_in-1)*M-1 DOWNTO (N_in-N_w-1)*M); --bot-dx
  
  GEN_OUT_PREC: FOR j IN 1 TO 5 GENERATE  
    out_precomp1(N_w*(N_w-i)-j) <= out_sh_regs(i)((N_in-j+1-2)*M-1-1); --top-sx --- il -1 finale è perche l'input ha 1 intero e 7 decimali
    out_precomp2(N_w*(N_w-i)-j) <= out_sh_regs(i)((N_in-j-2)*M-1-1); --top-dx
    out_precomp3(N_w*(N_w-i)-j) <= out_sh_regs(i+1)((N_in-j+1-2)*M-1-1); --bot-sx
    out_precomp4(N_w*(N_w-i)-j) <= out_sh_regs(i+1)((N_in-j-2)*M-1-1); --bot-dx
    
  END GENERATE GEN_OUT_PREC;
END GENERATE GEN_OUT;



END structural;