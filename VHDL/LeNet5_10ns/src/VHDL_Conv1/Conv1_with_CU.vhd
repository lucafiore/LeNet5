-- conv1 + CU_conv1 --

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

-- INFO
-- i MAC devono stare fuori da questo layer (sono in comune con tutti i layer)

ENTITY Conv1_with_CU IS
GENERIC(	N_in 						: NATURAL:=32; -- is the width of the input image
			   M_in 						: NATURAL:=8;  -- is the parallelism of each pixel
			   M_w 						 : NATURAL:=10; -- is the parallelism of weights
			   N_w        : NATURAL:=5;  -- is the width of the weights matrix
			   I_w        : NATURAL:=6;  -- is the number of weights matrices
			   N_out 					: NATURAL:=28; -- is the width of the output image
			   M_out 					: NATURAL:=10; -- is the parallelism of each element of the output matrix (the same of weights)
			   EXTRA_BIT		: NATURAL:=3); -- to avoid overflow
PORT(	in_row_image1		      : IN STD_LOGIC_VECTOR(N_in*M_in-1 DOWNTO 0); --DATAP
      in_row_image2		      : IN STD_LOGIC_VECTOR(N_in*M_in-1 DOWNTO 0); --DATAP
			CLK, GCLK, RST_n      : IN STD_LOGIC; --DATAP e CU
			START      			       : IN STD_LOGIC; --CU
			TC3_PAR, TC3_SHIFT, TC25       : IN STD_LOGIC; 
			TC14_C, TC14_R       : IN STD_LOGIC; 
			cnt_25             : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
			EN_CNT_25        : OUT STD_LOGIC;
			EN_CNT_3_PAR         : OUT STD_LOGIC;
			EN_CNT_14_R      : OUT STD_LOGIC;
			EN_CNT_14_C,EN_CNT_3_SHIFT: OUT STD_LOGIC;
			EN_MPY, EN_ACC 		: OUT STD_LOGIC;
			SEL_ACC    		 : OUT STD_LOGIC;
			RST_S						: OUT STD_LOGIC;
			out_mac_block        : IN OUTPUT_MAC; --DATAP
			matrix_weights 		: IN matrix_5x5xMw;
			bias_mac       		: IN INPUT_MAC_W;
			input_mac_1          : OUT INPUT_MAC_IMG; --DATAP
			input_mac_2          : OUT INPUT_MAC_W; --DATAP
			input_mac_3          : OUT INPUT_MAC_B; --DATAP
			output_layer  			: OUT INPUT_MAC_W;
			DONE, READ_IMG  		: OUT STD_LOGIC;
			SAVE_OUT_MAX			: OUT STD_LOGIC;
			ENABLE_PREC 			: OUT array_en;
			PREC_RESULT				: OUT STD_LOGIC); --DATAP
END Conv1_with_CU;


ARCHITECTURE structural OF Conv1_with_CU IS
------------------- COMPONENT ----------------------
COMPONENT CU_conv1 IS
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
		DONE_CONV, READ_IMG : OUT STD_LOGIC;
		SAVE_LAST_MAX	 : IN STD_LOGIC);
END COMPONENT CU_conv1;

COMPONENT Conv_layer_1 IS
GENERIC(		N_in 			: NATURAL:=32; -- is the width of the input image
			   M_in 			: NATURAL:=8;  -- is the parallelism of each pixel
			   M_w 			: NATURAL:=10; -- is the parallelism of weights
			   N_w         : NATURAL:=5;  -- is the width of the weights matrix
			   I_w         : NATURAL:=6;  -- is the number of weights matrices
			   N_out 		: NATURAL:=28; -- is the width of the output image
			   M_out 		: NATURAL:=10; -- is the parallelism of each element of the output matrix (the same of weights)
			   EXTRA_BIT	: NATURAL:=3); -- to avoid overflow
PORT(	in_row_image1		: IN STD_LOGIC_VECTOR(N_in*M_in-1 DOWNTO 0);
      in_row_image2		: IN STD_LOGIC_VECTOR(N_in*M_in-1 DOWNTO 0);
			CLK, RST_S 		: IN STD_LOGIC;
			EN_LOAD        : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- abilita caricamento (1 INPUT REGS, 0 OTHERS REGS)
			EN_SHIFT		   : IN STD_LOGIC;
			SEL_MUX			: IN STD_LOGIC_VECTOR(4 DOWNTO 0);
			EN_CONV        : IN STD_LOGIC;
			EN_MAX         : IN STD_LOGIC;
			DO_PREC        : IN STD_LOGIC;
			matrix_weights : IN matrix_5x5xMw;
			bias_mac       : IN INPUT_MAC_W;
			out_mac_block  : IN OUTPUT_MAC;
			PREC_RESULT    : OUT STD_LOGIC;
			input_mac_1    : OUT INPUT_MAC_IMG;
			input_mac_2    : OUT INPUT_MAC_W;
			input_mac_3    : OUT INPUT_MAC_B;
			output_layer  	: OUT INPUT_MAC_W;
			SAVE_OUT_MAX	: OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
			
			EN_PREC_CONV 	: OUT array_en);
END COMPONENT Conv_layer_1;

COMPONENT register_1bit IS
PORT(		data_in 			: IN STD_LOGIC;
			EN, CLK, RST   : IN STD_LOGIC;
			data_out 		: OUT STD_LOGIC);
END COMPONENT register_1bit;


------------------- SIGNALS -----------------------
SIGNAL PRECOMPUTATION                                 : STD_LOGIC;
SIGNAL RST														  	: STD_LOGIC;
SIGNAL EN_MAX, EN_PREC, EN_CONV, EN_SHIFT : STD_LOGIC;  --EN_MPY, EN_ACC 
--SIGNAL SEL_ACC													 : STD_LOGIC;
SIGNAL EN_LOAD                                        : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL SEL_MUX			                              	: STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL EN_REG_OUT													: STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL SAVE_LAST_MAX												: STD_LOGIC;

BEGIN
  

CU : CU_conv1
  PORT MAP( CLK, 
            RST_n, 
            START, 
            PRECOMPUTATION,
            TC3_PAR, TC3_SHIFT, TC25, TC14_C, TC14_R,
            cnt_25,
            RST,
            EN_CNT_25,EN_CNT_3_PAR,EN_CNT_14_R,EN_CNT_14_C,EN_CNT_3_SHIFT,
            EN_MAX, EN_PREC, EN_CONV, EN_MPY, EN_ACC,
				SEL_ACC,
				EN_LOAD, EN_SHIFT, 
            SEL_MUX,
				--EN_REG_OUT,
            DONE, READ_IMG,SAVE_LAST_MAX);

  
RST_S <= RST;
 
 
DATAPATH : Conv_layer_1
  GENERIC MAP( N_in,
			         M_in,
			         M_w,
			         N_w,
			         I_w,
			         N_out,
			         M_out,
			         EXTRA_BIT)
  PORT MAP(   in_row_image1,
              in_row_image2,
			        GCLK, RST,
			        EN_LOAD,
			        EN_SHIFT,
			        cnt_25,
			        EN_CONV,
			        EN_MAX,
			        EN_PREC,
			        matrix_weights,
			        bias_mac,
			        out_mac_block,
			        PRECOMPUTATION,
			        input_mac_1,
			        input_mac_2,
			        input_mac_3,
			        output_layer,
					  EN_REG_OUT,
					  ENABLE_PREC);

SAVE_LAST_MAX <= '0' when EN_REG_OUT=(EN_REG_OUT'RANGE=>'0') ELSE '1';				  
SAVE_OUT_MAX <= SAVE_LAST_MAX;						

--FF_PREC_RESULT : register_1bit
--PORT MAP(		PRECOMPUTATION,
--			EN_MAX, CLK, RST,
--			PREC_RESULT);


PREC_RESULT <= PRECOMPUTATION;
 
END structural;