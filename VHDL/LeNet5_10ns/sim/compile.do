#compile all vhd file

vcom -93 -work ./work ../src/VHDL_Packages/*.vhd
vcom -93 -work ./work ../src/VHDL_Common/*.vhd
vcom -93 -work ./work ../src/VHDL_Conv1/*.vhd
vcom -93 -work ./work ../src/VHDL_Conv2/*.vhd
vcom -93 -work ./work ../src/VHDL_FC1/*.vhd
vcom -93 -work ./work ../src/VHDL_FC2/*.vhd
vcom -93 -work ./work ../src/VHDL_FC3/*.vhd
vcom -93 -work ./work ../testbench/*.vhd

vsim -t 1ps -novopt work.LeNet5_tb
add wave *
add wave sim:/lenet5_tb/uut/fc1_layer/fc_layer/*
run 400 us

