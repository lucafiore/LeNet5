-- Output_registers  --

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

ENTITY Output_registers IS
GENERIC(	
		CONSTANT OUTPUT_NEURONS  	: POSITIVE := 84);		
PORT(		
			input_value              : IN out_from_mac_FC3; -- from the ReLu inside the layer			
			CLK, RST 			       : IN STD_LOGIC; 
			EN_REG_OUT               : IN STD_LOGIC; -- Enable of output bank register. We enable 24 register contemporary 
			output_reg				    : OUT STD_LOGIC_VECTOR(OUTPUT_SIZE*OUTPUT_NEURONS-1 DOWNTO 0) -- output of the output bank ragisters
);
END Output_registers;

ARCHITECTURE structural OF Output_registers IS

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
  

GENERATE_OUTPUT_BANK_REGISTER_0: for j in 0 to N_MAC_FC3-1 generate

	OUTPUT_BANK_REGISTER: register_nbit
			GENERIC MAP	(OUTPUT_SIZE ) -- size of output from mac to be saved for the next layer
			PORT MAP(input_value(j),
							 EN_REG_OUT, CLK, RST,
							 output_reg((((j+1)*OUTPUT_SIZE)-1) DOWNTO (j*OUTPUT_SIZE)));				

end generate GENERATE_OUTPUT_BANK_REGISTER_0;


------------------------------------------------------------------------------------------------

END structural;