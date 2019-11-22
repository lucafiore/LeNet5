close all
clear all
clc

inputSize = 32;
numInputs = 1;
filterSize = 5;
numFilters = 6;
parallelism=8;
parallelism_in=8;


%% GENERATION INPUTS, WEIGHTS AND OUTPUTS

Weights = zeros(filterSize,filterSize,numFilters);
% Out_conv1 = zeros(inputSize-filterSize+1,inputSize-filterSize+1,numFilters);

%% READING WEIGHTS AND BIAS
fileIn = fopen('inputs_test_n0.txt','r');
fileW = fopen('./w_b_files/ColumnWeights_conv2d_1.txt','r');
fileB = fopen('./w_b_files/ColumnBias_conv2d_1.txt','r');
%lettura totale del file dei pesi
fromatSpec = '%f';
In = fscanf(fileIn,fromatSpec)/256;
Weights_read = fscanf(fileW,fromatSpec);
Bias = fscanf(fileB,fromatSpec);
y=1;
for r=1:filterSize
    for c=1:filterSize
        for i=1:numFilters
            Weights(r,c,i) = Weights_read(y);
            y=y+1;
            %per prendere i pesi per righe invece che per colonne cambiare c
            %con r come fatto qua sotto, fare lo stesso per il conv2 
            %Weights2(c,r,i) = Weights_read((i-1)*numFilters+(r-1)*filterSize+c);
        end
    end
end
y=1;
for r=1:inputSize
    for c=1:inputSize
        Inputs_fixed(r,c) = In(y);
        y=y+1;
    end
end
%Weights=reshape(Weights_read,filterSize,filterSize,numFilters);%the transpose during operations
fclose(fileW);
fclose(fileB);
fclose(fileIn);

%% GENERATION FILE
fileIn = fopen('fileInputs_conv1.txt','w');
fileW = fopen('fileWeights_conv1.txt','w');
fileB = fopen('fileBias_conv1.txt','w');
fileO = fopen('fileOutputsMATLAB_conv1.txt','w');

%% VARIABLES
in_matrix_fixed = fi(Inputs_fixed, 1, parallelism_in, parallelism_in-1,'RoundingMethod', 'Floor','OverflowAction', 'Wrap'); 
in_matrix_fixed = fi(in_matrix_fixed, 1, parallelism_in, parallelism_in-1,'RoundingMethod', 'Convergent','OverflowAction', 'Wrap'); 

w_matrix_fixed  = fi(Weights, 1, parallelism, parallelism-1, 'RoundingMethod', 'Convergent', 'OverflowAction', 'Wrap');
bias_fixed = fi(Bias, 1, parallelism, parallelism-1, 'RoundingMethod', 'Convergent', 'OverflowAction', 'Wrap');
bias_fixed = fi(bias_fixed, 1, parallelism, parallelism-1, 'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');

%% WRITING FILES AND OPERATIONS
% BIAS AND WEIGHTS
for i=1:numFilters
    for r=1:filterSize
        for c=1:filterSize
            a = w_matrix_fixed(r,c,i);
            fprintf(fileW,'%s',a.bin);
        end
        fprintf(fileW,'\n');
    end
    %%fprintf(fileW,'\n');
    b = bias_fixed(i);
    fprintf(fileB,'%s\n',b.bin);
end
% INPUTS
for r=1:inputSize
    for c=1:inputSize
        d = in_matrix_fixed(r,c);
        fprintf(fileIn,'%s',d.bin);
    end
    fprintf(fileIn,'\n');
end

%% VARIABLE FOR OPTIMIZATION
inputs_opt = fi(Inputs_fixed, 0, 1, 1,'RoundingMethod', 'Floor');
w_opt = fi(w_matrix_fixed, 1, 2, 1,'RoundingMethod', 'Floor');

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

%% OPTIMIZATION
% NOSTRA CONVOLUZIONE
Out_conv1 = fi(zeros(28,28,6), 1, parallelism, parallelism-1);

%     flag=0;
conv_op=0;
for r=1:14
    for c=1:14
        convv=0;
        for i=1:numFilters
%             if(i==2 & r==12 & c==7)
%                     zz = sum(sum(fi(in_matrix_fixed(r*2-1:r*2+4-1,c*2:c*2+4).*w_matrix_fixed(:,:,i),1,2*parallelism, 2*parallelism-6,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap'))) + bias_fixed(i);
%                     zz.bin
%             end
            
            
            x2=x2_matrix(:,:,i);
            %1-matrix
            x1 = inputs_opt(r*2-1:r*2+4-1, c*2-1:c*2+4-1);
            G_pos = x1 & not(x2);
            P_pos = not(x1) & not(x2);
            P_neg = not(x1) & x2;
            prec = -50 + sum(sum(G_pos))*3 + sum(sum(P_pos))*2 + sum(sum(P_neg))*1;
            
            if prec >= 0
                convv=convv+1;
                a = sum(sum(fi(in_matrix_fixed(r*2-1:r*2+4-1,c*2-1:c*2+4-1).*w_matrix_fixed(:,:,i),1,2*parallelism-1, 2*parallelism-5-1,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap'))) + bias_fixed(i);
                if a > 0
                    Out_conv1(r*2-1,c*2-1,i) = fi(double(a)/2^4, 1, parallelism, parallelism-1,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
                end             
            end
            %2-matrix
            x1 = inputs_opt(r*2-1:r*2+4-1, c*2:c*2+4);
            G_pos = x1 & not(x2);
            P_pos = not(x1) & not(x2);
            P_neg = not(x1) & x2;
            prec = -50 + sum(sum(G_pos))*3 + sum(sum(P_pos))*2 + sum(sum(P_neg))*1;
            
            if prec >= 0
                convv=convv+1;
                a = sum(sum(fi(in_matrix_fixed(r*2-1:r*2+4-1, c*2:c*2+4).*w_matrix_fixed(:,:,i),1,2*parallelism-1, 2*parallelism-5-1,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap'))) + bias_fixed(i);
                if a > 0
                    Out_conv1(2*r-1,2*c,i) = fi(double(a)/2^4, 1, parallelism, parallelism-1,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
                end             
            end
            %3-matrix
            x1 = inputs_opt(r*2:r*2+4, c*2-1:c*2+4-1);
            G_pos = x1 & not(x2);
            P_pos = not(x1) & not(x2);
            P_neg = not(x1) & x2;
            prec = -50 + sum(sum(G_pos))*3 + sum(sum(P_pos))*2 + sum(sum(P_neg))*1;
            if prec >= 0
                convv=convv+1;
                a = sum(sum(fi(in_matrix_fixed(r*2:r*2+4, c*2-1:c*2+4-1).*w_matrix_fixed(:,:,i),1,2*parallelism-1, 2*parallelism-5-1,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap'))) + bias_fixed(i);
                if a > 0
                    Out_conv1(2*r,2*c-1,i) = fi(double(a)/2^4, 1, parallelism, parallelism-1,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
%                     if(i==1 & r==4 & c==4)
%                         zz=Out_conv1(2*r,2*c-1,i);
%                         zz.bin
%                     end
                end             
            end
            %4-matrix
            x1 = inputs_opt(r*2:r*2+4, c*2:c*2+4);
            G_pos = x1 & not(x2);
            P_pos = not(x1) & not(x2);
            P_neg = not(x1) & x2;
            prec = -50 + sum(sum(G_pos))*3 + sum(sum(P_pos))*2 + sum(sum(P_neg))*1;
            if prec >= 0
                convv=convv+1;
                a = sum(sum(fi(in_matrix_fixed(r*2:r*2+4, c*2:c*2+4).*w_matrix_fixed(:,:,i),1,2*parallelism-1, 2*parallelism-5-1,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap'))) + bias_fixed(i);
                if a > 0
                    Out_conv1(2*r,2*c,i) = fi(double(a)/2^4, 1, parallelism, parallelism-1,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
%                     if(i==1 & r==4 & c==4)
%                         zz=Out_conv1(2*r,2*c,i);
%                         zz.bin
%                     end

                end             
            end
        end
        if convv~=0
            conv_op=conv_op+1;
            %fprintf("%d  ->  %d, %d\n", convv, (r-1), (c-1))
        end
    end
end
%conv_op
%% MAX POOLING
inputSize = 28;
outputSize = inputSize/2;
numInputs = 6;
parallelism_in=parallelism;
parallelism_out=parallelism;

% GENERATION OUTPUTS
Outputs=ones(outputSize,outputSize,numInputs);

% MAX_POOLING
for k=1:numInputs
    for i=1:outputSize
        for j=1:outputSize
            t=max([Out_conv1(2*i-1,2*j-1,k),Out_conv1(2*i-1,2*j,k),Out_conv1(2*i,2*j-1,k),Out_conv1(2*i,2*j,k)]);
            if t<0
                Outputs(i,j,k)=0;
            else
                Outputs(i,j,k)=t;
            end
        end
    end
end

Out_max = fi(Outputs, 1, parallelism, parallelism-1,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');

for i=1:numFilters
    for r=1:outputSize
        for c=1:outputSize
            z = Out_max(r,c,i);
            fprintf(fileO,'%s\n',z.bin);
        end
        %fprintf(fileO,'\n');
    end
    %%fprintf(fileW,'\n');
end

fclose(fileO);
fclose(fileW);
fclose(fileIn);
fclose(fileB);
