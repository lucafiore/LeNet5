close all
clear
clc

%some constants
inputSize = 8;
parallelism_out=8;
Output_Neurons=10;
Input_Neurons=84;
integer_part=5;
decimal_part=parallelism_out-integer_part;

%% FILES

% OPEN FILES
%open file to be read: Input, biases, Weights and Output (data in decimal form)
fileW_in = fopen('ColumnWeights_dense_3.txt','r');
fileB_in = fopen('ColumnBias_dense_3.txt','r');
fileINPUT_in = fopen('ColumnInput_from_prev_layer.txt','r');
fileOUTPUT_in = fopen('ColumnOutput_dense_3.txt','r');

%open file to be written: Input, biases, Weights and Output (data in binaryl form)
% type ColumnBias_dense_3.txt   %to display the content of the file 
fileW_out = fopen('Bin_ColumnWeights_dense_3.txt','w');
fileB_out = fopen('Bin_ColumnBias_dense_3.txt','w');
fileINPUT_out = fopen('Bin_Input_from_prev_layer_3.txt','w');
fileOUTPUT_out = fopen('Bin_Output_dense_3.txt','w');
fileOUTPUT_matlab = fopen('Bin_Output_dense_3_matlab.txt','w');

%REORDER DATA IN WEIGHTS FILE

% READ FILES
formatSpec='%f';
Bias = fscanf(fileB_in,formatSpec);
Weights=fscanf(fileW_in,formatSpec);
Inputs=fscanf(fileINPUT_in,formatSpec);
Outputs=fscanf(fileOUTPUT_in,formatSpec);

% CONVERT DATA IN BINARY FIXED POINT
Bias_fixed=fi(Bias,1, parallelism_out, parallelism_out-1,'RoundingMethod', 'Convergent');
Bias_bin=Bias_fixed.bin;

Weights_fixed=fi(Weights,1, parallelism_out, parallelism_out-1,'RoundingMethod', 'Convergent');
Weights_bin=Weights_fixed.bin;

Inputs_fixed=fi(Inputs,1, parallelism_out, decimal_part,'RoundingMethod', 'Convergent');
Inputs_bin=Inputs_fixed.bin;

Outputs_fixed=fi(Outputs,1, parallelism_out, decimal_part,'RoundingMethod','Convergent');
Outputs_bin=Outputs_fixed.bin;

% % Outputs_fixed=fi(Outputs,1, parallelism_out, decimal_part,'RoundingMethod','Floor','OverflowAction','Wrap');
% % Outputs_bin=Outputs_fixed.bin;


%% WRITING FILES WITH DATA IN BINARY FORM FOR THE SIMULATION
% Data in these files comes from Keras

len=size(Weights_bin);
for i=1:len(1)
    fprintf(fileW_out,'%s',Weights_bin(i,:));
    fprintf(fileW_out,'\n');
end

len=size(Bias_bin);
for i=1:len(1)
    fprintf(fileB_out,'%s',Bias_bin(i,:));
    fprintf(fileB_out,'\n');
end

len=size(Inputs_bin);
for i=1:len(1)
    fprintf(fileINPUT_out,'%s',Inputs_bin(i,:));
    fprintf(fileINPUT_out,'\n');
end

len=size(Outputs_bin);
for i=1:len(1)
    fprintf(fileOUTPUT_out,'%s',Outputs_bin(i,:));
    fprintf(fileOUTPUT_out,'\n');
end


%%  Generate gloden output of FC1 to be compared with those from Modelsim
% Now we are going to simulate the behavior of the layer in the MATLAB
% obtaining results to be compared with those from the Modelsim and those from Keras

[Out_fc3,Out_fc3_bin]=FC3_function_speed(parallelism_out,Inputs_fixed);

len=size(Out_fc3_bin);
for i=1:len(1)
    fprintf(fileOUTPUT_matlab,'%s',Out_fc3_bin(i,:));
    fprintf(fileOUTPUT_matlab,'\n');
end


%% CLOSE FILES

fclose('all');

%% Read Modelsim Results
file_from_simulation = fopen('Bin_output_simulation_dense3.txt','r');
tline = fgetl(file_from_simulation); % read first line
i=1;
bin_simulation_res(i,:)=tline;
i=i+1;
while ischar(tline) 
    %disp(tline)
    tline = fgetl(file_from_simulation);
    bin_simulation_res(i,:)=tline;
    i=i+1;
end
bin_simulation_res(end,:)=[];

len=size(bin_simulation_res);
for i=1:len(1)
   fi_simulation_res(i)=CA2_bin2dec(bin_simulation_res(i,:),parallelism_out,integer_part);
end


%% Compare results
% compare output of simulation with output from MATLAB
figure(1)
error_Modelsim= abs(double(fi_simulation_res') - double(Out_fc3));
for i=1:length(Out_fc3)
    if Out_fc3(i)~=0
        error_Modelsim_perc(i)=abs(error_Modelsim(i)./double(Out_fc3(i)))*100;
    else 
        error_Modelsim_perc(i)=0;
    end
end
plot( error_Modelsim_perc,'o-')
title('Output of Modelsim vs output of MATLAB error [%]  - FC3');
ylim([-100 100]);
xlabel('Output Neurons');
ylabel('Error Modelsim vs MATLAB [%]');

% compare output of simulation with output from KERAS

error_keras= abs(double(fi_simulation_res') - Outputs);
for i=1:length(Outputs)
    if Outputs(i)~=0
        error_keras_perc(i)=abs(error_keras(i)./Outputs(i))*100;
    else 
        error_keras_perc(i)=0;
    end
end
figure(2)
plot(error_keras_perc,'o-')
title('Output of Modelsim vs output of KERAS error [%] - FC3');
% ylim([0 50]);
xlabel('Output Neurons');
ylabel('Error Modelsim vs Keras [%]');

figure(3)
plot(error_keras,'o-')
title('Output of Modelsim vs output of KERAS absolute error- FC3');
ylim([-0.5 1]);
xlabel('Output Neurons');
ylabel('Absolute error Modelsim vs Keras');
