library ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY full_adder IS
PORT ( x,y,cin: IN STD_LOGIC;
       sum,cout: OUT STD_LOGIC);
END full_adder;

ARCHITECTURE Behavior OF full_adder IS

SIGNAL G,P: STD_LOGIC;

BEGIN 

	G<=x AND y;
	P<=x XOR y;
	sum<=P XOR cin;
	cout<=G OR (P AND cin);

END Behavior;