-- 2_nd Fully connected layer [ 120 to 84 ] --
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

----------------------------------------------------------

-- New package to use this structure as input to the Fully Connected Layer
-- From Tb we receive two 21x12 bits which are 21 weights and 21 biases of 12bits.
-- for the moment we decided not to share the 21x12 bus for both weights and biases in order to reduce input pin.

package input_struct_pkg is
	CONSTANT BIAS_SIZE      	: POSITIVE := 8;	
	CONSTANT WEIGHT_SIZE    	: POSITIVE := 8;
	CONSTANT OUTPUT_SIZE 		: POSITIVE := 8;
	CONSTANT INPUT_SIZE    		: POSITIVE := 8;	
	CONSTANT N_MAC					: POSITIVE := 21;
	CONSTANT EXTRA_BIT			: NATURAL := 0;
	CONSTANT N_CYCLES				: POSITIVE :=4;
	CONSTANT SEL_MUX_IN_SIZE   : POSITIVE := 7; -- Parallelism of selector ( ceil(log2(INPUT_NEURONS)) )
	
	TYPE weights_struct IS ARRAY(N_MAC-1 DOWNTO 0) of STD_LOGIC_VECTOR(WEIGHT_SIZE-1 DOWNTO 0);
	TYPE bias_struct IS ARRAY(N_MAC-1 DOWNTO 0) OF STD_LOGIC_VECTOR(BIAS_SIZE-1 DOWNTO 0);
	TYPE bias_mac_struct IS ARRAY(N_MAC-1 DOWNTO 0) OF STD_LOGIC_VECTOR(2*BIAS_SIZE+EXTRA_BIT-2 DOWNTO 0);
	TYPE out_from_mac IS ARRAY(N_MAC-1 DOWNTO 0) OF STD_LOGIC_VECTOR(OUTPUT_SIZE-1 DOWNTO 0);
	
end package;

----------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use ieee.math_real.all;
USE work.all;
USE work.input_struct_pkg.all;

ENTITY Fully_Connected_Layer IS
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
END Fully_Connected_Layer;

ARCHITECTURE structural OF Fully_Connected_Layer IS

--------- COMPONENTS ---------

COMPONENT register_nbit IS
GENERIC(	N 					: NATURAL:=12);
PORT(		data_in 			: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			EN, CLK, RST 	: IN STD_LOGIC;
			data_out 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT register_nbit;


COMPONENT muxMto1_nbit IS 
GENERIC(P   : NATURAL:=4;  -- Parallelism of input
        M   : NATURAL:=4; -- Number of input elements
        S   : NATURAL:=2);  -- Parallelism of selector ( ceil(log2(M)) )
PORT(	data_in   : IN STD_LOGIC_VECTOR(M*P-1 DOWNTO 0);
			SEL				  : IN STD_LOGIC_VECTOR(S-1 DOWNTO 0):= (OTHERS => '0');
			q			 		: OUT STD_LOGIC_VECTOR(P-1 DOWNTO 0));
END COMPONENT muxMto1_nbit;

------ COUNTERS ------

COMPONENT counter_N_FC is
generic (n : integer:=10);
port (enable, clk, rst : in std_logic;
		count : out std_logic_vector(natural(ceil(log2(real(n))))-1 downto 0);
		tc : out std_logic);
end COMPONENT counter_N_FC;

------ ReLU ------

COMPONENT relu IS
GENERIC(	N 					: NATURAL:=8);
PORT(	data_in 		: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
      enable    : IN STD_LOGIC;
			q			 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT relu;

------ DECODER ------

COMPONENT decode_3to4 is
	Port (	cnt_4  		: in  STD_LOGIC_VECTOR (1 downto 0);      			-- 2-bit input
				EN_decoder 	: in  STD_LOGIC;                       				-- enable decoder
				en_reg_out  	: out STD_LOGIC_VECTOR (N_CYCLES-1 downto 0));  	-- 4-bit output                  
end COMPONENT decode_3to4;


------------- SIGNALS --------------

TYPE output_Layer IS ARRAY(N_MAC-1 DOWNTO 0) OF STD_LOGIC_VECTOR(OUTPUT_SIZE-1 DOWNTO 0);
SIGNAL out_mux_input_values        : STD_LOGIC_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- output of mux which choose one of 120 previous layer output
--SIGNAL in_add_opt_1, in_add_opt_2	: output_MAC; -- qua in realtÃ  posso non avere in_add_opt_1 quindi posso proprio togliere il mux 2_to_1 del primo ingresso del sommatore perchè sarà sempre connesso con l'uscita del moltiplicatore 
SIGNAL output_relu   				  : out_from_mac; -- are 21x12bit output to be saved into output registers
SIGNAL cnt_120						:	STD_LOGIC_VECTOR(6 downto 0);
SIGNAL cnt_4							:	STD_LOGIC_VECTOR(1 downto 0);
SIGNAL rst_120_s, rst_4_s     : STD_LOGIC;
SIGNAL tc120, tc4			      : STD_LOGIC;

----------- END SIGNALS -----------------
BEGIN
  

Mux120to1: muxMto1_nbit 
		GENERIC MAP	(INPUT_SIZE, INPUT_NEURONS, SEL_MUX_IN_SIZE)
		PORT MAP		(input_value, cnt_120, out_mux_input_values);
		  

PIPE_REGISTER: register_nbit
			GENERIC MAP	(OUTPUT_SIZE) -- size of one of the INPUT_NEURONS input
			PORT MAP(out_mux_input_values,
							 EN_REG_PIPE, CLK, RST,
							 out_reg_pipe);				

output_weights <= input_weights;	


GENERATE_EXTENDED_BIAS: for i in 0 to N_MAC-1 generate

	output_bias(i)(2*BIAS_SIZE+EXTRA_BIT-2 DOWNTO 2*BIAS_SIZE+EXTRA_BIT-5) <= (OTHERS => input_bias(i)(BIAS_SIZE-1));
	output_bias(i)(2*BIAS_SIZE+EXTRA_BIT-6 DOWNTO 2*BIAS_SIZE+EXTRA_BIT-5-BIAS_SIZE) <= input_bias(i);
	output_bias(i)(2*BIAS_SIZE+EXTRA_BIT-6-BIAS_SIZE DOWNTO 0) <= (OTHERS => '0');	
	
end generate GENERATE_EXTENDED_BIAS; 

  
GENERATE_RELU: for i in 0 to N_MAC-1 generate
    
  ReLU_conv1: relu
			GENERIC MAP  (OUTPUT_SIZE)
			PORT MAP     (data_from_mac(i), EN_RELU, output_FC2(i));

end generate GENERATE_RELU;


-- decoder of enables of out registers

DECODER_OF_ENABLES : decode_3to4
			PORT MAP     (cnt_4,EN_DEC,EN_REG_OUT);
			
			
-- counters 
		
COUNTER120: counter_N_FC
			GENERIC MAP  (120)
			PORT MAP     (EN_CNT_120,CLK, rst_120_s, cnt_120, tc120);

COUNTER4: counter_N_FC
			GENERIC MAP  (4)
			PORT MAP     (EN_CNT_4,CLK, rst_4_s, cnt_4, tc4);

rst_120_s <= (tc120 or RST);			
rst_4_s <= (tc4 or RST);			
			
TC_120 <=rst_120_s;
TC_4 <=rst_4_s;

------------------------------------------------------------------------------------------------

END structural;