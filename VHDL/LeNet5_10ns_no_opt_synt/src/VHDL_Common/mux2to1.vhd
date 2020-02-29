LIBRARY ieee;
USE ieee.std_logic_1164.all;



ENTITY mux2to1 IS
     PORT( in_0, in_1 : IN STD_LOGIC;
	        SEL  : IN STD_LOGIC;
			  q      : OUT STD_LOGIC);
END mux2to1;

ARCHITECTURE LogicFunc OF mux2to1 IS
BEGIN

	  q <= (in_0 AND NOT (SEL)) OR (SEL AND in_1);  
	  

END LogicFunc;
