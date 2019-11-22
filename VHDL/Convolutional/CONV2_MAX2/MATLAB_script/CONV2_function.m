%% This function is perfect!

function [Out_conv2] = CONV2_function(parallelism,Inputs_fixed)
%FIRST CONVOLUTIONAL LAYER EMULATING THE VHDL

%% PARAMETERS AND INITIALIZATION
inputSize   = 14;
numInputs   = 6;
filterSize  = 5;
numFilters  = 16;
integer_part= 5;

%uscite del moltiplicatore
parallelism_out_mult=2*parallelism-1;
decimal_part_mult=parallelism_out_mult-integer_part;

%uscite del sommatore e MAC
parallelism_out=parallelism;

%preallocation
Weights     = zeros(filterSize,filterSize,numFilters,numInputs);
Out_conv2   = zeros(inputSize-filterSize+1,inputSize-filterSize+1,numFilters);

%% READING WEIGHTS AND BIAS
fileW = fopen('./w_b_files/ColumnWeights_conv2d_2.txt','r');
fileB = fopen('./w_b_files/ColumnBias_conv2d_2.txt','r');
%lettura totale del file dei pesi
fromatSpec = '%f';
Weights_read = fscanf(fileW,fromatSpec);
Bias = fscanf(fileB,fromatSpec);
 
y=1;
for r=1:filterSize
    for c=1:filterSize
        for n=1:numInputs
            for i=1:numFilters
                Weights(r,c,i,n) = Weights_read(y);
                y=y+1;
            end
        end
    end
end

fclose(fileW);
fclose(fileB);

%% VARIABLES

in_matrix_fixed = fi(Inputs_fixed, 1,  parallelism_out, parallelism_out-1,'RoundingMethod', 'Convergent', 'OverflowAction', 'Wrap');
w_matrix_fixed = fi(Weights, 1,  parallelism_out, parallelism_out-1,'RoundingMethod', 'Convergent', 'OverflowAction', 'Wrap');
bias_fixed = fi(Bias, 1,  parallelism_out, parallelism_out-1, 'RoundingMethod', 'Convergent', 'OverflowAction', 'Wrap');

bias_fixed = fi(bias_fixed, 1,  parallelism_out, parallelism_out-1, 'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
%% NOSTRA CONVOLUZIONE
for i=1:numFilters
    for r=1:10
        for c=1:10
            a = bias_fixed(i);
            for n=1:numInputs
                a = a + fi(sum(sum(double(2^4*in_matrix_fixed(r:r+4,c:c+4,n).*w_matrix_fixed(:,:,i,n)))),1,parallelism_out_mult,decimal_part_mult,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
            end
            if a > 0
               %normalize the output
                Out_conv2(r,c,i) = fi(double(a)./2^4,1,parallelism_out,parallelism_out-1, 'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');

            else
                Out_conv2(r,c,i) =  fi(0, 1, parallelism_out,parallelism_out-1, 'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
            end
        end
    end
end


end



