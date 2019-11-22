-- Input_registers  --

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
USE work.all;
USE work.FC_struct_pkg.all;

ENTITY Input_registers IS
GENERIC(	
		CONSTANT INPUT_NEURONS  	: POSITIVE := 400);	
PORT(		
			input_value              : IN STD_LOGIC_VECTOR(INPUT_SIZE*INPUT_NEURONS-1 DOWNTO 0); 	
			CLK, RST 			       : IN STD_LOGIC; 
			EN_REG_IN                : IN STD_LOGIC; -- Enable of input bank register.
			output_reg				    : OUT STD_LOGIC_VECTOR(INPUT_SIZE*INPUT_NEURONS-1 DOWNTO 0) -- output of the input bank ragisters
);
END Input_registers;

ARCHITECTURE structural OF Input_registers IS

--------- COMPONENTS ---------

COMPONENT register_nbit IS
GENERIC(N : NATURAL:=8);
PORT(   data_in 			   : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
		  EN, CLK, RST 		: IN STD_LOGIC;
		  data_out 		    	: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT register_nbit;


------------- SIGNALS --------------


----------- END SIGNALS -----------------

BEGIN
  

GENERATE_INPUT_BANK_REGISTER: for j in 0 to INPUT_NEURONS-1 generate

	OUTPUT_BANK_REGISTER: register_nbit
			GENERIC MAP	(INPUT_SIZE ) -- size of output from mac to be saved for the next layer
			PORT MAP(input_value((((j+1)*INPUT_SIZE)-1) DOWNTO (j*INPUT_SIZE)),
							 EN_REG_IN, CLK, RST,
							 output_reg((((j+1)*INPUT_SIZE)-1) DOWNTO (j*INPUT_SIZE)));					

end generate GENERATE_INPUT_BANK_REGISTER;


------------------------------------------------------------------------------------------------

END structural;