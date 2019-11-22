function [Outputs,Outputs_bin] =FC1_function(parallelism,Inputs)
%tic    
    Output_Neurons=120;
    Input_Neurons=400;
    integer_part=6-1;
    
    %uscite del moltiplicatore
    parallelism_out_mult=2*parallelism-1;
    decimal_part_mult=parallelism_out_mult-integer_part;
    
    %uscite del sommatore e MAC
    parallelism_out=parallelism;
%     decimal_part=parallelism_out-1;
   
    %% FILES

    % OPEN FILES
    %open file to be read: Input, biases, Weights and Output (data in decimal form)
    fileW_in = fopen('ColumnWeights_dense_1.txt','r');
    fileB_in = fopen('ColumnBias_dense_1.txt','r');

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


    %%  Generate gloden output of FC1
    % Now we are going to simulate the behavior of the layer in the MATLAB

    out_sim_gold=fi(zeros(1,Output_Neurons),1,parallelism_out_mult,decimal_part_mult,'RoundingMethod', 'Floor', 'OverflowAction', 'Saturate');
    for j=1:Output_Neurons % initialize out_sim_gold with bias values
        out_sim_gold(j)=fi(Bias_fixed(j),1,parallelism_out_mult,decimal_part_mult,'RoundingMethod', 'Floor', 'OverflowAction', 'Saturate');
    end
    
%     Inputs_fixed = fi(Inputs_fixed, 1, parallelism_out, parallelism_out-1);
    
    for i=0:Input_Neurons-1 % calculate the theoretical output of the Modelsim simulation with MATLAB
        for j=1:24
%             out_sim_gold(j)=fi(out_sim_gold(j)+fi((2^4*Inputs_fixed(i+1)*Weights_fixed(i*24+j)),1, parallelism_out_mult,decimal_part_mult),1,parallelism_out_mult,decimal_part_mult, 'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
% 
%             out_sim_gold(24+j)=fi(out_sim_gold(24+j)+fi((2^4*Inputs_fixed(i+1)*Weights_fixed(i*24+j+24*400*1)),1,parallelism_out_mult,decimal_part_mult),1,parallelism_out_mult,decimal_part_mult, 'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
% 
%             out_sim_gold(48+j)=fi(out_sim_gold(48+j)+fi((2^4*Inputs_fixed(i+1)*Weights_fixed(i*24+j+24*400*2)),1,parallelism_out_mult,decimal_part_mult),1,parallelism_out_mult,decimal_part_mult, 'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
% 
%             out_sim_gold(72+j)=fi(out_sim_gold(72+j)+fi((2^4*Inputs_fixed(i+1)*Weights_fixed(i*24+j+24*400*3)),1,parallelism_out_mult,decimal_part_mult),1,parallelism_out_mult,decimal_part_mult, 'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
% 
%             out_sim_gold(96+j)=fi(out_sim_gold(96+j)+fi((2^4*Inputs_fixed(i+1)*Weights_fixed(i*24+j+24*400*4)),1,parallelism_out_mult,decimal_part_mult),1,parallelism_out_mult,decimal_part_mult, 'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
        
            out_sim_gold(j)=fi(double(out_sim_gold(j))+(double(fi(Inputs_fixed(i+1)*Weights_fixed(i*24+j),1,parallelism_out_mult,decimal_part_mult,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap'))),1,'RoundingMethod', 'Floor', 'OverflowAction', 'Saturate');

            out_sim_gold(24+j)=fi(double(out_sim_gold(24+j))+(double(fi(Inputs_fixed(i+1)*Weights_fixed(i*24+j+24*400*1),1,parallelism_out_mult,decimal_part_mult,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap'))),1,'RoundingMethod', 'Floor', 'OverflowAction', 'Saturate');
%             out_sim_gold(24+j)=out_sim_gold(24+j)+(double(Inputs_fixed(i+1)*Weights_fixed(i*24+j+24*400*1)));
            
            out_sim_gold(48+j)=fi(double(out_sim_gold(48+j))+(double(fi(Inputs_fixed(i+1)*Weights_fixed(i*24+j+24*400*2),1,parallelism_out_mult,decimal_part_mult,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap'))),1,'RoundingMethod', 'Floor', 'OverflowAction', 'Saturate');   
%             out_sim_gold(48+j)=out_sim_gold(48+j)+(double(Inputs_fixed(i+1)*Weights_fixed(i*24+j+24*400*2)));

            out_sim_gold(72+j)=fi(double(out_sim_gold(72+j))+(double(fi(Inputs_fixed(i+1)*Weights_fixed(i*24+j+24*400*3),1,parallelism_out_mult,decimal_part_mult,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap'))),1,'RoundingMethod', 'Floor', 'OverflowAction', 'Saturate');   
%             out_sim_gold(72+j)=out_sim_gold(72+j)+(double(Inputs_fixed(i+1)*Weights_fixed(i*24+j+24*400*3)));

            out_sim_gold(96+j)=fi(double(out_sim_gold(96+j))+(double(fi(Inputs_fixed(i+1)*Weights_fixed(i*24+j+24*400*4),1,parallelism_out_mult,decimal_part_mult,'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap'))),1,'RoundingMethod', 'Floor', 'OverflowAction', 'Saturate');   
%             out_sim_gold(96+j)=out_sim_gold(96+j)+(double(Inputs_fixed(i+1)*Weights_fixed(i*24+j+24*400*4)));  
        end
    end

    %RELU of golden output
    for j=1:Output_Neurons
        if (out_sim_gold(j)<0)
            out_sim_gold(j)=0;
        end
    end
    
    %normalize the output to be of the length of the parallelism of the
    %network with only one bit of integer part
    Outputs=fi(double(out_sim_gold)'./2^4,1, parallelism_out, parallelism_out-1, 'RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
%     Outputs=fi(double(out_sim_gold)'./2^4,1, parallelism_out, parallelism_out-1, 'RoundingMethod', 'Convergent', 'OverflowAction', 'Wrap');

%fprintf('\nFC1: ')
%toc
end
