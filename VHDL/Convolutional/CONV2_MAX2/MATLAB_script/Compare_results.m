% confronto i due file e plot graficamente


parallelism=8;
integer_part=5;
file1 = fopen('fileOutputsMATLAB_conv2.txt','r');
file2 = fopen('fileOutputsVHDL_conv2.txt','r');

%file1 read
tline = fgetl(file1); % read first line
i=1;
bin_values1(i,:)=tline;
i=i+1;
while ischar(tline) 
    %disp(tline)
    tline = fgetl(file1);
    bin_values1(i,:)=tline;
    i=i+1;
end
bin_values1(end,:)=[];

len=size(bin_values1);
for i=1:len(1)
   dec_values1(i)=CA2_bin2dec(bin_values1(i,:),parallelism,integer_part);
end

% file2 read
tline = fgetl(file2); % read first line
i=1;
bin_values2(i,:)=tline;
i=i+1;
while ischar(tline) 
    %disp(tline)
    tline = fgetl(file2);
    bin_values2(i,:)=tline;
    i=i+1;
end
bin_values2(end,:)=[];

len=size(bin_values2);
for i=1:len(1)
   dec_values2(i)=CA2_bin2dec(bin_values2(i,:),parallelism,integer_part);
end
fclose(file1)
fclose(file2)
plot(dec_values1-dec_values2,'o-')
title('Output of Modelsim vs output of MATLAB absolute error - CONV2\_MAX2');
ylim([-100 100]);
xlabel('Output elements');
ylabel('Absolute error Modelsim vs MATLAB');
