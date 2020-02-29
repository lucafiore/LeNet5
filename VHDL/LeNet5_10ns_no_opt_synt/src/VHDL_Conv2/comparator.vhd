 -- high-speed/low-power group
-- Fiore, Neri, Zheng
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

-- y = a>b function's implementation for 8 bit

ENTITY comparator IS

  PORT(	 
			a, b: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			RESULT: OUT STD_LOGIC
      );
      
END comparator;

ARCHITECTURE LogicFunc OF comparator IS

  SIGNAL x: STD_LOGIC_VECTOR(7 DOWNTO 1);

BEGIN
  
 xi_GEN: FOR i IN 1 TO 7 GENERATE
      x(i)<=(NOT(a(i)) AND b(i)) NOR (a(i) AND (NOT(b(i))));
 END GENERATE;
  
  
		RESULT <= (a(7) AND (NOT(b(7))))  OR  (x(7)AND a(6) AND (NOT(b(6))))  OR  (x(7) AND x(6) AND a(5) AND (NOT(b(5))))  OR    (x(7) AND x(6) AND x(5) AND  ( (a(4) AND (NOT(b(4))))  OR  (x(4) AND a(3) AND (NOT(b(3))))  OR  (x(4) AND x(3) AND a(2) AND (NOT(b(2))))  OR  (x(4) AND x(3) AND x(2) AND ( (a(1) AND (NOT(b(1)))) OR (x(1) AND a(0) AND (NOT(b(0))))))));      
	 -- da 9bit   RESULT <= (a(8) AND (NOT b(8)))  OR  (x(8) AND a(7) AND (NOT(b(7))))  OR  (x(8)AND x(7)AND a(6) AND (NOT(b(6))))  OR  (x(8) AND x(7) AND x(6) AND    (    (a(5) AND (NOT(b(5))))  OR  (x(5) AND a(4) AND (NOT(b(4))))  OR  ( x(5)AND x(4) AND a(3) AND (NOT(b(3)))) OR ( x(5) AND x(4) AND x(3) AND ( (a(2) AND (NOT(b(2)))) OR (x(2) AND a(1) AND (NOT(b(1)))) OR (x(2) AND x(1) AND a(0) AND (NOT(b(0))) )   )   )    )   );

	  
END LogicFunc;

