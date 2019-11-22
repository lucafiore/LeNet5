-- FC2 Top file --
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
USE work.input_struct_pkg.all;


ENTITY FC2_top IS
GENERIC(		
		CONSTANT INPUT_NEURONS   	: POSITIVE := 120;
		CONSTANT OUTPUT_NEURONS  	: POSITIVE := 84);
		
PORT(		
		START           	: IN STD_LOGIC;
		RST_A_n         	: IN STD_LOGIC;
		
		-- port useful for testbench
		EN_READ_W		 : OUT STD_LOGIC;
		EN_READ_B		 : OUT STD_LOGIC;
		EN_READ_IN		 : OUT STD_LOGIC;		
		
		input_FC2			: IN STD_LOGIC_VECTOR(INPUT_NEURONS*INPUT_SIZE-1 DOWNTO 0); -- input yo the layer coming from previous layer
		input_weights	   : IN weights_struct;
		input_bias		   : IN bias_struct;
		CLK    	 			: IN STD_LOGIC; 
		DONE_FC2        	: OUT STD_LOGIC;
		output_FC2			: OUT STD_LOGIC_VECTOR(OUTPUT_NEURONS*OUTPUT_SIZE-1 DOWNTO 0) -- output of the layer to the output bank ragisters (outside the layer)
);
END FC2_top;

ARCHITECTURE structural OF FC2_top IS

--------- COMPONENTS ---------

COMPONENT Input_registers IS
GENERIC(	
		CONSTANT INPUT_NEURONS  	: POSITIVE := 120);	
PORT(		
			input_value              : IN STD_LOGIC_VECTOR(INPUT_SIZE*INPUT_NEURONS-1 DOWNTO 0); 	
			CLK, RST 			       : IN STD_LOGIC; 
			EN_REG_IN                : IN STD_LOGIC; -- Enable of input bank register.
			output_reg				    : OUT STD_LOGIC_VECTOR(INPUT_SIZE*INPUT_NEURONS-1 DOWNTO 0) -- output of the input bank ragisters
);
END COMPONENT Input_registers;


COMPONENT CU_FC2 IS
PORT(    
		CLK             : IN STD_LOGIC;
      RST_A_n         : IN STD_LOGIC;
      START           : IN STD_LOGIC;
		TC_120			 : IN STD_LOGIC;
		TC_4				 : IN STD_LOGIC;

		RST_S           : OUT STD_LOGIC;
		RST_CNT_120     : OUT STD_LOGIC;
		RST_REG_MPY		 : OUT STD_LOGIC;
				
		EN_READ_W		 : OUT STD_LOGIC;
		EN_READ_B		 : OUT STD_LOGIC;
		EN_READ_IN		 : OUT STD_LOGIC;
		
		EN_REG_IN		 : OUT STD_LOGIC; -- Enable of input register;
		EN_REG_PIPE		 : OUT STD_LOGIC; -- Enable of the pipe register after the input mux and before the MAC
      EN_CNT_120      : OUT STD_LOGIC;
      EN_CNT_4        : OUT STD_LOGIC;
      EN_MPY, EN_ACC  : OUT STD_LOGIC;
      SEL_ACC         : OUT STD_LOGIC; -- if '0' load out adder, if '1' load external data
		EN_RELU,EN_DEC  : OUT STD_LOGIC;
		DONE_FC2        : OUT STD_LOGIC);				
		
END COMPONENT CU_FC2;


COMPONENT Fully_Connected_Layer IS
GENERIC(		
		CONSTANT INPUT_NEURONS   	: POSITIVE := 120;
		CONSTANT OUTPUT_NEURONS  	: POSITIVE := 84);
		
PORT(		-- Suppose that from tb we can access 21 weights from a text file where weigths are stored. 
			-- In fact we will use 21 MAC 

			input_weights	          : IN weights_struct;
			input_bias		          : IN bias_struct;
			input_value              : IN STD_LOGIC_VECTOR(INPUT_NEURONS*INPUT_SIZE-1 DOWNTO 0); -- 1 value from previous layer, input to mux 120_to_1
			data_from_mac				 : IN out_from_mac;	-- Output of MAC block from outside
			
			CLK, RST, RST_CNT_120 	 : IN STD_LOGIC; 
			--SEL_MUX_INPUT		       : IN STD_LOGIC_VECTOR(SEL_MUX_IN_SIZE-1 DOWNTO 0);
			EN_REG_PIPE					 : IN STD_LOGIC; --Enable of the pipe register after the input mux INPUT_NEURONS to 1
			EN_RELU                  : IN STD_LOGIC;
			EN_DEC						 : IN STD_LOGIC; --Enable of decoder (from CU)
			EN_CNT_120,EN_CNT_4		 : IN STD_LOGIC;
			
			EN_REG_OUT               : OUT STD_LOGIC_VECTOR(N_CYCLES-1 DOWNTO 0); -- Enable of output bank register. We enable 21 register contemporary 
			TC_120, TC_4    			 : OUT STD_LOGIC;						
			output_weights	          : OUT weights_struct;
			output_bias		          : OUT bias_mac_struct;
			out_reg_pipe				 : OUT STD_LOGIC_VECTOR(INPUT_SIZE-1 DOWNTO 0); --Output of the register sampling the output from the input mux. It goes to external MAC_block
			output_FC2					 : OUT out_from_mac
);
END COMPONENT Fully_Connected_Layer;

COMPONENT mac_block IS  
GENERIC(	N		: NATURAL:=10;
			M		: NATURAL:=3);
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


COMPONENT Output_registers IS
GENERIC(	
		CONSTANT OUTPUT_NEURONS  	: POSITIVE := 84);		
PORT(		
			input_value              : IN out_from_mac; -- from the ReLu inside the layer			
			CLK, RST 			       : IN STD_LOGIC; 
			EN_REG_OUT               : IN STD_LOGIC_VECTOR(N_CYCLES-1 DOWNTO 0); -- Enable of output bank register. We enable OUTPUT_NEURONS register contemporary 
			output_reg				    : OUT STD_LOGIC_VECTOR(OUTPUT_SIZE*OUTPUT_NEURONS-1 DOWNTO 0)); -- output of the output bank ragisters
END COMPONENT Output_registers;


------------- SIGNALS --------------

SIGNAL input_to_layer         : STD_LOGIC_VECTOR(INPUT_NEURONS*INPUT_SIZE-1 DOWNTO 0); -- values from previous layer, input to mux 120_to_1
SIGNAL EN_REG_IN              : STD_LOGIC; 	-- Enable of input bank register.
SIGNAL data_from_mac				: out_from_mac;	-- from MAC block to layer
SIGNAL RST,RST_CNT_120			: STD_LOGIC;
SIGNAL RST_MPY		 				: STD_LOGIC; 						  						 
SIGNAL EN_REG_PIPE				: STD_LOGIC;
SIGNAL EN_MPY, EN_ACC  			: STD_LOGIC;
SIGNAL SEL_ACC         			: STD_LOGIC; -- if '0' load out adder, if '1' load external data					 
SIGNAL EN_RELU                : STD_LOGIC;  
SIGNAL EN_DEC						: STD_LOGIC; 
SIGNAL EN_CNT_120,EN_CNT_4		: STD_LOGIC;
SIGNAL EN_REG_OUT             : STD_LOGIC_VECTOR(N_CYCLES-1 DOWNTO 0); -- Enable of output bank register. We enable 21 register contemporary 
SIGNAL TC_120, TC_4    			: STD_LOGIC;						
SIGNAL output_weights	      : weights_struct;
SIGNAL output_bias		      : bias_mac_struct;
SIGNAL out_reg_pipe				: STD_LOGIC_VECTOR(INPUT_SIZE-1 DOWNTO 0); --Output of the register sampling the output from the input mux. It goes to external MAC_block
SIGNAL output_layer			   : out_from_mac; --Output of the layer (21 numbers)
--SIGNAL output_layer			   : STD_LOGIC_VECTOR(N_MAC*OUTPUT_NEURONS-1 DOWNTO 0); --Output of the layer (21 numbers)

----------- END SIGNALS -----------------
BEGIN
  
IN_REGISTERS:  Input_registers
			GENERIC MAP  (INPUT_NEURONS)
			PORT MAP     (input_FC2,CLK,RST,EN_REG_IN,input_to_layer);
			
			
FC_LAYER:  Fully_Connected_Layer
			GENERIC MAP(INPUT_NEURONS,OUTPUT_NEURONS)
			
			PORT MAP(input_weights,
						input_bias,
						input_to_layer,
						data_from_mac,					
						CLK,RST,
						RST_CNT_120,
						EN_REG_PIPE,
						EN_RELU,
						EN_DEC,
						EN_CNT_120,EN_CNT_4,
						EN_REG_OUT,
						TC_120, TC_4,
						output_weights,
						output_bias,
						out_reg_pipe,
						output_layer);
						
						
GEN_21_MAC:FOR i IN 0 TO N_MAC-1 GENERATE
	MAC: mac_block
		GENERIC MAP(OUTPUT_SIZE,EXTRA_BIT)
		PORT MAP(	output_weights(i),
						out_reg_pipe,
						(OTHERS=>'0'), (OTHERS=>'0'),
						output_bias(i),
						CLK, RST, '0', RST_MPY,
						EN_MPY, EN_ACC,
						'0', '0',
						SEL_ACC,
						'0',
						open,
						open,
						data_from_mac(i));	
END GENERATE;
			
CU_LAYER:  CU_FC2
			PORT MAP(CLK,
						RST_A_n,
						START,
						TC_120, TC_4,
						RST,
						RST_CNT_120,
						RST_MPY,
						
						EN_READ_W,
						EN_READ_B,
						EN_READ_IN,
						
						EN_REG_IN,
						EN_REG_PIPE,
						EN_CNT_120,EN_CNT_4,
						EN_MPY, EN_ACC,
						SEL_ACC, 
						EN_RELU,EN_DEC,
						DONE_FC2);			

		
OUT_REGISTERS:  Output_registers
			GENERIC MAP  (OUTPUT_NEURONS)
			PORT MAP     (output_layer,CLK,RST,EN_REG_OUT,output_FC2);

------------------------------------------------------------------------------------------------

END structural;