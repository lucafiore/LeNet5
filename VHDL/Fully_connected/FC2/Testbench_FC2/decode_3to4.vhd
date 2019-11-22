-- Decoder of Enables of Output_registers  --

-- high-speed/low-power group
-- Fiore, Neri, Zheng
-- 
-- keyword in MAIUSCOLO (es: STD_LOGIC)
-- dati in minuscolo (es: data_in)
-- segnali di controllo in MAIUSCOLO (es: EN)
-- componenti instanziati con l'iniziale maiuscola (es: Shift_register_1)
-- i segnali attivi bassi con _n finale (es: RST_n)


----------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.all;
USE work.input_struct_pkg.all;

entity decode_3to4 is
	Port (	cnt_4  		: in  STD_LOGIC_VECTOR (1 downto 0);      			-- 2-bit input
				EN_decoder 	: in  STD_LOGIC;                       				-- enable decoder
				en_reg_out  	: out STD_LOGIC_VECTOR (N_CYCLES-1 downto 0));  	-- 4-bit output  

end decode_3to4;

architecture Behavioral of decode_3to4 is
begin
process (cnt_4, EN_decoder)
begin
    en_reg_out <= "0000";        -- default output value
    if (EN_decoder = '1') then  -- active high enable pin
        case cnt_4 is
            when "01" => en_reg_out <= "0001";
            when "10" => en_reg_out <= "0010";
            when "11" => en_reg_out <= "0100";
				when "00" => en_reg_out <= "1000";
            when others => en_reg_out <= "0000";
        end case;
    end if;
end process;
end Behavioral;