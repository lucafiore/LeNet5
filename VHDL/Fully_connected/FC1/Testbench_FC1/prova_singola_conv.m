%%Questo script serve per calcolare un solo output di un MAC per vedere se
%%le operazioni vengono fatte bene in MATLAB. 

close all
clear
clc

%read files
fileW_in = fopen('ColumnWeights_dense_1.txt','r');
fileB_in = fopen('ColumnBias_dense_1.txt','r');
fileINPUT_in = fopen('ColumnInput_from_prev_layer.txt','r');
fileOUTPUT_in = fopen('ColumnOutput_dense_1.txt','r');

formatSpec='%f';
Bias = fscanf(fileB_in,formatSpec);
Weights=fscanf(fileW_in,formatSpec);
Inputs=fscanf(fileINPUT_in,formatSpec);
Outputs=fscanf(fileOUTPUT_in,formatSpec);

%Converto da binario a decimale fixed il risultato di Modelsim
Output_Modelsim_bin='0010100111001101';

Output_Modelsim=0;
Output_Modelsim=CA2_bin2dec(Output_Modelsim_bin,16,5)

%%%%%%%%%%%%%%%%%%%%%%%%%%

w=fi(Weights(2:24:24*400),1,16,11);
b_16=fi(Bias(2),1,16,11);
b_32=fi(Bias(2),1,32,22);
in=fi(Inputs,1,16,11);

output_Keras=Outputs(2)

%Simulo un singolo MAC
output_MATLAB=fi(sum(in.*w)+b_32,1,16,11,'RoundingMethod','Floor')

error_Modelsim= abs(double(output_MATLAB) - double(Output_Modelsim))

%close files
fclose(fileW_in);
fclose(fileB_in);
fclose(fileINPUT_in);
fclose(fileOUTPUT_in);

