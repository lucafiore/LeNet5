#compile all vhd file

vcom ./VHDL_Packages/*.vhd
vcom ./VHDL_Conv1/*.vhd
vcom ./VHDL_Conv2/*.vhd
vcom ./VHDL_FC1/*.vhd
vcom ./VHDL_FC2/*.vhd
vcom ./VHDL_FC3/*.vhd
vcom ./VHDL_tb/*.vhd
vcom ./VHDL_Common/*.vhd

# Loads the technological library and the SDFs
vsim -voptargs=+acc -L /software/dk/nangate45/verilog/msim6.5c -sdftyp /LeNet5_tb/LeNet5_top=fir.sdf work.LeNet5_tb -t 1ps //cambia tb_fir col nome del testbench e UUT col nome che hai dato nel testbench al divece che stai testando

# Generates the VCD file and add all the DUT signals
vcd file frommentor_data.vcd
vcd add /LeNet5_tb/LeNet5_top/* // idem come sopra

run 400 us
quit -f
