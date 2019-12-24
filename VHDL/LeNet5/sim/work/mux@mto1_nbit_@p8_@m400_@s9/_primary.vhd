library verilog;
use verilog.vl_types.all;
entity muxMto1_nbit_P8_M400_S9 is
    port(
        data_in         : in     vl_logic_vector(3199 downto 0);
        SEL             : in     vl_logic_vector(8 downto 0);
        q               : out    vl_logic_vector(7 downto 0)
    );
end muxMto1_nbit_P8_M400_S9;
