library verilog;
use verilog.vl_types.all;
entity DFF_X2 is
    port(
        D               : in     vl_logic;
        CK              : in     vl_logic;
        Q               : out    vl_logic;
        QN              : out    vl_logic
    );
end DFF_X2;
