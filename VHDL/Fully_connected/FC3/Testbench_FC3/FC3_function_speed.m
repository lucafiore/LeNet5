function [Outputs,Outputs_bin] =FC3_function(parallelism,Inputs)
%tic    
    Output_Neurons=10;
    Input_Neurons=84;
    integer_part=5;
    
    %uscite del moltiplicatore
    parallelism_out_mult=2*parallelism;
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
    Inputs_fixed = fi(Inputs,1,parallelism_out, parallelism_out-integer_part,'RoundingMethod', 'Convergent'); % from prev layer

    % CONVERT DATA IN BINARY FIXED POINT
    Bias_fixed=fi(Bias,1, parallelism_out, parallelism_out-1,'RoundingMethod', 'Convergent');
    Weights_fixed=fi(Weights,1, parallelism_out, parallelism_out-1,'RoundingMethod', 'Convergent');


    %% CLOSE FILES

    fclose(fileW_in);
    fclose(fileB_in);


    %%  Generate gloden output of FC1
    % Now we are going to simulate the behavior of the layer in the MATLAB

    out_sim_gold=fi(zeros(1,Output_Neurons),1,parallelism_out_mult,decimal_part_mult);
    for j=1:Output_Neurons % initialize out_sim_gold with bias values 
        out_sim_gold(j)=double(fi(Bias_fixed(j),1,parallelism_out_mult,decimal_part_mult));
    end

    
%     Inputs_fixed = fi(Inputs_fixed, 1, parallelism_out, parallelism_out-1);
    
    for i=0:Input_Neurons-1 % calculate the theoretical output of the Modelsim simulation with MATLAB
        for j=1:Output_Neurons
                        out_sim_gold(j)=fi(out_sim_gold(j)+fi((Inputs_fixed(i+1)*Weights_fixed(j+i*10)),1,parallelism_out_mult,decimal_part_mult),1,parallelism_out_mult,decimal_part_mult, 'RoundingMethod', 'Floor');
        end
    end

    Outputs=fi(double(out_sim_gold)',1, parallelism_out, parallelism_out-integer_part, 'RoundingMethod', 'Floor', 'OverflowAction', 'Saturate');
    Outputs_bin=Outputs.bin;
%     Outputs=fi(out_sim_gold',1, parallelism_out, decimal_part,'RoundingMethod', 'Convergent');

%fprintf('\nFC3: ')
%toc
end
