-- FC3 Top file --
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
USE work.FC_struct_pkg.all;


ENTITY FC3_top IS
GENERIC(		
		CONSTANT INPUT_NEURONS   	: POSITIVE := 84;
		CONSTANT OUTPUT_NEURONS  	: POSITIVE := 10);
		
PORT(		
		START           	: IN STD_LOGIC;
		RST_A_n         	: IN STD_LOGIC;
		CLK,GCLK	 			: IN STD_LOGIC;
		
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
		out_reg_pipe		  : OUT STD_LOGIC_VECTOR(INPUT_SIZE-1 DOWNTO 0); --Output of the register sampling the output from the input mux. It goes to external MAC_block
		output_weights  : OUT weights_struct_FC3;
		output_bias     : OUT bias_mac_struct_FC3;
		output_layer		: OUT out_from_mac_FC3 -- Output of the layer (10 numbers)
);
END FC3_top;

ARCHITECTURE structural OF FC3_top IS

--------- COMPONENTS ---------


COMPONENT CU_FC3 IS
PORT(    
		CLK             : IN STD_LOGIC;
      RST_A_n         : IN STD_LOGIC;
      START           : IN STD_LOGIC;
		TC_84			 : IN STD_LOGIC;

		RST_S           : OUT STD_LOGIC;
		RST_CNT_84     : OUT STD_LOGIC;
		RST_REG_MPY		 : OUT STD_LOGIC;
		
		EN_READ_W		 : OUT STD_LOGIC;
		EN_READ_B		 : OUT STD_LOGIC;
		--EN_READ_IN		 : OUT STD_LOGIC;
		
		--EN_REG_IN		 : OUT STD_LOGIC; -- Enable of input register;
		EN_REG_PIPE		 : OUT STD_LOGIC; -- Enable of the pipe register after the input mux and before the MAC
      EN_CNT_84      : OUT STD_LOGIC;
      EN_MPY, EN_ACC  : OUT STD_LOGIC;
		EN_REG_OUT		 : OUT STD_LOGIC;
      SEL_ACC         : OUT STD_LOGIC; -- if '0' load out adder, if '1' load external data
		DONE_FC3        : OUT STD_LOGIC);				
		
END COMPONENT CU_FC3;


COMPONENT Fully_Connected_Layer_3 IS
GENERIC(		
		CONSTANT INPUT_NEURONS   	: POSITIVE := 84;
		CONSTANT OUTPUT_NEURONS  	: POSITIVE := 10);
		
PORT(		-- Suppose that from tb we can access 10 weights from a text file where weigths are stored. 
			-- In fact we will use 10 MAC 

			input_weights	          : IN weights_struct_FC3;
			input_bias		          : IN bias_struct_FC3;
			input_value              : IN STD_LOGIC_VECTOR(INPUT_NEURONS*INPUT_SIZE-1 DOWNTO 0); -- 1 value from previous layer, input to mux 84_to_1
			data_from_mac				 : IN out_from_mac_FC3;	-- Output of MAC block from outside
			
			CLK, RST, RST_CNT_84 	 : IN STD_LOGIC;
			--SEL_MUX_INPUT		       : IN STD_LOGIC_VECTOR(SEL_MUX_IN_SIZE-1 DOWNTO 0);
			EN_REG_PIPE					 : IN STD_LOGIC; --Enable of the pipe register after the input mux INPUT_NEURONS to 1)
			EN_CNT_84					 : IN STD_LOGIC;
			
			TC_84		    			 : OUT STD_LOGIC;						
			output_weights	          : OUT weights_struct_FC3;
			output_bias		          : OUT bias_mac_struct_FC3;
			out_reg_pipe				 : OUT STD_LOGIC_VECTOR(INPUT_SIZE-1 DOWNTO 0); --Output of the register sampling the output from the input mux. It goes to external MAC_block
			output_FC3					 : OUT out_from_mac_FC3

);
END COMPONENT Fully_Connected_Layer_3;


------------- SIGNALS --------------

SIGNAL RST,RST_CNT_84 	 		: STD_LOGIC;
					 
SIGNAL EN_REG_PIPE				: STD_LOGIC;
				 
SIGNAL EN_RELU                : STD_LOGIC;  
SIGNAL EN_CNT_84					: STD_LOGIC;
SIGNAL TC_84		    			: STD_LOGIC;						

----------- END SIGNALS -----------------
BEGIN

			
			
FC_LAYER:  Fully_Connected_Layer_3
			GENERIC MAP(INPUT_NEURONS,OUTPUT_NEURONS)
			
			PORT MAP(input_weights,
						input_bias,
						input_to_layer,
						data_from_mac,					
						GCLK,RST,
						RST_CNT_84,
						EN_REG_PIPE,
						EN_CNT_84,
						TC_84,
						output_weights,
						output_bias,
						out_reg_pipe,
						output_layer);
						
									
CU_LAYER:  CU_FC3
			PORT MAP(CLK,
						RST_A_n,
						START,
						TC_84,
						RST,
						RST_CNT_84,
						RST_MPY,
						
						EN_READ_W,
						EN_READ_B,
						--EN_READ_IN,
						
						--EN_REG_IN,
						EN_REG_PIPE,
						EN_CNT_84,
						EN_MPY, EN_ACC,
						EN_REG_OUT,
						SEL_ACC, 
						DONE_FC3);			

------------------------------------------------------------------------------------------------

END structural;