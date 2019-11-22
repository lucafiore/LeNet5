-- MAC Block --
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
USE ieee.std_logic_unsigned.all;

-- MAC is a multiply and accumulate circuit with 1 MPY and 1 ADDER
-- 2 inputs for MPY (from outside)
-- 4 inputs for ADDER (2 from outside, 2 derived from the circuit), chosen with 2 MUX
-- 2 inputs for the ACCUMULATOR register (1 from outside, 1 derived from the circuit), chosen with 1 MUX
-- ENables are to enable registers
-- SELectors are to select the mux inputs, '0' normal flow, '1' outside inputs
-- outputs are the outputs from the registers
-- subtraction with C_IN=1 and second input already inverted

ENTITY mac_block IS  
GENERIC(	N					: NATURAL:=10;
			   M				 : NATURAL:=3);
PORT(	in_mpy_1, in_mpy_2		: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			in_add_1, in_add_2	: IN STD_LOGIC_VECTOR(2*N+M-2 DOWNTO 0);
			in_accumulator	      : IN STD_LOGIC_VECTOR(2*N+M-2 DOWNTO 0); -- data to pre-load reg_add
			CLK, RST 				: IN STD_LOGIC;
			SEL_MUX_MAC				: IN STD_LOGIC; -- '0' standard, '1' conv1.
			RST_REG_MPY		 		: IN STD_LOGIC;
			EN_MPY, EN_ACC			: IN STD_LOGIC;
			SEL_ADD_1, SEL_ADD_2	: IN STD_LOGIC; -- if '0' classic MAC, if '1' add external input
			SEL_ACC    				: IN STD_LOGIC; -- if '0' load out adder, if '1' load external data
			C_IN						: IN STD_LOGIC;
			mpy_reg_out	         : OUT STD_LOGIC_VECTOR(2*N-2 DOWNTO 0);
			add_reg_out	         : OUT STD_LOGIC_VECTOR(2*N+M-2 DOWNTO 0);
			out_mac              : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END mac_block;

ARCHITECTURE structural OF mac_block IS

--------- COMPONENTS ---------
COMPONENT register_nbit IS
GENERIC(	N 					: NATURAL:=8);
PORT(	data_in 			     : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			EN, CLK, RST 	: IN STD_LOGIC;
			data_out 			    : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT register_nbit;

COMPONENT mux2to1_nbit IS
GENERIC(	N 					: NATURAL:=8);
PORT(	in_0, in_1 : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			SEL					 : IN STD_LOGIC;
			q			 		 : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT mux2to1_nbit;

COMPONENT saturation IS
GENERIC(  N : NATURAL := 8);
PORT(     --CARRY_OUT   			: IN STD_LOGIC;
			 data_in     			: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
          in_add_1, in_add_2 	: IN STD_LOGIC; -- are MSB of the two adder operands to detect OVERLFLOW
			 data_out   			: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT saturation;


--------- SIGNALS ---------
SIGNAL out_mpy 			: STD_LOGIC_VECTOR(2*N-1 DOWNTO 0);
SIGNAL out_reg_mpy 	   : STD_LOGIC_VECTOR(2*N-2 DOWNTO 0);
SIGNAL out_mpy_extended,out_mpy_extended_norm,out_mpy_extended_conv1  : STD_LOGIC_VECTOR(2*N+M-2 DOWNTO 0);
SIGNAL out_mux_1, out_mux_2		: STD_LOGIC_VECTOR(2*N+M-2 DOWNTO 0);

SIGNAL out_add 	               : STD_LOGIC_VECTOR(2*N+M-2 DOWNTO 0);
SIGNAL RSTMPY                 : STD_LOGIC;
SIGNAL out_reg_add, in_reg_add	: STD_LOGIC_VECTOR(2*N+M-2 DOWNTO 0);
SIGNAL out_saturation            : STD_LOGIC_VECTOR(2*N+M-2 DOWNTO 0);



--------- BEGIN ---------
BEGIN
out_mpy <= STD_LOGIC_VECTOR(SIGNED(in_mpy_1)*SIGNED(in_mpy_2));

RSTMPY <= RST_REG_MPY or RST;
Reg_mpy: register_nbit 
				GENERIC MAP	(2*N-1)
				PORT MAP 	(out_mpy(2*N+M-2 DOWNTO 0), EN_MPY, CLK, RSTMPY, out_reg_mpy); -- DELETE MSB OF OUT_MPY


-- out_mpy extended of M bits to avoid overflows
out_mpy_extended_norm(2*N+M-2 DOWNTO M) <= out_reg_mpy;
---- estensione di segno
out_mpy_extended_norm(M-1 DOWNTO 0) <= (others => '0');

-- ESTENSIONE DIVERSA SOLO PER IL CONV1
out_mpy_extended_conv1(2*N+M-2 DOWNTO 2*N+M-5) <= (OTHERS=>out_reg_mpy(2*N-2));
out_mpy_extended_conv1(2*N+M-6 DOWNTO M) <= out_reg_mpy(2*N-2 DOWNTO 4);
out_mpy_extended_conv1(M-1 DOWNTO 0) <= (others => '0');

Mux_LAYER : mux2to1_nbit 
				GENERIC MAP (2*N+M-1)
				PORT MAP 	(out_mpy_extended_norm, out_mpy_extended_conv1, SEL_MUX_MAC, out_mpy_extended);
				
Mux_add_1 : mux2to1_nbit 
				GENERIC MAP (2*N+M-1)
				PORT MAP 	(out_mpy_extended, in_add_1, SEL_ADD_1, out_mux_1);

Mux_add_2 : mux2to1_nbit 
				GENERIC MAP (2*N+M-1)
				PORT MAP 	(out_reg_add, in_add_2, SEL_ADD_2, out_mux_2);

out_add <= STD_LOGIC_VECTOR(SIGNED(out_mux_1) + SIGNED(out_mux_2));

---- SATURATION ---- 
Saturation_block : saturation
        GENERIC MAP (2*N+M-1)
        PORT MAP    (out_add, out_mux_1(2*N+M-2), out_mux_2(2*N+M-2), out_saturation);

--out_saturation <= out_add;

Mux_accumulator : mux2to1_nbit 
				GENERIC MAP (2*N+M-1)
				PORT MAP 	(out_saturation, in_accumulator, SEL_ACC, in_reg_add);
				
Reg_add: register_nbit 
				GENERIC MAP	(2*N+M-1)
				PORT MAP 	(in_reg_add, EN_ACC, CLK, RST, out_reg_add);

--------- OUTPUT ---------

mpy_reg_out <= out_reg_mpy;
add_reg_out <= out_reg_add;

out_mac <= out_reg_add(2*N+M-2 DOWNTO N+M-1);
				
END structural;