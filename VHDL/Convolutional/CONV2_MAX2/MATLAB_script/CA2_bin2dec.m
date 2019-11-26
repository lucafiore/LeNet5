% Author: Luca Fiore

function [dec_num] = CA2_bin2dec(bin_num,parallelism,integer_part)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes
bin_num=bin_num;
dec_num=0;
decimal_part=parallelism-integer_part;

if integer_part==1
    
    for i=integer_part+1:length(bin_num)
        if(bin_num(1,i)=='1')
            dec_num=dec_num+2^(-(i-integer_part));
        else
            dec_num=dec_num;
        end
    end
    
    if bin_num(1,1)=='0'
        dec_num = dec_num;
    else
        dec_num = -(2^(integer_part-1))+dec_num;
    end
    
else
    
    for i=2:integer_part
        if(bin_num(1,i)=='1')
            dec_num=dec_num+2^(integer_part-i);
        else
            dec_num=dec_num;
        end
    end

    for i=integer_part+1:length(bin_num)
        if(bin_num(1,i)=='1')
            dec_num=dec_num+2^(-(i-integer_part));
        else
            dec_num=dec_num;
        end
    end

    if bin_num(1,1)=='0'
        dec_num = dec_num;
    else
        dec_num = -(2^(integer_part-1))+dec_num;
    end
    
end



end