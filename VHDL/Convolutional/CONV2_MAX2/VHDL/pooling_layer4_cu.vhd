 LIBRARY ieee;
USE ieee.numeric_std.all;
USE ieee.std_logic_1164.all;

Entity pooling_layer4_cu IS
port(
        
		    Clock, RST, DATA_READY, EVEN, TC2, TC10, DONE: IN STD_LOGIC;
		    SEL, RST_ALL, W_R, OUT_WRITE, CNT5_EN, CNT10_RST, CNT_CLN_EN, REG_C_EN, R_LE_RST, R_LE_EN: OUT STD_LOGIC
	  );
END pooling_layer4_cu;
	  
	  





ARCHITECTURE STRUCTURE OF pooling_layer4_cu IS


TYPE states IS (RST_STATE, IDLE, LOAD1, LOAD2, DATA_WRITE, DATA_SAVE, MAX_EVALUATION, CLN_CHANGE, DATA_OUT_SAVE);
SIGNAL stato_presente: states;

BEGIN

PROCESS(Clock,RST) -- il passaggio degli stati prensenti
BEGIN
	IF RST='1' THEN 
		stato_presente<=RST_STATE;
	ELSIF Clock'EVENT AND Clock='1' THEN 
			CASE stato_presente IS
				WHEN RST_STATE => stato_presente <= IDLE;

				WHEN IDLE => IF DATA_READY='0' THEN
									stato_presente <= IDLE;
							  ELSE
									IF EVEN='0' THEN
										IF TC2='0' THEN
											stato_presente <= IDLE;
										ELSE
											stato_presente <= LOAD1;
										END IF;
									ELSE
										IF TC2='0' THEN
											stato_presente <= IDLE;
										ELSE
											stato_presente <= LOAD2;
										END IF;
									END IF;
							  END IF;	
				WHEN LOAD1 => stato_presente <= DATA_WRITE;
				WHEN LOAD2 => stato_presente <= DATA_SAVE;
				WHEN DATA_WRITE => IF TC10='0' THEN
											stato_presente <= IDLE;
										ELSE
											stato_presente <= CLN_CHANGE;
										END IF;
				WHEN DATA_SAVE => stato_presente <= MAX_EVALUATION;
				WHEN MAX_EVALUATION => stato_presente <= DATA_OUT_SAVE;
				WHEN DATA_OUT_SAVE => IF TC10='0' THEN
											stato_presente <= IDLE;
										ELSE
											stato_presente <= CLN_CHANGE;
										END IF;
				WHEN CLN_CHANGE => IF DONE='0' THEN
											stato_presente <= IDLE;
										ELSE
											stato_presente <= RST_STATE;
										END IF;
			END CASE;
	END IF;		
END PROCESS;
	
	

outputs: PROCESS(stato_presente)
BEGIN

	CASE stato_presente IS
		WHEN RST_STATE => 	
							SEL<='0';
							RST_ALL<='1';
							W_R<='0';
							OUT_WRITE<='0';
							CNT5_EN<='0';
							CNT10_RST<='1';
							CNT_CLN_EN<='0';
							REG_C_EN<='0';
							R_LE_RST<='1';
							R_LE_EN<='0';
		WHEN IDLE => 
							SEL<='0';
							RST_ALL<='0';
							W_R<='0';
							OUT_WRITE<='0';
							CNT5_EN<='0';
							CNT10_RST<='0';
							CNT_CLN_EN<='0';
							REG_C_EN<='0';
							R_LE_RST<='0';
							R_LE_EN<='0';
		WHEN LOAD1 => 
							SEL<='0';
							RST_ALL<='0';
							W_R<='0';
							OUT_WRITE<='0';
							CNT5_EN<='0';
							CNT10_RST<='0';
							CNT_CLN_EN<='0';
							REG_C_EN<='0';
							R_LE_RST<='0';
							R_LE_EN<='1';
		WHEN LOAD2 => 
							SEL<='0';
							RST_ALL<='0';
							W_R<='0';
							OUT_WRITE<='0';
							CNT5_EN<='0';
							CNT10_RST<='0';
							CNT_CLN_EN<='0';
							REG_C_EN<='0';
							R_LE_RST<='0';
							R_LE_EN<='1';
		WHEN DATA_WRITE =>
							SEL<='0';
							RST_ALL<='0';
							W_R<='1';
							OUT_WRITE<='0';
							CNT5_EN<='1';
							CNT10_RST<='0';
							CNT_CLN_EN<='0';
							REG_C_EN<='0';
							R_LE_RST<='1';
							R_LE_EN<='0';
		WHEN DATA_SAVE =>
							SEL<='0';
							RST_ALL<='0';
							W_R<='0';
							OUT_WRITE<='0';
							CNT5_EN<='0';
							CNT10_RST<='0';
							CNT_CLN_EN<='0';
							REG_C_EN<='1';
							R_LE_RST<='1';
							R_LE_EN<='0';
		WHEN MAX_EVALUATION =>
							SEL<='1';
							RST_ALL<='0';
							W_R<='0';
							OUT_WRITE<='0';
							CNT5_EN<='0';
							CNT10_RST<='0';
							CNT_CLN_EN<='0';
							REG_C_EN<='0';
							R_LE_RST<='0';
							R_LE_EN<='1';
		WHEN CLN_CHANGE =>
							SEL<='0';
							RST_ALL<='0';
							W_R<='0';
							OUT_WRITE<='0';
							CNT5_EN<='0';
							CNT10_RST<='1';
							CNT_CLN_EN<='1';
							REG_C_EN<='0';
							R_LE_RST<='0';
							R_LE_EN<='0';
		WHEN DATA_OUT_SAVE =>
							SEL<='1';
							RST_ALL<='0';
							W_R<='0';
							OUT_WRITE<='1';
							CNT5_EN<='1';
							CNT10_RST<='0';
							CNT_CLN_EN<='0';
							REG_C_EN<='0';
							R_LE_RST<='1';
							R_LE_EN<='0';

	END CASE;
END PROCESS;
END STRUCTURE;
-- ??