LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY flipflop_rst IS
PORT( 
        Clock, RST: IN STD_LOGIC;
        input: IN STD_LOGIC;
        output: OUT STD_LOGIC 
        );
END flipflop_rst;

ARCHITECTURE Behavior OF flipflop_rst IS
BEGIN

PROCESS(Clock, RST)
BEGIN
  IF RST = '1' THEN
      output <= '0';
  ELSE
	  IF Clock'EVENT AND Clock = '1' THEN
			output <= input;
	  END IF;
	END IF;
END PROCESS;

END Behavior;