# USAGE
# python lenet_mnist.py --save-model 1 --weights output/lenet_weights.hdf5
# python lenet_mnist.py --load-model 1 --weights output/lenet_weights.hdf5

# import the necessary packages
from pyimagesearch.cnn.networks.lenet import LeNet
from sklearn.model_selection import train_test_split
from keras.datasets import mnist
from keras.optimizers import SGD
from keras.utils import np_utils
from keras import backend as K
from keras.models import Model #added to get intermediate outputs
import numpy as np
import argparse
import cv2
import os

def lenet_def(mode,n_epoch):

	# grab the MNIST dataset (if this is your first time running this
	# script, the download may take a minute -- the 55MB MNIST dataset
	# will be downloaded)
	print("[INFO] downloading MNIST...")
	((trainData, trainLabels), (testData, testLabels)) = mnist.load_data()

	# if we are using "channels first" ordering, then reshape the
	# design matrix such that the matrix is:
	# num_samples x depth x rows x columns
	if K.image_data_format() == "channels_first":
		trainData = trainData.reshape((trainData.shape[0], 1, 28, 28))
		testData = testData.reshape((testData.shape[0], 1, 28, 28))

	# otherwise, we are using "channels last" ordering, so the design
	# matrix shape should be: num_samples x rows x columns x depth
	else:
		trainData = trainData.reshape((trainData.shape[0], 28, 28, 1))
		testData = testData.reshape((testData.shape[0], 28, 28, 1))

	# scale data to the range of [0, 1]
	trainData = trainData.astype("float32") / 256.0
	testData = testData.astype("float32") / 256.0

	# transform the training and testing labels into vectors in the
	# range [0, classes] -- this generates a vector for each label,
	# where the index of the label is set to `1` and all other entries
	# to `0`; in the case of MNIST, there are 10 class labels
	trainLabels = np_utils.to_categorical(trainLabels, 10)
	testLabels = np_utils.to_categorical(testLabels, 10)

	#################################################################################
	# initialize the optimizer and model
	print("[INFO] compiling model...")
	opt = SGD(lr=0.01)
	model = LeNet.build(numChannels=1, imgRows=28, imgCols=28,
		numClasses=10,
		weightsPath="output/Output_Keras/lenet_weights.hdf5" if mode=='2' else None) #where to load the weight
	model.compile(loss="categorical_crossentropy", optimizer=opt,
		metrics=["accuracy"])


	# save a summary of the Network
	from contextlib import redirect_stdout

	with open('model_summary.txt', 'w') as summary:
		with redirect_stdout(summary):
			model.summary()

	# save model configurations
	model_config = model.get_config()
	import json
	with open('model_config.txt','w+') as conf:
	     	conf.write(json.dumps(model_config)) # use `pickle.loads` to do the reverse


	##################################################################################
	# train and evaluate the model if we are not loading a pre-existing model
	if mode=='1':
		print("[INFO] training...")
		model.fit(trainData, trainLabels, batch_size=128, epochs=n_epoch,
			verbose=1)

		# show the accuracy on the testing set
		print("[INFO] evaluating...")
		(loss, accuracy) = model.evaluate(testData, testLabels,
			batch_size=128, verbose=1)
		print("[INFO] accuracy: {:.2f}%".format(accuracy * 100))

		# save weights 
		print("[INFO] dumping weights to file...")
		model.save_weights("output/Output_Keras/lenet_weights.hdf5", overwrite=True) # save weights to a file
		os.system("h5dump ./output/Output_Keras/lenet_weights.hdf5 > ./output/Output_Keras/weights.txt")

	file_outputs = open("output/Output_Keras/outputs_layers.txt","w") # open file to save intermediate outputs

	test_number=-1
	test_choice=input("New test? [y] or [n]\n")
	while test_choice!='n':
		test_number=test_number+1
		while test_choice!='y' and test_choice!='n':
			test_choice=input("Enter [y] or [n]\n")
		
		if test_choice=='n':
				break	
		
		# randomly select testing digits
		i = test_number
		# write outputs for each layer
		file_outputs.write("For test "+ str(i) +"\n\n") # write the test input code
		for layer in model.layers: # for loop to scan each layer for each test
			intermediate_layer_model = Model(inputs=model.input, outputs=model.get_layer(layer.name).output)
			intermediate_output = intermediate_layer_model.predict(testData[np.newaxis, i]) # get data predicted
			file_outputs.write(layer.name+"\n") # write all intermediate outputs
			intermediate_output.tofile(file_outputs, sep=" ", format="%s")
			file_outputs.write("\n\n")

		# classify the digit
		probs = model.predict(testData[np.newaxis, i])
		prediction = probs.argmax(axis=1)
		
		# write results for each test
		file_outputs.write("Predicted: {}, Actual: {}".format(prediction[0],np.argmax(testLabels[i]))+"\n\n\n") 

		# extract the image from the testData if using "channels_first" ordering
		if K.image_data_format() == "channels_first":
			image = (testData[i][0] * 256).astype("uint8")
		

		# otherwise we are using "channels_last" ordering
		else:
			image = (testData[i] * 256).astype("uint8")
		
		# copy test inputs and outputs into a file
		file_test = open("output/Tests/inputs_test_n{0}.txt".format(test_number),"w")
		image_tocopy = cv2.copyMakeBorder(image, 2, 2, 2, 2, cv2.BORDER_CONSTANT)
		image_tocopy.tofile(file_test, sep=" ", format="%s")
		file_test.close()
		file_test = open("output/Tests/outputs_test_n{0}.txt".format(test_number),"w")
		Model(inputs=model.input, outputs=model.get_layer('dense_3').output).predict(testData[np.newaxis, i]).tofile(file_test, sep=" ", format="%s")
		file_test.close()

		# merge the channels into one image
		image = cv2.merge([image] * 3)

		# resize the image from a 28 x 28 image to a 96 x 96 image to show it
		image = cv2.resize(image, (96, 96), interpolation=cv2.INTER_LINEAR)

		# show the image and prediction
		cv2.putText(image, str(prediction[0]), (5, 20),
					cv2.FONT_HERSHEY_SIMPLEX, 0.75, (0, 255, 0), 2)
		print("[INFO] Predicted: {}, Actual: {}".format(prediction[0],
			np.argmax(testLabels[i])))
		cv2.imshow("Digit", image)
		cv2.waitKey(0) # press a key on the image window, then answer for a new test
		print("Press a key on the image and then make the choice in order to make sure you have seen the image!")
		test_choice=input("New test? [y] or [n]\n")
	print("[INFO] Exiting...")
	file_outputs.close()
