vlib work
#compile all vhd file
vcom network2.vhd
vcom *.vhd

#load top file for simulation
vsim work.network2
add wave *
run 280 us
