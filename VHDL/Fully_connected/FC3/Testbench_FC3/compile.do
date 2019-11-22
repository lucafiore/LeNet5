#compile all vhd file
vcom Fully_Connected_Layer.vhd
vcom *.vhd

vsim work.FC3_tb
add wave *
run 2 us



