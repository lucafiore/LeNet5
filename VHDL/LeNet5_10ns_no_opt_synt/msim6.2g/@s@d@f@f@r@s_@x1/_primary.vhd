library verilog;
use verilog.vl_types.all;
entity SDFFRS_X1 is
    port(
        D               : in     vl_logic;
        RN              : in     vl_logic;
        SE              : in     vl_logic;
        SI              : in     vl_logic;
        SN              : in     vl_logic;
        CK              : in     vl_logic;
        Q               : out    vl_logic;
        QN              : out    vl_logic
    );
end SDFFRS_X1;
