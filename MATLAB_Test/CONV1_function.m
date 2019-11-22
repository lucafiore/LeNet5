function [Out_conv1] = CONV1_function(parallelism,Inputs_fixed)
%FIRST CONVOLUTIONAL LAYER EMULATING THE VHDL

%% PARAMETERS AND INITIALIZATION
inputSize   = 32;
numInputs   = 1;
filterSize  = 5;
numFilters  = 6;
integer_part= 5;

%uscite del moltiplicatore
parallelism_out_mult=2*parallelism-1;
decimal_part_mult=parallelism_out_mult-integer_part;

%uscite del sommatore e MAC
parallelism_out=parallelism;
%decimal_part=parallelism_out-1;

Out_conv1 = fi(zeros(inputSize-filterSize+1, inputSize-filterSize+1, numFilters), 1, parallelism, parallelism-1);
Weights = zeros(filterSize,filterSize,numFilters);

%% READING WEIGHTS AND BIAS
fileW = fopen('ColumnWeights_conv2d_1.txt','r');
fileB = fopen('ColumnBias_conv2d_1.txt','r');
%lettura totale del file dei pesi
fromatSpec = '%f';
Weights_read = fscanf(fileW,fromatSpec);
Bias = fscanf(fileB,fromatSpec);
           
y=1;
for r=1:filterSize
    for c=1:filterSize
        for i=1:numFilters
            Weights(r,c,i) = Weights_read(y);
            y=y+1;
        end
    end
end

fclose(fileW);
fclose(fileB);

%% VARIABLES
in_matrix_fixed = fi(Inputs_fixed, 1, parallelism, parallelism-1,'RoundingMethod', 'Floor','OverflowAction', 'Wrap'); 
in_matrix_fixed = fi(in_matrix_fixed, 1, parallelism, parallelism-1,'RoundingMethod', 'Convergent','OverflowAction', 'Wrap'); 

w_matrix_fixed  = fi(Weights, 1, parallelism, parallelism-1, 'RoundingMethod', 'Convergent', 'OverflowAction', 'Wrap');
bias_fixed = fi(Bias, 1, parallelism, parallelism-1, 'RoundingMethod', 'Convergent', 'OverflowAction', 'Wrap');
bias_fixed = fi(bias_fixed, 1, parallelism, parallelism-1, 'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');

%% NOSTRA CONVOLUZIONE
for i=1:numFilters
    for r=1:28
        for c=1:28
            a = sum(sum(fi(in_matrix_fixed(r:r+4,c:c+4).*w_matrix_fixed(:,:,i),1,parallelism_out_mult,decimal_part_mult,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap'))) + bias_fixed(i);
            if a > 0
               %normalize the output
               Out_conv1(r,c,i) = fi((double(a)/2^4),1,parallelism_out,parallelism_out-1, 'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
            else
               Out_conv1(r,c,i) = fi(0, 1, parallelism_out,parallelism_out-1, 'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
            end
        end
    end
end

end