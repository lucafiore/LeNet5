#!/bin/bash
# per lanciare la simulazione modelsim più in fretta
# $1 è lo script.do di comandi modelsim

if [[ $# -ne 1 ]]; then
	echo "Usage: ./compile.sh \"do script name\""
	exit -1
fi

rm -rf work
source /software/scripts/init_msim6.2g
vlib work

vsim -do $1
