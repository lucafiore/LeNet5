-- 1_st Decoder of Enables of Output_registers  --

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
USE work.FC_struct_pkg.all;

entity decode_3to5 is
	Port (	cnt_5  		: in  STD_LOGIC_VECTOR (2 downto 0);      			-- 3-bit input
				EN_decoder 	: in  STD_LOGIC;                       				-- enable decoder
				en_reg_out  	: out STD_LOGIC_VECTOR (N_CYCLES_FC1-1 downto 0));  	-- 5-bit output  

end decode_3to5;
architecture Behavioral of decode_3to5 is
begin
process (cnt_5, EN_decoder)
begin
    en_reg_out <= "00000";        -- default output value
    if (EN_decoder = '1') then  -- active high enable pin
        case cnt_5 is
            when "001" => en_reg_out <= "00001";
            when "010" => en_reg_out <= "00010";
            when "011" => en_reg_out <= "00100";
            when "100" => en_reg_out <= "01000";
				when "000" => en_reg_out <= "10000";
            when others => en_reg_out <= "00000";
        end case;
    end if;
end process;
end Behavioral;