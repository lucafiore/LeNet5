-- Master CU

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
USE work.CONV_struct_pkg.all;


ENTITY CU_TOT IS
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
		
END CU_TOT;

ARCHITECTURE behaviour OF CU_TOT IS
TYPE state IS ( idle, reset_state, start_conv1, conv1_op, start_conv2, conv2_op, start_fc1, fc1_op, start_fc2, fc2_op, start_fc3, fc3_op, done);
ATTRIBUTE enum_encoding : string;
ATTRIBUTE enum_encoding OF state : TYPE IS "0001 0000 0011 0111 1111 1110 1100 1000 1010 1011 1001 1101 0101";
SIGNAL P_S, N_S : state;
  
BEGIN
  
  
state_transitions : PROCESS(P_S, START, DONE_CU_CONV1, DONE_CU_CONV2, DONE_CU_FC1, DONE_CU_FC2, DONE_CU_FC3)
BEGIN 
    CASE P_S IS 
	 
		  WHEN idle =>  	IF (START='1') THEN N_S <= start_conv1;
								ELSE N_S <= idle;
								END IF;
								
		  WHEN start_conv1 => N_S <= conv1_op;
		  
        WHEN conv1_op =>  IF (DONE_CU_CONV1='1') THEN N_S <= start_conv2;
								ELSE N_S <= conv1_op;
								END IF;
		
		  WHEN start_conv2 => N_S <= conv2_op;
		  
        WHEN conv2_op =>  IF (DONE_CU_CONV2='1') THEN N_S <= start_fc1;
								ELSE N_S <= conv2_op;
								END IF;		
		                             
		  WHEN start_fc1 => N_S <= fc1_op;
		  
        WHEN fc1_op =>  IF (DONE_CU_FC1='1') THEN N_S <= start_fc2;
								ELSE N_S <= fc1_op;
								END IF;
								
					
		  WHEN start_fc2 => N_S <= fc2_op;			
							 
        WHEN fc2_op =>  IF (DONE_CU_FC2='1') THEN N_S <= start_fc3;
								ELSE N_S <= fc2_op;
								END IF;							 
		
		  WHEN start_fc3 => N_S <= fc3_op;
		  
		  WHEN fc3_op =>  IF (DONE_CU_FC3='1') THEN N_S <= done;
								ELSE N_S <= fc3_op;
								END IF;
		  
		  WHEN done =>    N_S <= idle;
                            
        WHEN reset_state => 	N_S <= idle;
        
        WHEN others => 			N_S <= reset_state;
		  
    END CASE;
END PROCESS;

--RST_A_n_out <= RST_A_n; -- give asynchronus reset to internal CU of each layer

state_register : PROCESS (CLK, RST_A_n)
BEGIN
    IF (RST_A_n='0') THEN
        P_S <= reset_state;
    ELSE 
        IF (CLK'EVENT AND CLK='1') THEN
            P_S <= N_S;
        END IF;
    END IF;
END PROCESS;

output : PROCESS (P_S)
BEGIN

-- Default values

RST_S <= '0';
DONE_TOT <= '0';

START_CU_CONV1 <= '0';	
START_CU_CONV2 <= '0';	
START_CU_FC1   <= '0';		
START_CU_FC2	<= '0';	
START_CU_FC3	<= '0';	

SEL_MUX_5 <= "000";	
SEL_MUX_4 <= "00";
SEL_MUX_3 <= "00";

SEL_MUX_MAC <= '0';

CLOCK_EN_CONV1	<= '0';
CLOCK_EN_CONV2	<= '0';	
CLOCK_EN_FC1	<= '0';	
CLOCK_EN_FC2	<= '0';	
CLOCK_EN_FC3	<= '0';	


    CASE P_S IS 
	 
        WHEN idle 		=>  NULL;
		 		  
		  WHEN start_conv1 =>  	START_CU_CONV1 <= '1';
										CLOCK_EN_CONV1	<= '1';
		  
		  WHEN conv1_op 	=>  SEL_MUX_5 <= "000";
									 SEL_MUX_4 <= "00";
									 SEL_MUX_3 <= "00";
									 SEL_MUX_MAC <= '1';
									 CLOCK_EN_CONV1	<= '1';
									 
									 
		  WHEN start_conv2 =>  	START_CU_CONV2 <= '1';
										CLOCK_EN_CONV2	<= '1';
									 
		  WHEN conv2_op 	=>  SEL_MUX_5 <= "001";
									 SEL_MUX_4 <= "01";
									 SEL_MUX_3 <= "01";
									 CLOCK_EN_CONV2 <= '1';
									 
									 
		  WHEN start_fc1	=>		START_CU_FC1 <= '1';
										CLOCK_EN_FC1	<= '1';
		  
		  WHEN fc1_op 		=>  SEL_MUX_5 <= "010";
									 SEL_MUX_4 <= "10";
									 SEL_MUX_3 <= "10";
									 CLOCK_EN_FC1 <= '1';

		  
		  WHEN start_fc2	=>  START_CU_FC2 <= '1';
									 CLOCK_EN_FC2<= '1';
		  
		  WHEN fc2_op 		=>  SEL_MUX_5 <= "011";
									 SEL_MUX_4 <= "11";
									 CLOCK_EN_FC2 <= '1';

		  
		  WHEN start_fc3 	=>  START_CU_FC3 <= '1';
									 CLOCK_EN_FC3 <= '1';
		  
		  WHEN fc3_op 		=>  SEL_MUX_5 <= "100";
									 CLOCK_EN_FC3 <= '1';

		  
        WHEN done 		=>  DONE_TOT <= '1';
		                 
        WHEN reset_state => 	RST_S <= '1';
										CLOCK_EN_CONV1	<= '1';
										CLOCK_EN_CONV2	<= '1';	
										CLOCK_EN_FC1	<= '1';	
										CLOCK_EN_FC2	<= '1';	
										CLOCK_EN_FC3	<= '1';	
									 									 
        
        WHEN others => NULL;
		  
    END CASE;
END PROCESS;
END behaviour;