#!/bin/bash

if [[ $# -ne 1 ]]; then
	echo "Usage: ./Total_cycle.sh \"period in ns\""
	exit -1
fi

period=$1
ext="_$1"

#modifico il clock nel file variables.scr

while read line; do
	if [[ "$line" =~ 'period' ]]; then 
		echo "variable period $period" >> variables_new.scr 
	elif [[ "$line" =~ 'ext' ]]; then 
		echo "variable ext _$period" >> variables_new.scr
	else 
		echo "$line" >> variables_new.scr
	fi
done < variables.scr

rm variables.scr
mv variables_new.scr variables.scr


# esecuzione della sintesi
./synt_save.sh 
echo "- This file are generated by synopsys:
		synt/synt_out/compilexx.txt
		synt/synt_out/report_timingxx.txt
		synt/synt_out/report_area.txt
		netlist/top_entity.sdf
		netlist/top_entity.sdc
		netlist/top_enetity.v

"
# modifico il clock della simulazione nel testbench
cd ../testbench_post
sed -i -E "s/CONSTANT T_CLK : TIME:= [0-9]+(\.)?[0-9]+ ns;/CONSTANT T_CLK : TIME:= ${period} ns;/" LeNet5_tb.vhd

#moving topfile
#cd ../src
#mv VHDL_Common/LeNet5_top.vhd ./

# execution of netlist
cd ../sim
./sim_saif.sh
echo "- This file are generated by modelsim
		vcd/top_entity.vcd
		saif/top_entity.saif
		
"

# potenza finale
cd ../synt
source /software/scripts/init_synopsys_64.18
dc_shell -f final_power.scr >> ./synt_out/dc_shell_output.txt
echo "- This file are generated by synopsys
		synt_out/report_power_final.txt

"

#cd ../src
#mv ./LeNet5_top.vhd ./VHDL_Common/

