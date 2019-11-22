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
USE work.data_for_mac_pkg2.all;


-- tale circuito si collega direttamente al CONV2, gi¨¤ ¨¨ replicato per 8 volte(richiesta da CONV2) con un'unica CU 
ENTITY pooling_layer4 IS
  GENERIC(N                    : NATURAL:=8); -- il numero di volte che si ripete in CONV2
  PORT(	
        clock, RST: IN STD_LOGIC;
		  DATA_READY: IN STD_LOGIC;
        data_in: IN output_conv;
		  DONE_MAX : OUT STD_LOGIC;
        EN_25: OUT STD_LOGIC_VECTOR(24 DOWNTO 0); 
        output: OUT output_conv
		);
END pooling_layer4;





ARCHITECTURE structural OF pooling_layer4 IS
--------------------------------------- COMPONENTS --------------------------------------------

COMPONENT pooling_layer4_dp IS
  GENERIC(
		N                    : NATURAL:=8; -- il numero di volte che si ripete in CONV2
      M_in 						: NATURAL:=M_in;  -- is the parallelism of each element
      M_out 					: NATURAL:=M_out);-- is the parallelism of each element
  PORT(	 
			clock, SEL, RST_ALL, W_R, CNT5_EN, CNT10_RST, CNT_CLN_EN, REG_C_EN, DATA_READY, R_LE_RST, R_LE_EN: IN STD_LOGIC;
			data_in: IN output_conv;
			TC2: BUFFER STD_LOGIC;
			EVEN, TC10, DONE: OUT STD_LOGIC;
			output: BUFFER output_conv
      );
END COMPONENT;

COMPONENT pooling_layer4_cu IS
port(
        
		    Clock, RST, DATA_READY, EVEN, TC2, TC10, DONE: IN STD_LOGIC;
		    SEL, RST_ALL, W_R, OUT_WRITE, CNT5_EN, CNT10_RST, CNT_CLN_EN, REG_C_EN, R_LE_RST, R_LE_EN: OUT STD_LOGIC
	  );
END COMPONENT;
	  
COMPONENT one_hot_dec IS
 GENERIC( N                    : NATURAL:=25); -- numero di stati
    PORT(	
        ENABLE, RST: IN STD_LOGIC;
        data_out: OUT STD_LOGIC_VECTOR(0 to N-1)
		);
END COMPONENT one_hot_dec;

------------------------------------SIGNAL------------------------------------------
SIGNAL SEL,RST_ALL, CNT5_EN, CNT10_RST, 
 CNT_CLN_EN, REG_C_EN,TC2,EVEN, TC10, DONE, W_R, R_LE_EN, R_LE_RST,OUT_WRITE: STD_LOGIC;


----------------------------BEGIN--------------------------------------
BEGIN


layer4_dp: pooling_layer4_dp
  GENERIC MAP(M_in,M_out)
  PORT MAP(clock=>clock, SEL=>SEL, RST_ALL=>RST_ALL, W_R=>W_R,
   CNT5_EN=>CNT5_EN, CNT10_RST=>CNT10_RST, CNT_CLN_EN=>CNT_CLN_EN, 
   REG_C_EN=>REG_C_EN, DATA_READY=>DATA_READY, R_LE_RST=>R_LE_RST, 
	R_LE_EN=>R_LE_EN,data_in=>data_in, TC2=>TC2, EVEN=>EVEN, 
   TC10=>TC10, DONE=>DONE, output=>output);
   
layer4_cu: pooling_layer4_cu
  PORT MAP(Clock=>clock, RST=>RST, DATA_READY=>DATA_READY, EVEN=>EVEN, TC2=>TC2, 
  TC10=>TC10, DONE=>DONE, SEL=>SEL, RST_ALL=>RST_ALL, 
  W_R=>W_R,OUT_WRITE=>OUT_WRITE, CNT5_EN=>CNT5_EN, 
  CNT10_RST=>CNT10_RST, CNT_CLN_EN=>CNT_CLN_EN, REG_C_EN=>REG_C_EN, R_LE_EN=>R_LE_EN, R_LE_RST=>R_LE_RST);

output_registers_decoder: one_hot_dec
	PORT MAP(ENABLE=>OUT_WRITE, RST=>RST_ALL, data_out=>EN_25);

DONE_MAX <= OUT_WRITE;

END structural;