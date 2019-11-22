function [Outputs] =FC3_function(parallelism,Inputs)
% tic
    Output_Neurons=10;
    Input_Neurons=84;
    integer_part=5;
    
    %uscite del moltiplicatore
    parallelism_out_mult=2*parallelism-1;
    decimal_part_mult=parallelism_out_mult-integer_part;
    
    %uscite del sommatore e MAC
    parallelism_out=parallelism;
%     decimal_part=parallelism_out-1;
    
    %% FILES

    % OPEN FILES
    %open file to be read: Input, biases, Weights and Output (data in decimal form)
    fileW_in = fopen('ColumnWeights_dense_3.txt','r');
    fileB_in = fopen('ColumnBias_dense_3.txt','r');

    % READ FILES
    formatSpec='%f';
    Bias = fscanf(fileB_in,formatSpec);
    Weights=fscanf(fileW_in,formatSpec);
    Inputs_fixed = fi(Inputs,1,parallelism_out, parallelism_out-1,'RoundingMethod', 'Convergent' , 'OverflowAction', 'Wrap'); % from prev layer
    Inputs_fixed = fi(Inputs_fixed*16,1,parallelism_out, parallelism_out-5,'RoundingMethod', 'Floor' , 'OverflowAction', 'Wrap'); % from prev layer

    % CONVERT DATA IN BINARY FIXED POINT
    Bias_fixed=fi(Bias,1, parallelism_out, parallelism_out-1,'RoundingMethod', 'Convergent', 'OverflowAction', 'Wrap');
    
    Weights_fixed=fi(Weights,1, parallelism_out, parallelism_out-1,'RoundingMethod', 'Convergent', 'OverflowAction', 'Wrap');
    Weights_fixed=fi(Weights_fixed,1, parallelism_out, parallelism_out-1,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');

    
    %% CLOSE FILES

    fclose(fileW_in);
    fclose(fileB_in);


    %%  Generate gloden output of FC3
    % Now we are going to simulate the behavior of the layer in the MATLAB

    out_sim_gold=fi(zeros(1,Output_Neurons),1,parallelism_out_mult,decimal_part_mult,'RoundingMethod', 'Floor', 'OverflowAction', 'Saturate');
    for j=1:Output_Neurons % initialize out_sim_gold with bias values
        out_sim_gold(j)=fi(Bias_fixed(j),1,parallelism_out_mult,decimal_part_mult,'RoundingMethod', 'Floor', 'OverflowAction', 'Saturate');
    end

    for i=0:Input_Neurons-1 % calculate the theoretical output of the Modelsim simulation 
        for j=1:Output_Neurons
%             out_sim_gold(j)=fi(out_sim_gold(j)+fi(2^4*Inputs_fixed(i+1)*Weights_fixed(j+i*10),1,parallelism_out_mult,decimal_part_mult),1,parallelism_out_mult,decimal_part_mult, 'RoundingMethod', 'Floor');
            out_sim_gold(j)=fi(double(out_sim_gold(j))+(double(fi(Inputs_fixed(i+1)*Weights_fixed(j+i*10),1,parallelism_out_mult,decimal_part_mult,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap'))),1,'RoundingMethod', 'Floor', 'OverflowAction', 'Saturate');
%             out_sim_gold(j)=out_sim_gold(j)+(2^4*double(Inputs_fixed(i+1)*Weights_fixed(j+i*10)));
        end
    end
    
    %normalize the output to be of the length of the parallelism of the
    %network with only one bit of integer part
   Outputs=fi(double(out_sim_gold)'./2^4,1, parallelism_out, parallelism_out-1, 'RoundingMethod', 'Floor', 'OverflowAction', 'Saturate');
%    Outputs=fi(double(out_sim_gold)'./2^4,1, parallelism_out, parallelism_out-1, 'RoundingMethod', 'Convergent', 'OverflowAction', 'Saturate');

% fprintf('\nFC3: ')
% toc
end
