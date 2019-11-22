#compile all vhd file
vcom Fully_Connected_Layer.vhd
vcom *.vhd

vsim work.FC1_tb 
add wave *
run 45 us
