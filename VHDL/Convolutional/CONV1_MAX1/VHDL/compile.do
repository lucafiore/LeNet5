vlib work
#compile all vhd file
vcom network.vhd
vcom *.vhd

#load top file for simulation
vsim work.network
add wave *
run 50 us
