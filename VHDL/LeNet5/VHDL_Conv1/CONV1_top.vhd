
-- CONV1 top file
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
USE ieee.math_real.all;
USE work.all;
USE work.CONV_struct_pkg.all;


ENTITY CONV1_top IS
GENERIC( N_in 				: NATURAL:=32; -- is the width of the input image
			M_in 				: NATURAL:=8;  -- is the parallelism of each pixel
			M_w 	  		 	: NATURAL:=9; -- is the parallelism of weights
			N_w        		: NATURAL:=5;  -- is the width of the weights matrix
			I_w        		: NATURAL:=6;  -- is the number of weights matrices
			N_out 			: NATURAL:=28; -- is the width of the output image
			M_out 			: NATURAL:=9; -- is the parallelism of each element of the output matrix (the same of weights)
			EXTRA_BIT		: NATURAL:=0;
			N_out_max 		: NATURAL:=14); -- to avoid overflow
			
PORT( 	in_row_image1	      : IN STD_LOGIC_VECTOR(N_in*M_in-1 DOWNTO 0); --DATAP
			in_row_image2	      : IN STD_LOGIC_VECTOR(N_in*M_in-1 DOWNTO 0); --DATAP
			CLK, GCLK, RST_n 	   : IN STD_LOGIC; --DATAP e CU
			START_CU_CONV1	      : IN STD_LOGIC; --CU
			out_mac_block        : IN OUTPUT_MAC; --DATAP
			matrix_weights 		: IN matrix_5x5xMw;
			bias_mac       		: IN INPUT_MAC_W;
			SEL_ACC    		 		: OUT STD_LOGIC;
			input_mac_1          : OUT INPUT_MAC_IMG; --DATAP
			input_mac_2          : OUT INPUT_MAC_W; --DATAP
			input_mac_3          : OUT INPUT_MAC_B; --DATAP
			output_layer  			: OUT INPUT_MAC_W;
			DONE, READ_IMG  		: OUT STD_LOGIC;
			EN_CONV_MPY				: OUT array_en;
			EN_CONV_ACC				: OUT array_en;
			EN_REG_OUT 			 	: OUT EN_14X14
			);
END CONV1_top;



ARCHITECTURE structural OF CONV1_top IS
------------------- COMPONENT ----------------------

COMPONENT Conv1_with_CU IS
GENERIC(	N_in 						: NATURAL:=32; -- is the width of the input image
			   M_in 					: NATURAL:=8;  -- is the parallelism of each pixel
			   M_w 					: NATURAL:=10; -- is the parallelism of weights
			   N_w        			: NATURAL:=5;  -- is the width of the weights matrix
			   I_w        			: NATURAL:=6;  -- is the number of weights matrices
			   N_out 				: NATURAL:=28; -- is the width of the output image
			   M_out 				: NATURAL:=10; -- is the parallelism of each element of the output matrix (the same of weights)
			   EXTRA_BIT			: NATURAL:=3); -- to avoid overflow
PORT(	in_row_image1		      : IN STD_LOGIC_VECTOR(N_in*M_in-1 DOWNTO 0); --DATAP
      in_row_image2		      : IN STD_LOGIC_VECTOR(N_in*M_in-1 DOWNTO 0); --DATAP
			CLK, GCLK, RST_n     : IN STD_LOGIC; --DATAP e CU
			START      			   : IN STD_LOGIC; --CU
			
			TC3_PAR, TC3_SHIFT, TC25       : IN STD_LOGIC; 
			TC14_C, TC14_R       : IN STD_LOGIC; 
			cnt_25             	: IN STD_LOGIC_VECTOR(4 DOWNTO 0);
			EN_CNT_25        		: OUT STD_LOGIC;
			EN_CNT_3_PAR         : OUT STD_LOGIC;
			EN_CNT_14_R      		: OUT STD_LOGIC;
			EN_CNT_14_C,EN_CNT_3_SHIFT: OUT STD_LOGIC;
			
			EN_MPY, EN_ACC 		: OUT STD_LOGIC;
			SEL_ACC    		 		: OUT STD_LOGIC;
			
			RST_S						: OUT STD_LOGIC;
			
			out_mac_block        : IN OUTPUT_MAC; --DATAP
			matrix_weights 		: IN matrix_5x5xMw;
			bias_mac       		: IN INPUT_MAC_W;
			input_mac_1          : OUT INPUT_MAC_IMG; --DATAP
			input_mac_2          : OUT INPUT_MAC_W; --DATAP
			input_mac_3          : OUT INPUT_MAC_B; --DATAP
			output_layer  			: OUT INPUT_MAC_W;
			DONE, READ_IMG  		: OUT STD_LOGIC;
			SAVE_OUT_MAX			: OUT STD_LOGIC;
			ENABLE_PREC 			: OUT array_en;
			PREC_RESULT				: OUT STD_LOGIC	
			); 
			
END COMPONENT Conv1_with_CU;

--COMPONENT mac_block IS  
--GENERIC(	N					: NATURAL:=10;
--			   M				 : NATURAL:=3);
--PORT(		in_mpy_1, in_mpy_2		: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
--			in_add_1, in_add_2	: IN STD_LOGIC_VECTOR(2*N+M-1 DOWNTO 0);
--			in_accumulator	      : IN STD_LOGIC_VECTOR(2*N+M-1 DOWNTO 0); -- data to pre-load reg_add
--			CLK, RST 				: IN STD_LOGIC;
--			SEL_MUX_MAC				: IN STD_LOGIC; -- '0' standard, '1' conv1
--			RST_REG_MPY		 		: IN STD_LOGIC;
--			EN_MPY, EN_ACC			: IN STD_LOGIC;
--			SEL_ADD_1, SEL_ADD_2	: IN STD_LOGIC; -- if '0' classic MAC, if '1' add external input
--			SEL_ACC    				: IN STD_LOGIC; -- if '0' load out adder, if '1' load external data
--			C_IN						: IN STD_LOGIC;
--			mpy_reg_out	         : OUT STD_LOGIC_VECTOR(2*N-1 DOWNTO 0);
--			add_reg_out	         : OUT STD_LOGIC_VECTOR(2*N+M-1 DOWNTO 0);
--			out_mac              : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
--END COMPONENT mac_block;


COMPONENT register_nbit IS
GENERIC(	N 					: NATURAL:=160);
PORT(		data_in 			: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			EN, CLK, RST 	: IN STD_LOGIC;
			data_out 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT register_nbit;


-- Counter --

COMPONENT counter_14_c is
generic (n : integer:=10);
port (enable, clk, rst : in std_logic;
		count : out std_logic_vector(natural(ceil(log2(real(n))))-1 downto 0);
		tc : out std_logic);
end COMPONENT counter_14_c;


COMPONENT counter_N is
generic (n : integer:=10);
port (enable, clk, rst : in std_logic;
		count : out std_logic_vector(natural(ceil(log2(real(n))))-1 downto 0);
		tc : out std_logic);
end COMPONENT counter_N;


------------------- SIGNALS -----------------------
SIGNAL RST_S      : STD_LOGIC; 
--SIGNAL RST_n 			 : STD_LOGIC;

SIGNAL EN_CNT_25,EN_CNT_3_PAR,EN_CNT_14_R : STD_LOGIC;
SIGNAL EN_CNT_14_C,EN_CNT_3_SHIFT   		: STD_LOGIC;
SIGNAL cnt_14_C,cnt_14_R,cnt_14_REG_OUT	: STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL cnt_3_s, cnt_3_p 						: STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL cnt_25             						: STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL TC14_C, TC14_R       					:  STD_LOGIC:='0'; 
SIGNAL TC3_SHIFT, TC3_PAR, TC25      		:  STD_LOGIC:='0'; 

SIGNAL EN_MPY, EN_ACC 		 : STD_LOGIC;
--SIGNAL SEL_ACC					 : STD_LOGIC;
--SIGNAL in_row_image1		    :  STD_LOGIC_VECTOR(N_in*M_in-1 DOWNTO 0); -- signal immagine
--SIGNAL in_row_image2		    :  STD_LOGIC_VECTOR(N_in*M_in-1 DOWNTO 0); -- signal immagine

--SIGNAL START_CU_CONV1     :  STD_LOGIC:='0'; 
--SIGNAL READ_IMG		 :  STD_LOGIC:='0'; 
--SIGNAL out_mac_block        :  OUTPUT_MAC; --DATAP
--SIGNAL matrix_weights 		 :  matrix_5x5xMw; -- signal dei pesi 
--SIGNAL bias_mac       		 :  INPUT_MAC_W; -- signal dei bias

--SIGNAL input_mac_1          :  INPUT_MAC_IMG; --DATAP
--SIGNAL input_mac_2          :  INPUT_MAC_W; --DATAP
--SIGNAL input_mac_3          :  INPUT_MAC_B; --DATAP
--SIGNAL output_layer  		 	:  INPUT_MAC_W;
--SIGNAL DONE                 :  STD_LOGIC; 

SIGNAL SAVE_OUT_MAX			 :  STD_LOGIC;
SIGNAL EN_REG_OUT_C,EN_REG_OUT_R : STD_LOGIC_VECTOR(13 DOWNTO 0);

--SIGNAL EN_CONV_MPY, EN_CONV_ACC:  array_en;

SIGNAL ENABLE_PREC			 :  array_en;

SIGNAL PREC_RESULT          :  STD_LOGIC;

----- SIGNAL FOR TESTBENCH
--SIGNAL START_TB, DONE_W_B_FILE, DONE_READ_IN, DONE_W : STD_LOGIC :='0';
--TYPE out_reg_out IS ARRAY(0 TO 5, 13 DOWNTO 0, 13 DOWNTO 0) OF STD_LOGIC_VECTOR(M_w-1 DOWNTO 0);
--SIGNAL out_regs_out : out_reg_out;
--SIGNAL T_CLK : TIME := 20 ns;

BEGIN
----- CIRCUIT
CONV1: Conv1_with_CU
GENERIC MAP(	N_in, -- is the width of the input image
			   M_in,  -- is the parallelism of each pixel
			   M_w, -- is the parallelism of weights
			   N_w,  -- is the width of the weights matrix
			   I_w,  -- is the number of weights matrices
			   N_out, -- is the width of the output image
			   M_out, -- is the parallelism of each element of the output matrix (the same of weights)
			   EXTRA_BIT) -- to avoid overflow
PORT MAP(in_row_image1,
			in_row_image2,
			CLK, GCLK, RST_n,
			START_CU_CONV1,
			TC3_PAR, TC3_SHIFT, TC25,
			TC14_C, TC14_R,
			cnt_25,
			EN_CNT_25,
			EN_CNT_3_PAR,
			EN_CNT_14_R,
			EN_CNT_14_C,EN_CNT_3_SHIFT,
			EN_MPY, EN_ACC,
			SEL_ACC,
			RST_S,
			out_mac_block,
			matrix_weights,
			bias_mac,
			input_mac_1,
			input_mac_2,
			input_mac_3,
			output_layer,
			DONE, READ_IMG,
			SAVE_OUT_MAX, ENABLE_PREC,open); --DATAP


----- CONTATORI


COUNTER14_R: counter_N
			GENERIC MAP  (14)
			PORT MAP     (EN_CNT_14_R, GCLK, RST_S, cnt_14_R, TC14_R);
			
COUNTER14_C: counter_14_c
			GENERIC MAP  (14)
			PORT MAP     (EN_CNT_14_C, GCLK, RST_S, cnt_14_C, TC14_C);
			
COUNTER14_REG_OUT: counter_N
			GENERIC MAP  (14)
			PORT MAP     (SAVE_OUT_MAX, GCLK, RST_S, cnt_14_REG_OUT, open);
			
COUNTER25: counter_N
			GENERIC MAP  (27)
			PORT MAP     (EN_CNT_25, GCLK, RST_S, cnt_25, TC25);
			
COUNTER3_SHIFT: counter_N
			GENERIC MAP  (3)
			PORT MAP     (EN_CNT_3_SHIFT, GCLK, RST_S, cnt_3_s, TC3_SHIFT);

COUNTER3_PARALLEL: counter_N
			GENERIC MAP  (3)
			PORT MAP     (EN_CNT_3_PAR, GCLK, RST_S, cnt_3_p, TC3_PAR);

			
--------- MAC
			
GENERATE_ENABLE_MAC:FOR a IN 0 TO I_w-1 GENERATE
	GEN_4_ELEMENTS:FOR i IN 0 TO 3 GENERATE
	 EN_CONV_MPY(i,a) <= EN_MPY AND ENABLE_PREC(i,a);
	 EN_CONV_ACC(i,a) <= EN_ACC AND ENABLE_PREC(i,a);
	END GENERATE;
END GENERATE;		
	

--GEN_6_MAC:FOR a IN 0 TO I_w-1 GENERATE
--	GEN_4_ELEMENTS:FOR i IN 0 TO 3 GENERATE
--		EN_CONV_MPY(i,a) <= EN_MPY AND ENABLE_PREC(i,a);
--		EN_CONV_ACC(i,a) <= EN_ACC AND ENABLE_PREC(i,a);
--		MAC: mac_block
--			GENERIC MAP(M_w,EXTRA_BIT)
--			PORT MAP(	input_mac_1(i),
--							input_mac_2(a),
--							(OTHERS=>'0'), (OTHERS=>'0'),
--							input_mac_3(a),
--							CLK, RST_S, '1', RST_S,
--							EN_CONV_MPY(i,a), EN_CONV_ACC(i,a),
--							'0', '0',
--							SEL_ACC,
--							'0',
--							open,
--							open,
--							out_mac_block(4*a+i));	
--	
--	END GENERATE;
--END GENERATE;

DECODER_14R: PROCESS(cnt_14_R,SAVE_OUT_MAX)
BEGIN
	IF (SAVE_OUT_MAX='1') THEN
		 EN_REG_OUT_R <= (OTHERS => '0');
		 EN_REG_OUT_R(TO_INTEGER(UNSIGNED(cnt_14_R))) <= '1';
	ELSE 
		EN_REG_OUT_R <= (OTHERS => '0');
	END IF;
END PROCESS;

DECODER_14C: PROCESS(cnt_14_REG_OUT,SAVE_OUT_MAX)
BEGIN
	IF (SAVE_OUT_MAX='1') THEN
		 EN_REG_OUT_C <= (OTHERS => '0');
		 EN_REG_OUT_C(TO_INTEGER(UNSIGNED(cnt_14_REG_OUT))) <= '1';
	ELSE 
		EN_REG_OUT_C <= (OTHERS => '0');
	END IF;
END PROCESS;

-------- OUTPUTS	
GEN_6_OUT_MATRIX:FOR a IN 0 TO I_w-1 GENERATE	
	GEN_BANK_REG1: FOR i IN 0 TO N_out_max-1 GENERATE					  
		GEN_BANK_REG2: FOR j IN 0 TO N_out_max-1 GENERATE		
				EN_REG_OUT(i,j) <=  EN_REG_OUT_C(j) AND EN_REG_OUT_R(i);
		END GENERATE;
	END GENERATE;
END GENERATE;

------- TESTBENCH
--Clock_process: PROCESS
--BEGIN
--	CLK <= '0';
--	WAIT FOR T_CLK/2;
--	CLK <= '1';
--	WAIT FOR T_CLK/2;
--END PROCESS;
--
--Start_reset_process: PROCESS
--BEGIN
--	RST_n <= '0';
--	START_TB <= '0';
--	START <= '0';
--	WAIT FOR 85 ns;
--	RST_n <= '1';
--	START_TB <= '0';
--	START <= '0';
--	WAIT FOR 25 ns;
--	RST_n <= '1';
--	START_TB <= '1';
--	START <= '0';
--	WAIT FOR 10 ns;
--	RST_n <= '1';
--	START_TB <= '0';
--	START <= '0';
--	WAIT FOR 20 ns;
--	RST_n <= '1';
--	START_TB <= '0';
--	START <= '1';
--	WAIT FOR 30 ns;
--	RST_n <= '1';
--	START_TB <= '0';
--	START <= '0';
--	WAIT;
--END PROCESS;
--
--
--Weights_Bias_files: PROCESS(START_TB)
--    FILE w_file: text OPEN read_mode IS "fileWeights.txt"; -- the file
--    FILE b_file: text OPEN read_mode IS "fileBias.txt"; -- the file
--    VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
--    VARIABLE line_buffer_w, line_buffer_b : LINE; -- read buffer
--    VARIABLE read_data_w     : BIT_VECTOR(5*M_w-1 DOWNTO 0); -- The line read from the file
--    VARIABLE read_data_b     : BIT_VECTOR(M_w-1 DOWNTO 0); -- The line read from the file
--
--    BEGIN
--      IF(START_TB='1' AND DONE_W_B_FILE='0') THEN
--          FOR i IN 0 TO 5 LOOP
--            FOR j IN 0 TO 4 LOOP             
--                IF(NOT endfile(w_file)) THEN
--                    readline(w_file, line_buffer_w); -- Reads the next full line from the file
--                    read(line_buffer_w, read_data_w); -- Stores the first bit_n bits from the buffer into the output signal 
--                    matrix_weights(i,j) <= TO_STDLOGICVECTOR(read_data_w);
--                END IF;   
--            END LOOP;
--            
--            IF(NOT endfile(b_file)) THEN
--                  readline(b_file, line_buffer_b); -- Reads the next full line from the file
--                  read(line_buffer_b, read_data_b); -- Stores the first bit_n bits from the buffer into the output signal 
--                  bias_mac(i) <= TO_STDLOGICVECTOR(read_data_b);
--            END IF;
--            
--          END LOOP;
--          DONE_W_B_FILE <= '1';
--      END IF;
--      
--END PROCESS;
--
--Input_files: PROCESS(READ_IMG, CLK)
--    FILE in_file: text OPEN read_mode IS "fileInputs.txt"; -- the file
--    VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
--    VARIABLE line_buffer_in : LINE; -- read buffer
--    VARIABLE read_data_in : BIT_VECTOR(N_in*M_in-1 DOWNTO 0); -- The line read from the file
--
--    BEGIN
--      IF(DONE_W_B_FILE='1' AND READ_IMG='1' AND DONE_READ_IN='0') THEN 
--            IF(CLK'EVENT AND CLK='0') THEN
--				--IF(CLK='1') THEN
--                IF(NOT endfile(in_file)) THEN
--                    readline(in_file, line_buffer_in); -- Reads the next full line from the file
--                    read(line_buffer_in, read_data_in); -- Stores the first bit_n bits from the buffer into the output signal 
--                    in_row_image1 <= TO_STDLOGICVECTOR(read_data_in);
--						  readline(in_file, line_buffer_in); -- Reads the next full line from the file
--                    read(line_buffer_in, read_data_in); -- Stores the first bit_n bits from the buffer into the output signal 
--                    in_row_image2 <= TO_STDLOGICVECTOR(read_data_in);
--                ELSE
--                    DONE_READ_IN<='1';
--                END IF;
--            END IF;
--      END IF;
--END PROCESS;
--
--
--Writing_process: PROCESS(DONE)
--    FILE output_file: text OPEN write_mode IS "fileOutputsVHDL.txt"; -- the file
--    VARIABLE file_status: File_open_status; -- to check wether the file is already open
--    VARIABLE line_buffer: line; -- read buffer
--    VARIABLE write_data: bit_vector(M_out-1 DOWNTO 0); -- The line to write to the file
--
--    BEGIN   
--        IF(DONE='1' AND DONE_W='0') THEN
--              FOR a IN 0 TO 5 LOOP
--                  FOR i IN 0 TO 13 LOOP
--							FOR j IN 0 TO 13 LOOP
--							  write_data := to_bitvector(out_regs_out(a,i,j));    
--							  write(line_buffer, write_data, left , M_out); -- writes the output data to the buffer
--							  writeline(output_file, line_buffer); -- writes the buffer content to the file
--							END LOOP;
--						END LOOP;
--              END LOOP;
--              DONE_W <='1';
--        END IF;     
--END PROCESS;


  
END structural;