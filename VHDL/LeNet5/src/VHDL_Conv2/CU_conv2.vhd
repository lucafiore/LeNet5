
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
--USE work.all;
--USE work.data_for_mac_pkg.all;


ENTITY CU_conv2 IS
PORT(	CLK             : IN STD_LOGIC;
      RST_A_n         : IN STD_LOGIC;
      START           : IN STD_LOGIC;
      TC4, LSB_cnt4, TC5, TC25  : IN STD_LOGIC; -- TC3 per il parallel_in iniziale, TC5 per fare 5 (o 3?) shift alla fine delle colonne, TC25 per le operazione della conv
      TC10_c, TC10_r  : IN STD_LOGIC; -- TC28_c per sapere a che colonna sono arrivato, TC28_r per sapere a che riga sono arrivato
      cnt25_in        : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
      RST_S   			 : OUT STD_LOGIC;
      EN_CNT5,
		EN_CNT25,
		EN_CNT10_r,
		EN_CNT10_c,
		EN_CNT4    : OUT STD_LOGIC;
      EN_MAX          : OUT STD_LOGIC;
      EN_REG_PARTIAL  : OUT STD_LOGIC;
      EN_CONV         : OUT STD_LOGIC; -- abilita il registro (barriera) di ingresso prima del mpy
		EN_MPY, SEL_ADD1,SEL_RIS1_RIS2: OUT STD_LOGIC;
		SEL_ACC,SEL_BIAS_RIS: OUT STD_LOGIC; -- if '0' load out adder, if '1' load external data
		EN_LOAD,EN_ACC  : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		EN_SHIFT		    : OUT STD_LOGIC;
		SEL_MUX			 : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
		--EN_REG_OUT			: OUT EN_28X28;
		DONE_CONV, READ_IMG,SEL_IMG : OUT STD_LOGIC;
		SAVE_LAST_MAX	: IN STD_LOGIC);
END CU_conv2;

ARCHITECTURE behaviour OF CU_conv2 IS
TYPE state IS (reset_state, idle, parallel_in_1, parallel_in_2, conv_bias, conv_ris, start_conv, conv, somma_1, somma_2, shift_save, shift_max, save, max, shift, parallel_in_save,parallel_in_max, sel_step, wait_done, done);
ATTRIBUTE enum_encoding : string;
ATTRIBUTE enum_encoding OF state : TYPE IS "11001 01001 01000 00010 01100 00110 01110 01010 01000 00000 11000 00011 00010 00001 00100 10100 00101 01011 01111 01101";
SIGNAL P_S, N_S : state;

SIGNAL CNT_SEL_MUX : STD_LOGIC_VECTOR(4 DOWNTO 0);

  
BEGIN
  
CNT_SEL_MUX <= cnt25_in;
 
state_transitions : PROCESS(P_S, START, TC4, TC5, TC25, TC10_r, TC10_c, LSB_cnt4,SAVE_LAST_MAX)
BEGIN 
	CASE P_S IS 
		WHEN idle =>  IF (START='1') THEN 
								IF (LSB_cnt4='0') THEN 
									N_S <= parallel_in_1;
								ELSE 
									N_S <= parallel_in_2;
								END IF;
							ELSE N_S <= idle;
							END IF;
						
		WHEN parallel_in_1 => IF (TC5='0') THEN N_S <= parallel_in_1;
							       ELSE N_S <= conv_bias;
								    END IF;
									 
		WHEN parallel_in_2 => IF (TC5='0') THEN N_S <= parallel_in_2;
							       ELSE N_S <= conv_ris;
								    END IF;
									 
		WHEN conv_ris  => N_S <= start_conv;
		WHEN conv_bias => N_S <= start_conv;
		
		WHEN start_conv  => N_S <= conv;
		
		WHEN conv =>	IF (TC25='0') THEN N_S <= conv;
							ELSE 
							      N_S <= somma_1;
							END IF;
							
		WHEN somma_1 => N_S <= somma_2;
		
		WHEN somma_2 =>  	       IF (TC10_c='0') THEN 
											IF (LSB_cnt4='0') THEN N_S <= shift_save;
								         ELSE N_S <= shift_max;
											END IF;
										 ELSE 
								         IF (TC10_r='0') THEN N_S <= shift;
								         ELSE 
												IF (LSB_cnt4='0') THEN N_S <= save;
												ELSE N_S <= max;
												END IF;
								         END IF;
								       END IF;
								
		WHEN shift_save => 	N_S <= conv_bias;
		
		WHEN shift_max => 	N_S <= conv_ris;
		
		WHEN sel_step=>	IF (LSB_cnt4='0') THEN N_S <= parallel_in_1;
										ELSE N_S <= parallel_in_2;
										END IF;
				
		WHEN shift =>	IF (TC5='1') THEN 
								IF (LSB_cnt4='0') THEN N_S <= parallel_in_save;
								ELSE N_S <= parallel_in_max;
								END IF;
							 ELSE N_S <= shift;
							 END IF;
							 
		WHEN parallel_in_save => 	N_S <= conv_bias;
		
		WHEN parallel_in_max => 	N_S <= conv_ris;
							
		WHEN save  =>	 IF (TC4='0') THEN 
									N_S <= sel_step;
							 ELSE N_S <= wait_done;
							 END IF;
									 
		WHEN max =>		 IF (TC4='0') THEN 
									N_S <= sel_step;
							 ELSE N_S <= wait_done;
							 END IF;
	 
		  
		WHEN done =>		N_S <= idle;
		
		WHEN wait_done =>	 IF (SAVE_LAST_MAX='1') THEN N_S <= done;
							    ELSE N_S <= wait_done;
							    END IF;
							
		WHEN reset_state =>		n_s <= idle;
		
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
--EN_CNT5 <= '0';
EN_CNT5 <= '0';
EN_CNT25 <= '0';
EN_CNT10_r <= '0';
EN_CNT10_c <= '0';
EN_CNT4  <= '0';

EN_MAX <= '0';
EN_REG_PARTIAL <= '0';
EN_CONV <= '0';

EN_MPY <= '0';
EN_ACC <= "00"; -- MSB è per il mac dove salvo le somme parziali, LSB è per gli altri 2 mac
SEL_ACC <= '0';
SEL_BIAS_RIS <= '0';
SEL_ADD1 <= '0';
SEL_RIS1_RIS2 <= '0';

EN_LOAD <= "00";
EN_SHIFT <= '0';

SEL_MUX	<= CNT_SEL_MUX;
DONE_CONV <= '0';
READ_IMG <= '0';
SEL_IMG	<= '0';

	CASE P_S IS 
		WHEN idle =>  NULL;
						
		WHEN parallel_in_1 =>EN_LOAD <= "11";
									EN_SHIFT <= '1'; 
									READ_IMG <= '1';
									SEL_IMG	<= '0';
									EN_CNT5 <= '1';
									 
		WHEN parallel_in_2 =>EN_LOAD <= "11";
									EN_SHIFT <= '1'; 
									READ_IMG <= '1';
									SEL_IMG	<= '1';
									EN_CNT5 <= '1';

								
		WHEN conv_ris => 	EN_MPY <= '0';
								EN_ACC <= "11";
								SEL_ACC <= '1';
								SEL_BIAS_RIS <= '1';
								EN_CONV <= '1';
								EN_CNT25 <= '1';
								SEL_MUX	<= CNT_SEL_MUX;
		
		WHEN conv_bias => EN_MPY <= '0';
								EN_ACC <= "11";
								SEL_ACC <= '1';
								SEL_BIAS_RIS <= '0';
								EN_CONV <= '1';
								EN_CNT25 <= '1';
								SEL_MUX	<= CNT_SEL_MUX;
									 		
-- possibile errore puo essere il registro di accumulazione che deve essere resettato prima di ogni convoluzione

		WHEN start_conv =>	EN_MPY <= '1'; 
								EN_ACC <= "00";
								SEL_ACC <= '0';
								SEL_BIAS_RIS <= '0';
								EN_CONV <= '1';
								EN_CNT25 <= '1';
								SEL_MUX	<= CNT_SEL_MUX;
								
								
		WHEN conv =>	EN_MPY <= '1';
							EN_ACC <= "11";
							SEL_ACC <= '0';
							EN_CNT25 <= '1';
							EN_CONV <= '1';
							SEL_MUX	<= CNT_SEL_MUX;
							
		WHEN somma_1 => EN_MPY <= '0';
								EN_ACC <= "10";
								SEL_ADD1 <= '1';
								SEL_RIS1_RIS2 <= '0';
								
		
		WHEN somma_2 =>  EN_MPY <= '0';
								EN_ACC <= "10";
								SEL_ADD1 <= '1';
								SEL_RIS1_RIS2 <= '1';
								
		WHEN shift_save => EN_LOAD <= "11";
									EN_SHIFT <= '0';
									EN_MAX <= '0';
								EN_REG_PARTIAL <= '1';
								EN_CNT10_c <= '1';
								
		
		WHEN shift_max => EN_LOAD <= "11";
									EN_SHIFT <= '0';
									EN_MAX <= '1';
								EN_REG_PARTIAL <= '0';
								EN_CNT10_c <= '1';
								
		WHEN save => 		EN_MAX <= '0';
								EN_REG_PARTIAL <= '1';
								EN_CNT10_c <= '1';
								EN_CNT10_r <= '1';
								EN_CNT4 <= '1';

		WHEN max => 		EN_MAX <= '1';
								EN_REG_PARTIAL <= '0';
								EN_CNT10_c <= '1';
								EN_CNT10_r <= '1';
								EN_CNT4 <= '1';
								
							
		WHEN shift =>			EN_LOAD <= "11";
									EN_SHIFT <= '0';
									EN_CNT5 <= '1';
							 
		WHEN parallel_in_save => 	EN_LOAD <= "10";
									EN_SHIFT <= '1'; 
									READ_IMG <= '1';
									SEL_IMG	<= '0';
									EN_REG_PARTIAL <= '1';
									EN_CNT10_r <= '1';
									EN_CNT10_c <= '1';
		
		WHEN parallel_in_max => EN_LOAD <= "10";
									EN_SHIFT <= '1'; 
									READ_IMG <= '1';
									SEL_IMG	<= '1';
									EN_MAX <= '1';
									EN_CNT10_r <= '1';
									EN_CNT10_c <= '1';
							
		WHEN sel_step  =>	--EN_CNT4 <= '1';
		  
		WHEN wait_done =>	NULL;
		  
		WHEN done =>		DONE_CONV <= '1';
							
		WHEN reset_state => RST_S <= '1';
									SEL_MUX	<= CNT_SEL_MUX;
		
		WHEN others => NULL;
	END CASE;
END PROCESS;
END behaviour;