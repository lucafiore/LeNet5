% This script simulate the behaviour of th entire network 

close all
clear
clc
tic

Conv1_optimized=1;    % set to '0' if you want to simulate with NO otimization for Conv1
                                        % set to '1' if you want to simulate with otimization for Conv1
                                        
start_script=datetime('now');
disp(['Test starting at ',datestr(start_script)]);

prompt={'\fontsize{12} Insert the code of the image you want to analyze in the mnist\_test dataset [1 to 10000]:'};
dlgtitle='Image code selector';
dims=[1 70];
definput = {'1'};
opts.Interpreter = 'tex'; 
code_s=inputdlg(prompt,dlgtitle,dims,definput,opts);

code=str2double(code_s);

Parallelism_in=8;
% Parallelism=[8;7;6;5];
Parallelism=[8];

% NB: Inputs numbers are represented wth 5-bits of integer part while weights and biases with 1-bit of integer part 
% Inside the MAC number are represented with 2N total bits with 6-bits of integer part 

%IMPORT DATESET AND EXTRACT AN IMAGE TO FEED THE NETWORK
data=load('mnist_test.csv');
labels=data(:,1);
images=data(:,2:end);

fprintf("\n")

   fprintf('Image n° %d\n',code);

    %create base matrix to padding the 28x28 mnist image
    Inputs=zeros(32,32); 

    % choose the image to feed the network
    n_im=code;
    im=reshape(images(n_im,:),28,28); 
    Inputs(3:end-2,3:end-2)=im/256; %padding the image and normalize the pixels
    Inputs = reshape(Inputs,32,32); % inputs transposed    

    %display the image
        figure
        colormap gray
        imagesc(im');

    %% SIMULATION TEST
    formatSpec='%f';

        N_bit_test=Parallelism;

        % CONVERT INPUT DATA IN FIXED POINT    
        Inputs_fixed = fi(Inputs',0, Parallelism_in,Parallelism_in);

        %% PERFORM NETWORK OPERATIONS

        format long
        if Conv1_optimized==0
            [Out_conv1]=CONV1_function(Parallelism,Inputs_fixed);
        else 
            [Out_conv1,conv_op,conv_n]=CONV1_function_OPT(Parallelism,Inputs_fixed);
        end

        [Out_max1]=MAX1_function(Parallelism,Out_conv1);
        [Out_conv2]=CONV2_function(Parallelism,Out_max1);
        [Out_max2]=MAX2_function(Parallelism,Out_conv2);
        [Out_fc1]=FC1_function_speed(Parallelism,Out_max2);
        [Out_fc2]=FC2_function_speed(Parallelism,Out_fc1);
        [Out_fc3]=FC3_function_speed(Parallelism,Out_fc2);


        %% COMPARE RESULTS FROM MATLAB WITH THOSE FROM KERAS

        [Out_max,Predicted]=max(Out_fc3);
        [Out_min,Predicted_min]=min(Out_fc3);


        if Out_max == Out_min
            Predicted=-1;
            fprintf('- ERROR: no output differentiation!!!\n');
        else
            Predicted=Predicted-1;
        end

        new_image=datetime('now');
        fprintf('Parallelism: %d - Predicted: %d - Time: %s\n', Parallelism, Predicted,datestr(new_image));

fileIn = fopen('fileInputs.txt','w'); 
% to save input image to feed testbech
for r=1:32
    for c=1:32
        d = Inputs_fixed(r,c);
        fprintf(fileIn,'%s',d.bin);
    end
    fprintf(fileIn,'\n');
end
fclose('all')

stop_script=datetime('now');
disp(['Test ending at ',datestr(stop_script)]);
toc
fprintf('\n');

