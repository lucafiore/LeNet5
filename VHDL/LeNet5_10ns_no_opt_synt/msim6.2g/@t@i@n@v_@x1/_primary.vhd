library verilog;
use verilog.vl_types.all;
entity TINV_X1 is
    port(
        EN              : in     vl_logic;
        I               : in     vl_logic;
        ZN              : out    vl_logic
    );
end TINV_X1;
