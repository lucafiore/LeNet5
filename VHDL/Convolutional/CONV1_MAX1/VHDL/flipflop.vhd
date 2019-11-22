LIBRARY ieee;
USE ieee.std_logic_1164.all;




ENTITY flipflop IS 
PORT( 
        Clock: IN STD_LOGIC;
        input: IN STD_LOGIC;
        output: OUT STD_LOGIC 
        );
END flipflop;


ARCHITECTURE Behavior OF flipflop IS
BEGIN

PROCESS( Clock )
BEGIN
  IF Clock'EVENT AND Clock = '1' THEN
  output <= input;
  END IF;
END PROCESS;

END Behavior;