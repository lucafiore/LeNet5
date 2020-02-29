-- 3_rd Fully connected layer [ 84 to 10 ] --
-- high-speed/low-power group
-- Fiore, Neri, Zheng
-- 
-- keyword in MAIUSCOLO (es: STD_LOGIC)
-- dati in minuscolo (es: data_in)
-- segnali di controllo in MAIUSCOLO (es: EN)
-- componenti instanziati con l'iniziale maiuscola (es: Shift_register_1)
-- i segnali attivi bassi con _n finale (es: RST_n)

----------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.math_real.all;
USE work.all;
USE work.FC_struct_pkg.all;

ENTITY Fully_Connected_Layer_3 IS
GENERIC(		
		CONSTANT INPUT_NEURONS   	: POSITIVE := 84;
		CONSTANT OUTPUT_NEURONS  	: POSITIVE := 10);
		
PORT(		-- Suppose that from tb we can access 10 weights from a text file where weigths are stored. 
			-- In fact we will use 10 MAC 

			input_weights	          : IN weights_struct_FC3;
			input_bias		          : IN bias_struct_FC3;
			input_value              : IN STD_LOGIC_VECTOR(INPUT_NEURONS_FC3*INPUT_SIZE-1 DOWNTO 0); -- 1 value from previous layer, input to mux 84_to_1
			data_from_mac				 : IN out_from_mac_FC3;	-- Output of MAC block from outside
			
			CLK, RST, RST_CNT_84 	 : IN STD_LOGIC;
			EN_REG_PIPE					 : IN STD_LOGIC; --Enable of the pipe register after the input mux INPUT_NEURONS to 1
			EN_CNT_84					 : IN STD_LOGIC;
			TC_84		    			 	 : OUT STD_LOGIC;						
			output_weights	          : OUT weights_struct_FC3;
			output_bias		          : OUT bias_mac_struct_FC3;
			out_reg_pipe				 : OUT STD_LOGIC_VECTOR(INPUT_SIZE-1 DOWNTO 0); --Output of the register sampling the output from the input mux. It goes to external MAC_block
			output_FC3					 : OUT out_from_mac_FC3

);
END Fully_Connected_Layer_3;

ARCHITECTURE structural OF Fully_Connected_Layer_3 IS

--------- COMPONENTS ---------

COMPONENT register_nbit IS
GENERIC(	N 					: NATURAL:=8);
PORT(		data_in 			: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			EN, CLK, RST 	: IN STD_LOGIC;
			data_out 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT register_nbit;


COMPONENT mux84to1_nbit IS 
GENERIC(	N 					: NATURAL:=8);
PORT(	data_in	: IN STD_LOGIC_VECTOR(84*N-1 DOWNTO 0);
			SEL				: IN STD_LOGIC_VECTOR(6 DOWNTO 0):=(OTHERS=>'0');
			q			 	: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT mux84to1_nbit;

------ COUNTERS ------

COMPONENT counter_N_FC is
generic (n : integer:=10);
port (enable, clk, rst : in std_logic;
		count : out std_logic_vector(natural(ceil(log2(real(n))))-1 downto 0);
		tc : out std_logic);
end COMPONENT counter_N_FC;


------------- SIGNALS --------------

TYPE output_Layer IS ARRAY(N_MAC_FC3-1 DOWNTO 0) OF STD_LOGIC_VECTOR(OUTPUT_SIZE-1 DOWNTO 0);
SIGNAL out_mux_input_values         : STD_LOGIC_VECTOR(INPUT_SIZE-1 DOWNTO 0); -- output of mux which choose one of 84 previous layer output
SIGNAL output_relu   				   : out_from_mac_FC3; -- are 10x12bit output to be saved into output registers
SIGNAL cnt_84								: STD_LOGIC_VECTOR(SEL_MUX_IN_SIZE_FC3-1 downto 0);
SIGNAL rst_84_s					   	: STD_LOGIC;
SIGNAL tc84 			      		: STD_LOGIC;

----------- END SIGNALS -----------------
BEGIN
  

Mux84to1: mux84to1_nbit 
		GENERIC MAP	(INPUT_SIZE)
		PORT MAP		(input_value, cnt_84, out_mux_input_values);
		  

PIPE_REGISTER: register_nbit
			GENERIC MAP	(OUTPUT_SIZE ) -- size of one of the INPUT_NEURONS input
			PORT MAP(out_mux_input_values,
							 EN_REG_PIPE, CLK, RST,
							 out_reg_pipe);				

output_weights <= input_weights;	


GENERATE_EXTENDED_BIAS: for i in 0 to N_MAC_FC3-1 generate

	output_bias(i)(2*BIAS_SIZE+EXTRA_BIT-2 DOWNTO 2*BIAS_SIZE+EXTRA_BIT-5) <= (OTHERS => input_bias(i)(BIAS_SIZE-1));
	output_bias(i)(2*BIAS_SIZE+EXTRA_BIT-6 DOWNTO 2*BIAS_SIZE+EXTRA_BIT-5-BIAS_SIZE) <= input_bias(i);
	output_bias(i)(2*BIAS_SIZE+EXTRA_BIT-6-BIAS_SIZE DOWNTO 0) <= (OTHERS => '0');

end generate GENERATE_EXTENDED_BIAS; 


output_FC3 <= data_from_mac;
			
-- counters 

		
COUNTER84: counter_N_FC
			GENERIC MAP  (84)
			PORT MAP     (EN_CNT_84,CLK, rst_84_s, cnt_84, tc84);


rst_84_s <= (tc84 or RST);			
			
TC_84 <=rst_84_s;


------------------------------------------------------------------------------------------------

END structural;
