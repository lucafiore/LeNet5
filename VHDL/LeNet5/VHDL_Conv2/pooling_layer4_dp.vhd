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
USE work.all;
USE CONV_struct_pkg.all;



ENTITY pooling_layer4_dp IS
  GENERIC(
		N                    : NATURAL:=8; -- il numero di volte che si ripete in CONV2
      M_in 						: NATURAL:=8;  -- is the parallelism of each element
      M_out 					: NATURAL:=8);-- is the parallelism of each element
  PORT(	 
			clock, SEL, RST_ALL, W_R, CNT5_EN, CNT10_RST, CNT_CLN_EN, REG_C_EN, DATA_READY, R_LE_RST, R_LE_EN: IN STD_LOGIC;
			data_in: IN output_conv_2;
			TC2: OUT STD_LOGIC;
			EVEN, TC10, DONE: OUT STD_LOGIC;
			output: OUT output_conv_2
      );
END pooling_layer4_dp;




ARCHITECTURE structural OF pooling_layer4_dp IS
--------------------------------------- COMPONENTS --------------------------------------------

COMPONENT register_file IS
GENERIC(	N: NATURAL:=M_in; -- parallelism of a single register
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
END COMPONENT;

COMPONENT pooling_comparator IS
  GENERIC(
      M 						: NATURAL:=M_in);-- is the parallelism of each element
  PORT(	
			clock: IN STD_LOGIC;
			R_LE_RST, R_LE_EN: IN STD_LOGIC;
			data1, data2: IN STD_LOGIC_VECTOR(M-1 DOWNTO 0);
			output: OUT STD_LOGIC_VECTOR(M-1 DOWNTO 0)
      );
END COMPONENT;

COMPONENT register_nbit IS
GENERIC(	N 					: NATURAL:=M_in);
PORT(		data_in 			: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			EN, CLK, RST : IN STD_LOGIC;
			data_out 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT;

COMPONENT mux2to1_nbit IS
GENERIC ( N : integer:=M_in);
PORT
 (	in_0, in_1: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
	SEL: IN STD_LOGIC:='0';
	q: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0)
 );
END COMPONENT;

COMPONENT counter IS
GENERIC ( N : NATURAL:=16; -- conta fino a 16
			 M : NATURAL:=4); -- su 4 bit di uscita
PORT(
		Clock,Enable,Reset: IN STD_LOGIC;
		output: OUT STD_LOGIC_VECTOR(M-1 DOWNTO 0)
);
END COMPONENT;



------------------------------------SIGNAL------------------------------------------
SIGNAL reg_a_out, reg_b_out, reg_c_out, mux_a_out, mux_b_out, rf_out, output_in: output_conv_2;
SIGNAL cnt5_out: STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL cnt10_out, cnt_cln_out: STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL TC2_IN, REG_A_EN, REG_B_EN, CNT5_RST: STD_LOGIC;

----------------------------BEGIN--------------------------------------
BEGIN


	
REG_A_EN<=(NOT(TC2_IN)) AND (DATA_READY);
REG_B_EN<=TC2_IN AND (DATA_READY);

GEN_8_MAX_POOLING: FOR i IN 0 TO 7 GENERATE
	Reg_a: register_nbit
	GENERIC MAP(M_in)
	  PORT MAP(data_in=>data_in(i), EN=>REG_A_EN, CLK=>clock, RST=>RST_ALL, data_out=>reg_a_out(i));
	Reg_b: register_nbit
	GENERIC MAP(M_in)
	  PORT MAP(data_in=>data_in(i), EN=>REG_B_EN, CLK=>clock, RST=>RST_ALL, data_out=>reg_b_out(i));
	Reg_c: register_nbit
	GENERIC MAP(M_in)
	  PORT MAP(data_in=>output_in(i), EN=>REG_C_EN, CLK=>clock, RST=>RST_ALL, data_out=>reg_c_out(i));

	Mux_a: mux2to1_nbit
	  PORT MAP(in_0=>reg_a_out(i), in_1=>rf_out(i), SEL=>SEL, q=>mux_a_out(i));
	Mux_b: mux2to1_nbit
	  PORT MAP(in_0=>reg_b_out(i), in_1=>reg_c_out(i), SEL=>SEL, q=>mux_b_out(i));

	pooling_comparator_block: pooling_comparator
	  PORT MAP(clock=>clock, R_LE_RST=>R_LE_RST, R_LE_EN=>R_LE_EN, data1=>mux_a_out(i), data2=>mux_b_out(i), output=>output_in(i));
	  
	Rf: register_file
	  PORT MAP(input=>output_in(i), W_R=>W_R, ADD=>cnt5_out, CLK=>clock, output=>rf_out(i));
END GENERATE GEN_8_MAX_POOLING;


CNT5_RST<=RST_ALL OR (cnt5_out(2) AND (NOT(cnt5_out(1))) AND (NOT(cnt5_out(0))) AND CNT5_EN);
CNT5: counter
GENERIC MAP( 8, 3)
  PORT MAP(Clock=>clock, Enable=>CNT5_EN, Reset=>CNT5_RST, output=>cnt5_out);

CNT10: counter
GENERIC MAP( 16, 4)
  PORT MAP(Clock=>clock, Enable=>DATA_READY, Reset=>CNT10_RST, output=>cnt10_out);
TC10<=cnt10_out(3) AND (NOT(cnt10_out(2))) AND cnt10_out(1) AND (NOT(cnt10_out(0)));
TC2_IN<=cnt10_out(0);

CNT_CLN: counter
GENERIC MAP( 10, 4)
  PORT MAP(Clock=>clock, Enable=>CNT_CLN_EN, Reset=>RST_ALL, output=>cnt_cln_out);
DONE<=cnt_cln_out(3) AND (NOT(cnt_cln_out(2))) AND (NOT(cnt_cln_out(1))) AND cnt_cln_out(0);
EVEN<=cnt_cln_out(0);
  
TC2<=TC2_IN;
output<=output_in;
END structural;
