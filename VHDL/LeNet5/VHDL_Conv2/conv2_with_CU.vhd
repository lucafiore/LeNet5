-- CONV2 top file
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
USE work.CONV_struct_pkg.all;



ENTITY conv2_with_CU IS
GENERIC(	N_in 						: NATURAL:=14; -- is the width of the 6 input matrixes 
			M_in 						: NATURAL:=8;  -- is the parallelism of each element
			M_w 						: NATURAL:=8; -- is the parallelism of weights
			N_out 					: NATURAL:=10; -- is the width of the output matrix
			M_out 					: NATURAL:=8;
			D_in       				: NATURAL:=6; -- is the number of input matrices
			D_w        				: NATURAL:=16; -- is the number of filters for each input matrix
			EXTRA_BIT				: NATURAL:=3);-- is the parallelism of each element of the 16 output matrixes
PORT(		in_row_image			: IN input_3_img_2;
			matrix_weights 		: IN matrix_5x5xMw_2;
			CLK, GCLK, RST_A_n 	: IN STD_LOGIC;			
			START           		: IN STD_LOGIC;
			SAVE_LAST_MAX			: IN STD_LOGIC;
			TC4, LSB_cnt4, TC5, TC25  : IN STD_LOGIC;
			TC10_c, TC10_r  		: IN STD_LOGIC;
			cnt25_in        		: IN STD_LOGIC_VECTOR(4 DOWNTO 0); --SEL_MUX: OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
			RST   			 		: OUT STD_LOGIC;
			EN_CNT5,
			EN_CNT25,
			EN_CNT10_r,
			EN_CNT10_c,
			EN_CNT4    		 		: OUT STD_LOGIC;
			EN_MAX          		: OUT STD_LOGIC;
			EN_REG_PARTIAL  		: OUT STD_LOGIC; -- questo enable va combinato con i 2 contatori da 10 (800 elemtni da salvares)	
			EN_MPY					: OUT STD_LOGIC;
			EN_ACC 					: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			SEL_ADD1,SEL_ACC		: OUT STD_LOGIC;
			partial_res				: IN input_mac_b_2; 
			bias						: IN input_bias_2;
			out_mac					: IN output_mac_2;
			acc_mac					: IN output_acc_2;
			in_mac_1					: OUT input_mac_img_2;
			in_mac_2					: OUT input_mac_w_2;
			in_add_opt_1			: OUT input_mac_b_2;
			bias_mac					: OUT input_mac_b_2;
			output_element			: OUT output_conv_2;
			DONE_CONV, READ_IMG,SEL_IMG : OUT STD_LOGIC);
END conv2_with_CU;


ARCHITECTURE structural OF conv2_with_CU IS

--------- COMPONENTS ---------
COMPONENT Conv_layer3 IS
GENERIC(	N_in 						: NATURAL:=14; -- is the width of the 6 input matrixes 
			M_in 						: NATURAL:=8;  -- is the parallelism of each element
			M_w 						: NATURAL:=8; -- is the parallelism of weights
			N_out 					: NATURAL:=10; -- is the width of the output matrix
			M_out 					: NATURAL:=8;
			D_in       				: NATURAL:=6; -- is the number of input matrices
			D_w        				: NATURAL:=16; -- is the number of filters for each input matrix
			EXTRA_BIT				: NATURAL:=3);-- is the parallelism of each element of the 16 output matrixes
PORT(		in_row_image				: IN input_3_img_2;
			matrix_weights 			: IN matrix_5x5xMw_2;
			CLK, RST_S   				: IN STD_LOGIC;
			EN_LOAD						: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			EN_SHIFT						: IN STD_LOGIC;
			SEL_MUX						: IN STD_LOGIC_VECTOR(4 DOWNTO 0);
			EN_CONV						: IN STD_LOGIC;
			SEL_RIS1_RIS2, SEL_BIAS_RIS : IN STD_LOGIC;
			partial_res					: IN input_mac_b_2; 
			bias							: IN input_bias_2;
			out_mac						: IN output_mac_2;
			acc_mac						: IN output_acc_2;
			in_mac_1						: OUT input_mac_img_2;
			in_mac_2						: OUT input_mac_w_2;
			in_add_opt_1				: OUT input_mac_b_2;
			bias_mac						: OUT input_mac_b_2;
			output_element				: OUT output_conv_2);
END COMPONENT Conv_layer3;

COMPONENT CU_conv2 IS
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
		
END COMPONENT CU_conv2;

--------- SIGNALS ---------
SIGNAL EN_SHIFT,SEL_BIAS_RIS,	SEL_RIS1_RIS2, RST_S,EN_CONV	:  STD_LOGIC;
SIGNAL SEL_MUX					:  STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL EN_LOAD 	:  STD_LOGIC_VECTOR(1 DOWNTO 0);
--SIGNAL EN_CNT5,EN_CNT25,EN_CNT10_r,EN_CNT10_c,EN_CNT4    :  STD_LOGIC;

--------- BEGIN ---------
BEGIN
Datapath:  Conv_layer3
GENERIC MAP(	N_in,M_in,M_w,N_out,M_out,D_in,D_w,EXTRA_BIT)
PORT MAP(		in_row_image, matrix_weights,
			GCLK, RST_S,
			EN_LOAD, EN_SHIFT,
			cnt25_in,
			EN_CONV,
			SEL_RIS1_RIS2, SEL_BIAS_RIS,
			partial_res, 
			bias,
			out_mac,
			acc_mac,
			in_mac_1,
			in_mac_2,
			in_add_opt_1,
			bias_mac,
			output_element);


CU:  CU_conv2
PORT MAP(	CLK ,
      RST_A_n,
      START,
      TC4, LSB_cnt4, TC5, TC25,TC10_c, TC10_r,
		cnt25_in,
      RST_S,
      EN_CNT5,
		EN_CNT25,
		EN_CNT10_r,
		EN_CNT10_c,
		EN_CNT4,
      EN_MAX,
      EN_REG_PARTIAL,
      EN_CONV,
		EN_MPY, SEL_ADD1,SEL_RIS1_RIS2,
		SEL_ACC,SEL_BIAS_RIS,
		EN_LOAD,EN_ACC,
		EN_SHIFT,
		SEL_MUX,
		DONE_CONV, READ_IMG,SEL_IMG,SAVE_LAST_MAX);

RST <= RST_S;
END structural;