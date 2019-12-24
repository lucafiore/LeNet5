library verilog;
use verilog.vl_types.all;
entity muxMto1_nbit_P8_M84_S7 is
    port(
        data_in         : in     vl_logic_vector(671 downto 0);
        SEL             : in     vl_logic_vector(6 downto 0);
        q               : out    vl_logic_vector(7 downto 0)
    );
end muxMto1_nbit_P8_M84_S7;
