-- FC Top file --
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
use ieee.math_real.all;
USE work.all;
USE work.FC_struct_pkg.all;
USE work.CONV_struct_pkg.all;

ENTITY LeNet5_top IS	
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
		matrix_weights_CONV1	: IN matrix_5x5xMw;
		bias_mac_CONV1   		: IN INPUT_MAC_W;
				
		matrix_weights_step1, 
		matrix_weights_step2, 
		matrix_weights_step3,
		matrix_weights_step4 : IN matrix_5x5xMw_2;
		bias_memory			   : IN bias_from_file;

		input_weights_1	   : IN weights_struct_FC1;
		input_bias_1		   : IN bias_struct_FC1;
		input_weights_2	   : IN weights_struct_FC2;
		input_bias_FC2		   : IN bias_struct_FC2;
		input_weights_3	   : IN weights_struct_FC3;
		input_bias_3		   : IN bias_struct_FC3;
		
		
		-- done of each layer of the network
		DONE_CONV1		: OUT STD_LOGIC;
		DONE_CONV2		: OUT STD_LOGIC;
		DONE_FC1			: OUT STD_LOGIC;
		DONE_FC2			: OUT STD_LOGIC;
		DONE_FC3			: OUT STD_LOGIC;
		
		DONE_TOT				: OUT STD_LOGIC;
		
		-- output of the network
		output_conv1	: OUT Conv1_reg_Conv2;
		output_conv2	: OUT STD_LOGIC_VECTOR(INPUT_NEURONS_FC1*OUTPUT_SIZE-1 DOWNTO 0);
		output_fc1		: OUT STD_LOGIC_VECTOR(OUTPUT_NEURONS_FC1*OUTPUT_SIZE-1 DOWNTO 0);
		output_fc2		: OUT STD_LOGIC_VECTOR(OUTPUT_NEURONS_FC2*OUTPUT_SIZE-1 DOWNTO 0);
		output_TOT		: OUT STD_LOGIC_VECTOR(OUTPUT_NEURONS_FC3*OUTPUT_SIZE-1 DOWNTO 0) -- output of the layer to the output bank ragisters (outside the layer)
);
END LeNet5_top;

ARCHITECTURE structural OF LeNet5_top IS

--------- COMPONENTS ---------


-- Registers --

COMPONENT Input_registers IS
GENERIC(	
		CONSTANT INPUT_NEURONS  	: POSITIVE := 400);	
PORT(		
			input_value              : IN STD_LOGIC_VECTOR(INPUT_SIZE*INPUT_NEURONS-1 DOWNTO 0); 	
			CLK, RST 			       : IN STD_LOGIC; 
			EN_REG_IN                : IN STD_LOGIC; -- Enable of input bank register.
			output_reg				    : OUT STD_LOGIC_VECTOR(INPUT_SIZE*INPUT_NEURONS-1 DOWNTO 0) -- output of the input bank ragisters
);
END COMPONENT Input_registers;


COMPONENT Intermediate_Registers_1 IS
GENERIC(	
		CONSTANT OUTPUT_NEURONS  	: POSITIVE := 120);		
PORT(		
			input_value              : IN out_from_mac_FC1; -- from the ReLu inside the layer			
			CLK, RST 			       : IN STD_LOGIC; 
			EN_REG_OUT               : IN STD_LOGIC_VECTOR(N_CYCLES_FC1-1 DOWNTO 0); -- Enable of output bank register. We enable 24 register contemporary 
			output_reg				    : OUT STD_LOGIC_VECTOR(OUTPUT_SIZE*OUTPUT_NEURONS-1 DOWNTO 0) -- output of the output bank ragisters
);
END COMPONENT Intermediate_Registers_1;


COMPONENT Intermediate_Registers_2 IS
GENERIC(	
		CONSTANT OUTPUT_NEURONS  	: POSITIVE := 84);		
PORT(		
			input_value              : IN out_from_mac_FC2; -- from the ReLu inside the layer			
			CLK, RST 			       : IN STD_LOGIC; 
			EN_REG_OUT               : IN STD_LOGIC_VECTOR(N_CYCLES_FC2-1 DOWNTO 0); -- Enable of output bank register. We enable OUTPUT_NEURONS register contemporary 
			output_reg				    : OUT STD_LOGIC_VECTOR(OUTPUT_SIZE*OUTPUT_NEURONS-1 DOWNTO 0) -- output of the output bank ragisters
);
END COMPONENT Intermediate_Registers_2;

COMPONENT Output_registers IS
GENERIC(	
		CONSTANT OUTPUT_NEURONS  	: POSITIVE := 10);		
PORT(		
			input_value              : IN out_from_mac_FC3; -- from the ReLu inside the layer			
			CLK, RST 			       : IN STD_LOGIC; 
			EN_REG_OUT               : IN STD_LOGIC; -- Enable of output bank register. We enable 10 register contemporary 
			output_reg				    : OUT STD_LOGIC_VECTOR(OUTPUT_SIZE*OUTPUT_NEURONS-1 DOWNTO 0)); -- output of the output bank ragisters
END COMPONENT Output_registers;

-- End Registers --

-- Master CU --

COMPONENT CU_TOT IS -- AGGIUNGERE IL RESET DEI MAC QUANDO SI PASSA DA UN LAYER A UN ALTRO
PORT(        
		CLK            : IN STD_LOGIC;
      RST_A_n        : IN STD_LOGIC;
      START          : IN STD_LOGIC;
		
		DONE_CU_CONV1	: IN STD_LOGIC;
		DONE_CU_CONV2	: IN STD_LOGIC;
		DONE_CU_FC1		: IN STD_LOGIC;
		DONE_CU_FC2		: IN STD_LOGIC;
		DONE_CU_FC3		: IN STD_LOGIC;
		
		RST_S          : OUT STD_LOGIC;
		
		START_CU_CONV1		: OUT STD_LOGIC;
		START_CU_CONV2		: OUT STD_LOGIC;
		START_CU_FC1		: OUT STD_LOGIC;
		START_CU_FC2		: OUT STD_LOGIC;
		START_CU_FC3		: OUT STD_LOGIC;
		
		SEL_MUX_5		: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		SEL_MUX_4		: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		SEL_MUX_3		: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		
		SEL_MUX_MAC		: OUT STD_LOGIC;
		
		CLOCK_EN_CONV1 : OUT STD_LOGIC;
		CLOCK_EN_CONV2	: OUT STD_LOGIC;
		CLOCK_EN_FC1	: OUT STD_LOGIC;
		CLOCK_EN_FC2	: OUT STD_LOGIC;
		CLOCK_EN_FC3	: OUT STD_LOGIC;
		
		DONE_TOT        : OUT STD_LOGIC);
		
END COMPONENT CU_TOT;

-- Layers with their CU --


COMPONENT CONV1_top IS
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
			CLK, GCLK, RST_n     : IN STD_LOGIC; --DATAP e CU
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
			EN_REG_OUT 			 	: OUT EN_14X14);
END COMPONENT CONV1_top;


COMPONENT CONV2_top IS
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
				
PORT( 		in_row_image			: IN input_3_img_2;
				CLK, GCLK, RST_n 		: IN STD_LOGIC; --DATAP e CU
				START_CU_CONV2			: IN STD_LOGIC; --CU
				out_mac					: IN output_mac_2;
				acc_mac_0				: IN input_mac_b_2;
				acc_mac					: IN output_acc_2;
				matrix_weights 		: IN matrix_5x5xMw_2;
				bias						: IN input_bias_2;
				EN_MPY					: OUT STD_LOGIC;
				EN_ACC    				: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
				SEL_ADD1, SEL_ACC 	: OUT STD_LOGIC;
				in_mac_1					: OUT input_mac_img_2;
				in_mac_2					: OUT input_mac_w_2;
				in_add_opt_sum			: OUT input_mac_b_2;
				bias_mac					: OUT input_mac_b_2;
				SEL_ROW					: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
				DONE_CONV				: OUT STD_LOGIC;
				SEL_IMG 					: OUT STD_LOGIC;
				out_max_pool			: OUT output_conv_2;
				EN_REG_OUT_1,EN_REG_OUT_2	: OUT STD_LOGIC_VECTOR(24 DOWNTO 0);
				cnt4_step	         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
				);


END COMPONENT CONV2_top;


COMPONENT FC1_top IS
GENERIC(		
		CONSTANT INPUT_NEURONS   	: POSITIVE := 400;
		CONSTANT OUTPUT_NEURONS  	: POSITIVE := 120);
		
PORT(		
		START           	: IN STD_LOGIC;
		RST_A_n         	: IN STD_LOGIC;
		CLK, GCLK 			: IN STD_LOGIC;
		
		-- port useful for testbench
		EN_READ_W		 	: OUT STD_LOGIC;
		EN_READ_B		 	: OUT STD_LOGIC;
		--EN_READ_IN		 	: OUT STD_LOGIC;
		--EN_REG_IN      	: OUT STD_LOGIC; 	-- Enable of input bank register.		
		
		input_to_layer		: IN STD_LOGIC_VECTOR(INPUT_NEURONS*INPUT_SIZE-1 DOWNTO 0); -- input To the layer coming from previous layer
		input_weights	   : IN weights_struct_FC1;
		input_bias		   : IN bias_struct_FC1;
		
		RST_MPY				: OUT STD_LOGIC;
		EN_MPY, EN_ACC		: OUT STD_LOGIC;
		SEL_ACC				: OUT STD_LOGIC;

		data_from_mac		: IN out_from_mac_FC1;	-- from MAC block to layer
		EN_REG_OUT        : OUT STD_LOGIC_VECTOR(N_CYCLES_FC1-1 DOWNTO 0); -- Enable of output bank register. We enable 24 register contemporary
		DONE_FC1        	: OUT STD_LOGIC;
		out_reg_pipe		: OUT STD_LOGIC_VECTOR(INPUT_SIZE-1 DOWNTO 0); --Output of the register sampling the output from the input mux. It goes to external MAC_block
		output_weights  	: OUT weights_struct_FC1;
		output_bias     	: OUT bias_mac_struct_FC1;
		output_layer		: OUT out_from_mac_FC1 -- output of the layer to the output bank ragisters (outside the layer)
);
END COMPONENT FC1_top;

COMPONENT FC2_top IS
GENERIC(		
		CONSTANT INPUT_NEURONS   	: POSITIVE := 120;
		CONSTANT OUTPUT_NEURONS  	: POSITIVE := 84);
		
PORT(		
		START           	: IN STD_LOGIC;
		RST_A_n         	: IN STD_LOGIC;
		CLK, GCLK 			: IN STD_LOGIC;
		
		-- port useful for testbench
		EN_READ_W		 : OUT STD_LOGIC;
		EN_READ_B		 : OUT STD_LOGIC;
		--EN_READ_IN		 : OUT STD_LOGIC;
		--EN_REG_IN       : OUT STD_LOGIC; 	-- Enable of input bank register.		
		
		input_to_layer    : STD_LOGIC_VECTOR(INPUT_NEURONS*INPUT_SIZE-1 DOWNTO 0); -- values from previous layer, input to mux 120_to_1
		input_weights	   : IN weights_struct_FC2;
		input_bias		   : IN bias_struct_FC2;
		
		RST_MPY				: OUT STD_LOGIC;
		EN_MPY, EN_ACC		: OUT STD_LOGIC;
		SEL_ACC				: OUT STD_LOGIC;

		data_from_mac		: IN out_from_mac_FC2;	-- from MAC block to layer		
		EN_REG_OUT        : OUT STD_LOGIC_VECTOR(N_CYCLES_FC2-1 DOWNTO 0); -- Enable of output bank register. We enable 21 register contemporary	
		DONE_FC2        	: OUT STD_LOGIC;
		out_reg_pipe		: OUT STD_LOGIC_VECTOR(INPUT_SIZE-1 DOWNTO 0); --Output of the register sampling the output from the input mux. It goes to external MAC_block
		output_weights  	: OUT weights_struct_FC2;
		output_bias     	: OUT bias_mac_struct_FC2;
		output_layer	   : OUT out_from_mac_FC2 --Output of the layer (21 numbers)
);
END  COMPONENT FC2_top;

COMPONENT FC3_top IS
GENERIC(		
		CONSTANT INPUT_NEURONS   	: POSITIVE := 84;
		CONSTANT OUTPUT_NEURONS  	: POSITIVE := 10);
		
PORT(		
		START           	: IN STD_LOGIC;
		RST_A_n         	: IN STD_LOGIC;
		CLK, GCLK 			: IN STD_LOGIC;
		
		-- port useful for testbench
		EN_READ_W		 : OUT STD_LOGIC;
		EN_READ_B		 : OUT STD_LOGIC;
		--EN_READ_IN		 : OUT STD_LOGIC;
		--EN_REG_IN       : OUT STD_LOGIC; 	-- Enable of input bank register.			
		
		input_to_layer    : IN STD_LOGIC_VECTOR(INPUT_NEURONS*INPUT_SIZE-1 DOWNTO 0); -- values from previous layer, input to mux 84_to_1
		input_weights	   : IN weights_struct_FC3;
		input_bias		   : IN bias_struct_FC3;
		
		RST_MPY				: OUT STD_LOGIC;
		EN_MPY, EN_ACC		: OUT STD_LOGIC;
		SEL_ACC				: OUT STD_LOGIC;

		data_from_mac		: IN out_from_mac_FC3;	-- from MAC block to layer		
		EN_REG_OUT        : OUT STD_LOGIC; -- Enable of output bank register. We enable 10 register contemporary	
		DONE_FC3       	: OUT STD_LOGIC;
		out_reg_pipe		: OUT STD_LOGIC_VECTOR(INPUT_SIZE-1 DOWNTO 0); --Output of the register sampling the output from the input mux. It goes to external MAC_block
		output_weights  	: OUT weights_struct_FC3;
		output_bias     	: OUT bias_mac_struct_FC3;
		output_layer		: OUT out_from_mac_FC3 -- Output of the layer (10 numbers)
);
END COMPONENT FC3_top;


-- MAC block --
COMPONENT mac_block IS  
GENERIC(	N				: NATURAL:=10;
			M				: NATURAL:=3);
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



-- MUX to manage the shared MACs --
COMPONENT mux5to1_nbit IS
GENERIC(P   : NATURAL:=8;  -- Parallelism of input
        --M   : NATURAL:=4; -- Number of input elements
        S   : NATURAL:=3);  -- Parallelism of selector ( ceil(log2(M)) )
PORT(	data_in_1   : IN STD_LOGIC_VECTOR(P-1 DOWNTO 0);
		data_in_2   : IN STD_LOGIC_VECTOR(P-1 DOWNTO 0);
		data_in_3   : IN STD_LOGIC_VECTOR(P-1 DOWNTO 0);
		data_in_4   : IN STD_LOGIC_VECTOR(P-1 DOWNTO 0);
		data_in_5   : IN STD_LOGIC_VECTOR(P-1 DOWNTO 0);
		
		SEL			: IN STD_LOGIC_VECTOR(S-1 DOWNTO 0):= (OTHERS => '0');
		q		 		: OUT STD_LOGIC_VECTOR(P-1 DOWNTO 0));
END COMPONENT mux5to1_nbit;

COMPONENT mux4to1_nbit IS
GENERIC(P   : NATURAL:=8;  -- Parallelism of input
        --M   : NATURAL:=4; -- Number of input elements
        S   : NATURAL:=3);  -- Parallelism of selector ( ceil(log2(M)) )
PORT(	data_in_1   : IN STD_LOGIC_VECTOR(P-1 DOWNTO 0);
		data_in_2   : IN STD_LOGIC_VECTOR(P-1 DOWNTO 0);
		data_in_3   : IN STD_LOGIC_VECTOR(P-1 DOWNTO 0);
		data_in_4   : IN STD_LOGIC_VECTOR(P-1 DOWNTO 0);
		
		SEL			: IN STD_LOGIC_VECTOR(S-1 DOWNTO 0):= (OTHERS => '0');
		q		 		: OUT STD_LOGIC_VECTOR(P-1 DOWNTO 0));
END COMPONENT mux4to1_nbit;

COMPONENT mux5to1_1bit IS
GENERIC(S   : NATURAL:=3);  -- Parallelism of selector ( ceil(log2(M)) )
PORT(	data_in_1   : IN STD_LOGIC;
		data_in_2   : IN STD_LOGIC;
		data_in_3   : IN STD_LOGIC;
		data_in_4   : IN STD_LOGIC;
		data_in_5   : IN STD_LOGIC;
		
		SEL			: IN STD_LOGIC_VECTOR(S-1 DOWNTO 0):= (OTHERS => '0');
		q		 		: OUT STD_LOGIC);
END COMPONENT mux5to1_1bit;

COMPONENT mux4to1_1bit IS
GENERIC(S   : NATURAL:=2);  -- Parallelism of selector ( ceil(log2(M)) )
PORT(	data_in_1   : IN STD_LOGIC;
		data_in_2   : IN STD_LOGIC;
		data_in_3   : IN STD_LOGIC;
		data_in_4   : IN STD_LOGIC;
		
		SEL			: IN STD_LOGIC_VECTOR(S-1 DOWNTO 0):= (OTHERS => '0');
		q		 		: OUT STD_LOGIC);
END COMPONENT mux4to1_1bit;

COMPONENT muxMto1_nbit IS
GENERIC(P   : NATURAL:=4;  -- Parallelism of input
        M   : NATURAL:=4; 	-- Number of input elements
        S   : NATURAL:=2); -- Parallelism of selector ( ceil(log2(M)) )
PORT(	data_in   : IN STD_LOGIC_VECTOR(M*P-1 DOWNTO 0);
			SEL				  : IN STD_LOGIC_VECTOR(S-1 DOWNTO 0):= (OTHERS => '0');
			q			 		: OUT STD_LOGIC_VECTOR(P-1 DOWNTO 0));
END COMPONENT muxMto1_nbit;

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

COMPONENT clock_gating IS
PORT(    
		CLK       : IN STD_LOGIC;
      EN        : IN STD_LOGIC;
		GCLK	    : OUT STD_LOGIC);		
END COMPONENT clock_gating;

------------- SIGNALS --------------

-- CU SIGNALS --
SIGNAL START_CU_CONV1	: STD_LOGIC;
SIGNAL START_CU_CONV2	: STD_LOGIC;
SIGNAL START_CU1			: STD_LOGIC;
SIGNAL START_CU2			: STD_LOGIC; 
SIGNAL START_CU3			: STD_LOGIC;  	

SIGNAL DONE_CU_CONV1		: STD_LOGIC;
SIGNAL DONE_CU_CONV2		: STD_LOGIC;					 
SIGNAL DONE_CU1			: STD_LOGIC;
SIGNAL DONE_CU2			: STD_LOGIC;
SIGNAL DONE_CU3			: STD_LOGIC;

SIGNAL SEL_MUX_5			: STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL SEL_MUX_4			: STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL SEL_MUX_3			: STD_LOGIC_VECTOR(1 DOWNTO 0);

SIGNAL RST				 	: STD_LOGIC;

-- REGISTERS SIGNALS --
SIGNAL EN_REG_OUT_CONV1	: EN_14X14; 

SIGNAL EN_REG_400_1,EN_REG_400_2		: STD_LOGIC_VECTOR(24 DOWNTO 0);

SIGNAL EN_REG_120			: STD_LOGIC_VECTOR(N_CYCLES_FC1-1 DOWNTO 0); -- Enable of intermediate 120 bank register;
SIGNAL EN_REG_84			: STD_LOGIC_VECTOR(N_CYCLES_FC2-1 DOWNTO 0); -- Enable of intermediate 84 bank register;
SIGNAL EN_REG_10			: STD_LOGIC; -- Enable of output bank register;

-- input to MAC mux --
-- various control signals --
SIGNAL RST_MPY_CONV1						: STD_LOGIC;
SIGNAL EN_MPY_CONV1, EN_ACC_CONV1	: array_en;
SIGNAL EN_MPY_CONV1_24 , EN_ACC_CONV1_24: STD_LOGIC_VECTOR(23 DOWNTO 0);
SIGNAL SEL_ACC_CONV1 					: STD_LOGIC;
SIGNAL SEL_MUX_MAC        : STD_LOGIC;

SIGNAL RST_MPY_CONV2						: STD_LOGIC;
SIGNAL EN_MPY_CONV2						: STD_LOGIC;
SIGNAL EN_ACC_CONV2						: STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL EN_ACC_CONV2_24					: STD_LOGIC_VECTOR(23 DOWNTO 0);
SIGNAL SEL_ACC_CONV2 					: STD_LOGIC;
SIGNAL SEL_ADD1_CONV2					: STD_LOGIC;

SIGNAL RST_MPY_FC1						: STD_LOGIC;
SIGNAL EN_MPY_FC1, EN_ACC_FC1			: STD_LOGIC;
SIGNAL SEL_ACC_FC1 						: STD_LOGIC;

SIGNAL RST_MPY_FC2						: STD_LOGIC;
SIGNAL EN_MPY_FC2, EN_ACC_FC2			: STD_LOGIC;
SIGNAL SEL_ACC_FC2						: STD_LOGIC;

SIGNAL RST_MPY_FC3						: STD_LOGIC;
SIGNAL EN_MPY_FC3, EN_ACC_FC3			: STD_LOGIC;
SIGNAL SEL_ACC_FC3						: STD_LOGIC;

			
-- output weights from each layer to MAC block
SIGNAL out_conv1_weights      : INPUT_MAC_W; -- CONV1
SIGNAL out_conv1_weights_24   : weights_struct_FC1;

SIGNAL out_conv2_weights		: input_mac_w_2;
SIGNAL out_conv2_weights_24	: weights_struct_FC1;

SIGNAL out_fc1_weights	   	: weights_struct_FC1;
SIGNAL out_fc2_weights	   	: weights_struct_FC2;
SIGNAL out_fc3_weights	   	: weights_struct_FC3;

-- output bias from each layer to MAC block
SIGNAL out_conv1_bias         : INPUT_MAC_B;
SIGNAL out_conv1_bias_24      : bias_mac_struct_FC1;

SIGNAL out_conv2_bias       	: input_mac_b_2;
SIGNAL out_conv2_bias_24		: bias_mac_struct_FC1; -- := ( others => (others => '0') );

SIGNAL out_fc1_bias	   		: bias_mac_struct_FC1;
SIGNAL out_fc2_bias	   		: bias_mac_struct_FC2;
SIGNAL out_fc3_bias	   		: bias_mac_struct_FC3;

-- output from each layer to MAC block
SIGNAL input_mac_conv1     	: INPUT_MAC_IMG;

SIGNAL input_mac_conv2			: input_mac_img_2;
SIGNAL input_mac_conv2_24: weights_struct_FC1;

SIGNAL output_reg_pipe_fc1		: STD_LOGIC_VECTOR(INPUT_SIZE-1 DOWNTO 0); --Output of the layer (1 numbers)
SIGNAL output_reg_pipe_fc2		: STD_LOGIC_VECTOR(INPUT_SIZE-1 DOWNTO 0); --Output of the layer (1 numbers)
SIGNAL output_reg_pipe_fc3		: STD_LOGIC_VECTOR(INPUT_SIZE-1 DOWNTO 0); --Output of the layer (1 numbers)

SIGNAL zeros_input 				: STD_LOGIC_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- := ( others => '0' );
SIGNAL zeros_bias					: STD_LOGIC_VECTOR(2*INPUT_SIZE-2 DOWNTO 0); -- := ( others => '0' );

-- output of MAC mux --
SIGNAL out_mux_weights	   	: weights_struct_FC1;
SIGNAL out_mux_bias	   		: bias_mac_struct_FC1;
SIGNAL out_mux_input	   		: out_from_mac_FC1;
SIGNAL RST_MPY						: STD_LOGIC;
SIGNAL EN_MPY, EN_ACC			: STD_LOGIC_VECTOR(N_MAC_FC1-1 DOWNTO 0);
SIGNAL SEL_ACC						: STD_LOGIC_VECTOR(N_MAC_FC1-1 DOWNTO 0);

-- outputs of MAC --
SIGNAL out_mac_conv1          : OUTPUT_MAC;
SIGNAL out_mac_conv2			   : output_mac_2;
SIGNAL data_from_mac			   : out_from_mac_FC1;	-- from MAC block to layer
SIGNAL data_from_mac_FC2	   : out_from_mac_FC2;	-- from MAC block to layer
SIGNAL data_from_mac_FC3	   : out_from_mac_FC3;	-- from MAC block to layer

-- ........... --

-- outputs from layers to registers --
SIGNAL input_to_reg14X14X6  	: INPUT_MAC_W;
SIGNAL input_to_reg_400			: output_conv_2;
SIGNAL input_to_reg120        : out_from_mac_FC1; -- 24 Numbers
SIGNAL input_to_reg84         : out_from_mac_FC2; -- 21 Numbers
SIGNAL input_to_reg10         : out_from_mac_FC3; -- 10 Numbers

-- inputs to layers from registers --
SIGNAL out_regs_conv1		 : Conv1_reg_Conv2;

SIGNAL row_in					 :	array6_row_14x14;
SIGNAL out_mux_row			 :	array6_row;
SIGNAL input_to_conv2       : input_3_img_2;

SIGNAL input_to_fc1         : STD_LOGIC_VECTOR(INPUT_NEURONS_FC1*INPUT_SIZE-1 DOWNTO 0); -- values from previous layer, input to mux 400_to_1
SIGNAL input_to_fc2         : STD_LOGIC_VECTOR(INPUT_NEURONS_FC2*INPUT_SIZE-1 DOWNTO 0); -- values from previous layer, input to mux 120_to_1
SIGNAL input_to_fc3         : STD_LOGIC_VECTOR(INPUT_NEURONS_FC3*INPUT_SIZE-1 DOWNTO 0); -- values from previous layer, input to mux 84_to_1

-- bias and weights of conv2 after muliplexer --
SIGNAL bias_conv2						: input_bias_2;
SIGNAL matrix_weights_conv2 		: matrix_5x5xMw_2;


-- Signals (only conv2) --
SIGNAL in_add_opt_sum			: input_mac_b_2;
SIGNAL in_add_opt_sum_24		: bias_mac_struct_FC1; -- := ( others => (others => '0') );

SIGNAL acc_mac				      : output_acc_2;
SIGNAL acc_mac_24					: bias_mac_struct_FC1; -- := ( others => (others => '0') );
SIGNAL acc_mac_0				   : input_mac_b_2;
SIGNAL SEL_ROW						: STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL SEL_IMG 					: STD_LOGIC;
SIGNAL cnt4_step	         	: STD_LOGIC_VECTOR(1 DOWNTO 0);


-- Signals CLOCK GATING --
SIGNAL CLOCK_EN_CONV1 	:  STD_LOGIC;
SIGNAL CLOCK_EN_CONV2 	:  STD_LOGIC;
SIGNAL CLOCK_EN_FC1		:  STD_LOGIC;
SIGNAL CLOCK_EN_FC2		:  STD_LOGIC;
SIGNAL CLOCK_EN_FC3		:  STD_LOGIC;
SIGNAL GCLK_CONV1			: 	STD_LOGIC;
SIGNAL GCLK_CONV2			: 	STD_LOGIC;
SIGNAL GCLK_FC1			: 	STD_LOGIC;
SIGNAL GCLK_FC2			: 	STD_LOGIC;
SIGNAL GCLK_FC3			: 	STD_LOGIC;

----------- END SIGNALS -----------------

BEGIN

-----------------------------------------------------------------------------
---------------------------------- CONV1 ------------------------------------
-----------------------------------------------------------------------------
CONVOLUTIONAL_1: CONV1_top

			GENERIC MAP(32, 				-- is the width of the input image
							8,  				-- is the parallelism of each pixel
							WEIGHT_SIZE, 	-- is the parallelism of weights
							5,  				-- is the width of the weights matrix
							6,  				-- is the number of weights matrices
							28, 				-- is the width of the output image
							OUTPUT_SIZE,	-- is the parallelism of each element of the output matrix (the same of weights)
							0,  				-- EXTRA BIT
							14) 				-- to avoid overflow
							
			PORT MAP(in_row_image1,	      
						in_row_image2,      
						CLK, GCLK_CONV1, RST_A_n, 		      
						START_CU_CONV1,	      
						out_mac_conv1,    -- gestire questo ingresso dalle uscite dei mac    
						matrix_weights_CONV1, 	
						bias_mac_CONV1,       		
						SEL_ACC_CONV1,	 				
						input_mac_conv1,         	
						out_conv1_weights,          
						out_conv1_bias,          	
						input_to_reg14X14X6,  		
						DONE_CU_CONV1, READ_IMG,  	
						EN_MPY_CONV1,					
						EN_ACC_CONV1,					
						EN_REG_OUT_CONV1); 			 	
			
-- ASSEGNAZIONE USCITA DEL MAC IN INGRESSO AL LAYER --
GEN_out_mac:FOR i IN 0 TO 23 GENERATE	
  out_mac_conv1(i) <= data_from_mac(i);
END GENERATE;
			
-----------------------------------------------------------------------------
--------------------------- Matrix CONV1 OUT --------------------------------
-----------------------------------------------------------------------------
			
GEN_6_OUT_MATRIX:FOR a IN 0 TO 6-1 GENERATE	
	GEN_BANK_REG1: FOR i IN 0 TO 14-1 GENERATE					  
		GEN_BANK_REG2: FOR j IN 0 TO 14-1 GENERATE		
				Out_registers: register_nbit
					GENERIC MAP (M_mpy)
					PORT MAP    (input_to_reg14X14X6(a), --output_layer(a)
										EN_REG_OUT_CONV1(i,j), GCLK_CONV1, RST,
										out_regs_conv1(a,i,j));
										
					row_in(a)((14*(14-i)-j)*M_in-1 DOWNTO (14*(14-i)-j-1)*M_in) <= out_regs_conv1(a,i,j);
		END GENERATE;
	END GENERATE;
END GENERATE;
			


-- READ_IMG serve per dirmi quando leggere una riga
--INTERFACCIA TRA REGISTRI DI USCITA DEL CONV1 E INGRESSO DEL CONV2, bisogna mettere dei mux 14to1
GEN_6_MUX14: FOR a IN 0 TO 5 GENERATE
		MUX_14TO1 : mux14to1_nbit 
			GENERIC MAP(14*M_mpy)
			PORT MAP(	row_in(a),
							SEL_ROW,
							out_mux_row(a));
END GENERATE;

GEN_3_MUX2: FOR a IN 0 TO 2 GENERATE
		MUX_2TO1 : mux2to1_nbit 
			GENERIC MAP(M_in*14)
			PORT MAP(	out_mux_row(a),out_mux_row(a+3),
							SEL_IMG,
							input_to_conv2(a));
END GENERATE;			


--- MUX PER SCEGLIERE I WEIGHTS
matrix_weights_sel: PROCESS(cnt4_step,matrix_weights_step1,matrix_weights_step2,matrix_weights_step3,matrix_weights_step4)
BEGIN
	CASE cnt4_step IS
		--WHEN "00" => matrix_weights <= matrix_weights_step1;
		WHEN "01" => matrix_weights_conv2 <= matrix_weights_step2;
		WHEN "10" => matrix_weights_conv2 <= matrix_weights_step3;
		WHEN "11" => matrix_weights_conv2 <= matrix_weights_step4;
		WHEN OTHERS => matrix_weights_conv2 <= matrix_weights_step1;
	END CASE;
END PROCESS;

--- MUX PER SCEGLIERE I BIAS
GEN_8_MUX2: FOR a IN 0 TO 7 GENERATE
		MUX_2TO1 : mux2to1_nbit 
			GENERIC MAP(M_mpy)
			PORT MAP(	bias_memory(a),bias_memory(a+8),
							cnt4_step(1),
							bias_conv2(a));
END GENERATE;



-----------------------------------------------------------------------------
---------------------------------- CONV2 ------------------------------------
-----------------------------------------------------------------------------



CONVOLUTIONAL_2: CONV2_top

GENERIC MAP(		14, 				-- is the width of the input image
						WEIGHT_SIZE, 	-- is the parallelism of each pixel
						WEIGHT_SIZE, 	-- is the parallelism of weights
						5,  				-- is the width of the weights matrix
						--I_w        		: NATURAL:=16;  -- is the number of weights matrices
						10, 				-- is the width of the output image
						OUTPUT_SIZE, 	-- is the parallelism of each element of the output matrix (the same of weights)
						6, 				-- is the number of input matrices
						16,
						0,
						5) 				-- to avoid overflow
				
PORT MAP( 			input_to_conv2,
						CLK, GCLK_CONV2, RST_A_n, 				
						START_CU_CONV2,			
						out_mac_conv2,			
						acc_mac_0,				
						acc_mac,					
						matrix_weights_conv2, 		
						bias_conv2,						
						EN_MPY_CONV2,					
						EN_ACC_CONV2,    				
						SEL_ADD1_CONV2, SEL_ACC_CONV2, 	
						input_mac_conv2,					
						out_conv2_weights,					
						in_add_opt_sum,			
						out_conv2_bias,					
						SEL_ROW,					
						DONE_CU_CONV2,				
						SEL_IMG, 					
						input_to_reg_400,			
						EN_REG_400_1,EN_REG_400_2,	
						cnt4_step);

-- ASSEGNAZIONE USCITA DEL MAC IN INGRESSO AL LAYER --
GEN_out_mac_conv2_a : FOR a IN 0 TO 2 GENERATE
	GEN_out_mac_conv2_i : FOR i IN 0 TO 7 GENERATE
		out_mac_conv2(a,i) <= data_from_mac(a*8+i);
	END GENERATE;
END GENERATE;

-----------------------------------------------------------------------------
------------------------- FC REGISTERS + LAYERS -----------------------------
----------------------------------------------------------------------------- 

------- BANCO DI REGISTRI 400
GEN_16 : FOR a IN 0 TO 7 GENERATE
	GEN_5R : FOR i IN 0 TO 4 GENERATE
		GEN_5C : FOR j IN 0 TO 4 GENERATE
				BANK_OUTPUT_STEP2: register_nbit 
				GENERIC MAP(M_mpy)
				PORT MAP(	input_to_reg_400(a),
								EN_REG_400_1((i*5+j)), GCLK_CONV2, RST,
								input_to_fc1( ((i*5+j)*16+a+1)*M_mpy-1 DOWNTO ((i*5+j)*16+a)*M_mpy) );
				
				BANK_OUTPUT_STEP4: register_nbit 
				GENERIC MAP(M_mpy)
				PORT MAP(	input_to_reg_400(a),
								EN_REG_400_2((i*5+j)), GCLK_CONV2, RST,
								input_to_fc1(((i*5+j)*16+a+1+8)*M_mpy-1 DOWNTO ((i*5+j)*16+a+8)*M_mpy));
		END GENERATE;
	END GENERATE;
END GENERATE;
			
			
FC1_LAYER:  FC1_top
			GENERIC MAP(INPUT_NEURONS_FC1,OUTPUT_NEURONS_FC1)
			
			PORT MAP(START_CU1,
						RST_A_n,
						CLK, GCLK_FC1,
						EN_READ_W_1,
						EN_READ_B_1,
						input_to_fc1,
						input_weights_1,
						input_bias_1,
						RST_MPY_FC1,
						EN_MPY_FC1, EN_ACC_FC1,
						SEL_ACC_FC1,
						data_from_mac, --NEGLI ALTRI LAYER PRENDERE SOLO QUELLI CHE SERVONO
						EN_REG_120,
						DONE_CU1,
						output_reg_pipe_fc1,
						out_fc1_weights,
						out_fc1_bias,
						input_to_reg120);
						
						
REGISTER_120:  Intermediate_Registers_1
			GENERIC MAP  (OUTPUT_NEURONS_FC1)
			PORT MAP     (input_to_reg120,GCLK_FC1,RST,EN_REG_120,input_to_fc2);
			
			

GEN_DATA_FROM_MAC_FC2:FOR i IN 0 TO N_MAC_FC2-1 GENERATE
	data_from_mac_FC2(i) <= data_from_mac(i);
END GENERATE;


FC2_LAYER:  FC2_top
			GENERIC MAP(INPUT_NEURONS_FC2,OUTPUT_NEURONS_FC2)
			
			PORT MAP(START_CU2,
						RST_A_n,
						CLK, GCLK_FC2,
						EN_READ_W_2,
						EN_READ_B_2,
						input_to_fc2,
						input_weights_2,
						input_bias_FC2,
						RST_MPY_FC2,
						EN_MPY_FC2, EN_ACC_FC2,
						SEL_ACC_FC2,
						data_from_mac_FC2,
						EN_REG_84,
						DONE_CU2,
						output_reg_pipe_fc2,
						out_fc2_weights,
						out_fc2_bias,
						input_to_reg84);

						
REGISTER_84:  Intermediate_Registers_2
			GENERIC MAP  (OUTPUT_NEURONS_FC2)
			PORT MAP     (input_to_reg84,GCLK_FC2,RST,EN_REG_84,input_to_fc3);
			
			
GEN_DATA_FROM_MAC_FC3:FOR i IN 0 TO N_MAC_FC3-1 GENERATE
	data_from_mac_FC3(i) <= data_from_mac(i);
END GENERATE;
			
			
FC3_LAYER:  FC3_top
			GENERIC MAP(INPUT_NEURONS_FC3,OUTPUT_NEURONS_FC3)
			
			PORT MAP(START_CU3,
						RST_A_n,
						CLK, GCLK_FC3,
						EN_READ_W_3,
						EN_READ_B_3,
						input_to_fc3,
						input_weights_3,
						input_bias_3,
						RST_MPY_FC3,
						EN_MPY_FC3, EN_ACC_FC3,
						SEL_ACC_FC3,
						data_from_mac_FC3,
						EN_REG_10,
						DONE_CU3,
						output_reg_pipe_fc3,
						out_fc3_weights,
						out_fc3_bias,
						input_to_reg10);	

		
	
REGISTER_10: Output_registers 
			GENERIC MAP  (OUTPUT_NEURONS_FC3)
			PORT MAP     (input_to_reg10,GCLK_FC3,RST,EN_REG_10,output_TOT);	
	
			
-- GENERATE TO CORRECTLY FEED MAC MUXs --
			
GEN_BIAS_24_CONV2: FOR i in 0 to 7 GENERATE
	out_conv2_bias_24(i) <= out_conv2_bias(i);
	in_add_opt_sum_24(i) <= in_add_opt_sum(i);
	acc_mac_0(i) <= acc_mac_24(i);
END GENERATE;	
		
GEN_ACC_CONV2_2: FOR a in 0 to 1 GENERATE
	GEN_ACC_CONV2_8: FOR i in 0 to 7 GENERATE
	acc_mac(a,i)	 <= acc_mac_24((a+1)*8+i);
	END GENERATE;		
END GENERATE;

GEN_WEIGHTS_CONV2_3: FOR a in 0 to 2 GENERATE
	GEN_WEIGHTS_CONV2_8: FOR i in 0 to 7 GENERATE
		out_conv2_weights_24(a*8+i) <= out_conv2_weights(a,i);
	END GENERATE;		
END GENERATE;


GEN_ACC_24_CONV2_1: FOR i in 0 to 7 GENERATE
	EN_ACC_CONV2_24(i) <= EN_ACC_CONV2(1);
END GENERATE;	

GEN_ACC_24_CONV2_2: FOR i in 8 to 23 GENERATE
	EN_ACC_CONV2_24(i) <= EN_ACC_CONV2(0);
END GENERATE;	


-- GENERATE OF out_conv1_bias --
GEN_OUT_CONV1_BIAS_a: FOR a in 0 to 5 GENERATE
  GEN_OUT_CONV1_BIAS_i: FOR i in 0 to 3 GENERATE
    out_conv1_bias_24(a*4+i) <= out_conv1_bias(a);
  END GENERATE;
END GENERATE;	


-- GENERATE OF out_conv1_weights --
GEN_OUT_CONV1_WEIGHTS_a: FOR a in 0 to 5 GENERATE
  GEN_OUT_CONV1_WEIGHTS_i : FOR i in 0 to 3 GENERATE
	  out_conv1_weights_24(i+a*4) <= out_conv1_weights(a);
	END GENERATE;
END GENERATE;	


-- GENERATE OF EN_ACC_CONV1 --
GEN_EN_ACC_CONV1_a: FOR a in 0 to 5 GENERATE
  GEN_EN_AC_CONV1_i : FOR i in 0 to 3 GENERATE
	  EN_ACC_CONV1_24(i+a*4) <= EN_ACC_CONV1(i,a);
	END GENERATE;
END GENERATE;


-- GENERATE OF EN_MPY_CONV1 --
GEN_EN_MPY_CONV1_a: FOR a in 0 to 5 GENERATE
  GEN_EN_MPY_CONV1_i : FOR i in 0 to 3 GENERATE
	  EN_MPY_CONV1_24(i+a*4) <= EN_MPY_CONV1(i,a);
	END GENERATE;
END GENERATE;

-- GENERATE OF input_mac_conv2 --			
GEN_INPUT_MAC_CONV2_a: FOR a in 0 to 2 GENERATE
  GEN_INPUT_MAC_CONV2_i: FOR i in 0 to 7 GENERATE
	 input_mac_conv2_24(a*8+i) <= input_mac_conv2(a);
	END GENERATE;
END GENERATE;	


-----------------------------------------------------------------------------
----------------------------- 10 MUX 5 TO 1 ---------------------------------
-----------------------------------------------------------------------------
--- DATA MUXs ---			
GEN_MUX_BIAS: FOR i in 0 TO N_MAC_FC3-1 GENERATE
	MUX_BIAS : mux5to1_nbit
		GENERIC MAP(BIAS_SIZE*2-1,3)
		PORT MAP(out_conv1_bias_24(i),out_conv2_bias_24(i),out_fc1_bias(i),out_fc2_bias(i),out_fc3_bias(i),SEL_MUX_5,out_mux_bias(i));
END GENERATE;

GEN_MUX_WEIGTHS: FOR i in 0 TO N_MAC_FC3-1 GENERATE
	MUX_WEIGTHS : mux5to1_nbit
		GENERIC MAP(WEIGHT_SIZE,3)
		PORT MAP(out_conv1_weights_24(i),out_conv2_weights_24(i),out_fc1_weights(i),out_fc2_weights(i),out_fc3_weights(i),SEL_MUX_5,out_mux_weights(i));
END GENERATE;

GEN_MUX_INPUT: FOR i in 0 TO N_MAC_FC3-1 GENERATE
	MUX_INPUT : mux5to1_nbit
		GENERIC MAP(OUTPUT_SIZE,3)
		PORT MAP(input_mac_conv1(i mod 4),input_mac_conv2_24(i),output_reg_pipe_fc1,output_reg_pipe_fc2,output_reg_pipe_fc3,SEL_MUX_5,out_mux_input(i));
END GENERATE;

--- CTRL MUXs ---

RST_MPY <= RST_MPY_FC1 OR RST_MPY_FC2 OR RST_MPY_FC3; -- The same for each of 24 MACs

-----------------

GEN_MUX_EN_MUL: FOR i in 0 TO N_MAC_FC3-1 GENERATE
	MUX_EN_MUL : mux5to1_1bit
		GENERIC MAP(3)
		PORT MAP(EN_MPY_CONV1_24(i),EN_MPY_CONV2,EN_MPY_FC1,EN_MPY_FC2,EN_MPY_FC3,SEL_MUX_5,EN_MPY(i));
END GENERATE;

GEN_MUX_EN_ACC: FOR i in 0 TO N_MAC_FC3-1 GENERATE
	MUX_EN_ACC : mux5to1_1bit
		GENERIC MAP(3)
		PORT MAP(EN_ACC_CONV1_24(i),EN_ACC_CONV2_24(i),EN_ACC_FC1,EN_ACC_FC2,EN_ACC_FC3,SEL_MUX_5,EN_ACC(i));
END GENERATE;

GEN_MUX_SEL_ACC: FOR i in 0 TO N_MAC_FC3-1 GENERATE
	MUX_SEL_ACC : mux5to1_1bit
		GENERIC MAP(3)
		PORT MAP(SEL_ACC_CONV1,SEL_ACC_CONV2,SEL_ACC_FC1,SEL_ACC_FC2,SEL_ACC_FC3,SEL_MUX_5,SEL_ACC(i));
END GENERATE;



-----------------------------------------------------------------------------
---------------------------- 21-10 MUX 4 TO 1 -------------------------------
-----------------------------------------------------------------------------
--- DATA MUXs ---			
GEN_MUX_BIAS_4: FOR i in N_MAC_FC3 TO N_MAC_FC2-1 GENERATE
	MUX_BIAS : mux4to1_nbit
		GENERIC MAP(BIAS_SIZE*2-1,2)
		PORT MAP(out_conv1_bias_24(i),out_conv2_bias_24(i),out_fc1_bias(i),out_fc2_bias(i),SEL_MUX_4,out_mux_bias(i));
END GENERATE;

GEN_MUX_WEIGTHS_4: FOR i in N_MAC_FC3 TO N_MAC_FC2-1 GENERATE
	MUX_WEIGTHS : mux4to1_nbit
		GENERIC MAP(WEIGHT_SIZE,2)
		PORT MAP(out_conv1_weights_24(i),out_conv2_weights_24(i),out_fc1_weights(i),out_fc2_weights(i),SEL_MUX_4,out_mux_weights(i));
END GENERATE;

GEN_MUX_INPUT_4: FOR i in N_MAC_FC3 TO N_MAC_FC2-1 GENERATE
	MUX_INPUT : mux4to1_nbit
		GENERIC MAP(OUTPUT_SIZE,2)
		PORT MAP(input_mac_conv1(i mod 4),input_mac_conv2_24(i),output_reg_pipe_fc1,output_reg_pipe_fc2,SEL_MUX_4,out_mux_input(i));
END GENERATE;

--- CTRL MUXs ---

GEN_MUX_EN_MUL_4: FOR i in N_MAC_FC3 TO N_MAC_FC2-1 GENERATE
	MUX_EN_MUL : mux4to1_1bit
		GENERIC MAP(2)
		PORT MAP(EN_MPY_CONV1_24(i),EN_MPY_CONV2,EN_MPY_FC1,EN_MPY_FC2,SEL_MUX_4,EN_MPY(i));
END GENERATE;

GEN_MUX_EN_ACC_4: FOR i in N_MAC_FC3 TO N_MAC_FC2-1 GENERATE
	MUX_EN_ACC : mux4to1_1bit
		GENERIC MAP(2)
		PORT MAP(EN_ACC_CONV1_24(i),EN_ACC_CONV2_24(i),EN_ACC_FC1,EN_ACC_FC2,SEL_MUX_4,EN_ACC(i));
END GENERATE;

GEN_MUX_SEL_ACC_4: FOR i in N_MAC_FC3 TO N_MAC_FC2-1 GENERATE
	MUX_SEL_ACC : mux4to1_1bit
		GENERIC MAP(2)
		PORT MAP(SEL_ACC_CONV1,SEL_ACC_CONV2,SEL_ACC_FC1,SEL_ACC_FC2,SEL_MUX_4,SEL_ACC(i));
END GENERATE;


-----------------------------------------------------------------------------
--------------------------- 24-21 MUX 3 TO 1 --------------------------------
-----------------------------------------------------------------------------
--- DATA MUXs ---	

GEN_MUX_BIAS_3: FOR i in N_MAC_FC2 TO N_MAC_FC1-1 GENERATE
	MUX_BIAS : mux4to1_nbit
		GENERIC MAP(BIAS_SIZE*2-1,2)
		PORT MAP(out_conv1_bias_24(i),out_conv2_bias_24(i),out_fc1_bias(i),zeros_bias,SEL_MUX_3,out_mux_bias(i));
END GENERATE;		

GEN_MUX_WEIGTHS_3: FOR i in N_MAC_FC2 TO N_MAC_FC1-1 GENERATE
	MUX_WEIGTHS : mux4to1_nbit
		GENERIC MAP(WEIGHT_SIZE,2)
		PORT MAP(out_conv1_weights_24(i),out_conv2_weights_24(i),out_fc1_weights(i),zeros_input,SEL_MUX_3,out_mux_weights(i));
END GENERATE;

GEN_MUX_INPUT_3: FOR i in N_MAC_FC2 TO N_MAC_FC1-1 GENERATE
	MUX_INPUT : mux4to1_nbit
		GENERIC MAP(OUTPUT_SIZE,2)
		PORT MAP(input_mac_conv1(i mod 4),input_mac_conv2_24(i),output_reg_pipe_fc1,zeros_input,SEL_MUX_3,out_mux_input(i));
END GENERATE;

--- CTRL MUXs ---

GEN_MUX_EN_MUL_3: FOR i in N_MAC_FC2 TO N_MAC_FC1-1 GENERATE
	MUX_EN_MUL : mux4to1_1bit
		GENERIC MAP(2)
		PORT MAP(EN_MPY_CONV1_24(i),EN_MPY_CONV2,EN_MPY_FC1,'0',SEL_MUX_3,EN_MPY(i));
END GENERATE;

GEN_MUX_EN_ACC_3: FOR i in N_MAC_FC2 TO N_MAC_FC1-1 GENERATE
	MUX_EN_ACC : mux4to1_1bit
		GENERIC MAP(2)
		PORT MAP(EN_ACC_CONV1_24(i),EN_ACC_CONV2_24(i),EN_ACC_FC1,'0',SEL_MUX_3,EN_ACC(i));
END GENERATE;

GEN_MUX_SEL_ACC_3: FOR i in N_MAC_FC2 TO N_MAC_FC1-1 GENERATE
	MUX_SEL_ACC : mux4to1_1bit
		GENERIC MAP(2)
		PORT MAP(SEL_ACC_CONV1,SEL_ACC_CONV2,SEL_ACC_FC1,'0',SEL_MUX_3,SEL_ACC(i));
END GENERATE;



-----------------------------------------------------------------------------
-------------------------------- 10 MAC -------------------------------------
-----------------------------------------------------------------------------	
GEN_10_MAC:FOR i IN 0 TO N_MAC_FC3-1 GENERATE
	MAC: mac_block
		GENERIC MAP(OUTPUT_SIZE,EXTRA_BIT)
		PORT MAP(	out_mux_weights(i),
						out_mux_input(i),
						in_add_opt_sum_24(i),(OTHERS => '0'),
						out_mux_bias(i),
						CLK, RST,
						SEL_MUX_MAC, RST_MPY,
						EN_MPY(i), EN_ACC(i),
						SEL_ADD1_CONV2, '0',
						SEL_ACC(i),
						'0',
						open,
						acc_mac_24(i),
						data_from_mac(i));	
END GENERATE;

-----------------------------------------------------------------------------
------------------------------- 21-10 MAC -----------------------------------
-----------------------------------------------------------------------------	
GEN_11_MAC:FOR i IN N_MAC_FC3 TO N_MAC_FC2-1 GENERATE
	MAC: mac_block
		GENERIC MAP(OUTPUT_SIZE,EXTRA_BIT)
		PORT MAP(	out_mux_weights(i),
						out_mux_input(i),
						in_add_opt_sum_24(i),(OTHERS => '0'),
						out_mux_bias(i),
						CLK, RST,
						SEL_MUX_MAC, RST_MPY,
						EN_MPY(i), EN_ACC(i),
						SEL_ADD1_CONV2, '0',
						SEL_ACC(i),
						'0',
						open,
						acc_mac_24(i),
						data_from_mac(i));	
END GENERATE;


-----------------------------------------------------------------------------
------------------------------- 24-21 MAC -----------------------------------
-----------------------------------------------------------------------------	

GEN_3_MAC:FOR i IN N_MAC_FC2 TO N_MAC_FC1-1 GENERATE
	MAC: mac_block
		GENERIC MAP(OUTPUT_SIZE,EXTRA_BIT)
		PORT MAP(	out_mux_weights(i),
						out_mux_input(i),
						in_add_opt_sum_24(i),(OTHERS => '0'),
						out_mux_bias(i),
						CLK, RST,
						SEL_MUX_MAC, RST_MPY,
						EN_MPY(i), EN_ACC(i),
						SEL_ADD1_CONV2, '0',
						SEL_ACC(i),
						'0',
						open,
						acc_mac_24(i),
						data_from_mac(i));	
END GENERATE;
			
			
-----------------------------------------------------------------------------
----------------------------------- CU --------------------------------------
-----------------------------------------------------------------------------	
	
CU_MASTER:  CU_TOT
			PORT MAP(CLK,
						RST_A_n,
						START,
						DONE_CU_CONV1,
						DONE_CU_CONV2,
						DONE_CU1,
						DONE_CU2,
						DONE_CU3,
						RST,
						START_CU_CONV1,
						START_CU_CONV2,
						START_CU1,
						START_CU2,
						START_CU3,
						SEL_MUX_5,
						SEL_MUX_4,
						SEL_MUX_3,
						SEL_MUX_MAC,
						CLOCK_EN_CONV1,
						CLOCK_EN_CONV2,
						CLOCK_EN_FC1,
						CLOCK_EN_FC2,
						CLOCK_EN_FC3,
						DONE_TOT);			

------------------------------------------------------------------------------------------------

-- output of each layer to testbench --
output_conv1 <= out_regs_conv1;
output_conv2 <= input_to_fc1;
output_fc1 <= input_to_fc2;
output_fc2 <= input_to_fc3;


-- DONE OF EACH LAYER GO OUT OF THE NETWORK TO TESTBENCH TO ENABLE THE WRITE OF OUTPUT O
DONE_CONV1 <= DONE_CU_CONV1;
DONE_CONV2 <= DONE_CU_CONV2;
DONE_FC1 <= DONE_CU1;
DONE_FC2 <= DONE_CU2;
DONE_FC3 <= DONE_CU3;


----------------------------------------------------------------
------------------------ CLOCK GATING --------------------------
----------------------------------------------------------------

-- CONV1 --
CLOCK_G1: clock_gating
	PORT MAP( CLK, CLOCK_EN_CONV1, GCLK_CONV1 );		

-- CONV2 --
CLOCK_G2: clock_gating
	PORT MAP( CLK, CLOCK_EN_CONV2, GCLK_CONV2 );

-- FC1 --
CLOCK_G3: clock_gating
	PORT MAP( CLK, CLOCK_EN_FC1, GCLK_FC1 );

-- FC2 --
CLOCK_G4: clock_gating
	PORT MAP( CLK, CLOCK_EN_FC2, GCLK_FC2 );
	
-- FC3 --
CLOCK_G5: clock_gating
	PORT MAP( CLK, CLOCK_EN_FC3, GCLK_FC3 );	



END structural;

