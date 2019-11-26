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

ENTITY precomputation_conv IS
GENERIC(	N 					 : NATURAL:=25); -- CONSTANT number of elements to evaluate
PORT(		in_1, in_2	    : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0); -- in_1 = ingresso, in_2 = peso
			EN            	 : IN STD_LOGIC;
			EN_OP				 : OUT STD_LOGIC);
END precomputation_conv;

ARCHITECTURE behavior OF precomputation_conv IS
------------ COMPONENTS -------------
----COMPONENT mux2to1_nbit IS
----GENERIC(	N 				: NATURAL:=8);
----PORT(	in_0, in_1 	: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
----		SEL		   : IN STD_LOGIC:='0';
----		q				: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
----END COMPONENT;

COMPONENT full_adder IS
PORT ( x,y,cin: IN STD_LOGIC;
       sum,cout: OUT STD_LOGIC);
END COMPONENT full_adder;

------------ SIGNALS -----------------
----SIGNAL big_positive 		: STD_LOGIC_VECTOR(N-1 DOWNTO 0);
------SIGNAL big_negative 		: STD_LOGIC_VECTOR(N-1 DOWNTO 0);
----SIGNAL small_positive 	: STD_LOGIC_VECTOR(N-1 DOWNTO 0);
----SIGNAL small_negative 	: STD_LOGIC_VECTOR(N-1 DOWNTO 0);
----SIGNAL ones				 	: STD_LOGIC_VECTOR(1 DOWNTO 0):="11";
----
----TYPE	array_of_2 IS ARRAY(N-1 DOWNTO 0) OF STD_LOGIC_VECTOR(1 DOWNTO 0);
----SIGNAL small_num			: array_of_2;
----
----SIGNAL num_type			: array_of_2;
----SIGNAL partial_res		: SIGNED(8 DOWNTO 0);
----
----BEGIN
----ones <= "11";
----
----circuit_gen: FOR i IN 0 TO N-1 GENERATE
----	big_positive(i) <= (in_1(i) AND NOT(in_2(i)));
----	--big_negative(i) <= in_1(i) AND in_2(i);
----	small_positive(i) <= (NOT(in_1(i)) AND NOT(in_2(i)));
----	small_negative(i) <= (NOT(in_1(i)) AND in_2(i));
----	
----	small_num(i) <= small_positive(i) & small_negative(i);
----	
----	mux_num : mux2to1_nbit
----					GENERIC MAP(2)
----					PORT MAP(small_num(i), ones, big_positive(i), num_type(i));
----	
----END GENERATE circuit_gen;
----
----PROCESS(num_type, EN)
----VARIABLE dec_out : INTEGER:=-150;
----BEGIN
----	dec_out := -150; --initial value -150 (see at the end of process)
----	IF (EN='1') THEN
----  	FOR i IN 0 TO N-1 LOOP
----    		IF (num_type(i) = "11") THEN dec_out := dec_out + 9;
----    		ELSIF (num_type(i) = "10") THEN dec_out := dec_out + 7;
----    		ELSIF (num_type(i) = "01") THEN dec_out := dec_out + 4;
----    		END IF;
----  	END LOOP;
----	END IF;
----	
----	partial_res <= TO_SIGNED(dec_out, 9);
----	
----END PROCESS;
----
----EN_OP <= partial_res(8) AND EN; -- if 1 no operation, else yes convolution
----

------------ SIGNALS -----------------
TYPE	array_of_2 IS ARRAY(N-1 DOWNTO 0) OF STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL num_type			: array_of_2;

SIGNAL sum_bit_0 		: STD_LOGIC_VECTOR(10 DOWNTO 0);
SIGNAL c_out_bit_0	: STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL sum_bit_1		: STD_LOGIC_VECTOR(17 DOWNTO 0);
SIGNAL c_out_bit_1	: STD_LOGIC_VECTOR(18 DOWNTO 0);
SIGNAL sum_bit_2		: STD_LOGIC_VECTOR(8 DOWNTO 0);
SIGNAL c_out_bit_2	: STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL sum_bit_3		: STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL c_out_bit_3	: STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL sum_bit_4		: STD_LOGIC_VECTOR(0 DOWNTO 0);
SIGNAL c_out_bit_4	: STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN

circuit_gen: FOR i IN 0 TO N-1 GENERATE
	num_type(i) <= NOT(in_2(i)) & (in_1(i) XOR in_2(i));
END GENERATE circuit_gen;

---- 0 BIT
--strato 1
gen_fa_0bit_1: FOR i IN 0 TO 7 GENERATE
	fa_0bit_strato_1: full_adder
			PORT MAP(	num_type(i*3)(0),
							num_type(i*3+1)(0),
							num_type(i*3+2)(0),
							sum_bit_0(i),
							c_out_bit_0(i));
END GENERATE;
--strato 2
gen_fa_0bit_2: FOR i IN 0 TO 1 GENERATE
	fa_0bit_strato_2: full_adder
			PORT MAP(	sum_bit_0(i*3),
							sum_bit_0(i*3+1),
							sum_bit_0(i*3+2),
							sum_bit_0(8+i),
							c_out_bit_0(8+i));
END GENERATE;
	fa_0bit_strato_2_last: full_adder
			PORT MAP(	sum_bit_0(6),
							sum_bit_0(7),
							num_type(24)(0),
							sum_bit_0(10),
							c_out_bit_0(10));
--strato 3
	c_out_bit_0(11) <= ((sum_bit_0(8) XOR sum_bit_0(9)) AND sum_bit_0(10)) OR (sum_bit_0(8) AND sum_bit_0(9));	
	
---- 1 BIT
--strato 1
gen_fa_1bit_1: FOR i IN 0 TO 11 GENERATE
	fa_1bit_strato_1: full_adder
			PORT MAP(	num_type(i*2)(1),
							num_type(i*2+1)(1),
							c_out_bit_0(i),
							sum_bit_1(i),
							c_out_bit_1(i));
END GENERATE;
--strato 2
gen_fa_1bit_2: FOR i IN 0 TO 3 GENERATE
	fa_1bit_strato_2: full_adder
			PORT MAP(	sum_bit_1(i*3),
							sum_bit_1(i*3+1),
							sum_bit_1(i*3+2),
							sum_bit_1(12+i),
							c_out_bit_1(12+i));
END GENERATE;
--strato 3
	fa_1bit_strato_3: full_adder
			PORT MAP(	sum_bit_1(12),
							sum_bit_1(13),
							sum_bit_1(14),
							sum_bit_1(16),
							c_out_bit_1(16));
							
	fa_1bit_strato_3_last: full_adder
			PORT MAP(	sum_bit_1(15),
							'1', -- questo 1 rappresenta il secondo bit del numero -50
							num_type(24)(1),
							sum_bit_1(17),
							c_out_bit_1(17));
--strato 4
	c_out_bit_1(18) <= (sum_bit_1(16) AND sum_bit_1(17));
	
---- 2 BIT
--strato 1
gen_fa_2bit_1: FOR i IN 0 TO 5 GENERATE
	fa_2bit_strato_1: full_adder
			PORT MAP(	c_out_bit_1(i*3),
							c_out_bit_1(i*3+1),
							c_out_bit_1(i*3+2),
							sum_bit_2(i),
							c_out_bit_2(i));
END GENERATE;
--strato 2
gen_fa_2bit_2: FOR i IN 0 TO 1 GENERATE
	fa_2bit_strato_2: full_adder
			PORT MAP(	sum_bit_2(i*3),
							sum_bit_2(i*3+1),
							sum_bit_2(i*3+2),
							sum_bit_2(6+i),
							c_out_bit_2(6+i));
END GENERATE;
--strato 3
	fa_2bit_strato_3: full_adder
			PORT MAP(	sum_bit_2(6),
							sum_bit_2(7),
							c_out_bit_1(18),
							sum_bit_2(8),
							c_out_bit_2(8));
--strato 4
	c_out_bit_2(9) <= sum_bit_2(8);

---- 3 BIT
--strato 1
gen_fa_3bit_1: FOR i IN 0 TO 2 GENERATE
	fa_3bit_strato_1: full_adder
			PORT MAP(	c_out_bit_2(i*3),
							c_out_bit_2(i*3+1),
							c_out_bit_2(i*3+2),
							sum_bit_3(i),
							c_out_bit_3(i));
END GENERATE;
--strato 2
	fa_3bit_strato_2: full_adder
			PORT MAP(	sum_bit_3(0),
							sum_bit_3(1),
							sum_bit_3(2),
							sum_bit_3(3),
							c_out_bit_3(3));
--strato 3
	c_out_bit_3(4) <= (sum_bit_3(3) OR c_out_bit_2(9));	
	
---- 4 BIT
--strato 1
	fa_4bit_strato_1: full_adder
			PORT MAP(	c_out_bit_3(0),
							c_out_bit_3(1),
							c_out_bit_3(2),
							sum_bit_4(0),
							c_out_bit_4(0));
--strato 2
	c_out_bit_4(1) <= ((c_out_bit_3(3) XOR c_out_bit_3(4)) AND sum_bit_4(0)) OR (c_out_bit_3(3) AND c_out_bit_3(4));	

---- 5-6 BIT
--strato 1
	EN_OP <= NOT(c_out_bit_4(0) AND c_out_bit_4(1)); -- 1=NO_OPERAZIONI, 0=CONVOLUZIONE
END behavior;