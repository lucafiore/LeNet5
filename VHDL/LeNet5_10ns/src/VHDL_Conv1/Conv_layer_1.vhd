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
USE work.CONV_struct_pkg.all;

-- INFO
-- i MAC devono stare fuori da questo layer (sono in comune con tutti i layer)

ENTITY Conv_layer_1 IS
GENERIC(	N_in 						: NATURAL:=32; -- is the width of the input image
			   M_in 						: NATURAL:=8;  -- is the parallelism of each pixel
			   M_w 						: NATURAL:=10; -- is the parallelism of weights
			   N_w        			: NATURAL:=5;  -- is the width of the weights matrix
			   I_w        			: NATURAL:=6;  -- is the number of weights matrices
			   N_out 					: NATURAL:=28; -- is the width of the output image
			   M_out 					: NATURAL:=10; -- is the parallelism of each element of the output matrix (the same of weights)
			   EXTRA_BIT		: NATURAL:=3); -- to avoid overflow
PORT(	in_row_image1		      : IN STD_LOGIC_VECTOR(N_in*M_in-1 DOWNTO 0);
      in_row_image2		      : IN STD_LOGIC_VECTOR(N_in*M_in-1 DOWNTO 0);
			CLK, RST_S 			   : IN STD_LOGIC;
			EN_LOAD              : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- abilita caricamento (1 INPUT REGS, 0 OTHERS REGS)
			EN_SHIFT		         : IN STD_LOGIC; -- se caricamento abilitato, shifta o carica in parallelo ('0' -> shift,'1' -> parallel load)
			SEL_MUX			      : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
			EN_CONV              : IN STD_LOGIC;
			EN_MAX               : IN STD_LOGIC;
			DO_PREC              : IN STD_LOGIC;
			matrix_weights 		: IN matrix_5x5xMw;
			bias_mac       		: IN INPUT_MAC_W;
			out_mac_block        : IN OUTPUT_MAC;
			PREC_RESULT          : OUT STD_LOGIC;
			input_mac_1          : OUT INPUT_MAC_IMG;
			input_mac_2          : OUT INPUT_MAC_W;
			input_mac_3          : OUT INPUT_MAC_B;
			output_layer  			: OUT INPUT_MAC_W;
			SAVE_OUT_MAX			: OUT STD_LOGIC_VECTOR(I_w-1 DOWNTO 0);
			EN_PREC_CONV 			: OUT array_en); -- 6 uscite solamente
END Conv_layer_1;


ARCHITECTURE structural OF Conv_layer_1 IS
--------- COMPONENTS ---------
COMPONENT max_pooling IS
GENERIC( M_in 						: NATURAL:=8;  -- is the parallelism of each element
         M_out 					: NATURAL:=8);-- is the parallelism of each element of the 16 output matrixes
  PORT(	MAX_EN, PREC, REG_RST: IN STD_LOGIC;
			clock: IN STD_LOGIC;
			data1, data2, data3, data4: IN STD_LOGIC_VECTOR(M_in-1 DOWNTO 0);
			OUT_READY: OUT STD_LOGIC;
			output: OUT STD_LOGIC_VECTOR(M_out-1 DOWNTO 0));  
END COMPONENT max_pooling;

COMPONENT precomputation_conv IS
GENERIC(	N 					 : NATURAL:=25); -- number of elements to evaluate
PORT(		in_1, in_2	 : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0); -- in_1 = ingresso, in_2 = peso
			 EN				     : IN STD_LOGIC;
			 EN_OP				   : OUT STD_LOGIC);
END COMPONENT precomputation_conv;



COMPONENT shift_reg_5x32x8bit_4out IS
GENERIC(  N_in    : NATURAL:=32; -- is the width of the input image
          N_w 				: NATURAL:=5; -- is the width of the weight matrix
			    M 						: NATURAL:=8);  -- is the parallelism of each pixel
PORT(	parallel_in1	: IN STD_LOGIC_VECTOR(N_in*M-1 DOWNTO 0);
      parallel_in2	: IN STD_LOGIC_VECTOR(N_in*M-1 DOWNTO 0);
			EN           : IN STD_LOGIC_VECTOR(1 DOWNTO 0); --1 INPUT REGS, 0 OTHERS REGS
			CLK, RST   : IN STD_LOGIC;
			EN_SHIFT			  : IN STD_LOGIC; -- if '0' -> shift, if '1' -> parallel load (it's the selector of mux)
			matrix_out_1	: OUT STD_LOGIC_VECTOR(N_w*N_w*M-1 DOWNTO 0); -- prima sub_matrix 
			matrix_out_2	: OUT STD_LOGIC_VECTOR(N_w*N_w*M-1 DOWNTO 0);
			matrix_out_3	: OUT STD_LOGIC_VECTOR(N_w*N_w*M-1 DOWNTO 0);
			matrix_out_4	: OUT STD_LOGIC_VECTOR(N_w*N_w*M-1 DOWNTO 0);
			out_precomp1 : OUT STD_LOGIC_VECTOR(N_w*N_w-1 DOWNTO 0);
			out_precomp2 : OUT STD_LOGIC_VECTOR(N_w*N_w-1 DOWNTO 0);
			out_precomp3 : OUT STD_LOGIC_VECTOR(N_w*N_w-1 DOWNTO 0);
			out_precomp4 : OUT STD_LOGIC_VECTOR(N_w*N_w-1 DOWNTO 0)); -- devo prendere i MSB delle 4 submatrix per la precomputation
END COMPONENT shift_reg_5x32x8bit_4out;

COMPONENT mux2to1_nbit IS
GENERIC(	N 				: NATURAL:=8);
PORT(	in_0, in_1 	: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
		SEL		   : IN STD_LOGIC:='0';
		q				: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT;

COMPONENT mux25to1_nbit IS
GENERIC(	N 					: NATURAL:=8);
PORT(	data_in	 	: IN STD_LOGIC_VECTOR(25*N-1 DOWNTO 0):= (OTHERS=>'0');
			SEL				  : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
			q			 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT mux25to1_nbit;

COMPONENT relu_conv IS ---- sistemare relu_conv
GENERIC(	N 					: NATURAL:=8);
PORT(		data_in 	: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			 q			 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT relu_conv;

COMPONENT register_nbit IS
GENERIC(	N 					: NATURAL:=8);
PORT(	data_in 			    : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			EN, CLK, RST   : IN STD_LOGIC;
			data_out 		    : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT register_nbit;

COMPONENT register_1bit IS
PORT(		data_in 			: IN STD_LOGIC;
			EN, CLK, RST   : IN STD_LOGIC;
			data_out 		: OUT STD_LOGIC);
END COMPONENT register_1bit;


--------- SIGNALS ---------
-- matrix of inputs and weights
TYPE matrix_5x5xMin	IS ARRAY(0 TO 3) OF STD_LOGIC_VECTOR(N_w*N_w*M_in-1 DOWNTO 0); -- variabile per ottenere le 4 sub-matrix 5x5 dell'immagine in input
TYPE matrix_5x5xMSB_w	 IS ARRAY(0 TO 5) OF STD_LOGIC_VECTOR(N_w*N_w-1 DOWNTO 0); 
TYPE matrix_5x5xMSB_in	 IS ARRAY(0 TO 3) OF STD_LOGIC_VECTOR(N_w*N_w-1 DOWNTO 0); 

SIGNAL 	matrix_image	  : matrix_5x5xMin;
SIGNAL  matrix_prec_in : matrix_5x5xMSB_in;
SIGNAL  matrix_prec_w  : matrix_5x5xMSB_w;

-- signals to prepare the image for the mac block
TYPE out_4_mux    IS ARRAY(0 TO 3) OF STD_LOGIC_VECTOR(M_in-1 DOWNTO 0);
SIGNAL	 out_mux_in					: out_4_mux;
SIGNAL  out_reg_mux_in : out_4_mux;

-- signals to prepare the weights for the mac block
TYPE in_mux_w_6	  IS ARRAY(0 TO I_w-1) OF STD_LOGIC_VECTOR(N_w*N_w*M_w-1 DOWNTO 0);
TYPE out_mux_w_6 	IS ARRAY(0 TO I_w-1) OF STD_LOGIC_VECTOR(M_w-1 DOWNTO 0); -- variabile per l'uscita dei 6 mux che andrà in ingresso ai 6x4 MAC
SIGNAL 	in_mux_w  					: in_mux_w_6;
SIGNAL	 out_mux_w		    : out_mux_w_6;
SIGNAL  out_reg_mux_w  : out_mux_w_6;

-- signals for the precomputation
TYPE out_mac		    IS ARRAY(0 TO 3, 0 TO I_w-1) OF STD_LOGIC_VECTOR(M_w-1 DOWNTO 0); -- variabile per l'uscita del blocco di precomputation
--TYPE en_prec_max	 IS ARRAY(0 TO I_w-1) OF STD_LOGIC;
SIGNAL precomputation,PRECOMPUTATION_REG : STD_LOGIC_VECTOR(I_w-1 DOWNTO 0);--en_prec_max;
--SIGNAL	 out_mac_block, out_prec_block : out_mac;
--TYPE array_en	    IS ARRAY(0 TO 3, 0 TO I_w-1) OF STD_LOGIC;
SIGNAL  ENABLE_PREC,EN_PREC_CONV_TMP1,EN_PREC_CONV_TMP2 : array_en;
--SIGNAL  out_prec    : STD_LOGIC_VECTOR(M_w-1 DOWNTO 0):= (M_w-1 => '1', OTHERS=>'0');
SIGNAL  out_prec    : STD_LOGIC_VECTOR(M_w-1 DOWNTO 0):= '1' & ( M_w-2 downto 0 =>'0');
SIGNAL  output_to_mac : OUTPUT_MAC;

-- outputs
TYPE out_rounder	 IS ARRAY(0 TO 3, 0 TO I_w-1) OF STD_LOGIC_VECTOR(M_out-1 DOWNTO 0); 
SIGNAL 	out_mac_round, out_relu		     : out_rounder;
TYPE out_bank_reg IS ARRAY(0 TO I_w, 0 TO N_out*N_out-1) OF STD_LOGIC_VECTOR(M_out-1 DOWNTO 0); -- variabile per i 6 banchi da 784 registri in uscita
SIGNAL out_regs_out : out_bank_reg;
SIGNAL EN_REG_OUT   : STD_LOGIC_VECTOR(N_out*N_out-1 DOWNTO 0):=(OTHERS=>'0'); -- enable dei registri di uscita (in comune per i 6 banchi)


------------- BEGIN -------------
BEGIN

-- bank of shift registers instance
in_Shift_registers: shift_reg_5x32x8bit_4out
		PORT MAP(	in_row_image1,
		          in_row_image2,
						  EN_LOAD,
						  CLK,
					 	  RST_S,
						  EN_SHIFT,
						  matrix_image(0),
						  matrix_image(1),
						  matrix_image(2),
						  matrix_image(3),
						  matrix_prec_in(0),
						  matrix_prec_in(1),
						  matrix_prec_in(2),
						  matrix_prec_in(3)); -- parallel_out e serial_out non mi servono e non li definisco nel portmap



-- generation of 6 weight matrix and 6 mux to select the right weight to feed the MAC, and 6 bias
GEN_MUX25_WEIGHTS: FOR i IN 0 TO I_w-1 GENERATE
	in_mux_w(i) <= matrix_weights(i,0) & matrix_weights(i,1) & matrix_weights(i,2) & matrix_weights(i,3) & matrix_weights(i,4);
	
	GEN_MSB_WEIGHTS: FOR j IN 0 TO N_w-1 GENERATE
	   matrix_prec_w(i)(N_w*(N_w-j)-1 DOWNTO N_w*(N_w-j-1)) <= matrix_weights(i,j)(N_w*M_w-1) & matrix_weights(i,j)((N_w-1)*M_w-1) & matrix_weights(i,j)((N_w-2)*M_w-1) & matrix_weights(i,j)((N_w-3)*M_w-1) & matrix_weights(i,j)((N_w-4)*M_w-1);
	END GENERATE;
	
	Mux25to1_weights: mux25to1_nbit
			GENERIC MAP	(M_w)
			PORT MAP		(in_mux_w(i), SEL_MUX, out_mux_w(i));
	
	Registers_conv_w: register_nbit
	       GENERIC MAP (M_w)
	       PORT MAP    (out_mux_w(i), 
	                    EN_CONV, CLK, RST_S,
			                out_reg_mux_w(i));
			  
  input_mac_2(i)	<=	out_reg_mux_w(i);
  
  input_mac_3(i)(2*M_w+EXTRA_BIT-2 DOWNTO 2*M_w+EXTRA_BIT-5) <= (OTHERS => bias_mac(i)(M_w-1));
  input_mac_3(i)(2*M_w+EXTRA_BIT-6 DOWNTO 2*M_w+EXTRA_BIT-5-M_w) <= bias_mac(i);
  input_mac_3(i)(2*M_w+EXTRA_BIT-6-M_w DOWNTO 0) <= (OTHERS => '0');
END GENERATE GEN_MUX25_WEIGHTS;

						
-- image data inputs are the same for every filter, but there are 4 different submatrix
GEN_4_INPUTS: FOR i IN 0 TO 3 GENERATE
  Mux25to1_in: mux25to1_nbit -- 4 mux per l'immagine perchè ho 4 submatrix
		GENERIC MAP	(M_in)
		PORT MAP		  (matrix_image(i), SEL_MUX, out_mux_in(i));
		  
	Registers_conv_in: register_nbit
	       GENERIC MAP (M_in)
	       PORT MAP    (out_mux_in(i), 
	                    EN_CONV, CLK, RST_S,
			                out_reg_mux_in(i));
		  
	-- in_mac_1 lo devo estendere al parallelismo dei pesi (1 intero, 9 decimali ??), ci saranno 4 tipi di ingresso diversi (perche ci sono 4 submatrix)
  --input_mac_1(i)(M_w-1) <= '0';
  input_mac_1(i)(M_w-1 DOWNTO M_w-M_in) <= out_reg_mux_in(i);	
  input_mac_1(i)(M_w-1-M_in DOWNTO 0) <= (OTHERS => '0');



-- generation of 24 precomputation blocks and 24 outputs to feed the max pooling layer
  GEN_MAC_RELU: FOR a IN 0 TO I_w-1 GENERATE
  
    Precomputation_block:  precomputation_conv
        GENERIC MAP (N_w*N_w) -- number of elements to evaluate
        PORT MAP(		 matrix_prec_in(i), 
                    matrix_prec_w(a), ------- CONTROLLARE POI SE L'ORDINE DEI PESI è GIUSTO
			              DO_PREC,
			              ENABLE_PREC(i,a));
							  
		EN_PREC_CONV_TMP1(i,a) <= NOT(ENABLE_PREC(i,a));
		
		FF_en_prec_to_mac: register_1bit
			PORT MAP (		EN_PREC_CONV_TMP1(i,a),
								EN_MAX, CLK, RST_S,
								EN_PREC_CONV_TMP2(i,a));
								
		EN_PREC_CONV(i,a) <= EN_PREC_CONV_TMP2(i,a);		
		--EN_PREC_CONV(i,a) <= NOT(ENABLE_PREC(i,a));
		
		PRECOMPUTATION(a) <= ENABLE_PREC(0,a) AND ENABLE_PREC(1,a) AND ENABLE_PREC(2,a) AND ENABLE_PREC(3,a);
			  
		Mux_to_pooling: mux2to1_nbit
		  GENERIC MAP(  M_w)
      PORT MAP(	out_prec,out_mac_block(4*a+i), 
                
		            EN_PREC_CONV_TMP2(i,a),
		            output_to_mac(4*a+i));
	
	
	--out_mac_round(i,a) <= out_mac_block(i,a)(2*M_w+EXTRA_BIT-1 DOWNTO 2*M_w+EXTRA_BIT-M_w); --per ora tronco		

  --GEN_BANK_REG: FOR j IN 0 TO N_out*N_out-1 GENERATE		---------------- QUESTO NON BISOGNA PIU FARLO PERCHE SI SALVA TUTTO NEL REGISTER FILE	  
	--   Out_registers: register_nbit
	--       GENERIC MAP (M_out)
	--       PORT MAP    (out_relu(i,a), 
	--                    EN_REG_OUT(j), CLK, RST_n,
	--		                out_regs_out(a,j));
  --  END GENERATE;
	   
			
    END GENERATE GEN_MAC_RELU;
END GENERATE GEN_4_INPUTS;

Registers_prec_en: register_nbit
	       GENERIC MAP (6)
	       PORT MAP    (PRECOMPUTATION, 
	                    EN_MAX, CLK, RST_S,
			                PRECOMPUTATION_REG);
								 
GEN_6_MAX: FOR a IN 0 TO I_w-1 GENERATE
  Max_block: max_pooling 
      GENERIC MAP(8,8)
      PORT MAP(EN_MAX ,PRECOMPUTATION_REG(a), RST_S,
			         CLK,
			         output_to_mac(4*a), output_to_mac(4*a+1), output_to_mac(4*a+2), output_to_mac(4*a+3),
			         SAVE_OUT_MAX(a),
						output_layer(a));
END GENERATE GEN_6_MAX;


--PREC_RESULT <= '1' WHEN PRECOMPUTATION=(PRECOMPUTATION'RANGE=>'1') ELSE '0'; -- sarebbe l'AND
PREC_RESULT <= PRECOMPUTATION(0) AND PRECOMPUTATION(1) AND PRECOMPUTATION(2) AND PRECOMPUTATION(3) AND PRECOMPUTATION(4) AND PRECOMPUTATION(5);

END structural;
