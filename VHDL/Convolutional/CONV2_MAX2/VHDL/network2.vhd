
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


-- pacchetto per definire un nuovo type di dato (per avere interfacce pisnelle)
PACKAGE data_for_mac_pkg2 IS
  CONSTANT M_mpy : NATURAL := 8;
  CONSTANT M_add : NATURAL := 2*M_mpy-1;
  CONSTANT M_w   : NATURAL:=8; -- is the parallelism of weights
  CONSTANT M_in  : NATURAL:=8;
  CONSTANT M_out : NATURAL:=8;
   TYPE input_3_img IS ARRAY(2 DOWNTO 0) OF STD_LOGIC_VECTOR(14*M_mpy-1 DOWNTO 0);
	TYPE input_mac_img IS ARRAY(2 DOWNTO 0) OF STD_LOGIC_VECTOR(M_mpy-1 DOWNTO 0); 
	TYPE input_mac_w IS ARRAY(2 DOWNTO 0, 7 DOWNTO 0) OF STD_LOGIC_VECTOR(M_mpy-1 DOWNTO 0); 
	TYPE input_mac_b IS ARRAY(7 DOWNTO 0) OF STD_LOGIC_VECTOR(M_add-1 DOWNTO 0);
	TYPE input_bias IS ARRAY(7 DOWNTO 0) OF STD_LOGIC_VECTOR(M_mpy-1 DOWNTO 0);
	TYPE output_acc IS ARRAY(0 TO 1, 7 DOWNTO 0) OF STD_LOGIC_VECTOR(M_add-1 DOWNTO 0);
	TYPE output_mac IS ARRAY(2 DOWNTO 0, 7 DOWNTO 0) OF STD_LOGIC_VECTOR(M_mpy-1 DOWNTO 0);
	TYPE output_conv IS ARRAY(7 DOWNTO 0) OF STD_LOGIC_VECTOR(M_mpy-1 DOWNTO 0);
	TYPE matrix_5x5xMw	IS ARRAY(0 TO 2, 0 TO 7, 0 TO 4) OF STD_LOGIC_VECTOR(5*M_w-1 DOWNTO 0); 
	TYPE reg_intermed_8x10x10 IS ARRAY(0 TO 7, 0 TO 9, 0 TO 9) OF STD_LOGIC_VECTOR(M_add-1 DOWNTO 0); 
	
END PACKAGE;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.all;
USE work.data_for_mac_pkg2.all;
USE std.textio.all;
 

-- INFO
-- i MAC devono stare fuori da questo layer (sono in comune con tutti i layer)
ENTITY network2 IS
GENERIC(		N_in 				: NATURAL:=14; -- is the width of the input image
			   M_in 				: NATURAL:=8;  -- is the parallelism of each pixel
			   M_w 	  		 	: NATURAL:=8; -- is the parallelism of weights
			   N_w        		: NATURAL:=5;  -- is the width of the weights matrix
			   --I_w        		: NATURAL:=16;  -- is the number of weights matrices
			   N_out 			: NATURAL:=10; -- is the width of the output image
			   M_out 			: NATURAL:=8; -- is the parallelism of each element of the output matrix (the same of weights)
			   D_in       		: NATURAL:=6; -- is the number of input matrices
				D_w        		: NATURAL:=16;
				EXTRA_BIT		: NATURAL:=0;
				N_out_max 		: NATURAL:=5); -- to avoid overflow
END network2;



ARCHITECTURE structural OF network2 IS
------------------- COMPONENT ----------------------

COMPONENT conv2_with_CU IS
GENERIC(	N_in 						: NATURAL:=14; -- is the width of the 6 input matrixes 
			M_in 						: NATURAL:=9;  -- is the parallelism of each element
			M_w 						: NATURAL:=9; -- is the parallelism of weights
			N_out 					: NATURAL:=10; -- is the width of the output matrix
			M_out 					: NATURAL:=9;
			D_in       				: NATURAL:=6; -- is the number of input matrices
			D_w        				: NATURAL:=16; -- is the number of filters for each input matrix
			EXTRA_BIT				: NATURAL:=0);-- is the parallelism of each element of the 16 output matrixes
PORT(		in_row_image			: IN input_3_img;
			matrix_weights : IN matrix_5x5xMw;
			CLK, RST_A_n   	: IN STD_LOGIC;			
			START           : IN STD_LOGIC;
			TC4, LSB_cnt4, TC5, TC25  : IN STD_LOGIC;
			TC10_c, TC10_r  : IN STD_LOGIC;
			cnt25_in        : IN STD_LOGIC_VECTOR(4 DOWNTO 0); --SEL_MUX: OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
			RST   			 : OUT STD_LOGIC;
			EN_CNT5,
			EN_CNT25,
			EN_CNT10_r,
			EN_CNT10_c,
			EN_CNT4    		 : OUT STD_LOGIC;
			EN_MAX          : OUT STD_LOGIC;
			EN_REG_PARTIAL  : OUT STD_LOGIC; -- questo enable va combinato con i 2 contatori da 10 (800 elemtni da salvares)
			
			EN_MPY			: OUT STD_LOGIC;
			EN_ACC : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			SEL_ADD1, SEL_ACC	: OUT STD_LOGIC;
			partial_res				: IN input_mac_b; 
			bias						: IN input_bias;
			out_mac					: IN output_mac;
			acc_mac					: IN output_acc;
			in_mac_1					: OUT input_mac_img;
			in_mac_2					: OUT input_mac_w;
			in_add_opt_1			: OUT input_mac_b;
			bias_mac					: OUT input_mac_b;
			output_element			: OUT output_conv;
			DONE_CONV, READ_IMG,SEL_IMG : OUT STD_LOGIC);
END COMPONENT conv2_with_CU;

COMPONENT mac_block IS  -- IN -> N-bit, OUT -> (2N+M)-bit (M are extra bits necessary to calculate all the sums with the right parallelism without overflows)
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
END COMPONENT mac_block;

COMPONENT register_nbit IS
GENERIC(	N 					: NATURAL:=160);
PORT(		data_in 			: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			EN, CLK, RST 	: IN STD_LOGIC;
			data_out 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT register_nbit;

COMPONENT mux14to1_nbit IS
GENERIC(	N 					: NATURAL:=8);
PORT(	data_in	: IN STD_LOGIC_VECTOR(14*N-1 DOWNTO 0);
			SEL				: IN STD_LOGIC_VECTOR(3 DOWNTO 0):=(OTHERS=>'0');
			q			 	: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT mux14to1_nbit;

COMPONENT mux2to1_nbit IS
GENERIC(	N 				: NATURAL:=8);
PORT(	in_0, in_1 	: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			SEL				    : IN STD_LOGIC:='0';
			q			 		  : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT mux2to1_nbit;

COMPONENT pooling_layer4 IS
  GENERIC(N                    : NATURAL:=8); -- il numero di volte che si ripete in CONV2
  PORT(	
        clock, RST: IN STD_LOGIC;
		  DATA_READY: IN STD_LOGIC;
        data_in: IN output_conv;
		  DONE_MAX : OUT STD_LOGIC;
        EN_25: OUT STD_LOGIC_VECTOR(24 DOWNTO 0); 
        output: OUT output_conv);
END COMPONENT pooling_layer4;


COMPONENT register_1bit IS
PORT(		data_in 			: IN STD_LOGIC;
			EN, CLK, RST : IN STD_LOGIC;
			data_out 		: OUT STD_LOGIC
	  );
END COMPONENT register_1bit;



------------------- SIGNALS -----------------------
SIGNAL     in_row_image			:  input_3_img;
SIGNAL 	matrix_weights_step1, matrix_weights_step2, matrix_weights_step3, matrix_weights_step4, matrix_weights :  matrix_5x5xMw;
SIGNAL			CLK, RST_A_n   				:  STD_LOGIC;			
SIGNAL			START           				: STD_LOGIC;
SIGNAL			TC4, LSB_cnt4, TC5, TC25  	:  STD_LOGIC;
SIGNAL			TC10_c, TC10_r  : STD_LOGIC;
SIGNAL			cnt4_out        : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL			cnt25_in        : STD_LOGIC_VECTOR(4 DOWNTO 0); --SEL_MUX: OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL			RST_S   			 :  STD_LOGIC;
SIGNAL			EN_CNT5,
					EN_CNT25,
					EN_CNT10_r,
					EN_CNT10_c,
					EN_CNT4    		 :  STD_LOGIC;
SIGNAL			EN_MAX          :  STD_LOGIC;
SIGNAL			EN_REG_PARTIAL  :  STD_LOGIC; -- questo enable va combinato con i 2 contatori da 10 (800 elemtni da salvares)
			
SIGNAL			EN_MPY			:  STD_LOGIC;
SIGNAL			EN_ACC :  STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL			SEL_ADD1,SEL_ACC	:  STD_LOGIC;
SIGNAL			bias						:  input_bias;
SIGNAL			out_mac					:  output_mac;
SIGNAL			in_mac_1					:  input_mac_img;
SIGNAL			in_mac_2					:  input_mac_w;
SIGNAL			in_add_opt_1,partial_res:  input_mac_b;
SIGNAL			in_add_opt_sum			:  input_mac_b;
SIGNAL			bias_mac,acc_mac_0	:  input_mac_b;
SIGNAL			acc_mac					:  output_acc;
SIGNAL			output_element			:  output_conv;
SIGNAL			DONE, DONE_CONV, DONE_MAX, READ_IMG,SEL_IMG :  STD_LOGIC:='0';
TYPE				array6_row_14x14 IS ARRAY(0 TO 5) OF STD_LOGIC_VECTOR(14*14*M_in-1 DOWNTO 0);
TYPE				array6_row IS ARRAY(0 TO 5) OF STD_LOGIC_VECTOR(14*M_in-1 DOWNTO 0);
SIGNAL			row_in					:	array6_row_14x14;
SIGNAL			out_mux_row				:	array6_row;
SIGNAL			SEL_ROW,CNT10R, CNT10C	:  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL			reg_intermed 			: reg_intermed_8x10x10;
SIGNAL			out_max_pool			: output_conv;
SIGNAL			EN_REG_OUT_1,EN_REG_OUT_2	: STD_LOGIC_VECTOR(24 DOWNTO 0);
--SIGNAL			SAVE_OUT_MAX		: STD_LOGIC;
SIGNAL 			CONT25_EN			: STD_LOGIC_VECTOR(24 DOWNTO 0);
SIGNAL 			input_to_fc1		: STD_LOGIC_VECTOR(400*M_w-1 DOWNTO 0);
TYPE		bias_from_file IS ARRAY(0 TO 15) OF STD_LOGIC_VECTOR(M_w-1 DOWNTO 0);
SIGNAL 			bias_memory			: bias_from_file;
TYPE				en_10x10	IS ARRAY(0 TO 9, 0 TO 9) OF STD_LOGIC;	
SIGNAL			EN_REG_INTERM		: en_10x10;
SIGNAL			EN_REG_INTERM_R,EN_REG_INTERM_C	: STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL			MSB_EN				: STD_LOGIC;--_VECTOR(3 DOWNTO 0):=(OTHERS=>'0');
----- SIGNAL FOR TESTBENCH
TYPE out_reg_conv1 IS ARRAY(0 TO 5, 13 DOWNTO 0, 13 DOWNTO 0) OF STD_LOGIC_VECTOR(M_w-1 DOWNTO 0);
SIGNAL out_regs_conv1 : out_reg_conv1;

SIGNAL START_TB, DONE_W_B_FILE, EN_READ_IN, DONE_READ_IN, DONE_W,DONE_2 : STD_LOGIC:='0';
TYPE out_reg_out IS ARRAY(0 TO 7, 9 DOWNTO 0, 9 DOWNTO 0) OF STD_LOGIC_VECTOR(M_w-1 DOWNTO 0); -- partial results out reg
--SIGNAL out_regs_out : out_reg_out;
SIGNAL T_CLK : TIME := 20 ns;

BEGIN
----- CIRCUIT

CIRCUIT: conv2_with_CU
GENERIC MAP(	N_in,M_in,M_w,N_out,M_out,D_in,D_w,EXTRA_BIT)
PORT MAP(	in_row_image,
			matrix_weights,
			CLK, RST_A_n,			
			START,
			TC4, LSB_cnt4, TC5, TC25,
			TC10_c, TC10_r,
			cnt25_in,
			RST_S,
			EN_CNT5,
			EN_CNT25,
			EN_CNT10_r,
			EN_CNT10_c,
			EN_CNT4,
			EN_MAX,
			EN_REG_PARTIAL,
			EN_MPY,
			EN_ACC,
			SEL_ADD1, SEL_ACC,
			partial_res, bias,
			out_mac,
			acc_mac,
			in_mac_1,
			in_mac_2,
			in_add_opt_1,
			bias_mac,
			output_element,
			DONE_CONV, READ_IMG,SEL_IMG);




----- CONTATORI
COUNTER_10: PROCESS(CLK)
VARIABLE CNT10_r, CNT10_c : INTEGER RANGE 0 TO 9;
BEGIN
IF (CLK'EVENT AND CLK='1') THEN
IF (RST_S='1') THEN 	CNT10_r := 0;
							CNT10_c := 0;
ELSE
	IF (EN_CNT10_r='1') THEN 
		IF (CNT10_r=9) THEN
			CNT10_r := 0;
		ELSE
			CNT10_r := CNT10_r + 1;
		END IF;
	END IF;
	
	
	IF (EN_CNT10_c='1') THEN 
		IF (CNT10_c=9) THEN
			CNT10_c := 0;
		ELSE
			CNT10_c := CNT10_c + 1;
		END IF;
	END IF;

END IF;
END IF;
IF (CNT10_r=9) THEN TC10_r <= '1';
ELSE TC10_r <= '0';
END IF;
IF (CNT10_c=9) THEN TC10_c <= '1';
ELSE TC10_c <= '0';
END IF;
CNT10R <= STD_LOGIC_VECTOR(TO_UNSIGNED(CNT10_r,4));
CNT10C <= STD_LOGIC_VECTOR(TO_UNSIGNED(CNT10_c,4));
END PROCESS;

COUNTER_4: PROCESS(CLK)
VARIABLE CNT4 : INTEGER RANGE 0 TO 3;
BEGIN
IF (CLK'EVENT AND CLK='1') THEN
IF (RST_S='1') THEN 	CNT4 := 0;
ELSE
	IF (EN_CNT4='1') THEN 
		IF (CNT4=3) THEN 	CNT4 := 0;
		ELSE CNT4 := CNT4 + 1;
		END IF;
	END IF;
END IF;
END IF;

IF (CNT4=3) THEN TC4 <= '1';
ELSE TC4 <= '0';
END IF;

cnt4_out <= STD_LOGIC_VECTOR(TO_UNSIGNED(CNT4,2));
LSB_cnt4 <= cnt4_out(0);
END PROCESS;


COUNTER_25: PROCESS(CLK)
VARIABLE CNT25 : INTEGER RANGE 0 TO 26;
BEGIN
IF (CLK'EVENT AND CLK='1') THEN
IF (RST_S='1') THEN 	CNT25 := 0;
ELSE
	IF (EN_CNT25='1') THEN 
		IF (CNT25=26) THEN 	CNT25 := 0;
		ELSE CNT25 := CNT25 + 1;
		END IF;
	END IF;
END IF;
END IF;

IF (CNT25=26) THEN TC25 <= '1';
ELSE TC25 <= '0';
END IF;
	
cnt25_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(CNT25,5));

END PROCESS;

COUNTER_5: PROCESS(CLK)
VARIABLE CNT5 : INTEGER RANGE 0 TO 4;
BEGIN
IF (CLK'EVENT AND CLK='1') THEN
IF (RST_S='1') THEN 	CNT5 := 0;
ELSE
	IF (EN_CNT5='1') THEN 
		IF (CNT5=4) THEN 	CNT5 := 0;
		ELSE CNT5 := CNT5 + 1;
		END IF;
	END IF;
END IF;
END IF;

IF (CNT5=4) THEN TC5 <= '1';
ELSE TC5 <= '0';
END IF;
	
END PROCESS;

COUNTER_ROW: PROCESS(CLK)
VARIABLE CNT14 : INTEGER RANGE 0 TO 13;
BEGIN
IF (CLK'EVENT AND CLK='1') THEN
	IF (RST_S='1') THEN 	CNT14 := 0;
	ELSE
		IF (READ_IMG='1') THEN 
			IF (CNT14=13) THEN 	CNT14 := 0;
			ELSE CNT14 := CNT14 + 1;
			END IF;
		END IF;
	--	IF (CNT14=13) THEN TC14 <= '1';
	--	ELSE TC14 <= '0';
	--	END IF;
	END IF;
END IF;
SEL_ROW <= STD_LOGIC_VECTOR(TO_UNSIGNED(CNT14,4));
END PROCESS;

--------- MAC
GEN_8_MACS:FOR i IN 0 TO 7 GENERATE

in_add_opt_sum(i) <= in_add_opt_1(i);

MAC1: mac_block
			GENERIC MAP(M_w,EXTRA_BIT)
			PORT MAP(	in_mac_1(0),
							in_mac_2(0,i),
							in_add_opt_sum(i),(OTHERS=>'0'), 
							bias_mac(i),
							CLK, RST_S,'0','0',
							EN_MPY, EN_ACC(1),
							SEL_ADD1, '0',
							SEL_ACC,
							'0',
							open,
							acc_mac_0(i),
							out_mac(0,i));	
END GENERATE;

GEN_2_IN:FOR a IN 1 TO 2 GENERATE  
	GEN_8_MACS:FOR i IN 0 TO 7 GENERATE
		MAC: mac_block
			GENERIC MAP(M_w,EXTRA_BIT)
			PORT MAP(in_mpy_1=>in_mac_1(a), in_mpy_2=>in_mac_2(a,i), 
			in_add_1=>(OTHERS=>'0'), in_add_2=>(OTHERS=>'0'), 
			in_accumulator=>(OTHERS=>'0'), CLK=>CLK, RST=>RST_S, 
			SEL_MUX_MAC=>'0', RST_REG_MPY=>'0', EN_MPY=>EN_MPY, 
			EN_ACC=>EN_ACC(0), SEL_ADD_1=>'0', SEL_ADD_2=>'0', 
			SEL_ACC=>SEL_ACC, C_IN=>'0', mpy_reg_out=>OPEN, add_reg_out=>acc_mac(a-1,i),
			out_mac=>out_mac(a,i));
	END GENERATE;
END GENERATE;

------- BANCO DI REGISTRI INTERMEDI 10x10x8=800
DECODER_10R: PROCESS(CNT10R,EN_REG_PARTIAL)
BEGIN
	IF (EN_REG_PARTIAL='1') THEN
		 EN_REG_INTERM_R <= (OTHERS => '0');
		 EN_REG_INTERM_R(TO_INTEGER(UNSIGNED(CNT10R))) <= '1';
	ELSE 
		EN_REG_INTERM_R <= (OTHERS => '0');
	END IF;
END PROCESS;

DECODER_10C: PROCESS(CNT10C,EN_REG_PARTIAL)
BEGIN
	IF (EN_REG_PARTIAL='1') THEN
		 EN_REG_INTERM_C <= (OTHERS => '0');
		 EN_REG_INTERM_C(TO_INTEGER(UNSIGNED(CNT10C))) <= '1';
	ELSE 
		EN_REG_INTERM_C <= (OTHERS => '0');
	END IF;
END PROCESS;

GEN_10R : FOR i IN 0 TO 9 GENERATE
	GEN_10C : FOR j IN 0 TO 9 GENERATE
		
		EN_REG_INTERM(i,j) <=  EN_REG_INTERM_C(j) AND EN_REG_INTERM_R(i);

		GEN_8 : FOR a IN 0 TO 7 GENERATE
				
				BANK_INTERM: register_nbit 
				GENERIC MAP(2*M_w-1)
				PORT MAP(	acc_mac_0(a),
								EN_REG_INTERM(i,j), CLK, RST_S,
								reg_intermed(a,i,j)); -- COLLEGARE QUESTA USCITA AI MAC
		END GENERATE;
	END GENERATE;
END GENERATE;

GEN_8 : FOR a IN 0 TO 7 GENERATE				
	partial_res(a) <= reg_intermed(a,TO_INTEGER(UNSIGNED(CNT10R)),TO_INTEGER(UNSIGNED(CNT10C)));
END GENERATE;

-- MAX POOLING out_mac
MAX_POOLING_2: pooling_layer4
		GENERIC MAP(8)
		PORT MAP(	CLK, RST_S,
						EN_MAX,
						output_element,
						DONE_MAX,
						CONT25_EN,
						out_max_pool);
						
-- SAVE_OUT_MAX andrà al one hot encoding
--MSB_EN(0) <= cnt4_out(1);

--GEN_3FF : FOR i IN 0 TO 2 GENERATE

FF_EN: register_1bit
PORT MAP( 	cnt4_out(1),
				EN_MAX, CLK, RST_S,
				MSB_EN);      
--END GENERATE;

GEN_EN_5R : FOR i IN 0 TO 4 GENERATE
		GEN_EN_5C : FOR j IN 0 TO 4 GENERATE
					EN_REG_OUT_1(i*5+j) <= CONT25_EN(24-(i*5+j)) AND NOT(MSB_EN); -- lo zeresimo EN salva nel 400esimo registro
					EN_REG_OUT_2(i*5+j) <= CONT25_EN(24-(i*5+j)) AND MSB_EN;
		END GENERATE;
END GENERATE;

------- BANCO DI REGISTRI USCITA 400
GEN_16 : FOR a IN 0 TO 7 GENERATE
	GEN_5R : FOR i IN 0 TO 4 GENERATE
		GEN_5C : FOR j IN 0 TO 4 GENERATE
				BANK_OUTPUT_STEP2: register_nbit 
				GENERIC MAP(M_w)
				PORT MAP(	out_max_pool(a),
								EN_REG_OUT_1((i*5+j)), CLK, RST_S,
								input_to_fc1( ((i*5+j)*16+a+1)*M_w-1 DOWNTO ((i*5+j)*16+a)*M_w) );
				
				BANK_OUTPUT_STEP4: register_nbit 
				GENERIC MAP(M_w)
				PORT MAP(	out_max_pool(a),
								EN_REG_OUT_2((i*5+j)), CLK, RST_S,
								input_to_fc1(((i*5+j)*16+a+1+8)*M_w-1 DOWNTO ((i*5+j)*16+a+8)*M_w));
		END GENERATE;
	END GENERATE;
END GENERATE;


-- READ_IMG serve per dirmi quando leggere una riga
--INTERFACCIA TRA REGISTRI DI USCITA DEL CONV1 E INGRESSO DEL CONV2, bisogna mettere dei mux 14to1
GEN_6_MUX14: FOR a IN 0 TO 5 GENERATE
		MUX_14TO1 : mux14to1_nbit 
			GENERIC MAP(14*M_in)
			PORT MAP(	row_in(a),
							SEL_ROW,
							out_mux_row(a));
END GENERATE;

GEN_3_MUX2: FOR a IN 0 TO 2 GENERATE
		MUX_2TO1 : mux2to1_nbit 
			GENERIC MAP(M_in*14)
			PORT MAP(	out_mux_row(a),out_mux_row(a+3),
							SEL_IMG,
							in_row_image(a));
END GENERATE;

--- MUX PER SCEGLIERE I WEIGHTS
matrix_weights_sel: PROCESS(cnt4_out,matrix_weights_step1,matrix_weights_step2,matrix_weights_step3,matrix_weights_step4)
BEGIN
	CASE cnt4_out IS
		--WHEN "00" => matrix_weights <= matrix_weights_step1;
		WHEN "01" => matrix_weights <= matrix_weights_step2;
		WHEN "10" => matrix_weights <= matrix_weights_step3;
		WHEN "11" => matrix_weights <= matrix_weights_step4;
		WHEN OTHERS => matrix_weights <= matrix_weights_step1;
	END CASE;
END PROCESS;

--- MUX PER SCEGLIERE I BIAS
GEN_8_MUX2: FOR a IN 0 TO 7 GENERATE
		MUX_2TO1 : mux2to1_nbit 
			GENERIC MAP(M_w)
			PORT MAP(	bias_memory(a),bias_memory(a+8),
							cnt4_out(1),
							bias(a));
END GENERATE;

-------- OUTPUTS	
--DONE <= DONE_CONV AND DONE_MAX;-- questo si puo anche levare tanto appena finisce il conv2 puo gia iniziare il fc1 e dopo 2 clk viene salvato l'ultimo dato del max pooling

------- TESTBENCH
Clock_process: PROCESS
BEGIN
	CLK <= '0';
	WAIT FOR T_CLK/2;
	CLK <= '1';
	WAIT FOR T_CLK/2;
END PROCESS;

Start_reset_process: PROCESS
BEGIN
	RST_A_n <= '0';
	START_TB <= '0';
	START <= '0';
	WAIT FOR 85 ns;
	RST_A_n <= '1';
	START_TB <= '0';
	START <= '0';
	WAIT FOR 25 ns;
	RST_A_n <= '1';
	START_TB <= '1';
	START <= '0';
	WAIT FOR 10 ns;
	RST_A_n <= '1';
	START_TB <= '0';
	START <= '0';
	WAIT FOR 20 ns;
	RST_A_n <= '1';
	START_TB <= '0';
	START <= '1';
	WAIT FOR 30 ns;
	RST_A_n <= '1';
	START_TB <= '0';
	START <= '0';
	WAIT;
END PROCESS;

Weights_Bias_files: PROCESS(START_TB)
    FILE w_file: text OPEN read_mode IS "../MATLAB_script/fileWeights_conv2.txt"; -- the file
    FILE b_file: text OPEN read_mode IS "../MATLAB_script/fileBias_conv2.txt"; -- the file
    --VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
    VARIABLE line_buffer_w, line_buffer_b : LINE; -- read buffer
    VARIABLE read_data_w     : BIT_VECTOR(5*M_w-1 DOWNTO 0); -- The line read from the file
    VARIABLE read_data_b     : BIT_VECTOR(M_w-1 DOWNTO 0); -- The line read from the file
	 
	 FILE in_file: text OPEN read_mode IS "../MATLAB_script/fileInputs_conv2.txt"; -- the file
	 --FILE in_file: text OPEN read_mode IS "outputs_prova.txt"; -- the file
    VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
    VARIABLE line_buffer_in : LINE; -- read buffer
    VARIABLE read_data_in : BIT_VECTOR(M_in-1 DOWNTO 0); -- The line read from the file
	 VARIABLE read_input		: STD_LOGIC_VECTOR(M_w-1 DOWNTO 0);

    BEGIN
      IF(START_TB='1' AND DONE_W_B_FILE='0') THEN
		-- LETTURA FILE DI INPUT PER SIMULARE I REGISTRI DI USCITA DEL CONV1
			FOR a IN 0 TO 5 LOOP	
				FOR i IN 0 TO 13 LOOP					  
					FOR j IN 0 TO 13 LOOP
						IF(NOT endfile(in_file)) THEN
							readline(in_file, line_buffer_in);
							read(line_buffer_in, read_data_in);
							read_input := TO_STDLOGICVECTOR(read_data_in);
							out_regs_conv1(a,i,j) <= read_input;
							row_in(a)((14*(14-i)-j)*M_in-1 DOWNTO (14*(14-i)-j-1)*M_in) <= read_input;
						END IF;
					END LOOP;
				END LOOP;
			END LOOP;
			
			file_close(in_file);
		
            FOR i IN 0 TO 2 LOOP
					FOR j IN 0 TO 7 LOOP
						FOR k IN 0 TO 4 LOOP
							IF(NOT endfile(w_file)) THEN
								readline(w_file, line_buffer_w); -- Reads the next full line from the file
								read(line_buffer_w, read_data_w); -- Stores the first bit_n bits from the buffer into the output signal 
								matrix_weights_step1(i,j,k) <= TO_STDLOGICVECTOR(read_data_w);
							END IF;   
						END LOOP;
					END LOOP;
				END LOOP;
				
				FOR i IN 0 TO 2 LOOP
					FOR j IN 0 TO 7 LOOP
						FOR k IN 0 TO 4 LOOP
							IF(NOT endfile(w_file)) THEN
								readline(w_file, line_buffer_w); -- Reads the next full line from the file
								read(line_buffer_w, read_data_w); -- Stores the first bit_n bits from the buffer into the output signal 
								matrix_weights_step2(i,j,k) <= TO_STDLOGICVECTOR(read_data_w);
							END IF;   
						END LOOP;
					END LOOP;
				END LOOP;
				
				FOR i IN 0 TO 2 LOOP
					FOR j IN 0 TO 7 LOOP
						FOR k IN 0 TO 4 LOOP
							IF(NOT endfile(w_file)) THEN
								readline(w_file, line_buffer_w); -- Reads the next full line from the file
								read(line_buffer_w, read_data_w); -- Stores the first bit_n bits from the buffer into the output signal 
								matrix_weights_step3(i,j,k) <= TO_STDLOGICVECTOR(read_data_w);
							ELSE
							END IF;   
						END LOOP;
					END LOOP;
				END LOOP;
				
				FOR i IN 0 TO 2 LOOP
					FOR j IN 0 TO 7 LOOP
						FOR k IN 0 TO 4 LOOP
							IF(NOT endfile(w_file)) THEN
								readline(w_file, line_buffer_w); -- Reads the next full line from the file
								read(line_buffer_w, read_data_w); -- Stores the first bit_n bits from the buffer into the output signal 
								matrix_weights_step4(i,j,k) <= TO_STDLOGICVECTOR(read_data_w);
							END IF;
						END LOOP;
					END LOOP;
				END LOOP;
				file_close(w_file);
				
          FOR i IN 0 TO 15 LOOP
            IF(NOT endfile(b_file)) THEN
                  readline(b_file, line_buffer_b); -- Reads the next full line from the file
                  read(line_buffer_b, read_data_b); -- Stores the first bit_n bits from the buffer into the output signal 
                  bias_memory(i) <= TO_STDLOGICVECTOR(read_data_b);
            END IF;    
          END LOOP;
			 file_close(b_file);
			 DONE_W_B_FILE<='1';
      END IF;
END PROCESS;


--Input_files: PROCESS(READ_IMG, CLK)
--    FILE in_file: text OPEN read_mode IS "fileInputs.txt"; -- the file
--    VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
--    VARIABLE line_buffer_in : LINE; -- read buffer
--    VARIABLE read_data_in : BIT_VECTOR(N_in*M_in-1 DOWNTO 0); -- The line read from the file
--
--    BEGIN
--      IF(DONE_W_B_FILE='1' AND READ_IMG='1' AND DONE_READ_IN='0') THEN -- devo fare in modo di aspettare il tempo necessario per far fare 32 shift e poi caricare la nuova riga
--            IF(CLK'EVENT AND CLK='1') THEN
--                IF(NOT endfile(in_file)) THEN
--                    readline(in_file, line_buffer_in); -- Reads the next full line from the file
--                    read(line_buffer_in, read_data_in); -- Stores the first bit_n bits from the buffer into the output signal 
--                    in_row_image(0) <= TO_STDLOGICVECTOR(read_data_in);
--						  readline(in_file, line_buffer_in); -- Reads the next full line from the file
--                    read(line_buffer_in, read_data_in); -- Stores the first bit_n bits from the buffer into the output signal 
--                    in_row_image(1) <= TO_STDLOGICVECTOR(read_data_in);
--						  readline(in_file, line_buffer_in); -- Reads the next full line from the file
--                    read(line_buffer_in, read_data_in); -- Stores the first bit_n bits from the buffer into the output signal 
--                    in_row_image(2) <= TO_STDLOGICVECTOR(read_data_in);
--                ELSE
--                    DONE_READ_IN<='1';
--                END IF;
--            END IF;
--      END IF;
--END PROCESS;


Writing_process: PROCESS(DONE_CONV, DONE,DONE_MAX)
    FILE output_file: text OPEN write_mode IS "../MATLAB_script/fileOutputsVHDL_conv2.txt"; -- the file
    VARIABLE file_status: File_open_status; -- to check wether the file is already open
    VARIABLE line_buffer: line; -- read buffer
    VARIABLE write_data: bit_vector(M_out-1 DOWNTO 0); -- The line to write to the file

    BEGIN   

			IF (DONE_CONV='1') THEN DONE <= '1';
			END IF;
			IF (DONE_MAX='1' AND DONE='1') THEN DONE_2 <= '1';
			END IF;
        IF(DONE_2='1' AND DONE_W='0' AND DONE='1') THEN
				  FOR i IN 0 TO 4 LOOP
						FOR j IN 0 TO 4 LOOP
							FOR a IN 0 TO 15 LOOP
							  write_data := to_bitvector(input_to_fc1( ((i*5+j)*16+a+1)*M_w-1 DOWNTO ((i*5+j)*16+a)*M_w ));
							  write(line_buffer, write_data, left , M_out); -- writes the output data to the buffer
							  writeline(output_file, line_buffer); -- writes the buffer content to the file
							END LOOP;
						END LOOP;
              END LOOP;
              DONE_W <='1';
        END IF;     
END PROCESS;


  
END structural;