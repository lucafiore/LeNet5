#Author - Luca Fiore
#This script is developed in order to produce N text file with weights and biases for each layer of the network in decimal form. This weights are converted from "weights.txt" file output of Keras but not useful for HW simulation.

import os

###### FLAGS ######

flag_find_layers=0
layers_list=[]
Layer_with_weights=0
biases=0
kernel=0
data=0

##################

with open("Output_Keras/weights.txt", "+r") as in_file:
	for line in in_file:
		if (flag_find_layers==1):
			if "}" in line:
				flag_find_layers=2 #The list of all layers is finished
			else:
				if 'DATA' in line: 
					layers_list=layers_list
					#do nothing			
				else:				
					line=line.replace(',', '')
					layers=line.split()[-1]
					if ('\\' in layers):				
						layers=layers.split("\\")[0] 
					layers=layers.strip('\"') 
					#print(isinstance(layers, str))
					layers_list.append(layers)

		if "DATASPACE  SIMPLE" in line and flag_find_layers==0:
			flag_find_layers=1 #I have found where are listed all layers 

		if flag_find_layers==2:
			if "GROUP" in line:
				biases=0						
				kernel=0
				data=0	
				Layer_with_weights=0
				for lay in layers_list:
					if lay in line: # if I found something like (GROUP "name of any layer")
						Layer_with_weights=1
						layer_good=lay

			elif  ("DATASET" in line and Layer_with_weights==1) or (biases==1 or kernel==1):
				#bias_kernel=line.split()[1].strip('\"')			
				if "bias:0" in line:
					#create a file with biases and kernel for each layer 
					fileName_bias = "./Bias/Bias_{0}.txt".format(layer_good)
					fileName_weights = "./Weights/Weights_{0}.txt".format(layer_good)
					biases=1
					try:
						# Create target File
						file_bias=open(fileName_bias,'x')
						file_weights=open(fileName_weights,'x')
						#file_weights.write("START - Biases\n\n")
						print("File " , file_bias ,  "and file", file_weights, " Created ") 
					except FileExistsError:
						print("Files already exists! Do you want to remove them? Y - N")
						ans=input()
						if (ans=='yes' or ans=='y' or ans=='Y'):
							os.system('rm ./Weights/Weights_*')
							os.system('rm ./Bias/Bias_*')
							exit()
						else:						
							exit()

				elif "kernel:0" in line:
					kernel=1				

				elif "DATA" in line:
					data=1

				elif data==1 and biases==1:
					# save biases
					if ('}' not in line):
						line=line.split()[1:]
						file_bias.write(' '.join(line))
					else:
						biases=0;
						#file_bias.write("\n\nSTART - Weights\n\n")


				elif data==1 and kernel==1:
					# save weights
					if ('}' not in line):
						line=line.split()[1:]
						file_weights.write(' '.join(line))
					else: kernel=0;
		
				
file_bias.close()
file_weights.close()



