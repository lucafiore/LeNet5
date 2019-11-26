LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;


ENTITY max_pooling IS

  GENERIC(
      M_in 						: NATURAL:=9;  -- is the parallelism of each element
      M_out 					: NATURAL:=9);-- is the parallelism of each element of the 16 output matrixes

  PORT(	 
      MAX_EN, PREC, REG_RST: IN STD_LOGIC;
			clock: IN STD_LOGIC;
			data1, data2, data3, data4: IN STD_LOGIC_VECTOR(M_in-1 DOWNTO 0);
			OUT_READY: OUT STD_LOGIC;
			output: OUT STD_LOGIC_VECTOR(M_out-1 DOWNTO 0)			
      );
      
END max_pooling;



ARCHITECTURE structural OF max_pooling IS
--------------------------------------- COMPONENTS --------------------------------------------

COMPONENT mux2to1 IS
     PORT( in_0, in_1 : IN STD_LOGIC;
	        SEL  : IN STD_LOGIC;
			  q      : OUT STD_LOGIC);
END COMPONENT;

COMPONENT mux2to1_nbit IS
GENERIC ( N : integer:=M_in);
PORT
 (	in_0, in_1: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
	SEL: IN STD_LOGIC:='0';
	q: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0)
 );
END COMPONENT;

COMPONENT register_nbit IS
GENERIC(	N 					: NATURAL:=M_in);
PORT(		data_in 			: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			EN, CLK, RST	: IN STD_LOGIC;
			data_out 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT;

COMPONENT register_1bit IS
PORT(		data_in 			: IN STD_LOGIC;
			EN, CLK, RST   : IN STD_LOGIC;
			data_out 		: OUT STD_LOGIC
	  );
END COMPONENT;

COMPONENT latch_nbit IS
-- Gated D latch
GENERIC ( N : integer:=M_in);
PORT
 (		data_in: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
		LATCH_ENABLE : IN STD_LOGIC;
		data_out  : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0)
 );
END COMPONENT;

COMPONENT comparator IS

  PORT(	 
			a, b: IN STD_LOGIC_VECTOR(8 DOWNTO 0);
			RESULT: OUT STD_LOGIC
      );
      
END COMPONENT;


COMPONENT flipflop IS
PORT( 
        Clock: IN STD_LOGIC;
        input: IN STD_LOGIC;
        output: OUT STD_LOGIC
        );
END COMPONENT;

------------------------------------SIGNAL------------------------------------------
SIGNAL reg1_out, reg2_out, reg3_out, reg4_out: STD_LOGIC_VECTOR(M_in-1 DOWNTO 0);
SIGNAL clock_neg: STD_LOGIC;
SIGNAL COMP_A_EN, COMP_B_EN, LE_A, LE_B , MUX_E_IN0, MUX_F_IN0, FF1_OUT, FF2_OUT, OUT_MUX_SEL, MUX_F_OUT, MUX_E_OUT: STD_LOGIC;
SIGNAL SEL_B, COMP_A_OUT, SEL_C, R_SEL_B_EN, COMP_B_OUT, R_SEL_B1_OUT, R_SEL_B2_OUT: STD_LOGIC;
SIGNAL mux_b_out, mux_c_out, mux_d_out, mux_a_out, la1_out, la2_out, lb1_out, lb2_out: STD_LOGIC_VECTOR(M_in-1 DOWNTO 0);
SIGNAL COMP, PRECOMP: STD_LOGIC;



----------------------------BEGIN--------------------------------------
BEGIN

--input registers
R1: register_nbit
	PORT MAP(data_in=>data1, EN=>COMP, CLK=>clock, RST=>REG_RST, data_out=>reg1_out);
R2: register_nbit
	PORT MAP(data_in=>data2, EN=>COMP, CLK=>clock, RST=>REG_RST, data_out=>reg2_out);
R3: register_nbit
	PORT MAP(data_in=>data3, EN=>COMP, CLK=>clock, RST=>REG_RST, data_out=>reg3_out);
R4: register_nbit
	PORT MAP(data_in=>data4, EN=>COMP, CLK=>clock, RST=>REG_RST, data_out=>reg4_out);


-- alcune porte logiche che servono per fare delle prevalutazioni
COMP_A_EN <= reg1_out(M_in-1) NOR reg2_out(M_in-1);  
MUX_E_IN0 <= (NOT(reg1_out(M_in-1))) NAND reg2_out(M_in-1);
COMP_B_EN <= mux_b_out(M_in-1) NOR mux_c_out(M_in-1); 
MUX_F_IN0 <= (NOT(mux_b_out(M_in-1))) NAND mux_c_out(M_in-1);
clock_neg <= NOT(clock);
COMP <= MAX_EN AND (NOT(PREC));-- quando ho 4 dati validi
PRECOMP <= MAX_EN AND PREC;  -- quando ho 4 dati tutti negativi


-- i registri per attivazione di alcuni controlli						
R_le_a: register_1bit
	PORT MAP(data_in=>COMP_A_EN,EN=>COMP_A_EN,CLK=>clock_neg, RST=>COMP, data_out=>LE_A);
R_le_b1: register_1bit
	PORT MAP(data_in=>COMP_B_EN,EN=>COMP_B_EN,CLK=>clock_neg, RST=>COMP, data_out=>R_SEL_B1_OUT);
R_le_b2: register_1bit
	PORT MAP(data_in=>COMP_B_EN,EN=>COMP_B_EN,CLK=>clock_neg, RST=>R_SEL_B_EN, data_out=>R_SEL_B2_OUT); -- R_SEL_B_EN ии COMP ritardato un 1 colpo di clk
R_sel_b: register_1bit
	PORT MAP(data_in=>MUX_F_OUT,EN=>R_SEL_B_EN,CLK=>clock, RST=>COMP, data_out=>SEL_B);
-- Il mux per R_le_b
R_le_b_mux: mux2to1  -- un mux da 1 bit
	PORT MAP(in_0=>R_SEL_B1_OUT, in_1=>R_SEL_B2_OUT, SEL=>SEL_C, q=>LE_B);	
-- FF di ritardo per COMP
FF_COMP1: flipflop
  PORT MAP(Clock=>clock, input=>COMP, output=>R_SEL_B_EN);
FF_COMP2: flipflop
  PORT MAP(Clock=>clock, input=>R_SEL_B_EN, output=>SEL_C);

-- i latch del blocco COMP_A
La1: latch_nbit
GENERIC MAP(M_in)
PORT MAP(data_in=>reg2_out,LATCH_ENABLE=>LE_A,data_out=>la1_out);
La2: latch_nbit
GENERIC MAP(M_in)
PORT MAP(data_in=>reg1_out,LATCH_ENABLE=>LE_A,data_out=>la2_out);

-- i latch del blocco COMP_B
Lb1: latch_nbit
GENERIC MAP(M_in)
PORT MAP(data_in=>mux_c_out,LATCH_ENABLE=>LE_B,data_out=>lb1_out);
Lb2: latch_nbit
GENERIC MAP(M_in)
PORT MAP(data_in=>mux_b_out,LATCH_ENABLE=>LE_B,data_out=>lb2_out);



-- tutti i MUX		
Mux_e: mux2to1  -- un mux da 1 bit
	PORT MAP(in_0=>MUX_E_IN0, in_1=>COMP_A_OUT,	SEL=>LE_A, q=>MUX_E_OUT);	
Mux_a: mux2to1_nbit
	PORT MAP(in_0=>reg1_out, in_1=>reg2_out,	SEL=>MUX_E_OUT, q=>mux_a_out);
Mux_b: mux2to1_nbit
	PORT MAP(in_0=>reg3_out, in_1=>reg4_out,	SEL=>SEL_B, q=>mux_b_out);
Mux_c: mux2to1_nbit
	PORT MAP(in_0=>reg4_out, in_1=>mux_a_out,	SEL=>SEL_C, q=>mux_c_out);
Mux_f: mux2to1  -- un mux da 1 bit 
	PORT MAP(in_0=>MUX_F_IN0, in_1=>COMP_B_OUT, SEL=>LE_B, q=>MUX_F_OUT);	
Mux_d: mux2to1_nbit
	PORT MAP(in_0=>mux_b_out, in_1=>mux_c_out, SEL=>MUX_F_OUT, q=>mux_d_out);

-- due comparatori (y=a>b)
Comp_A: comparator
  PORT MAP(a=>la1_out, b=>la2_out, RESULT=>COMP_A_OUT);
Comp_B: comparator
  PORT MAP(a=>lb1_out, b=>lb2_out, RESULT=>COMP_B_OUT);
    
-- FF di ritardo per PRECOMP
FF1: flipflop
  PORT MAP(Clock=>clock, input=>PRECOMP, output=>FF1_OUT);
FF2: flipflop
  PORT MAP(Clock=>clock, input=>FF1_OUT, output=>FF2_OUT);
    
-- ReLu
Out_mux: mux2to1_nbit
	PORT MAP(in_0=>mux_d_out, in_1=>(OTHERS=>'0'),	SEL=>OUT_MUX_SEL, q=>output);
OUT_MUX_SEL <= mux_d_out(M_in-1) OR FF2_OUT;

-- segnale che indica la presenza del dato valido in uscita
OUT_READY <= FF2_OUT OR SEL_C; -- SEL_C ии COMP ritardato di 2 colpi di clk

END structural;