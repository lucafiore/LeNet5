#compile all vhd file

vcom -93 -work ./work ../src/VHDL_Packages/*.vhd
vcom -93 -work ./work ../testbench/VHDL_tb/*.vhd
vlog -work ./work ../netlist/LeNet5.v

# Loads the technological library and the SDFs
vsim -L /software/dk/nangate45/verilog/msim6.2g work.LeNet5_tb -t 1ps
vsim -L /software/dk/nangate45/verilog/msim6.2g -sdftyp /LeNet5_tb/UUT=fir.sdf work.LeNet5_tb

# Generates the VCD file and add all the DUT signals
vcd file ../vcd/LeNet5.vcd
vcd add /LeNet5_tb/UUT/* 
#UUT means LeNet5_top

add wave *
#run -all
run 400 us
quit -f
