
-- LeNet5 top file
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
USE work.data_for_mac_pkg.all;


ENTITY CU_conv1 IS
PORT(	CLK             : IN STD_LOGIC;
      RST_A_n         : IN STD_LOGIC;
      START           : IN STD_LOGIC;
      PRECOMPUTATION  : IN STD_LOGIC;
      TC3, TC5, TC25  : IN STD_LOGIC; -- TC3 per il parallel_in iniziale, TC5 per fare 5 (o 3?) shift alla fine delle colonne, TC25 per le operazione della conv
      TC28_c, TC28_r  : IN STD_LOGIC; -- TC28_c per sapere a che colonna sono arrivato, TC28_r per sapere a che riga sono arrivato
      cnt25_in        : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
      RST_S   			 : OUT STD_LOGIC;
      EN_CNT25        : OUT STD_LOGIC;
      EN_CNT3         : OUT STD_LOGIC;
      EN_CNT28_r      : OUT STD_LOGIC;
      EN_CNT28_c,EN_CNT5   : OUT STD_LOGIC;
      EN_MAX          : OUT STD_LOGIC;
      EN_PREC         : OUT STD_LOGIC;
      EN_CONV         : OUT STD_LOGIC; -- abilita il registro (barriera) di ingresso prima del mpy
		EN_MPY, EN_ACC	 : OUT STD_LOGIC;
		SEL_ACC    		 : OUT STD_LOGIC; -- if '0' load out adder, if '1' load external data
		EN_LOAD         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		EN_SHIFT		    : OUT STD_LOGIC;
		SEL_MUX			 : OUT STD_LOGIC_VECTOR(4 DOWNTO 0); --prendo come sel l'uscita del contatore25
		--EN_REG_OUT			: OUT EN_28X28;
		DONE_CONV, READ_IMG : OUT STD_LOGIC);
END CU_conv1;

ARCHITECTURE behaviour OF CU_conv1 IS
TYPE state IS (reset_state, idle, parallel_in_1, parallel_in_2, max_prec_shift, start_conv, conv_bias, conv, max_shift, shift, done);
--ATTRIBUTE enum_encoding : string;
--ATTRIBUTE enum_encoding OF state : TYPE IS "1100 0000 0001 1001 0011 1011 1111 0111 0101 1101 1110 100";
SIGNAL P_S, N_S : state;
  
BEGIN
  
  
state_transitions : PROCESS(P_S, START, TC3, TC5, TC25, TC28_r, TC28_c, PRECOMPUTATION)
BEGIN 
	CASE P_S IS 
		WHEN idle =>  IF (START='0') THEN N_S <= idle;
							ELSE N_S <= parallel_in_1;
							END IF;
						
		WHEN parallel_in_1 => IF (TC3='0') THEN N_S <= parallel_in_1;
							            ELSE N_S <= max_prec_shift;
								          END IF;
						
		WHEN max_prec_shift =>  IF (PRECOMPUTATION='0') THEN N_S <= start_conv;
							              ELSE	
								              IF (TC28_c='0') THEN N_S <= max_prec_shift;
								              ELSE 
								                IF (TC28_r='0') THEN N_S <= max_shift;
								                ELSE N_S <= done;
								                END IF;
								              END IF;
							              END IF;
								
		WHEN max_shift => 	N_S <= shift;
							
		WHEN shift =>	IF (TC5='1') THEN N_S <= parallel_in_2;
							    ELSE N_S <= shift;
							    END IF;
							
		WHEN start_conv =>	N_S <= conv_bias;
		
		WHEN conv_bias =>		N_S <= conv;
		  
		WHEN conv =>	IF (TC25='0') THEN N_S <= conv; -- qui c'è un errore, se tc è 0 deve rimanere in conv
							    ELSE 
							      IF (TC28_c='0') THEN N_S <= max_prec_shift;
								    ELSE 
								      IF (TC28_r='0') THEN N_S <= max_shift;
								      ELSE N_S <= done;
								      END IF;
								    END IF;
							    END IF;
		
		WHEN parallel_in_2 =>		N_S <= max_prec_shift;
		  
		WHEN done =>		N_S <= idle;
							
		WHEN reset_state =>		N_S <= idle;
		
		WHEN others => n_s <= reset_state;
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
EN_CNT3 <= '0';
EN_CNT25 <= '0';
EN_CNT28_r <= '0';
EN_CNT28_c <= '0';
EN_CNT5  <= '0';
EN_MAX <= '0';
EN_PREC <= '0';
EN_CONV <= '0';
EN_MPY <= '0';
EN_ACC <= '0';
SEL_ACC <= '0';
EN_LOAD <= "00";
EN_SHIFT <= '0';
SEL_MUX	<= cnt25_in;
DONE_CONV <= '0';
READ_IMG <= '0';

	CASE P_S IS 
		WHEN idle =>  RST_S <= '1';
						
		WHEN parallel_in_1 =>   EN_LOAD <= "11";
                            EN_SHIFT <= '1'; --parallel load
                            EN_CNT3 <= '1';
									 READ_IMG <= '1';
						
		WHEN max_prec_shift =>  EN_MAX <= '1';
		                        EN_LOAD <= "11";
                            EN_SHIFT <= '0'; --shift
                            EN_PREC <= '1';
									 EN_CNT28_c <= '1';
								
		WHEN max_shift => 	EN_MAX <= '1';
		                   EN_LOAD <= "11";
                       EN_SHIFT <= '0'; --shift
								EN_CNT5  <= '1';
								EN_CNT28_c <= '1';

							
		WHEN shift =>	  EN_LOAD <= "11";
                    EN_SHIFT <= '0'; --shift
							EN_CNT5  <= '1';
		
		
		WHEN start_conv => EN_CONV <= '1';
		                  --EN_MAX <= '1';
		                  EN_CNT25 <= '1';
		                  SEL_MUX <= cnt25_in;
								EN_MPY <= '0';
								EN_ACC <= '0';
								SEL_ACC <= '0';
		
		WHEN conv_bias =>		EN_CONV <= '1';
		                  --EN_MAX <= '1';
		                  EN_CNT25 <= '1';
		                  SEL_MUX <= cnt25_in;
								EN_MPY <= '1';
								EN_ACC <= '1';
								SEL_ACC <= '1';
						
		  
		WHEN conv =>	 EN_CONV <= '1';
		              EN_CNT25 <= '1';
		              SEL_MUX <= cnt25_in;
						  EN_MPY <= '1';
						EN_ACC <= '1';
						SEL_ACC <= '0';
		
		WHEN parallel_in_2 =>		 EN_LOAD <= "10"; --solo i primi shift_reg si caricano in parallelo
                            EN_SHIFT <= '1'; --parallel load
                            --EN_CNT3 <= '1';
									 EN_CNT28_r <= '1';
									 READ_IMG <= '1';
		  
		WHEN done =>		DONE_CONV <= '1';
							
		WHEN reset_state => RST_S <= '1';
								SEL_MUX	<= cnt25_in;
		
		WHEN others => NULL;
	END CASE;
END PROCESS;
END behaviour;