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



ENTITY Conv_layer3 IS
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
END Conv_layer3;


ARCHITECTURE structural OF Conv_layer3 IS

--------- COMPONENTS ---------
COMPONENT shift_reg_5x14xNbit IS
GENERIC(N : NATURAL := 8); 
PORT(		parallel_in		: IN STD_LOGIC_VECTOR(14*N-1 DOWNTO 0);
			serial_in		: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			EN : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			CLK, RST   : IN STD_LOGIC;
			EN_SHIFT			: IN STD_LOGIC; -- if '0' -> shift, if '1' -> parallel load (it's the selector of mux)
			matrix_out_0	: OUT STD_LOGIC_VECTOR(5*N-1 DOWNTO 0);
			matrix_out_1	: OUT STD_LOGIC_VECTOR(5*N-1 DOWNTO 0);
			matrix_out_2	: OUT STD_LOGIC_VECTOR(5*N-1 DOWNTO 0);
			matrix_out_3	: OUT STD_LOGIC_VECTOR(5*N-1 DOWNTO 0);
			matrix_out_4	: OUT STD_LOGIC_VECTOR(5*N-1 DOWNTO 0));
END COMPONENT shift_reg_5x14xNbit;

COMPONENT mux25to1_nbit IS
GENERIC(	N 					: NATURAL:=8);
PORT(		data_in	 		: IN STD_LOGIC_VECTOR(25*N-1 DOWNTO 0):= (OTHERS=>'0');
			SEL				: IN STD_LOGIC_VECTOR(4 DOWNTO 0);
			q			 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT mux25to1_nbit;

COMPONENT mux2to1_nbit IS
GENERIC(	N 				: NATURAL:=8);
PORT(	in_0, in_1 	: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			SEL				    : IN STD_LOGIC:='0';
			q			 		  : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT mux2to1_nbit; 

COMPONENT register_nbit IS
GENERIC(	N 					: NATURAL:=160);
PORT(		data_in 			: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			EN, CLK, RST : IN STD_LOGIC;
			data_out 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT register_nbit;


--------- SIGNALS ---------
--TYPE matrix_5x5xMw	IS ARRAY(0 TO 2, 0 TO 7, 0 TO 4) OF STD_LOGIC_VECTOR(5*M_w-1 DOWNTO 0); -- 0 TO 5 la profondit(6 filtri)
TYPE matrix_5x5xMin	IS ARRAY(0 TO 2, 0 TO 4) OF STD_LOGIC_VECTOR(5*M_in-1 DOWNTO 0);
--SIGNAL 	matrix_weights : matrix_5x5xMw;
SIGNAL 	matrix_image	: matrix_5x5xMin;

TYPE out_mux_w_6 	IS ARRAY(0 TO 2, 0 TO 7) OF STD_LOGIC_VECTOR(M_w-1 DOWNTO 0);
TYPE in_mux_w_3x8	IS ARRAY(0 TO 2, 0 TO 7) OF STD_LOGIC_VECTOR(25*M_w-1 DOWNTO 0);
--TYPE out_mac		IS ARRAY(0 TO 5) OF STD_LOGIC_VECTOR(2*M_w+EXTRA_BIT-1 DOWNTO 0); -- +0 dato dagli extra bit
TYPE out_rounder	IS ARRAY(0 TO 5) OF STD_LOGIC_VECTOR(M_out-1 DOWNTO 0);
TYPE in_mux			IS ARRAY(0 TO 2) OF STD_LOGIC_VECTOR(25*M_in-1 DOWNTO 0);
TYPE out_mux		IS ARRAY(0 TO 5) OF STD_LOGIC_VECTOR(M_in-1 DOWNTO 0);

SIGNAL 	serial_in 									: input_mac_img_2;
SIGNAL 	in_mux_in									: in_mux;
SIGNAL	out_mux_in,out_reg_mux_in				: input_mac_img_2;
SIGNAL 	in_mux_w										: in_mux_w_3x8;
SIGNAL	out_mux_w,out_reg_mux_w					: input_mac_w_2;
--SIGNAL   out_mux_bias 								: input__mac_b;
SIGNAL	bias_extended								: input_mac_b_2;


--------- BEGIN ---------
BEGIN

------ TUTTO TRIPLICATO 

GEN_3_TIMES : FOR a IN 0 TO 2 GENERATE
	serial_in(a) <= in_row_image(a)(M_in-1 DOWNTO 0); 

	Shift_registers: shift_reg_5x14xNbit
				GENERIC MAP(M_w) 
				PORT MAP(	in_row_image(a),
								serial_in(a),
								EN_LOAD,
								CLK,
								RST_S,
								EN_SHIFT,
								matrix_image(a,0),
								matrix_image(a,1),
								matrix_image(a,2),
								matrix_image(a,3),
								matrix_image(a,4));

	in_mux_in(a) <= matrix_image(a,0) & matrix_image(a,1) & matrix_image(a,2) & matrix_image(a,3) & matrix_image(a,4);

	Mux25to1_in: mux25to1_nbit -- q lo estendo su piu bit invece di estendere i dati in ingresso
			GENERIC MAP	(M_in)
			PORT MAP		(in_mux_in(a), SEL_MUX, out_mux_in(a));
			
			
	Registers_conv_in: register_nbit
	       GENERIC MAP (M_in)
	       PORT MAP    (out_mux_in(a), 
	                    EN_CONV, CLK, RST_S,
			              out_reg_mux_in(a));
	in_mac_1(a) <= out_reg_mux_in(a);
			
	-- 8 convoluzioni per ogni layer, 3 layer alla volta
	GEN_8_OF_ALL: FOR i IN 0 TO 7 GENERATE
	
		in_mux_w(a,i) <= matrix_weights(a,i,0) & matrix_weights(a,i,1) & matrix_weights(a,i,2) & matrix_weights(a,i,3) & matrix_weights(a,i,4);
				
		Mux25to1_weights: mux25to1_nbit
				GENERIC MAP	(M_w)
				PORT MAP		(in_mux_w(a,i), SEL_MUX, out_mux_w(a,i));
		---METTERE REGISTRO
		Registers_conv_w: register_nbit
	       GENERIC MAP (M_w)
	       PORT MAP    (out_mux_w(a,i), 
	                    EN_CONV, CLK, RST_S,
			                out_reg_mux_w(a,i));
			  
		in_mac_2(a,i)	<=	out_reg_mux_w(a,i);
		
		
				
---- adesso ho 8 uscite per ogni layer, per 3 layer (totale 24 uscite) e devo sommarle a 3 a 3

	END GENERATE GEN_8_OF_ALL; 
END GENERATE GEN_3_TIMES;

SUMS: FOR i IN 0 TO 7 GENERATE

		bias_extended(i)(2*M_w-2 DOWNTO 2*M_w-5) <= (OTHERS => bias(i)(M_w-1));
		bias_extended(i)(2*M_w-6 DOWNTO M_w-5) <= bias(i);
		bias_extended(i)(M_w-6 DOWNTO 0) <= (OTHERS => '0');

		Mux_mac_bias_partial : mux2to1_nbit
			GENERIC MAP(2*M_w-1)
			PORT MAP(bias_extended(i), partial_res(i), SEL_BIAS_RIS, bias_mac(i));


		Mux_mac_1_2_partial_sums : mux2to1_nbit
			GENERIC MAP(2*M_w-1)
			PORT MAP(acc_mac(0,i), acc_mac(1,i), SEL_RIS1_RIS2, in_add_opt_1(i));
			
		output_element(i) <= out_mac(0,i);
END GENERATE SUMS; 

----- lo zeresimo mac quello che possiede l'uscita da andare a salvare nel register file
-- nel mac_0 salvato un dato, l'uscita del mac_1 si somma a questo dato e viene saòvato tutto nel mac_0, infine l'uscita del mac_2 precedentemente salvata in un registro viene sommata alla somma parziale di prima, infine l'uscita del mac_0 va al register file

END structural;