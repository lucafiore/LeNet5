-- FC1_CU
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


ENTITY CU_FC1 IS
PORT(    
		CLK             : IN STD_LOGIC;
      RST_A_n         : IN STD_LOGIC;
      START           : IN STD_LOGIC;
		TC_400			 : IN STD_LOGIC;
		TC_5				 : IN STD_LOGIC;

		RST_S           : OUT STD_LOGIC;
		RST_CNT_400     : OUT STD_LOGIC;
		RST_REG_MPY		 : OUT STD_LOGIC;
		
		EN_READ_W		 : OUT STD_LOGIC;
		EN_READ_B		 : OUT STD_LOGIC;
		--EN_READ_IN		 : OUT STD_LOGIC;
		
		--EN_REG_IN		 : OUT STD_LOGIC; -- Enable of input register;
		EN_REG_PIPE		 : OUT STD_LOGIC; -- Enable of the pipe register after the input mux and before the MAC
      EN_CNT_400      : OUT STD_LOGIC;
      EN_CNT_5        : OUT STD_LOGIC;
      EN_MPY, EN_ACC  : OUT STD_LOGIC;
      SEL_ACC         : OUT STD_LOGIC; -- if '0' load out adder, if '1' load external data
		EN_RELU,EN_DEC  : OUT STD_LOGIC;
		DONE_FC1        : OUT STD_LOGIC);				
		
END CU_FC1;

ARCHITECTURE behaviour OF CU_FC1 IS
TYPE state IS ( idle, reset_state, read_state, load_bias, reg_pipe, pipe, last_sum, write_out, done);
ATTRIBUTE enum_encoding : string;
ATTRIBUTE enum_encoding OF state : TYPE IS "0000 0111 0001 0011 0010 1000 1001 1011 1111";
SIGNAL P_S, N_S : state;
  
BEGIN
  
  
state_transitions : PROCESS(P_S, START, TC_400, TC_5)
BEGIN 
    CASE P_S IS 
	 
        WHEN idle =>  IF (START='1') THEN N_S <= read_state;
                      ELSE N_s <= idle;
                      END IF;

        WHEN read_state => N_S <= load_bias;
		  
        WHEN load_bias => N_S <= reg_pipe;
        
		  WHEN reg_pipe => N_S <= pipe;
		  
        WHEN pipe =>  IF (TC_400='1') THEN 
                            N_S <= last_sum;
                      ELSE N_S <= pipe;
							        END IF;
                                
        WHEN last_sum =>    N_S <= write_out;
		  
		  WHEN write_out =>  IF (TC_5='0') THEN N_S <= pipe;
													  ELSE N_S <= done;
									END IF;
								 
        WHEN done =>        	N_S <= idle;
                            
        WHEN reset_state => 	N_S <= idle;
        
        WHEN others => 			N_S <= reset_state;
		  
    END CASE;
END PROCESS;

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
RST_CNT_400 <= '0';
RST_REG_MPY <= '0';

EN_READ_W <= '0';
EN_READ_B <= '0';
--EN_READ_IN <= '0';

--EN_REG_IN <= '0';
EN_REG_PIPE <= '0';
EN_CNT_5 <= '0';
EN_CNT_400 <= '0';
EN_MPY <= '0';
EN_ACC <= '0';
SEL_ACC <= '0';
EN_RELU <= '0';
EN_DEC <= '0';
DONE_FC1 <= '0';

    CASE P_S IS 
	 
        WHEN idle =>  NULL;
		  
		  WHEN read_state =>  EN_READ_W <= '1';
									 EN_READ_B <= '1';
									 --EN_READ_IN <= '1';
                        
        WHEN load_bias =>   SEL_ACC <='1';
									 EN_ACC <= '1';
									 --EN_CNT_400 <= '1';
									 --EN_REG_PIPE <= '1';
									 --EN_REG_IN <= '1';
									 
		  WHEN reg_pipe  =>   EN_REG_PIPE <= '1';
									 EN_CNT_400 <= '1';
									 
		  
        WHEN pipe =>        EN_READ_W <= '1';
									 EN_CNT_400 <= '1';
									 EN_MPY <= '1';
									 EN_ACC <= '1';
									 EN_REG_PIPE <= '1';
									 EN_RELU <= '1';
									 
        
        WHEN last_sum =>    EN_ACC <= '1';
									 --SEL_ACC <= '1';
									 RST_CNT_400 <='1';
									 EN_CNT_5 <= '1';
									 --EN_READ_W <= '1';
									 EN_READ_B <= '1';
									 --EN_RELU <= '1';
		  
		  WHEN write_out =>   EN_ACC <= '1';
									 SEL_ACC <= '1';
									 EN_DEC <= '1';
									 --EN_READ_W <= '1';
									 EN_CNT_400 <='1';
									 EN_RELU <= '1';
									 RST_REG_MPY <= '1';

									 
									 
        WHEN done =>        DONE_FC1 <= '1';
		  
                            
        WHEN reset_state => RST_S <= '1';
									 RST_CNT_400 <= '1';
									 
        
        WHEN others => NULL;
		  
    END CASE;
END PROCESS;
END behaviour;