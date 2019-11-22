LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY counter IS
GENERIC ( N : NATURAL:=16; -- conta fino a 16
			 M : NATURAL:=4); -- su 4 bit di uscita
PORT(
		Clock,Enable,Reset: IN STD_LOGIC;
		output:	OUT STD_LOGIC_VECTOR(M-1 DOWNTO 0)
);
END counter;

ARCHITECTURE Structure OF counter IS

BEGIN

PROCESS (Clock)

VARIABLE cnt: INTEGER RANGE 0 TO N-1;
BEGIN
IF Clock'EVENT AND Clock='1' THEN
	IF Reset='0' THEN
		IF Enable='1' THEN
				IF cnt=N-1 THEN
					cnt:=0;
					output<=std_logic_vector(to_unsigned(cnt,M));
				ELSE
					cnt := cnt + 1;
					output<=std_logic_vector(to_unsigned(cnt,M));
				End IF;
		END IF;
	ELSE
		cnt:=0;
		output<=std_logic_vector(to_unsigned(cnt,M));
	END IF;
END IF;

	
END PROCESS;


END Structure;
	