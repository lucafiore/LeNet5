function [Outputs] =MAX1_function(parallelism,Inputs)

% Input_size= 28x28x6
% Output_size=14x14x6
inputSize = 28;
outputSize = inputSize/2;
numInputs = 6;
parallelism_in=parallelism;
parallelism_out=parallelism;


%% GENERATION OUTPUTS
% Outputs=ones(outputSize,outputSize,numInputs);


%% MAX_POOLING
for k=1:numInputs
    for i=1:outputSize
        for j=1:outputSize
            t=max([Inputs(2*i-1,2*j-1,k),Inputs(2*i-1,2*j,k),Inputs(2*i,2*j-1,k),Inputs(2*i,2*j,k)]);
            if t<0
                Outputs(i,j,k)=0;
            else
                Outputs(i,j,k)=t;
            end
        end
    end
end

end
