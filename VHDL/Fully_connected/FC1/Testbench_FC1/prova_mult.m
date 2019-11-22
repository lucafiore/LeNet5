clc

in_mpy_1='111110100100';
in_mpy_2='000000111001';

in_mpy_1_fi=fi(CA2_bin2dec(in_mpy_1,12,1),1,12,11);
in_mpy_2_fi=fi(CA2_bin2dec(in_mpy_2,12,5),1,12,7);

mul=in_mpy_2_fi*in_mpy_1_fi;
mul_bin=mul.bin
CA2_bin2dec(mul_bin,24,6);

bias_bin='000000000010';
bias_bin_extended='0000000000000001000000000'
bias_fi=fi(CA2_bin2dec(bias_bin_extended,24,6),1,24,18);

out_add_1=bias_fi+mul;
out_add_1_bin=out_add_1.bin
