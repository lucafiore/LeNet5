# import the necessary packages
from keras.models import Sequential
from keras.layers import ZeroPadding2D
from keras.layers.convolutional import Conv2D
from keras.layers.convolutional import MaxPooling2D
from keras.layers.core import Activation
from keras.layers.core import Flatten
from keras.layers.core import Dense
from keras import backend as K

class LeNet:
	@staticmethod #this means that this method can be called without an object for that class

	def build(numChannels, imgRows, imgCols, numClasses, #parameters passed in the main script
		activation="relu", weightsPath=None): 	     #weightsPath is addictional parameter passed to the main script
		
		# initialize the model
		model = Sequential() #this put layers sequentially as they are defined layer-by-layer (contrary of functional)
		inputShape = (imgRows, imgCols, numChannels)

		# if we are using "channels first", update the input shape
		# to verify the configuration go to $HOME/.keras/.keras.json
		if K.image_data_format() == "channels_first":
			inputShape = (numChannels, imgRows, imgCols)

		# this is a zero padding layer to resize dataset mnist into 32x32 images
		model.add(ZeroPadding2D(padding=(2, 2),input_shape=inputShape))
		# ---C1
		# define the first set of CONV => ACTIVATION => POOL layers
		model.add(Conv2D(filters=6, kernel_size=(5, 5), strides=(1, 1), padding="valid"))
		##model.add(Conv2D(filters=6, kernel_size=(5, 5), strides=(1, 1), padding="valid", input_shape=inputShape))
		# padding "same" to have a classic zero padding
		model.add(Activation(activation))  # we could write activation='relu' directly as argument of Conv2
		
		# ---S2		
		model.add(MaxPooling2D(pool_size=(2, 2), strides=(2, 2)))
		##model.add(AveragePooling2D(pool_size=(2, 2), strides=(2, 2)))

		# ---C3
		# define the second set of CONV => ACTIVATION => POOL layers
		model.add(Conv2D(filters=16, kernel_size=(5, 5), strides=(1, 1), padding="valid"))
		#model.add(Conv2D(filters=16, kernel_size=(5, 5), padding="same"))
		model.add(Activation(activation))

		# ---S4
		model.add(MaxPooling2D(pool_size=(2, 2), strides=(2, 2)))
		
		# ---C5
		# define the first FC => ACTIVATION layers
		model.add(Flatten()) #vectorize the input matrixs
		model.add(Dense(units=120, activation=None, use_bias=True)) #output=activation(dot(input,kernel) + bias)
							   # units --> dimensionality of the output space
		model.add(Activation(activation))

		# ---FC6		
		# define the second FC layer
		model.add(Dense(units=84, activation=None, use_bias=True))
		model.add(Activation(activation))

		# ---FC7	
		# define the third FC layer	
		model.add(Dense(units=numClasses, use_bias=True))

		# Output		
		# lastly, define the soft-max classifier
		model.add(Activation("softmax"))

		# if a weights path is supplied (indicating that the model was
		# pre-trained), then load the weights
		if weightsPath is not None:
			model.load_weights(weightsPath)

		# return the constructed network architecture
		return model

	
