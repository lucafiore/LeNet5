function [Outputs,Outputs_bin] =FC2_function(parallelism,Inputs)
%tic    
    Output_Neurons=84;
    Input_Neurons=120;
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
    fileW_in = fopen('ColumnWeights_dense_2.txt','r');
    fileB_in = fopen('ColumnBias_dense_2.txt','r');

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

     for i=0:Input_Neurons-1 % calculate the theoretical output of the Modelsim simulation 
            for j=1:21
                out_sim_gold(j)=fi(out_sim_gold(j)+fi((Inputs_fixed(i+1)*Weights_fixed(i*21+j)),1, parallelism_out_mult,decimal_part_mult),1,parallelism_out_mult,decimal_part_mult, 'RoundingMethod', 'Floor');

                out_sim_gold(21+j)=fi(out_sim_gold(21+j)+fi((Inputs_fixed(i+1)*Weights_fixed(i*21+j+21*120*1)),1, parallelism_out_mult,decimal_part_mult),1,parallelism_out_mult,decimal_part_mult, 'RoundingMethod', 'Floor');

                out_sim_gold(42+j)=fi(out_sim_gold(42+j)+fi((Inputs_fixed(i+1)*Weights_fixed(i*21+j+21*120*2)),1, parallelism_out_mult,decimal_part_mult),1,parallelism_out_mult,decimal_part_mult, 'RoundingMethod', 'Floor');

                out_sim_gold(63+j)=fi(out_sim_gold(63+j)+fi((Inputs_fixed(i+1)*Weights_fixed(i*21+j+21*120*3)),1, parallelism_out_mult,decimal_part_mult),1,parallelism_out_mult,decimal_part_mult, 'RoundingMethod', 'Floor');
            
% %                out_sim_gold(j)=out_sim_gold(j)+(2^4*double(Inputs_fixed(i+1)*Weights_fixed(i*21+j)));
% % 
% %                 out_sim_gold(21+j)=out_sim_gold(21+j)+(2^4*double(Inputs_fixed(i+1)*Weights_fixed(i*21+j+21*120*1)));
% % 
% %                 out_sim_gold(42+j)=out_sim_gold(42+j)+(2^4*double(Inputs_fixed(i+1)*Weights_fixed(i*21+j+21*120*2)));
% % 
% %                 out_sim_gold(63+j)=out_sim_gold(63+j)+(2^4*double(Inputs_fixed(i+1)*Weights_fixed(i*21+j+21*120*3)));
                   
            end
     end

    %RELU of golden output
    for j=1:Output_Neurons
        if (out_sim_gold(j)<0)
            out_sim_gold(j)=0;
        end
    end
    

    Outputs=fi(double(out_sim_gold)',1,parallelism_out, parallelism_out-integer_part, 'RoundingMethod', 'Floor', 'OverflowAction', 'Saturate');
    Outputs_bin=Outputs.bin;
%     Outputs=fi(out_sim_gold',1, parallelism_out, decimal_part,'RoundingMethod', 'Convergent');

%fprintf('\nFC2: ')
%toc
end
