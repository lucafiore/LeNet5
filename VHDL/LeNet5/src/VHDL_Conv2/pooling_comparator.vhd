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


ENTITY pooling_comparator IS
  GENERIC(
      M 						: NATURAL:=8);-- is the parallelism of each element

  PORT(	
			clock: IN STD_LOGIC;
			R_LE_RST, R_LE_EN: IN STD_LOGIC;
			data1, data2: IN STD_LOGIC_VECTOR(M-1 DOWNTO 0);
			output: OUT STD_LOGIC_VECTOR(M-1 DOWNTO 0)
      );
END pooling_comparator;




ARCHITECTURE structural OF pooling_comparator IS
--------------------------------------- COMPONENTS --------------------------------------------
COMPONENT register_1bit IS
PORT(		data_in 			: IN STD_LOGIC;
			EN, CLK, RST : IN STD_LOGIC;
			data_out 		: OUT STD_LOGIC
	  );
END COMPONENT;

COMPONENT mux2to1 IS
     PORT( in_0, in_1 : IN STD_LOGIC;
	        SEL  : IN STD_LOGIC;
			  q      : OUT STD_LOGIC);
END COMPONENT;

COMPONENT mux2to1_nbit IS
GENERIC ( N : integer:=M);
PORT
 (	in_0, in_1: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
	SEL: IN STD_LOGIC:='0';
	q: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0)
 );
END COMPONENT;

COMPONENT register_nbit IS
GENERIC(	N 					: NATURAL:=M);
PORT(		data_in 			: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			EN, CLK, RST_n : IN STD_LOGIC;
			data_out 		: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT;

COMPONENT latch_nbit IS
-- Gated D latch
GENERIC ( N : integer:=M);
PORT
 (		data_in: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
		LATCH_ENABLE : IN STD_LOGIC;
		data_out  : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0)
 );
END COMPONENT;

COMPONENT comparator IS

  PORT(	 
			a, b: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			RESULT: OUT STD_LOGIC
      );
      
END COMPONENT;


COMPONENT counter IS
GENERIC ( N : NATURAL:=16; -- conta fino a 16
			 M : NATURAL:=4); -- su 4 bit di uscita
PORT(
		Clock,Enable,Reset: IN STD_LOGIC;
		output: BUFFER STD_LOGIC_VECTOR(M-1 DOWNTO 0)
);
END COMPONENT;


------------------------------------SIGNAL------------------------------------------
SIGNAL l1_out, l2_out, mux_a_out: STD_LOGIC_VECTOR(M-1 DOWNTO 0);
SIGNAL MUX_E_IN0, COMP_OUT, MUX_E_OUT, COMP_EN, LE: STD_LOGIC;

----------------------------BEGIN--------------------------------------
BEGIN

COMP_EN <= data1(M-1) NOR data2(M-1);  
MUX_E_IN0 <= (NOT(data1(M-1))) NAND data2(M-1);


-- i latch del blocco COMP
L1: latch_nbit
GENERIC MAP(M)
PORT MAP(data_in=>data2,LATCH_ENABLE=>LE,data_out=>l1_out);
L2: latch_nbit
GENERIC MAP(M)
PORT MAP(data_in=>data1,LATCH_ENABLE=>LE,data_out=>l2_out);
-- il registro che carica LE
R_LE:register_1bit
PORT MAP(data_in=>COMP_EN, EN=>R_LE_EN, CLK=>clock, RST=>R_LE_RST, data_out=>LE);

-- tutti i MUX		
Mux_e: mux2to1  -- un mux da 1 bit
	PORT MAP(in_0=>MUX_E_IN0, in_1=>COMP_OUT,	SEL=>LE, q=>MUX_E_OUT);	
Mux_a: mux2to1_nbit
	PORT MAP(in_0=>data1, in_1=>data2,	SEL=>MUX_E_OUT, q=>mux_a_out);

-- comparatore (y=a>b)
Comp: comparator
  PORT MAP(a=>l1_out, b=>l2_out, RESULT=>COMP_OUT);

-- ReLu
ReLu_mux: mux2to1_nbit
	PORT MAP(in_0=>mux_a_out, in_1=>(OTHERS=>'0'),	SEL=>mux_a_out(M-1), q=>output);
	
	
END structural;