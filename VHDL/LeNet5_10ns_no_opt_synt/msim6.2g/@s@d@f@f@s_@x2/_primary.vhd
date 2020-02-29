library verilog;
use verilog.vl_types.all;
entity SDFFS_X2 is
    port(
        D               : in     vl_logic;
        SE              : in     vl_logic;
        SI              : in     vl_logic;
        SN              : in     vl_logic;
        CK              : in     vl_logic;
        Q               : out    vl_logic;
        QN              : out    vl_logic
    );
end SDFFS_X2;
