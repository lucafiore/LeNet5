#compile all vhd file
vcom Fully_Connected_Layer.vhd
vcom *.vhd

vsim work.FC2_tb
add wave *
run 10 us
