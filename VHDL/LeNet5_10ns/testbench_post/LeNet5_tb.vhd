
-------------------- LeNet5 TESTBENCH ----------------------------------------
-- This testbench generates the input signals to be sent to the DUT. 
-- It reads the input weights and biases from files and saves the results
-- of each layer into files ("Bin_output_simulation_<layer>.txt").
---------------------------------------------------------------------------
-- high-speed/low-power group
-- Authors: Fiore, Neri, Zheng
---------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
USE work.all;
USE work.FC_struct_pkg.all;
USE work.CONV_struct_pkg.all;
USE std.textio.all;
USE ieee.numeric_std.all;

entity LeNet5_tb is
    -- Empty entity
end LeNet5_tb;

architecture behaviour of LeNet5_tb is

  
----------------------- COMPONENTS --------------------------


COMPONENT LeNet5_top IS
--GENERIC ( M_in : NATURAL := 8);		
PORT(		
		START           	: IN STD_LOGIC;
		RST_A_n         	: IN STD_LOGIC;
		CLK    	 			: IN STD_LOGIC; 

		-- port useful for testbench
		-- output of the inner CU of the layer to the testbench
		
		-- Enable read inputs, weights and bias
		READ_IMG  			: OUT STD_LOGIC;
				
		EN_READ_W_1		 	: OUT STD_LOGIC;
		EN_READ_B_1		 	: OUT STD_LOGIC;
		--EN_READ_IN_1	 	: OUT STD_LOGIC;	
	
		EN_READ_W_2		 	: OUT STD_LOGIC;
		EN_READ_B_2		 	: OUT STD_LOGIC;
		--EN_READ_IN_2	 	: OUT STD_LOGIC;
	
		EN_READ_W_3		 	: OUT STD_LOGIC;
		EN_READ_B_3		 	: OUT STD_LOGIC;
		--EN_READ_IN_3	 	: OUT STD_LOGIC;	
		
		-- input image rows
		in_row_image1	      : IN STD_LOGIC_VECTOR(32*M_in-1 DOWNTO 0); 
		in_row_image2	      : IN STD_LOGIC_VECTOR(32*M_in-1 DOWNTO 0);
		
		
		-- Weights and bias
		matrix_weights_CONV1	: IN STD_LOGIC_VECTOR(1199 DOWNTO 0);
		bias_mac_CONV1   		: IN STD_LOGIC_VECTOR(47 DOWNTO 0);
				
		matrix_weights_step1, 
		matrix_weights_step2, 
		matrix_weights_step3,
		matrix_weights_step4 : IN STD_LOGIC_VECTOR(4799 DOWNTO 0);
		bias_memory			   : IN STD_LOGIC_VECTOR(127 DOWNTO 0);

		input_weights_1	   : IN STD_LOGIC_VECTOR(191 DOWNTO 0);
		input_bias_1		   : IN STD_LOGIC_VECTOR(191 DOWNTO 0);
		input_weights_2	   : IN STD_LOGIC_VECTOR(167 DOWNTO 0);
		input_bias_FC2		   : IN STD_LOGIC_VECTOR(167 DOWNTO 0);
		input_weights_3	   : IN STD_LOGIC_VECTOR(79 DOWNTO 0);
		input_bias_3		   : IN STD_LOGIC_VECTOR(79 DOWNTO 0);
		
		-- done of each layer of the network
		DONE_CONV1		: OUT STD_LOGIC;
		DONE_CONV2		: OUT STD_LOGIC;
		DONE_FC1			: OUT STD_LOGIC;
		DONE_FC2			: OUT STD_LOGIC;
		DONE_FC3			: OUT STD_LOGIC;
		
		-- output of the network
		output_conv1	: OUT STD_LOGIC_VECTOR(9407 DOWNTO 0);
		output_conv2	: OUT STD_LOGIC_VECTOR(INPUT_NEURONS_FC1*OUTPUT_SIZE-1 DOWNTO 0);
		output_fc1		: OUT STD_LOGIC_VECTOR(OUTPUT_NEURONS_FC1*OUTPUT_SIZE-1 DOWNTO 0);
		output_fc2		: OUT STD_LOGIC_VECTOR(OUTPUT_NEURONS_FC2*OUTPUT_SIZE-1 DOWNTO 0);
		output_TOT		: OUT STD_LOGIC_VECTOR(OUTPUT_NEURONS_FC3*OUTPUT_SIZE-1 DOWNTO 0) -- output of the layer to the output bank ragisters (outside the layer)
);
END COMPONENT LeNet5_top;


-------------------------- SIGNALS --------------------------------

   -- READ SIGNALS
	SIGNAL READ_IMG    	 : STD_LOGIC:='0';
	
	SIGNAL EN_READ_W_1    : STD_LOGIC:='0';
	SIGNAL EN_READ_B_1    : STD_LOGIC:='0';
	
	SIGNAL EN_READ_W_2    : STD_LOGIC:='0';
	SIGNAL EN_READ_B_2    : STD_LOGIC:='0';
	
	SIGNAL EN_READ_W_3    : STD_LOGIC:='0';
	SIGNAL EN_READ_B_3    : STD_LOGIC:='0';
	
	
	-- DONE READ SIGNALS
	
	SIGNAL done_read_in 			: STD_LOGIC:='0'; -- DONE read input image
	
	SIGNAL done_read_w_b_CONV1 : STD_LOGIC:='0';
	SIGNAL done_write_conv1		: STD_LOGIC:='0'; -- DONE write output results
	
	SIGNAL done_read_w_b_CONV2 : STD_LOGIC:='0';
	SIGNAL done_write_conv2		: STD_LOGIC:='0'; -- DONE write output results
	
	SIGNAL done_read_w_FC1  	: STD_LOGIC:='0';
	SIGNAL done_read_b_FC1  	: STD_LOGIC:='0';
	SIGNAL done_write_fc1		: STD_LOGIC:='0'; -- DONE write output results
	
	SIGNAL done_read_w_FC2  	: STD_LOGIC:='0';
	SIGNAL done_read_b_FC2  	: STD_LOGIC:='0';
	SIGNAL done_write_fc2		: STD_LOGIC:='0'; -- DONE write output results
		
	SIGNAL done_read_w_FC3  	: STD_LOGIC:='0';
	SIGNAL done_read_b_FC3  	: STD_LOGIC:='0';
	
	SIGNAL done_write   			: STD_LOGIC:='0'; -- DONE write output results

	-- TB Control signal 
	SIGNAL CLK_TB     	: STD_LOGIC:='0';
	SIGNAL RST_TB_A_n   	: STD_LOGIC:='0';
	SIGNAL START_TB   	: STD_LOGIC:='0';
		
	SIGNAL DONE_tb       : STD_LOGIC:='0'; -- done of all the operations of the DUT after which we can start to write output file	
		
		
	-- input image rows
	CONSTANT  M_in 				: POSITIVE := 8;
	CONSTANT  N_in     : positive := 32;
	SIGNAL in_row_image1	      : STD_LOGIC_VECTOR(32*M_in-1 DOWNTO 0); 
	SIGNAL in_row_image2	      : STD_LOGIC_VECTOR(32*M_in-1 DOWNTO 0);

	-- Weights and bias

	SIGNAL matrix_weights_CONV1_unflatten	: matrix_5x5xMw :=  (others => (others => (others => '0')));--FATTO
	SIGNAL matrix_weights_CONV1	: STD_LOGIC_VECTOR(1199 DOWNTO 0);
	SIGNAL bias_mac_CONV1_unflatten   		: INPUT_MAC_W :=  (others => (others => '0'));
	SIGNAL bias_mac_CONV1   		: STD_LOGIC_VECTOR(47 DOWNTO 0);
			
	SIGNAL matrix_weights_step1_unflatten , 
			 matrix_weights_step2_unflatten , 
			 matrix_weights_step3_unflatten ,
			 matrix_weights_step4_unflatten  	: matrix_5x5xMw_2 :=  (others => (others => (others => (others => '0'))));
	SIGNAL matrix_weights_step1, 
			 matrix_weights_step2, 
			 matrix_weights_step3,
			 matrix_weights_step4 	: STD_LOGIC_VECTOR(4799 DOWNTO 0);

	SIGNAL bias_memory_unflatten			   : bias_from_file 	:=  (others => (others => '0'));
	SIGNAL bias_memory			   : STD_LOGIC_VECTOR(127 DOWNTO 0);

	SIGNAL input_weights_1_unflatten	   : weights_struct_FC1 :=  (others => (others => '0')); -- from file to LAYER;
	SIGNAL input_bias_1_unflatten		   : bias_struct_FC1 	:=  (others => (others => '0')); 
	SIGNAL input_weights_2_unflatten	   : weights_struct_FC2 :=  (others => (others => '0')); 
	SIGNAL input_bias_FC2_unflatten		: bias_struct_FC2 	:=  (others => (others => '0')); 
	SIGNAL input_weights_3_unflatten	   : weights_struct_FC3 :=  (others => (others => '0')); 
	SIGNAL input_bias_3_unflatten		   : bias_struct_FC3 	:=  (others => (others => '0'));

	SIGNAL input_weights_1	   : STD_LOGIC_VECTOR(191 DOWNTO 0); -- from file to LAYER;
	SIGNAL input_bias_1		   : STD_LOGIC_VECTOR(191 DOWNTO 0); 
	SIGNAL input_weights_2	   : STD_LOGIC_VECTOR(167 DOWNTO 0);
	SIGNAL input_bias_FC2		: STD_LOGIC_VECTOR(167 DOWNTO 0);
	SIGNAL input_weights_3	   : STD_LOGIC_VECTOR(79 DOWNTO 0);
	SIGNAL input_bias_3		   : STD_LOGIC_VECTOR(79 DOWNTO 0);
		
		-- done of each layer of the network
	SIGNAL DONE_CONV1		: STD_LOGIC;
	SIGNAL DONE_CONV2		: STD_LOGIC;
	SIGNAL DONE_FC1		: STD_LOGIC;
	SIGNAL DONE_FC2		: STD_LOGIC;
	SIGNAL DONE_FC3		: STD_LOGIC;
	

		
	-- output of the network
	-- INSERIRE TUTTI GLI OUTPUT DI OGNI LAYERS
	SIGNAL output_conv1_unflatten	: Conv1_reg_Conv2;
	SIGNAL output_conv1	: STD_LOGIC_VECTOR(9407 DOWNTO 0);
	SIGNAL output_conv2	: STD_LOGIC_VECTOR(INPUT_NEURONS_FC1*OUTPUT_SIZE-1 DOWNTO 0);
	SIGNAL output_fc1		: STD_LOGIC_VECTOR(OUTPUT_NEURONS_FC1*OUTPUT_SIZE-1 DOWNTO 0);
	SIGNAL output_fc2		: STD_LOGIC_VECTOR(OUTPUT_NEURONS_FC2*OUTPUT_SIZE-1 DOWNTO 0);
	SIGNAL output_TOT		: STD_LOGIC_VECTOR(OUTPUT_NEURONS_FC3*OUTPUT_SIZE-1 DOWNTO 0);
	CONSTANT T_CLK : TIME:= 10 ns;
---------------------------------------------------------

begin

--Clock generation
PROCESS
  BEGIN
	 CLK_TB <= '1';
	 WAIT FOR T_CLK/2;
	 CLK_TB <= '0';
	 WAIT FOR T_CLK/2;
END PROCESS;

 -- Reset generation
 -- RST_TB_A_n <= '1' after 70 ns; -- Good for 20 ns clock period
    RST_TB_A_n <= '1' after 35 ns; -- Good for 10 ns clock period

--Start generation 
 
PROCESS
  BEGIN
	--WAIT FOR 75 ns; -- Good for 20 ns clock period
	WAIT FOR 55 ns; -- Good for 10 ns clock period
	START_TB <= '1';
	--WAIT FOR 30 ns; -- Good for 20 ns clock period
	WAIT FOR 15 ns; -- Good for 10 ns clock period
	START_TB <= '0';
	WAIT;
END PROCESS;



------------------------------------------------------------------------
--------------------------- CONV1 PROCESS ------------------------------
------------------------------------------------------------------------


Weights_Bias_files_conv1: PROCESS(START_TB)
    FILE w_file_conv1: text OPEN read_mode IS "../sim_in/Bin_ColumnWeights_conv_1.txt"; -- the file
    FILE b_file: text OPEN read_mode IS "../sim_in/Bin_ColumnBias_conv_1.txt"; -- the file
    VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
    VARIABLE line_buffer_w, line_buffer_b : LINE; -- read buffer
    VARIABLE read_data_w     : BIT_VECTOR(5*M_mpy-1 DOWNTO 0); -- The line read from the file
    VARIABLE read_data_b     : BIT_VECTOR(M_mpy-1 DOWNTO 0); -- The line read from the file

    BEGIN
      IF(START_TB='1' AND done_read_w_b_CONV1='0') THEN
          FOR i IN 0 TO 5 LOOP
            FOR j IN 0 TO 4 LOOP             
                IF(NOT endfile(w_file_conv1)) THEN
                    readline(w_file_conv1, line_buffer_w); -- Reads the next full line from the file
                    read(line_buffer_w, read_data_w); -- Stores the first bit_n bits from the buffer into the output signal 
                    matrix_weights_CONV1_unflatten(i,j) <= TO_STDLOGICVECTOR(read_data_w);
                END IF;   
            END LOOP;
            
            IF(NOT endfile(b_file)) THEN
                  readline(b_file, line_buffer_b); -- Reads the next full line from the file
                  read(line_buffer_b, read_data_b); -- Stores the first bit_n bits from the buffer into the output signal 
                  bias_mac_CONV1_unflatten(i) <= TO_STDLOGICVECTOR(read_data_b);
            END IF;
            
          END LOOP;
          done_read_w_b_CONV1 <= '1';
      END IF;
      
END PROCESS;

Input_files_conv1: PROCESS(READ_IMG, CLK_TB)
    FILE in_file_conv1: text OPEN read_mode IS "../sim_in/fileInputs.txt"; -- the file
    VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
    VARIABLE line_buffer_in : LINE; -- read buffer
    VARIABLE read_data_in : BIT_VECTOR(N_in*M_in-1 DOWNTO 0); -- The line read from the file

    BEGIN
      IF(done_read_w_b_CONV1='1' AND READ_IMG='1' AND done_read_in='0') THEN 
            IF(CLK_TB'EVENT AND CLK_TB='0') THEN
				--IF(CLK='1') THEN
                IF(NOT endfile(in_file_conv1)) THEN
                    readline(in_file_conv1, line_buffer_in); -- Reads the next full line from the file
                    read(line_buffer_in, read_data_in); -- Stores the first bit_n bits from the buffer into the output signal 
                    in_row_image1 <= TO_STDLOGICVECTOR(read_data_in);
						  readline(in_file_conv1, line_buffer_in); -- Reads the next full line from the file
                    read(line_buffer_in, read_data_in); -- Stores the first bit_n bits from the buffer into the output signal 
                    in_row_image2 <= TO_STDLOGICVECTOR(read_data_in);
                ELSE
                    done_read_in <= '1';
                END IF;
            END IF;
      END IF;
END PROCESS;


Writing_process_conv1: PROCESS(DONE_CONV1)
    FILE output_file_conv1: text OPEN write_mode IS "../sim_out/fileOutputsVHDL_conv1.txt"; -- the file
    VARIABLE file_status: File_open_status; -- to check wether the file is already open
    VARIABLE line_buffer: line; -- read buffer
    VARIABLE write_data: bit_vector(M_mpy-1 DOWNTO 0); -- The line to write to the file

    BEGIN   
        IF(DONE_CONV1='1' AND done_write_conv1='0') THEN
              FOR a IN 0 TO 5 LOOP
                  FOR i IN 0 TO 13 LOOP
							FOR j IN 0 TO 13 LOOP
							  write_data := to_bitvector(output_conv1_unflatten(a,i,j));    
							  write(line_buffer, write_data, left , M_mpy); -- writes the output data to the buffer
							  writeline(output_file_conv1, line_buffer); -- writes the buffer content to the file
							END LOOP;
						END LOOP;
              END LOOP;
              done_write_conv1 <='1';
        END IF;     
END PROCESS;



------------------------------------------------------------------------
--------------------------- CONV2 PROCESS ------------------------------
------------------------------------------------------------------------


Weights_Bias_files_conv2: PROCESS(START_TB)
    FILE w_file_conv2: text OPEN read_mode IS "../sim_in/Bin_ColumnWeights_conv_2.txt"; -- the file
    FILE b_file_conv2: text OPEN read_mode IS "../sim_in/Bin_ColumnBias_conv_2.txt"; -- the file
    --VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
    VARIABLE line_buffer_w, line_buffer_b : LINE; -- read buffer
    VARIABLE read_data_w     : BIT_VECTOR(5*M_mpy-1 DOWNTO 0); -- The line read from the file
    VARIABLE read_data_b     : BIT_VECTOR(M_mpy-1 DOWNTO 0); -- The line read from the file
	 
--	 FILE in_file_conv2: text OPEN read_mode IS "fileOutputsVHDL_CONV1.txt"; -- the file
--	 --FILE in_file: text OPEN read_mode IS "outputs_prova.txt"; -- the file
--    VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
--    VARIABLE line_buffer_in : LINE; -- read buffer
--    VARIABLE read_data_in : BIT_VECTOR(M_in-1 DOWNTO 0); -- The line read from the file
--	 VARIABLE read_input		: STD_LOGIC_VECTOR(M_w-1 DOWNTO 0);

    BEGIN
      IF(START_TB='1' AND done_read_w_b_CONV2='0') THEN
--		-- LETTURA FILE DI INPUT PER SIMULARE I REGISTRI DI USCITA DEL CONV1
--			FOR a IN 0 TO 5 LOOP	
--				FOR i IN 0 TO 13 LOOP					  
--					FOR j IN 0 TO 13 LOOP
--						IF(NOT endfile(in_file_conv2)) THEN
--							readline(in_file_conv2, line_buffer_in);
--							read(line_buffer_in, read_data_in);
--							read_input := TO_STDLOGICVECTOR(read_data_in);
--							out_regs_conv1(a,i,j) <= read_input;
--							row_in(a)((14*(14-i)-j)*M_in-1 DOWNTO (14*(14-i)-j-1)*M_in) <= read_input;
--						END IF;
--					END LOOP;
--				END LOOP;
--			END LOOP;
--			
--			file_close(in_file_conv2);
		
            FOR i IN 0 TO 2 LOOP
					FOR j IN 0 TO 7 LOOP
						FOR k IN 0 TO 4 LOOP
							IF(NOT endfile(w_file_conv2)) THEN
								readline(w_file_conv2, line_buffer_w); -- Reads the next full line from the file
								read(line_buffer_w, read_data_w); -- Stores the first bit_n bits from the buffer into the output signal 
								matrix_weights_step1_unflatten(i,j,k) <= TO_STDLOGICVECTOR(read_data_w);
							END IF;   
						END LOOP;
					END LOOP;
				END LOOP;
				
				FOR i IN 0 TO 2 LOOP
					FOR j IN 0 TO 7 LOOP
						FOR k IN 0 TO 4 LOOP
							IF(NOT endfile(w_file_conv2)) THEN
								readline(w_file_conv2, line_buffer_w); -- Reads the next full line from the file
								read(line_buffer_w, read_data_w); -- Stores the first bit_n bits from the buffer into the output signal 
								matrix_weights_step2_unflatten(i,j,k) <= TO_STDLOGICVECTOR(read_data_w);
							END IF;   
						END LOOP;
					END LOOP;
				END LOOP;
				
				FOR i IN 0 TO 2 LOOP
					FOR j IN 0 TO 7 LOOP
						FOR k IN 0 TO 4 LOOP
							IF(NOT endfile(w_file_conv2)) THEN
								readline(w_file_conv2, line_buffer_w); -- Reads the next full line from the file
								read(line_buffer_w, read_data_w); -- Stores the first bit_n bits from the buffer into the output signal 
								matrix_weights_step3_unflatten(i,j,k) <= TO_STDLOGICVECTOR(read_data_w);
							ELSE
							END IF;   
						END LOOP;
					END LOOP;
				END LOOP;
				
				FOR i IN 0 TO 2 LOOP
					FOR j IN 0 TO 7 LOOP
						FOR k IN 0 TO 4 LOOP
							IF(NOT endfile(w_file_conv2)) THEN
								readline(w_file_conv2, line_buffer_w); -- Reads the next full line from the file
								read(line_buffer_w, read_data_w); -- Stores the first bit_n bits from the buffer into the output signal 
								matrix_weights_step4_unflatten(i,j,k) <= TO_STDLOGICVECTOR(read_data_w);
							END IF;
						END LOOP;
					END LOOP;
				END LOOP;
				file_close(w_file_conv2);
				
          FOR i IN 0 TO 15 LOOP
            IF(NOT endfile(b_file_conv2)) THEN
                  readline(b_file_conv2, line_buffer_b); -- Reads the next full line from the file
                  read(line_buffer_b, read_data_b); -- Stores the first bit_n bits from the buffer into the output signal 
                  bias_memory_unflatten(i) <= TO_STDLOGICVECTOR(read_data_b);
            END IF;    
          END LOOP;
			 file_close(b_file_conv2);
			 done_read_w_b_CONV2 <='1';
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


Writing_process_conv2: PROCESS(DONE_CONV2)
    FILE output_file_conv2: text OPEN write_mode IS "../sim_out/fileOutputsVHDL_CONV2.txt"; -- the file
    VARIABLE file_status: File_open_status; -- to check wether the file is already open
    VARIABLE line_buffer: line; -- read buffer
    VARIABLE write_data: bit_vector(M_mpy-1 DOWNTO 0); -- The line to write to the file

    BEGIN   
        IF(DONE_CONV2='1' AND done_write_conv2='0') THEN
				  FOR i IN 0 TO 4 LOOP
						FOR j IN 0 TO 4 LOOP
							FOR a IN 0 TO 15 LOOP
							  write_data := to_bitvector(output_conv2( ((i*5+j)*16+a+1)*M_mpy-1 DOWNTO ((i*5+j)*16+a)*M_mpy ));
							  write(line_buffer, write_data, left , M_mpy); -- writes the output data to the buffer
							  writeline(output_file_conv2, line_buffer); -- writes the buffer content to the file
							END LOOP;
						END LOOP;
              END LOOP;
              done_write_conv2 <='1';
        END IF;     
END PROCESS;


------------------------------------------------------------------------
---------------------------- FC1 PROCESS -------------------------------
------------------------------------------------------------------------


Weights_Process_fc1: PROCESS(EN_READ_W_1,CLK_TB)

FILE w_file_fc1: text OPEN read_mode IS "../sim_in/Bin_ColumnWeights_dense_1.txt"; -- weights input file
VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
VARIABLE line_buffer_w: LINE; -- read buffer
--VARIABLE EOF_w: STD_LOGIC:='0'; -- End Of File variable
VARIABLE read_data_w: BIT_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- The line read from the file

BEGIN
  IF(EN_READ_W_1='1' and done_read_w_FC1='0') THEN
    IF (CLK_TB'EVENT AND CLK_TB='1') THEN
      FOR i IN 0 TO N_MAC_FC1-1 LOOP -- N_MAC=24
        IF(NOT endfile(w_file_fc1)) THEN
          readline(w_file_fc1, line_buffer_w); -- Reads the next full line from the file
          read(line_buffer_w, read_data_w); -- Stores the first bit_n bits from the buffer into the output signal 
          input_weights_1_unflatten(i) <= TO_STDLOGICVECTOR(read_data_w);
			ELSE
			 done_read_w_FC1 <='1';
        END IF;
      END LOOP;
    END IF;
  END IF;   
END PROCESS;


Bias_Process_fc1: PROCESS(EN_READ_B_1)

FILE b_file_fc1: text OPEN read_mode IS "../sim_in/Bin_ColumnBias_dense_1.txt"; -- weights input file
VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
VARIABLE line_buffer_b: LINE; -- read buffer
--VARIABLE EOF_b: STD_LOGIC:='0'; -- End Of File variable
VARIABLE read_data_b: BIT_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- The line read from the file

BEGIN
  IF(EN_READ_B_1='1' and done_read_b_FC1='0' ) THEN
      FOR i IN 0 TO N_MAC_FC1-1 LOOP -- N_MAC=24
        IF(NOT endfile(b_file_fc1)) THEN
          readline(b_file_fc1, line_buffer_b); -- Reads the next full line from the file
          read(line_buffer_b, read_data_b); -- Stores the first bit_n bits from the buffer into the output signal 
			 input_bias_1_unflatten(i) <= TO_STDLOGICVECTOR(read_data_b);
--          input_bias_tb(i)(2*INPUT_SIZE-1 DOWNTO 2*INPUT_SIZE-5) <= (OTHERS => TO_STDLOGICVECTOR(read_data_b)(INPUT_SIZE-1));
--          input_bias_tb(i)(2*INPUT_SIZE-6 DOWNTO INPUT_SIZE-5) <= TO_STDLOGICVECTOR(read_data_b);
--          input_bias_tb(i)(INPUT_SIZE-6 DOWNTO 0) <= (OTHERS => '0');

        END IF;
      END LOOP;
      --done_read_b <='1';
  END IF;   
END PROCESS;


--Input_Process_fc1: PROCESS(en_read_in)
--
--FILE in_file_fc1: text OPEN read_mode IS "Bin_Input_from_prev_layer_1.txt"; -- INPUT FILE FROM PREVIOUS LAYER
--VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
--VARIABLE line_buffer_in: LINE; -- read buffer
----VARIABLE EOF_b: STD_LOGIC:='0'; -- End Of File variable
--VARIABLE read_data_in: BIT_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- The line read from the file
--
--BEGIN
--  IF(en_read_in='1' and done_read_in='0') THEN
--    FOR i in 0 TO INPUT_NEURONS LOOP -- da 0 a 399
--      IF(NOT endfile(in_file_fc1)) THEN
--        readline(in_file_fc1, line_buffer_in); -- Reads the next full line from the file
--        read(line_buffer_in, read_data_in); -- Stores the first bit_n bits from the buffer into the output signal 
--        input_value_tb(i) <= TO_STDLOGICVECTOR(read_data_in);
--      END IF;
--    END LOOP;
--  done_read_in <='1'; -- quando finisco di leggere i 400 ingressi
--  END IF; 
--END PROCESS;


Output_Process_fc1: PROCESS(DONE_FC1)

FILE output_file_fc1: text OPEN write_mode IS "../sim_out/Bin_output_simulation_dense1.txt"; -- INPUT FILE FROM PREVIOUS LAYER
VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
VARIABLE line_buffer: LINE; -- write buffer
--VARIABLE EOF_b: STD_LOGIC:='0'; -- End Of File variable
VARIABLE write_data: BIT_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- The line to write to the file

BEGIN
  
  IF(DONE_FC1='1' and done_write_fc1='0') THEN
    FOR i in 0 TO OUTPUT_NEURONS_FC1-1 LOOP -- da 0 a 119
      write_data := to_bitvector(output_FC1((i+1)*OUTPUT_SIZE-1 DOWNTO i*OUTPUT_SIZE));
      write(line_buffer, write_data, left, OUTPUT_SIZE-1); -- writes the input data to the buffer
      writeline(output_file_fc1, line_buffer); -- writes the buffer content to the file
    END LOOP;
  done_write_fc1 <='1';
  END IF; 
  --file_close(output_file);
END PROCESS;


------------------------------------------------------------------------
----------------------------- FC2 PROCESS -------------------------------
------------------------------------------------------------------------


Weights_Process_fc2: PROCESS(EN_READ_W_2,CLK_TB)

FILE w_file_fc2: text OPEN read_mode IS "../sim_in/Bin_ColumnWeights_dense_2.txt"; -- weights input file
VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
VARIABLE line_buffer_w: LINE; -- read buffer
--VARIABLE EOF_w: STD_LOGIC:='0'; -- End Of File variable
VARIABLE read_data_w: BIT_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- The line read from the file

BEGIN
  IF(EN_READ_W_2='1' and done_read_w_FC2='0') THEN
    IF (CLK_TB'EVENT AND CLK_TB='1') THEN
      FOR i IN 0 TO N_MAC_FC2-1 LOOP -- N_MAC=21
        IF(NOT endfile(w_file_fc2)) THEN
          readline(w_file_fc2, line_buffer_w); -- Reads the next full line from the file
          read(line_buffer_w, read_data_w); -- Stores the first bit_n bits from the buffer into the output signal 
          input_weights_2_unflatten(i) <= TO_STDLOGICVECTOR(read_data_w);
			ELSE
			 done_read_w_FC2 <='1';
        END IF;
      END LOOP;
      
    END IF;
  END IF;   
END PROCESS;


Bias_Process_fc2: PROCESS(EN_READ_B_2)

FILE b_file_fc2: text OPEN read_mode IS "../sim_in/Bin_ColumnBias_dense_2.txt"; -- weights input file
VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
VARIABLE line_buffer_b: LINE; -- read buffer
--VARIABLE EOF_b: STD_LOGIC:='0'; -- End Of File variable
VARIABLE read_data_b: BIT_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- The line read from the file

BEGIN
  IF(EN_READ_B_2='1' and done_read_b_FC2='0' ) THEN
      FOR i IN 0 TO N_MAC_FC2-1 LOOP -- N_MAC=21
        IF(NOT endfile(b_file_fc2)) THEN
          readline(b_file_fc2, line_buffer_b); -- Reads the next full line from the file
          read(line_buffer_b, read_data_b); -- Stores the first bit_n bits from the buffer into the output signal 
			    input_bias_FC2_unflatten(i) <= TO_STDLOGICVECTOR(read_data_b);
        END IF;
      END LOOP;
      --done_read_b <='1';
  END IF;   
END PROCESS;


--Input_Process_fc2: PROCESS(en_read_in)
--
--FILE in_file_fc2: text OPEN read_mode IS "Bin_Input_from_prev_layer_2.txt"; -- INPUT FILE FROM PREVIOUS LAYER
--VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
--VARIABLE line_buffer_in: LINE; -- read buffer
----VARIABLE EOF_b: STD_LOGIC:='0'; -- End Of File variable
--VARIABLE read_data_in: BIT_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- The line read from the file
--
--BEGIN
--  IF(en_read_in='1' and done_read_in='0') THEN
--    FOR i in 0 TO INPUT_NEURONS LOOP -- da 0 a 119
--      IF(NOT endfile(in_file_fc2)) THEN
--        readline(in_file_fc2, line_buffer_in); -- Reads the next full line from the file
--        read(line_buffer_in, read_data_in); -- Stores the first bit_n bits from the buffer into the output signal 
--        input_value_tb(i) <= TO_STDLOGICVECTOR(read_data_in);
--      END IF;
--    END LOOP;
--  done_read_in <='1'; -- quando finisco di leggere i 120 ingressi
--  END IF; 
--END PROCESS;



Output_Process_fc2: PROCESS(DONE_FC2)

FILE output_file_fc2: text OPEN write_mode IS "../sim_out/Bin_output_simulation_dense2.txt"; -- INPUT FILE FROM PREVIOUS LAYER
VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
VARIABLE line_buffer: LINE; -- write buffer
--VARIABLE EOF_b: STD_LOGIC:='0'; -- End Of File variable
VARIABLE write_data: BIT_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- The line to write to the file

BEGIN
  
  IF(DONE_FC2='1' and done_write_fc2='0') THEN
    FOR i in 0 TO OUTPUT_NEURONS_FC2-1 LOOP -- da 0 a 83
      write_data := to_bitvector(output_FC2((i+1)*OUTPUT_SIZE-1 DOWNTO i*OUTPUT_SIZE));
      write(line_buffer, write_data, left, OUTPUT_SIZE-1); -- writes the input data to the buffer
      writeline(output_file_fc2, line_buffer); -- writes the buffer content to the file
    END LOOP;
  done_write_fc2 <='1';
  END IF; 
  --file_close(output_file);
END PROCESS;



------------------------------------------------------------------------
---------------------------- FC3 PROCESS -------------------------------
------------------------------------------------------------------------


Weights_Process_fc3: PROCESS(EN_READ_W_3,CLK_TB)

FILE w_file_fc3: text OPEN read_mode IS "../sim_in/Bin_ColumnWeights_dense_3.txt"; -- weights input file
VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
VARIABLE line_buffer_w: LINE; -- read buffer
--VARIABLE EOF_w: STD_LOGIC:='0'; -- End Of File variable
VARIABLE read_data_w: BIT_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- The line read from the file

BEGIN
  IF(EN_READ_W_3='1' and done_read_w_FC3='0') THEN
    IF (CLK_TB'EVENT AND CLK_TB='1') THEN
      FOR i IN 0 TO N_MAC_FC3-1 LOOP -- N_MAC=10
        IF(NOT endfile(w_file_fc3)) THEN
          readline(w_file_fc3, line_buffer_w); -- Reads the next full line from the file
          read(line_buffer_w, read_data_w); -- Stores the first bit_n bits from the buffer into the output signal 
          input_weights_3_unflatten(i) <= TO_STDLOGICVECTOR(read_data_w);
			ELSE
			 done_read_w_FC3 <='1';
        END IF;
      END LOOP;
      
    END IF;
  END IF;   
END PROCESS;



Bias_Process_fc3: PROCESS(EN_READ_B_2)

FILE b_file_fc3: text OPEN read_mode IS "../sim_in/Bin_ColumnBias_dense_3.txt"; -- weights input file
VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
VARIABLE line_buffer_b: LINE; -- read buffer
--VARIABLE EOF_b: STD_LOGIC:='0'; -- End Of File variable
VARIABLE read_data_b: BIT_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- The line read from the file

BEGIN
  IF(EN_READ_B_3='1' and done_read_b_FC3='0' ) THEN
      FOR i IN 0 TO N_MAC_FC3-1 LOOP -- N_MAC=10
        IF(NOT endfile(b_file_fc3)) THEN
          readline(b_file_fc3, line_buffer_b); -- Reads the next full line from the file
          read(line_buffer_b, read_data_b); -- Stores the first bit_n bits from the buffer into the output signal 
			 input_bias_3_unflatten(i) <= TO_STDLOGICVECTOR(read_data_b);
        END IF;
      END LOOP;
      --done_read_b <='1';
  END IF;   
END PROCESS;



--Input_Process_fc3: PROCESS(en_read_in)
--
--FILE in_file_fc3: text OPEN read_mode IS "Bin_Input_from_prev_layer_3.txt"; -- INPUT FILE FROM PREVIOUS LAYER
--VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
--VARIABLE line_buffer_in: LINE; -- read buffer
----VARIABLE EOF_b: STD_LOGIC:='0'; -- End Of File variable
--VARIABLE read_data_in: BIT_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- The line read from the file
--
--BEGIN
--  IF(en_read_in='1' and done_read_in='0') THEN
--    FOR i in 0 TO INPUT_NEURONS LOOP -- da 0 a 83
--      IF(NOT endfile(in_file_fc3)) THEN
--        readline(in_file_fc3, line_buffer_in); -- Reads the next full line from the file
--        read(line_buffer_in, read_data_in); -- Stores the first bit_n bits from the buffer into the output signal 
--        input_value_tb(i) <= TO_STDLOGICVECTOR(read_data_in);
--      END IF;
--    END LOOP;
--  done_read_in <='1'; -- quando finisco di leggere i 84 ingressi
--  END IF; 
--END PROCESS;
--


Output_Process_fc3: PROCESS(DONE_FC3)

FILE output_file_fc3: text OPEN write_mode IS "../sim_out/Bin_output_simulation_dense3.txt"; -- INPUT FILE FROM PREVIOUS LAYER
VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
VARIABLE line_buffer: LINE; -- write buffer
--VARIABLE EOF_b: STD_LOGIC:='0'; -- End Of File variable
VARIABLE write_data: BIT_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- The line to write to the file

BEGIN
  
  IF(DONE_FC3='1' and done_write='0') THEN
    FOR i in 0 TO OUTPUT_NEURONS_FC3-1 LOOP -- da 0 a 10
      write_data := to_bitvector(output_TOT((i+1)*OUTPUT_SIZE-1 DOWNTO i*OUTPUT_SIZE));
      write(line_buffer, write_data, left, OUTPUT_SIZE-1); -- writes the input data to the buffer
      writeline(output_file_fc3, line_buffer); -- writes the buffer content to the file
    END LOOP;
  done_write <='1';
  END IF; 
  --file_close(output_file);
END PROCESS;




------------------------------------------------------------------------
------------------------------ FLATTEN ---------------------------------
------------------------------------------------------------------------


gen_matrix_5x5xMw: FOR i2 IN 0 TO 5 GENERATE
gen_matrix_5x5xMw_2:	FOR i1 IN 0 TO 4 GENERATE
		matrix_weights_CONV1((i2*5+i1+1)*5*M_mpy-1 DOWNTO (i2*5+i1)*5*M_mpy) <= matrix_weights_CONV1_unflatten(i2, i1);
	END GENERATE;
END GENERATE;


gen_INPUT_MAC_W: FOR i IN 0 TO 5 GENERATE
		bias_mac_CONV1((i+1)*M_mpy-1 DOWNTO i*M_mpy) <= bias_mac_CONV1_unflatten(i);
END GENERATE;


gen_matrix_5x5xMw_2: FOR i3 IN 0 TO 2 GENERATE
gen_matrix_5x5xMw_2_2:	FOR i2 IN 0 TO 7 GENERATE
gen_matrix_5x5xMw_2_3:	FOR i1 IN 0 TO 4 GENERATE
			matrix_weights_step1((i3*8*5+i2*5+i1+1)*5*M_mpy-1 DOWNTO (i3*8*5+i2*5+i1)*5*M_mpy) <= matrix_weights_step1_unflatten(i3,i2,i1);
			matrix_weights_step2((i3*8*5+i2*5+i1+1)*5*M_mpy-1 DOWNTO (i3*8*5+i2*5+i1)*5*M_mpy) <= matrix_weights_step2_unflatten(i3,i2,i1);
			matrix_weights_step3((i3*8*5+i2*5+i1+1)*5*M_mpy-1 DOWNTO (i3*8*5+i2*5+i1)*5*M_mpy) <= matrix_weights_step3_unflatten(i3,i2,i1);
			matrix_weights_step4((i3*8*5+i2*5+i1+1)*5*M_mpy-1 DOWNTO (i3*8*5+i2*5+i1)*5*M_mpy) <= matrix_weights_step4_unflatten(i3,i2,i1);
		END GENERATE;
	END GENERATE;
END GENERATE;


gen_bias_from_file: FOR i IN 0 TO 15 GENERATE
	bias_memory((i+1)*M_mpy-1 DOWNTO i*M_mpy) <= bias_memory_unflatten(i);
END GENERATE;


gen_weights_struct_FC1: FOR i IN 0 TO N_MAC_FC1-1 GENERATE
	input_weights_1((i+1)*WEIGHT_SIZE-1 DOWNTO i*WEIGHT_SIZE) <= input_weights_1_unflatten(i);
END GENERATE;


gen_bias_struct_FC1: FOR i IN 0 TO N_MAC_FC1-1 GENERATE
	input_bias_1((i+1)*BIAS_SIZE-1 DOWNTO i*BIAS_SIZE) <= input_bias_1_unflatten(i);
END GENERATE;


gen_weights_struct_FC2: FOR i IN 0 TO N_MAC_FC2-1 GENERATE
	input_weights_2((i+1)*WEIGHT_SIZE-1 DOWNTO i*WEIGHT_SIZE) <= input_weights_2_unflatten(i);
END GENERATE;


gen_bias_struct_FC2: FOR i IN 0 TO N_MAC_FC2-1 GENERATE
	input_bias_FC2((i+1)*BIAS_SIZE-1 DOWNTO i*BIAS_SIZE) <= input_bias_FC2_unflatten(i);
END GENERATE;


gen_weights_struct_FC3: FOR i IN 0 TO N_MAC_FC3-1 GENERATE
	input_weights_3((i+1)*WEIGHT_SIZE-1 DOWNTO i*WEIGHT_SIZE) <= input_weights_3_unflatten(i);
END GENERATE;


gen_bias_struct_FC3: FOR i IN 0 TO N_MAC_FC3-1 GENERATE
	input_bias_3((i+1)*BIAS_SIZE-1 DOWNTO i*BIAS_SIZE) <= input_bias_3_unflatten(i);
END GENERATE;


gen_Conv1_reg_Conv2: FOR i3 IN 0 TO 5 GENERATE
gen_Conv1_reg_Conv2_2:	FOR i2 IN 0 TO 13 GENERATE
gen_Conv1_reg_Conv2_3:		FOR i1 IN 0 TO 13 GENERATE
			output_conv1((i3*14*14+i2*14+i1+1)*M_mpy-1 DOWNTO (i3*14*14+i2*14+i1)*M_mpy) <= output_conv1_unflatten(i3,i2,i1);
		END GENERATE;
	END GENERATE;
END GENERATE;




------------------------------------------------------------------------
------------------------------ PORTMAP ---------------------------------
------------------------------------------------------------------------


UUT : LeNet5_top 
	port map (START_TB,RST_TB_A_n,CLK_TB,
				 READ_IMG,
				 EN_READ_W_1,
				 EN_READ_B_1,
				 EN_READ_W_2,
				 EN_READ_B_2,
				 EN_READ_W_3,
				 EN_READ_B_3,
				 in_row_image1,
				 in_row_image2,
				 matrix_weights_CONV1,
				 bias_mac_CONV1,
						
				 matrix_weights_step1, 
				 matrix_weights_step2, 
				 matrix_weights_step3,
				 matrix_weights_step4,
				 bias_memory,

				 input_weights_1,
				 input_bias_1,
				 input_weights_2,
				 input_bias_FC2,
				 input_weights_3,
				 input_bias_3,
				 DONE_CONV1,
				 DONE_CONV2,
				 DONE_FC1,
				 DONE_FC2,
				 DONE_FC3,
				 output_conv1,
				 output_conv2,
				 output_fc1,
				 output_fc2,
				 output_TOT);

end architecture behaviour;


