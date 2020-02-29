library verilog;
use verilog.vl_types.all;
entity TLAT_X1 is
    port(
        D               : in     vl_logic;
        G               : in     vl_logic;
        OE              : in     vl_logic;
        Q               : out    vl_logic
    );
end TLAT_X1;
