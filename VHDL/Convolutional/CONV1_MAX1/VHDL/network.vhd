
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

-- pacchetto per definire un nuovo type di dato (per avere interfacce più snelle)
PACKAGE data_for_mac_pkg IS
  CONSTANT M_mpy : NATURAL := 8;
  CONSTANT M_add : NATURAL := 2*8;
	TYPE input_mac_img IS ARRAY(3 DOWNTO 0) OF STD_LOGIC_VECTOR(M_mpy-1 DOWNTO 0);
	TYPE input_mac_w IS ARRAY(5 DOWNTO 0) OF STD_LOGIC_VECTOR(M_mpy-1 DOWNTO 0);
	TYPE input_mac_b IS ARRAY(5 DOWNTO 0) OF STD_LOGIC_VECTOR(M_add-2 DOWNTO 0);
	TYPE output_mac IS ARRAY(23 DOWNTO 0) OF STD_LOGIC_VECTOR(M_mpy-1 DOWNTO 0);
	TYPE matrix_5x5xMw	IS ARRAY(0 TO 5, 0 TO 4) OF STD_LOGIC_VECTOR(5*M_mpy-1 DOWNTO 0); -- variabile per creare le 6 matrici 5x5 dei pesi
	TYPE EN_14X14 IS ARRAY(13 DOWNTO 0, 13 DOWNTO 0) OF STD_LOGIC; -- QUESTO DEVE ESSERE CAMBIATO NEGLI ALTRI FILE
	TYPE array_en	    IS ARRAY(0 TO 3, 0 TO 5) OF STD_LOGIC;
END PACKAGE;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.all;
USE work.data_for_mac_pkg.all;
USE std.textio.all;



-- INFO
-- i MAC devono stare fuori da questo layer (sono in comune con tutti i layer)
ENTITY network IS
GENERIC(		N_in 				: NATURAL:=32; -- is the width of the input image
			   M_in 				: NATURAL:=8;  -- is the parallelism of each pixel
			   M_w 	  		 	: NATURAL:=8; -- is the parallelism of weights
			   N_w        		: NATURAL:=5;  -- is the width of the weights matrix
			   I_w        		: NATURAL:=6;  -- is the number of weights matrices
			   N_out 			: NATURAL:=28; -- is the width of the output image
			   M_out 			: NATURAL:=8; -- is the parallelism of each element of the output matrix (the same of weights)
			   EXTRA_BIT		: NATURAL:=0;
				N_out_max 		: NATURAL:=14); -- to avoid overflow
END network;



ARCHITECTURE structural OF network IS
------------------- COMPONENT ----------------------

COMPONENT Conv1_with_CU IS
GENERIC(	N_in 						: NATURAL:=32; -- is the width of the input image
			   M_in 						: NATURAL:=8;  -- is the parallelism of each pixel
			   M_w 						 : NATURAL:=10; -- is the parallelism of weights
			   N_w        : NATURAL:=5;  -- is the width of the weights matrix
			   I_w        : NATURAL:=6;  -- is the number of weights matrices
			   N_out 					: NATURAL:=28; -- is the width of the output image
			   M_out 					: NATURAL:=10; -- is the parallelism of each element of the output matrix (the same of weights)
			   EXTRA_BIT		: NATURAL:=3); -- to avoid overflow
PORT(	in_row_image1		      : IN STD_LOGIC_VECTOR(N_in*M_in-1 DOWNTO 0); --DATAP
      in_row_image2		      : IN STD_LOGIC_VECTOR(N_in*M_in-1 DOWNTO 0); --DATAP
			CLK, RST_n 			       : IN STD_LOGIC; --DATAP e CU
			START      			       : IN STD_LOGIC; --CU
			TC3, TC5, TC25       : IN STD_LOGIC; 
			TC28_c, TC28_r       : IN STD_LOGIC; 
			cnt25_in             : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
			EN_CNT25        : OUT STD_LOGIC;
      EN_CNT3         : OUT STD_LOGIC;
      EN_CNT28_r      : OUT STD_LOGIC;
      EN_CNT28_c,EN_CNT5: OUT STD_LOGIC;
			EN_MPY, EN_ACC 		: OUT STD_LOGIC;
			SEL_ACC    		 : OUT STD_LOGIC;
			RST_S						: OUT STD_LOGIC;
			out_mac_block        : IN OUTPUT_MAC; --DATAP
			matrix_weights 		: IN matrix_5x5xMw;
			bias_mac       		: IN INPUT_MAC_W;
			input_mac_1          : OUT INPUT_MAC_IMG; --DATAP
			input_mac_2          : OUT INPUT_MAC_W; --DATAP
			input_mac_3          : OUT INPUT_MAC_B; --DATAP
			output_layer  			: OUT INPUT_MAC_W;
			DONE, READ_IMG  		: OUT STD_LOGIC;
			SAVE_OUT_MAX			: OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
			ENABLE_PREC 			: OUT array_en;
			PREC_RESULT				: OUT STD_LOGIC); --DATAP
END COMPONENT Conv1_with_CU;

COMPONENT mac_block IS  
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


------------------- SIGNALS -----------------------
SIGNAL CLK, RST_S, RST_n 			 : STD_LOGIC;
SIGNAL EN_CNT25,EN_CNT3,EN_CNT28_r,EN_CNT28_c,EN_CNT5   : STD_LOGIC;
SIGNAL CNT28C,CNT28R			 : STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL EN_MPY, EN_ACC 		 : STD_LOGIC;
SIGNAL SEL_ACC					 : STD_LOGIC;
SIGNAL EN_REG_OUT 			 : EN_14X14;
SIGNAL cnt25_in             : STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL in_row_image1		    :  STD_LOGIC_VECTOR(N_in*M_in-1 DOWNTO 0); -- signal immagine
SIGNAL in_row_image2		    :  STD_LOGIC_VECTOR(N_in*M_in-1 DOWNTO 0); -- signal immagine
SIGNAL START, READ_IMG		 :  STD_LOGIC:='0'; --CU
SIGNAL TC3, TC5, TC25       :  STD_LOGIC:='0'; 
SIGNAL TC28_c, TC28_r       :  STD_LOGIC:='0'; 
SIGNAL out_mac_block        :  OUTPUT_MAC; --DATAP
SIGNAL matrix_weights 		 :  matrix_5x5xMw; -- signal dei pesi
SIGNAL bias_mac       		 :  INPUT_MAC_W; -- signal dei bias
SIGNAL input_mac_1          :  INPUT_MAC_IMG; --DATAP
SIGNAL input_mac_2          :  INPUT_MAC_W; --DATAP
SIGNAL input_mac_3          :  INPUT_MAC_B; --DATAP
SIGNAL output_layer  		 :  INPUT_MAC_W;
SIGNAL DONE                 :  STD_LOGIC;
SIGNAL SAVE_OUT_MAX			 :  STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL EN_REG_OUT_C,EN_REG_OUT_R : STD_LOGIC_VECTOR(13 DOWNTO 0);
SIGNAL ENABLE_PREC, EN_CONV_MPY, EN_CONV_ACC:  array_en;
SIGNAL PREC_RESULT          :  STD_LOGIC;
----- SIGNAL FOR TESTBENCH
SIGNAL START_TB, DONE_W_B_FILE, DONE_READ_IN, DONE_W : STD_LOGIC :='0';
TYPE out_reg_out IS ARRAY(0 TO 5, 13 DOWNTO 0, 13 DOWNTO 0) OF STD_LOGIC_VECTOR(M_w-1 DOWNTO 0);
SIGNAL out_regs_out : out_reg_out;
SIGNAL T_CLK : TIME := 20 ns;

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
			CLK, RST_n,
			START,
			TC3, TC5, TC25,
			TC28_c, TC28_r,
			cnt25_in,
			EN_CNT25,
      EN_CNT3,
      EN_CNT28_r,
      EN_CNT28_c,EN_CNT5,
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
			SAVE_OUT_MAX, ENABLE_PREC,PREC_RESULT); --DATAP


----- CONTATORI
COUNTER_28: PROCESS(CLK)
VARIABLE CNT28_r, CNT28_c : INTEGER RANGE 0 TO 27;
BEGIN
IF (CLK'EVENT AND CLK='1') THEN
IF (RST_S='1') THEN 	CNT28_r := 0;
							CNT28_c := 0;
ELSE
	
	IF (EN_CNT28_r='1') THEN 
		IF (CNT28_r=13) THEN 	CNT28_r := 0;
		ELSE CNT28_r := CNT28_r + 1;
		END IF;
	END IF;
	IF (CNT28_r=13) THEN TC28_r <= '1';
	ELSE TC28_r <= '0';
	END IF;
	
	IF (EN_CNT28_c='1') THEN 
		IF (CNT28_c=13) THEN 	CNT28_c := 0;
		ELSE CNT28_c := CNT28_c + 1;
		END IF;
	END IF;
	IF (CNT28_c=12) THEN TC28_c <= '1';
	ELSE TC28_c <= '0';
	END IF;
END IF;
END IF;

--CNT28C <= STD_LOGIC_VECTOR(TO_UNSIGNED(CNT28_c,5));
CNT28R <= STD_LOGIC_VECTOR(TO_UNSIGNED(CNT28_r,5));
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
	IF (CNT25=26) THEN TC25 <= '1';
	ELSE TC25 <= '0';
	END IF;
END IF;
END IF;
cnt25_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(CNT25,5));
END PROCESS;

COUNTER_3: PROCESS(CLK)
VARIABLE CNT3 : INTEGER RANGE 0 TO 2;
BEGIN
IF (CLK'EVENT AND CLK='1') THEN
IF (RST_S='1') THEN 	CNT3 := 0;
ELSE
	IF (EN_CNT3='1') THEN 
		IF (CNT3=2) THEN 	CNT3 := 0;
		ELSE CNT3 := CNT3 + 1;
		END IF;
	END IF;
	IF (CNT3=2) THEN TC3 <= '1';
	ELSE TC3 <= '0';
	END IF;
END IF;
END IF;
END PROCESS;

COUNTER_5: PROCESS(CLK)-- in realta conta fino a 3 
VARIABLE CNT5 : INTEGER RANGE 0 TO 4;
BEGIN
IF (CLK'EVENT AND CLK='1') THEN
IF (RST_S='1') THEN 	CNT5 := 0;
ELSE
	IF (EN_CNT5='1') THEN 
		IF (CNT5=2) THEN 	CNT5 := 0;
		ELSE CNT5 := CNT5 + 1;
		END IF;
	END IF;
	IF (CNT5=2) THEN TC5 <= '1';
	ELSE TC5 <= '0';
	END IF;
END IF;
END IF;
END PROCESS;

COUNTER_14_REG_OUT: PROCESS(CLK)
VARIABLE CNT28_c : INTEGER RANGE 0 TO 13;
BEGIN
IF (CLK'EVENT AND CLK='1') THEN
	IF (RST_S='1') THEN 	CNT28_c := 0;
	ELSE	
		IF (SAVE_OUT_MAX(0)='1') THEN 
			IF (CNT28_c=13) THEN 	CNT28_c := 0;
			ELSE CNT28_c := CNT28_c + 1;
			END IF;
		END IF;
	END IF;
END IF;

CNT28C <= STD_LOGIC_VECTOR(TO_UNSIGNED(CNT28_c,5));
END PROCESS;

--------- MAC

GEN_6_MAC:FOR a IN 0 TO I_w-1 GENERATE
	GEN_4_ELEMENTS:FOR i IN 0 TO 3 GENERATE
		EN_CONV_MPY(i,a) <= EN_MPY AND ENABLE_PREC(i,a);
		EN_CONV_ACC(i,a) <= EN_ACC AND ENABLE_PREC(i,a);
		MAC: mac_block
			GENERIC MAP(M_w,EXTRA_BIT)
			PORT MAP(	input_mac_1(i),
							input_mac_2(a),
							(OTHERS=>'0'), (OTHERS=>'0'),
							input_mac_3(a),
							CLK, RST_S, '1', RST_S,
							EN_CONV_MPY(i,a), EN_CONV_ACC(i,a),
							'0', '0',
							SEL_ACC,
							'0',
							open,
							open,
							out_mac_block(4*a+i));	
	
	END GENERATE;
END GENERATE;

DECODER_14R: PROCESS(CNT28R,SAVE_OUT_MAX(0))
BEGIN
	IF (SAVE_OUT_MAX(0)='1') THEN
		 EN_REG_OUT_R <= (OTHERS => '0');
		 EN_REG_OUT_R(TO_INTEGER(UNSIGNED(CNT28R))) <= '1';
	ELSE 
		EN_REG_OUT_R <= (OTHERS => '0');
	END IF;
END PROCESS;

DECODER_14C: PROCESS(CNT28C,SAVE_OUT_MAX(0))
BEGIN
	IF (SAVE_OUT_MAX(0)='1') THEN
		 EN_REG_OUT_C <= (OTHERS => '0');
		 EN_REG_OUT_C(TO_INTEGER(UNSIGNED(CNT28C))) <= '1';
	ELSE 
		EN_REG_OUT_C <= (OTHERS => '0');
	END IF;
END PROCESS;

-------- OUTPUTS	
GEN_6_OUT_MATRIX:FOR a IN 0 TO I_w-1 GENERATE	
	GEN_BANK_REG1: FOR i IN 0 TO N_out_max-1 GENERATE					  
		GEN_BANK_REG2: FOR j IN 0 TO N_out_max-1 GENERATE		
				EN_REG_OUT(i,j) <=  EN_REG_OUT_C(j) AND EN_REG_OUT_R(i);
			Out_registers: register_nbit
				 GENERIC MAP (M_out)
				 PORT MAP    (output_layer(a), --output_layer(a)
								  EN_REG_OUT(i,j), CLK, RST_S,
									out_regs_out(a,i,j));
		END GENERATE;
	END GENERATE;
END GENERATE;

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
	RST_n <= '0';
	START_TB <= '0';
	START <= '0';
	WAIT FOR 85 ns;
	RST_n <= '1';
	START_TB <= '0';
	START <= '0';
	WAIT FOR 25 ns;
	RST_n <= '1';
	START_TB <= '1';
	START <= '0';
	WAIT FOR 10 ns;
	RST_n <= '1';
	START_TB <= '0';
	START <= '0';
	WAIT FOR 20 ns;
	RST_n <= '1';
	START_TB <= '0';
	START <= '1';
	WAIT FOR 30 ns;
	RST_n <= '1';
	START_TB <= '0';
	START <= '0';
	WAIT;
END PROCESS;


Weights_Bias_files: PROCESS(START_TB)
    FILE w_file: text OPEN read_mode IS "../MATLAB_script/fileWeights_conv1.txt"; -- the file
    FILE b_file: text OPEN read_mode IS "../MATLAB_script/fileBias_conv1.txt"; -- the file
    VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
    VARIABLE line_buffer_w, line_buffer_b : LINE; -- read buffer
    VARIABLE read_data_w     : BIT_VECTOR(5*M_w-1 DOWNTO 0); -- The line read from the file
    VARIABLE read_data_b     : BIT_VECTOR(M_w-1 DOWNTO 0); -- The line read from the file

    BEGIN
      IF(START_TB='1' AND DONE_W_B_FILE='0') THEN
          FOR i IN 0 TO 5 LOOP
            FOR j IN 0 TO 4 LOOP             
                IF(NOT endfile(w_file)) THEN
                    readline(w_file, line_buffer_w); -- Reads the next full line from the file
                    read(line_buffer_w, read_data_w); -- Stores the first bit_n bits from the buffer into the output signal 
                    matrix_weights(i,j) <= TO_STDLOGICVECTOR(read_data_w);
                END IF;   
            END LOOP;
            
            IF(NOT endfile(b_file)) THEN
                  readline(b_file, line_buffer_b); -- Reads the next full line from the file
                  read(line_buffer_b, read_data_b); -- Stores the first bit_n bits from the buffer into the output signal 
                  bias_mac(i) <= TO_STDLOGICVECTOR(read_data_b);
            END IF;
            
          END LOOP;
          DONE_W_B_FILE <= '1';
      END IF;
      
END PROCESS;

Input_files: PROCESS(READ_IMG, CLK)
    FILE in_file: text OPEN read_mode IS "../MATLAB_script/fileInputs_conv1.txt"; -- the file
    VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
    VARIABLE line_buffer_in : LINE; -- read buffer
    VARIABLE read_data_in : BIT_VECTOR(N_in*M_in-1 DOWNTO 0); -- The line read from the file

    BEGIN
      IF(DONE_W_B_FILE='1' AND READ_IMG='1' AND DONE_READ_IN='0') THEN 
            IF(CLK'EVENT AND CLK='0') THEN
				--IF(CLK='1') THEN
                IF(NOT endfile(in_file)) THEN
                    readline(in_file, line_buffer_in); -- Reads the next full line from the file
                    read(line_buffer_in, read_data_in); -- Stores the first bit_n bits from the buffer into the output signal 
                    in_row_image1 <= TO_STDLOGICVECTOR(read_data_in);
						  readline(in_file, line_buffer_in); -- Reads the next full line from the file
                    read(line_buffer_in, read_data_in); -- Stores the first bit_n bits from the buffer into the output signal 
                    in_row_image2 <= TO_STDLOGICVECTOR(read_data_in);
                ELSE
                    DONE_READ_IN<='1';
                END IF;
            END IF;
      END IF;
END PROCESS;


Writing_process: PROCESS(DONE)
    FILE output_file: text OPEN write_mode IS "../MATLAB_script/fileOutputsVHDL_conv1.txt"; -- the file
    VARIABLE file_status: File_open_status; -- to check wether the file is already open
    VARIABLE line_buffer: line; -- read buffer
    VARIABLE write_data: bit_vector(M_out-1 DOWNTO 0); -- The line to write to the file

    BEGIN   
        IF(DONE='1' AND DONE_W='0') THEN
              FOR a IN 0 TO 5 LOOP
                  FOR i IN 0 TO 13 LOOP
							FOR j IN 0 TO 13 LOOP
							  write_data := to_bitvector(out_regs_out(a,i,j));    
							  write(line_buffer, write_data, left , M_out); -- writes the output data to the buffer
							  writeline(output_file, line_buffer); -- writes the buffer content to the file
							END LOOP;
						END LOOP;
              END LOOP;
              DONE_W <='1';
        END IF;     
END PROCESS;


  
END structural;