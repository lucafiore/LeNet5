library verilog;
use verilog.vl_types.all;
entity DLL_X2 is
    port(
        D               : in     vl_logic;
        GN              : in     vl_logic;
        Q               : out    vl_logic
    );
end DLL_X2;
