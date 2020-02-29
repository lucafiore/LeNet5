#compile all vhd file

vcom -93 -work ./work ../src/VHDL_Packages/*.vhd
vlog -93 -work ./work ../netlist/LeNet5_top.v
vcom -93 -work ./work ../testbench_post/*.vhd


# Loads the technological library and the SDFs
#vsim -novopt -L /software/dk/nangate45/verilog/msim6.2g work.LeNet5_tb
#vsim -novopt -L /software/dk/nangate45/verilog/msim6.2g -sdftyp /LeNet5_tb/UUT=../netlist/LeNet5_top.sdf work.LeNet5_tb -t ps

#vsim -novopt -L ../msim6.2g work.LeNet5_tb -t ns
vsim -novopt -L ../msim6.2g -sdftyp /LeNet5_tb/UUT=../netlist/LeNet5_top.sdf work.LeNet5_tb -t ps
#vsim -t 1ps -novopt work.LeNet5_tb

# Generates the VCD file and add all the DUT signals
vcd file ../vcd/LeNet5.vcd
vcd add /LeNet5_tb/UUT/*
#UUT means LeNet5_top

add wave *
#run -all
run 400 us
#quit -f


