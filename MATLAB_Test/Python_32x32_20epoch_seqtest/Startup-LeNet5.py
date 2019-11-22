#use this script to start-up your LeNet5 model

# import the necessary packages
#import lenet_mnist
import os
import sys
import lenet_mnist

n_epoch=10
print("\nLeNet5\n\
Authors:Fiore-Neri-Zheng\n")
print("Select a number from the choices below:\n \
	1) Train LeNet5 with MNIST Dataset\n \
	2) Load LeNet5 pretrained weights\n \
	3) Exit")

choice=input('choice: ');

while (choice not in ['1','2','3']):
	print("Invalid number, please enter a valid number:\n \
	1) Train LeNet5 with MNIST Dataset\n \
	2) Load LeNet5 pretrained weights\n \
	3) Exit")
	choice=input('choice: ')
else:
	if (choice=='3'):
		sys.exit("You have selected 'Exit'")
	if (choice=='1'):
		n_epoch=input('Enter number of epochs for training (max value 50).\nNumber of epochs: ')
		while(n_epoch.isdigit()==False):
			print("Invalid character, please enter a valid number or 'exit' to quit.")
			n_epoch=input('Number of epochs: ')
			if (n_epoch=='exit'):
				sys.exit("You have selected 'Exit'")
		while (int(n_epoch) not in range(1,51)):
			print("Invalid number, please enter a valid number or 'exit' to quit.")
			n_epoch=input('Number of epochs: ')
			if (n_epoch=='exit'):
				sys.exit("You have selected 'Exit'")
	lenet_mnist.lenet_def(choice,int(n_epoch))
		
			

