-- Conv Package --

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

-- CONV1

PACKAGE CONV_struct_pkg IS
	CONSTANT M_mpy : NATURAL := 8;
	CONSTANT M_add : NATURAL := 2*M_mpy-1;
	CONSTANT M_in 	: NATURAL := 8;	
	TYPE input_mac_img IS ARRAY(3 DOWNTO 0) OF STD_LOGIC_VECTOR(M_mpy-1 DOWNTO 0);
	TYPE input_mac_w IS ARRAY(5 DOWNTO 0) OF STD_LOGIC_VECTOR(M_mpy-1 DOWNTO 0);
	TYPE input_mac_b IS ARRAY(5 DOWNTO 0) OF STD_LOGIC_VECTOR(M_add-1 DOWNTO 0);
	TYPE output_mac IS ARRAY(23 DOWNTO 0) OF STD_LOGIC_VECTOR(M_mpy-1 DOWNTO 0);
	TYPE matrix_5x5xMw	IS ARRAY(0 TO 5, 0 TO 4) OF STD_LOGIC_VECTOR(5*M_mpy-1 DOWNTO 0); -- variabile per creare le 6 matrici 5x5 dei pesi
	TYPE EN_14X14 IS ARRAY(13 DOWNTO 0, 13 DOWNTO 0) OF STD_LOGIC; -- QUESTO DEVE ESSERE CAMBIATO NEGLI ALTRI FILE
	TYPE Conv1_reg_Conv2 IS ARRAY(0 TO 5, 13 DOWNTO 0, 13 DOWNTO 0) OF STD_LOGIC_VECTOR(M_mpy-1 DOWNTO 0);
	TYPE array_en	    IS ARRAY(0 TO 3, 0 TO 5) OF STD_LOGIC;
	
-- CONV2
	
	TYPE input_3_img_2 IS ARRAY(2 DOWNTO 0) OF STD_LOGIC_VECTOR(14*M_mpy-1 DOWNTO 0);
	TYPE input_mac_img_2 IS ARRAY(2 DOWNTO 0) OF STD_LOGIC_VECTOR(M_mpy-1 DOWNTO 0); 
	TYPE input_mac_w_2 IS ARRAY(2 DOWNTO 0, 7 DOWNTO 0) OF STD_LOGIC_VECTOR(M_mpy-1 DOWNTO 0); 
	TYPE input_mac_b_2 IS ARRAY(7 DOWNTO 0) OF STD_LOGIC_VECTOR(M_add-1 DOWNTO 0);
	TYPE input_bias_2 IS ARRAY(7 DOWNTO 0) OF STD_LOGIC_VECTOR(M_mpy-1 DOWNTO 0);
	TYPE output_acc_2 IS ARRAY(0 TO 1, 7 DOWNTO 0) OF STD_LOGIC_VECTOR(M_add-1 DOWNTO 0);
	TYPE output_mac_2 IS ARRAY(2 DOWNTO 0, 7 DOWNTO 0) OF STD_LOGIC_VECTOR(M_mpy-1 DOWNTO 0);
	TYPE output_conv_2 IS ARRAY(7 DOWNTO 0) OF STD_LOGIC_VECTOR(M_mpy-1 DOWNTO 0);
	TYPE matrix_5x5xMw_2	IS ARRAY(0 TO 2, 0 TO 7, 0 TO 4) OF STD_LOGIC_VECTOR(5*M_mpy-1 DOWNTO 0); 
	TYPE reg_intermed_8x10x10_2 IS ARRAY(0 TO 7, 0 TO 9, 0 TO 9) OF STD_LOGIC_VECTOR(M_add-1 DOWNTO 0); 
	TYPE array6_row_14x14 IS ARRAY(0 TO 5) OF STD_LOGIC_VECTOR(14*14*M_mpy-1 DOWNTO 0);
	TYPE array6_row IS ARRAY(0 TO 5) OF STD_LOGIC_VECTOR(14*M_mpy-1 DOWNTO 0);
	TYPE bias_from_file IS ARRAY(0 TO 15) OF STD_LOGIC_VECTOR(M_mpy-1 DOWNTO 0);
	
	
END PACKAGE;