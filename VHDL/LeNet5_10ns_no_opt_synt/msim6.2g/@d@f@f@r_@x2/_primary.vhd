library verilog;
use verilog.vl_types.all;
entity DFFR_X2 is
    port(
        D               : in     vl_logic;
        RN              : in     vl_logic;
        CK              : in     vl_logic;
        Q               : out    vl_logic;
        QN              : out    vl_logic
    );
end DFFR_X2;
