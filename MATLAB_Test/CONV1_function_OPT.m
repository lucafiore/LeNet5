function [Out_conv1,conv_op,conv_n] = CONV1_function_OPT(parallelism,Inputs_fixed)
%FIRST CONVOLUTIONAL LAYER EMULATING THE VHDL

%% PARAMETERS AND INITIALIZATION
inputSize   = 32;
numInputs   = 1;
filterSize  = 5;
numFilters  = 6;
IntegerPart = 5;
parallelism_out_mult = 2*parallelism-1;
threshold=50;
%preallocation
Out_conv1 = fi(zeros(inputSize-filterSize+1, inputSize-filterSize+1, numFilters), 1, parallelism, parallelism-1);
Weights = zeros(filterSize,filterSize,numFilters);

%% READING WEIGHTS AND BIAS
fileW = fopen('ColumnWeights_conv2d_1.txt','r');
fileB = fopen('ColumnBias_conv2d_1.txt','r');

%lettura totale del file dei pesi
fromatSpec = '%f';
Weights_read = fscanf(fileW,fromatSpec);
Bias = fscanf(fileB,fromatSpec);
           
% % AAA= sum(Weights_read)/length(Weights_read);
% % BB= sum(Weights_read(Weights_read>0))/length(Weights_read(Weights_read>0));
% % CC= sum(Weights_read(Weights_read<0))/length(Weights_read(Weights_read<0));
% % BBB = max(Weights_read(Weights_read>0))-BB;
% % B= min(Weights_read(Weights_read>0))-BB;
% % CCC = min(Weights_read(Weights_read<0))-CC;
% % C= max(Weights_read(Weights_read<0))-CC;

%riordinamento pesi
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

%% VARIABLE FOR OPTIMIZATION

%preallocation
x2_matrix = zeros(filterSize,filterSize,numFilters);

inputs_opt = fi(Inputs_fixed, 0, 1, 1,'RoundingMethod', 'Floor'); %MSB inputs
w_opt = fi(w_matrix_fixed, 1, 2, 1,'RoundingMethod', 'Floor'); %MSB weights

for i=1:numFilters
    for r=1:filterSize
        for c=1:filterSize
            if w_opt(r,c,i)<0
                x2_matrix(r,c,i)=1;
            else
                x2_matrix(r,c,i)=0;
            end
        end
    end
end

%% NOSTRA CONVOLUZIONE

conv_n=0; %conta numero di convoluzioni totali effettivamente svolte (risparmio potenza)
conv_op=0; %conta in quanti gruppi da 24 c'è almeno una convoluzione da effettuare (risparmio velocita)

%threshold=46;

for r=1:14
    for c=1:14
        convv=0;
        for i=1:numFilters
            x2=x2_matrix(:,:,i);
            
            %1-matrix
            x1 = inputs_opt(r*2-1:r*2+4-1, c*2-1:c*2+4-1);
            G_pos = x1 & not(x2);
            P_pos = not(x1) & not(x2);
            P_neg = not(x1) & x2;
            prec = -threshold + sum(sum(G_pos))*3 + sum(sum(P_pos))*2 + sum(sum(P_neg))*1; 
            if prec >= 0
                convv=convv+1;
                a = sum(sum(fi(in_matrix_fixed(r*2-1:r*2+4-1,c*2-1:c*2+4-1).*w_matrix_fixed(:,:,i),1,parallelism_out_mult, parallelism_out_mult-IntegerPart,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap'))) + bias_fixed(i);
                if a > 0
                    Out_conv1(r*2-1,c*2-1,i) = fi(double(a)/2^4, 1, parallelism, parallelism-1,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
                end             
            end
            
            %2-matrix
            x1 = inputs_opt(r*2-1:r*2+4-1, c*2:c*2+4);
            G_pos = x1 & not(x2);
            P_pos = not(x1) & not(x2);
            P_neg = not(x1) & x2;
            prec = -threshold + sum(sum(G_pos))*3 + sum(sum(P_pos))*2 + sum(sum(P_neg))*1;
            if prec >= 0
                convv=convv+1;
                a = sum(sum(fi(in_matrix_fixed(r*2-1:r*2+4-1, c*2:c*2+4).*w_matrix_fixed(:,:,i),1,parallelism_out_mult, parallelism_out_mult-IntegerPart,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap'))) + bias_fixed(i);
                if a > 0
                    Out_conv1(2*r-1,2*c,i) = fi(double(a)/2^4, 1, parallelism, parallelism-1,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
                end             
            end
            %3-matrix
            x1 = inputs_opt(r*2:r*2+4, c*2-1:c*2+4-1);
            G_pos = x1 & not(x2);
            P_pos = not(x1) & not(x2);
            P_neg = not(x1) & x2;
            prec = -threshold + sum(sum(G_pos))*3 + sum(sum(P_pos))*2 + sum(sum(P_neg))*1;
            if prec >= 0
                convv=convv+1;
                a = sum(sum(fi(in_matrix_fixed(r*2:r*2+4, c*2-1:c*2+4-1).*w_matrix_fixed(:,:,i),1,parallelism_out_mult, parallelism_out_mult-IntegerPart,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap'))) + bias_fixed(i);
                if a > 0
                    Out_conv1(2*r,2*c-1,i) = fi(double(a)/2^4, 1, parallelism, parallelism-1,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
                end             
            end
            
            %4-matrix
            x1 = inputs_opt(r*2:r*2+4, c*2:c*2+4);
            G_pos = x1 & not(x2);
            P_pos = not(x1) & not(x2);
            P_neg = not(x1) & x2;
            prec = -threshold + sum(sum(G_pos))*3 + sum(sum(P_pos))*2 + sum(sum(P_neg))*1;
            if prec >= 0
                convv=convv+1;
                a = sum(sum(fi(in_matrix_fixed(r*2:r*2+4, c*2:c*2+4).*w_matrix_fixed(:,:,i),1,parallelism_out_mult, parallelism_out_mult-IntegerPart,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap'))) + bias_fixed(i);
                if a > 0
                    Out_conv1(2*r,2*c,i) = fi(double(a)/2^4, 1, parallelism, parallelism-1,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
                end             
            end
        end
        
        if convv~=0
            conv_op=conv_op+1;
            conv_n=conv_n+convv;
        end
        
    end
end

%display information
fprintf("[(SPEED) Convolution performed: %d  out of 196]\n", conv_op)
fprintf("[(POWER) Convolution performed: %d  out of 4704]\n", conv_n)



