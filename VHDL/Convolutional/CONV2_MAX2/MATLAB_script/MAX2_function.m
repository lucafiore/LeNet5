function [Outputs] =MAX2_function(parallelism,Inputs)

% Input_size= 28x28x6
% Output_size=14x14x6
inputSize = 10;
outputSize = inputSize/2;
numInputs = 16;
parallelism_in=parallelism;
parallelism_out=parallelism;


%% GENERATION OUTPUTS
% Outputs=ones(outputSize*outputSize*numInputs,1);

CNT=1;
%% MAX_POOLING

for i=1:outputSize
    for j=1:outputSize
        for k=1:numInputs
            t=max([Inputs(2*i-1,2*j-1,k),Inputs(2*i-1,2*j,k),Inputs(2*i,2*j-1,k),Inputs(2*i,2*j,k)]);
            if t<0
                Outputs(CNT)=0;
            else
                Outputs(CNT)=t;
            end
            CNT=CNT+1;
        end
    end
end


end
