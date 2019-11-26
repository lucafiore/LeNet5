#compile all vhd file

vcom ./VHDL_Packages/*.vhd
vcom ./VHDL_Conv1/*.vhd
vcom ./VHDL_Conv2/*.vhd
vcom ./VHDL_FC1/*.vhd
vcom ./VHDL_FC2/*.vhd
vcom ./VHDL_FC3/*.vhd
vcom ./VHDL_tb/*.vhd
vcom ./VHDL_Common/*.vhd

#load top file for simulation
vsim work.LeNet5_tb
add wave *
run 400 us
