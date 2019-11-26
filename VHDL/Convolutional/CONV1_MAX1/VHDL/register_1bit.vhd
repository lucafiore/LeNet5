LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY register_1bit IS
PORT(		data_in 			: IN STD_LOGIC;
			EN, CLK, RST   : IN STD_LOGIC;
			data_out 		: OUT STD_LOGIC
	  );
END register_1bit;

ARCHITECTURE behavior OF register_1bit IS
BEGIN

PROCESS(CLK)
BEGIN
	IF (CLK'EVENT AND CLK = '1') THEN
		IF RST='1' THEN 
			data_out <= '0';
		ELSE
			IF EN='1' THEN
				data_out <= data_in;
			ELSIF EN='0' THEN
				NULL;
			END IF;
		END IF;
	ELSE NULL;
	END IF;
END PROCESS;



END behavior;
