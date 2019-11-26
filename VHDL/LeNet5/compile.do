#compile all vhd file

vcom -93 -work ./work ./VHDL_Packages/*.vhd
vcom -93 -work ./work ./VHDL_Conv1/*.vhd
vcom -93 -work ./work ./VHDL_Conv2/*.vhd
vcom -93 -work ./work ./VHDL_FC1/*.vhd
vcom -93 -work ./work ./VHDL_FC2/*.vhd
vcom -93 -work ./work ./VHDL_FC3/*.vhd
vcom -93 -work ./work ./VHDL_tb/*.vhd
vcom -93 -work ./work ./VHDL_Common/*.vhd

#load top file for simulation
vsim work.LeNet5_tb
add wave *
run 400 us
