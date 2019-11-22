
-------------------- FC1 TESTBENCH ----------------------------------------
-- This testbench generates the input signals to be sent to the DUT. 
-- It reads the input weights and biases from a file and saves the results
-- on another file ("Bin_output_simulation_dense1.txt").
---------------------------------------------------------------------------
-- high-speed/low-power group
-- Authors: Fiore, Neri, Zheng
---------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
USE work.all;
USE work.input_struct_pkg.all;
USE std.textio.all;
USE ieee.numeric_std.all;

entity FC1_tb is
    -- Empty entity
end FC1_tb;

architecture behaviour of FC1_tb is

  
----------------------- COMPONENTS --------------------------


COMPONENT FC1_top IS
GENERIC(		
		CONSTANT INPUT_NEURONS   	: POSITIVE := 400;
		CONSTANT OUTPUT_NEURONS  	: POSITIVE := 120);
			
PORT(		
		START           	: IN STD_LOGIC;
		RST_A_n         	: IN STD_LOGIC;
		
		-- port useful for testbench
		EN_READ_W		 : OUT STD_LOGIC;
		EN_READ_B		 : OUT STD_LOGIC;
		EN_READ_IN		 : OUT STD_LOGIC;		
		
		input_FC1			: IN STD_LOGIC_VECTOR(INPUT_NEURONS*INPUT_SIZE-1 DOWNTO 0); -- input yo the layer coming from previous layer
		input_weights	   : IN weights_struct;
		input_bias		   : IN bias_struct;
		CLK    	 			: IN STD_LOGIC; 
		DONE_FC1        	: OUT STD_LOGIC;
		output_FC1			: OUT STD_LOGIC_VECTOR(OUTPUT_NEURONS*OUTPUT_SIZE-1 DOWNTO 0) -- output of the layer to the output bank ragisters (outside the layer)
);
END COMPONENT FC1_top;


-------------------------- SIGNALS --------------------------------


   -- TESTBENCH SIGNALS
	SIGNAL en_read_w    : STD_LOGIC:='0';
	SIGNAL en_read_b    : STD_LOGIC:='0';
	SIGNAL en_read_in   : STD_LOGIC:='0';
 
	-- READERS SIGNALS
	SIGNAL done_read_w  : STD_LOGIC:='0';
	SIGNAL done_read_b  : STD_LOGIC:='0';
	SIGNAL done_read_in : STD_LOGIC:='0';
	SIGNAL done_write   : STD_LOGIC:='0';
	 
	SIGNAL DONE         : STD_LOGIC:='0'; -- done of all the operations of the DUT after which we can start to write output file
 
	SIGNAL CLK_TB     : STD_LOGIC:='0';
	SIGNAL RST_TB_A_n   : STD_LOGIC:='0';
	SIGNAL START_TB   : STD_LOGIC:='0';
 
   CONSTANT INPUT_NEURONS    	: POSITIVE := 400;
   CONSTANT OUTPUT_NEURONS   	: POSITIVE := 120;
   CONSTANT T_CLK					: TIME:= 20 ns;
    
   -- DUT SIGNALS 
	SIGNAL input_weights_tb            : weights_struct :=  (others => (others => '0')); -- from file to LAYER
	SIGNAL input_bias_tb               : bias_struct :=  (others => (others => '0')); -- from file to LAYER
		
	TYPE in_val IS ARRAY(INPUT_NEURONS-1 DOWNTO 0) OF STD_LOGIC_VECTOR(INPUT_SIZE-1 DOWNTO 0);
	SIGNAL input_value_tb              : in_val:=  (others => (others => '0')); -- from file to LAYER
		
	SIGNAL input_dut_tb						: STD_LOGIC_VECTOR(INPUT_NEURONS*INPUT_SIZE-1 DOWNTO 0);
	SIGNAL output_FC1							: STD_LOGIC_VECTOR(OUTPUT_NEURONS*OUTPUT_SIZE-1 DOWNTO 0); -- output of the output bank ragisters

	
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
 RST_TB_A_n <= '1' after 70 ns;
 
--Start generation 
 
PROCESS
  BEGIN
	WAIT FOR 75 ns;
	START_TB <= '1';
	WAIT FOR 30 ns;
	START_TB <= '0';
	WAIT;
END PROCESS;

  
----------------------------------------------------
    

Weights_Process: PROCESS(en_read_w,CLK_TB)

FILE w_file: text OPEN read_mode IS "Bin_ColumnWeights_dense_1.txt"; -- weights input file
VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
VARIABLE line_buffer_w: LINE; -- read buffer
--VARIABLE EOF_w: STD_LOGIC:='0'; -- End Of File variable
VARIABLE read_data_w: BIT_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- The line read from the file

BEGIN
  IF(en_read_w='1' and done_read_w='0') THEN
    IF (CLK_TB'EVENT AND CLK_TB='1') THEN
      FOR i IN 0 TO N_MAC-1 LOOP -- N_MAC=24
        IF(NOT endfile(w_file)) THEN
          readline(w_file, line_buffer_w); -- Reads the next full line from the file
          read(line_buffer_w, read_data_w); -- Stores the first bit_n bits from the buffer into the output signal 
          input_weights_tb(i) <= TO_STDLOGICVECTOR(read_data_w);
			ELSE
			 done_read_w <='1';
        END IF;
      END LOOP;
      
    END IF;
  END IF;   
END PROCESS;

----------------------------------------------------


Bias_Process: PROCESS(en_read_b)

FILE b_file: text OPEN read_mode IS "Bin_ColumnBias_dense_1.txt"; -- weights input file
VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
VARIABLE line_buffer_b: LINE; -- read buffer
--VARIABLE EOF_b: STD_LOGIC:='0'; -- End Of File variable
VARIABLE read_data_b: BIT_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- The line read from the file

BEGIN
  IF(en_read_b='1' and done_read_b='0' ) THEN
      FOR i IN 0 TO N_MAC-1 LOOP -- N_MAC=24
        IF(NOT endfile(b_file)) THEN
          readline(b_file, line_buffer_b); -- Reads the next full line from the file
          read(line_buffer_b, read_data_b); -- Stores the first bit_n bits from the buffer into the output signal 
			 input_bias_tb(i) <= TO_STDLOGICVECTOR(read_data_b);
--          input_bias_tb(i)(2*INPUT_SIZE-1 DOWNTO 2*INPUT_SIZE-5) <= (OTHERS => TO_STDLOGICVECTOR(read_data_b)(INPUT_SIZE-1));
--          input_bias_tb(i)(2*INPUT_SIZE-6 DOWNTO INPUT_SIZE-5) <= TO_STDLOGICVECTOR(read_data_b);
--          input_bias_tb(i)(INPUT_SIZE-6 DOWNTO 0) <= (OTHERS => '0');

        END IF;
      END LOOP;
      --done_read_b <='1';
  END IF;   
END PROCESS;

----------------------------------------------------

Input_Process: PROCESS(en_read_in)

FILE in_file: text OPEN read_mode IS "Bin_Input_from_prev_layer_1.txt"; -- INPUT FILE FROM PREVIOUS LAYER
VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
VARIABLE line_buffer_in: LINE; -- read buffer
--VARIABLE EOF_b: STD_LOGIC:='0'; -- End Of File variable
VARIABLE read_data_in: BIT_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- The line read from the file

BEGIN
  IF(en_read_in='1' and done_read_in='0') THEN
    FOR i in 0 TO INPUT_NEURONS LOOP -- da 0 a 399
      IF(NOT endfile(in_file)) THEN
        readline(in_file, line_buffer_in); -- Reads the next full line from the file
        read(line_buffer_in, read_data_in); -- Stores the first bit_n bits from the buffer into the output signal 
        input_value_tb(i) <= TO_STDLOGICVECTOR(read_data_in);
      END IF;
    END LOOP;
  done_read_in <='1'; -- quando finisco di leggere i 400 ingressi
  END IF; 
END PROCESS;

----------------------------------------------------


Output_Process: PROCESS(DONE)

FILE output_file: text OPEN write_mode IS "Bin_output_simulation_dense1.txt"; -- INPUT FILE FROM PREVIOUS LAYER
VARIABLE file_status: FILE_OPEN_STATUS; -- to check wether the file is already open
VARIABLE line_buffer: LINE; -- write buffer
--VARIABLE EOF_b: STD_LOGIC:='0'; -- End Of File variable
VARIABLE write_data: BIT_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- The line to write to the file

BEGIN
  
  IF(DONE='1' and done_write='0') THEN
    FOR i in 0 TO OUTPUT_NEURONS-1 LOOP -- da 0 a 119
      write_data := to_bitvector(output_FC1((i+1)*OUTPUT_SIZE-1 DOWNTO i*OUTPUT_SIZE));
      write(line_buffer, write_data, left, OUTPUT_SIZE-1); -- writes the input data to the buffer
      writeline(output_file, line_buffer); -- writes the buffer content to the file
    END LOOP;
  done_write <='1';
  END IF; 
  --file_close(output_file);
END PROCESS;


------------------------PORTMAP------------------------------------------

 GEN: FOR i IN 0 TO INPUT_NEURONS-1 GENERATE
      input_dut_tb((i+1)*INPUT_SIZE-1 DOWNTO i*INPUT_SIZE) <= input_value_tb(i);
  END GENERATE;


DUT : FC1_top 
	port map (

		START_TB,           	
		RST_TB_A_n,
		en_read_w,
		en_read_b,
		en_read_in,
		input_dut_tb,			
		input_weights_tb,	   
		input_bias_tb,		   
		CLK_TB,		 
		DONE,        	
		output_FC1);

end architecture behaviour;


