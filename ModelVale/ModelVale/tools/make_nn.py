import coremltools
import coremltools.proto.FeatureTypes_pb2 as ft
from coremltools.models.neural_network import NeuralNetworkBuilder, SgdParams
import pdb
#import sys

def get_updatable_layers(spec):
	layers_to_update = []
	for layer in spec.layers:
		is_loss_layer(layer)
		if is_updatable_conv(layer):
			print('Adding', layer.name, 'to layers to update')
			layers_to_update.append(layer.name)
	return layers_to_update

def is_updatable_conv(layer):
	#if ('dense' in layer.name) and not (('activation' in layer.name) 
		#and ('merge' in layer.name))
	return layer.WhichOneof("layer") == 'convolution' and not (
		('activation' in layer.name) or ('padding' in layer.name) 
		or ('merge' in layer.name) 
		or ('normalization' in layer.name)
		or ('Norm' in layer.name)
		)

def is_updatable_innerProduct(layer):
	return layer.WhichOneof("layer") == 'innerProduct' and \
		('dense' in layer.name) and not (
		('activation' in layer.name) or ('padding' in layer.name) 
		or ('merge' in layer.name) or ('pooling' in layer.name)
		or ('normalization' in layer.name)
		)

def is_loss_layer(layer):
	if 'lossLayer' in layer.name:
		pdb.set_trace()

def manual_updatable_layers():
	layers_to_update = []
	#layers_to_update.append('xception/predictions/BiasAdd')
	layers_to_update.append('xception/block14_sepconv2_bn/FusedBatchNormV3_nchw')
	layers_to_update.append('xception/block14_sepconv2/separable_conv2d/depthwisex')
	layers_to_update.append('xception/block14_sepconv1_bn/FusedBatchNormV3_nchw')
	layers_to_update.append('xception/block14_sepconv1/separable_conv2d/depthwisex')
	return layers_to_update

def resnet_updatable():
	layers_to_update = []
	layers_to_update.append('fc1000')
	return layers_to_update

def squeezenet_updatable():
	layers_to_update = []
	layers_to_update.append('conv1')
	return layers_to_update

def make_updatable(builder):
	# Setup retraining hyperparams
	builder.set_epochs(10, [1, 10, 50])
	# Using the SDG optimizer:
	sgd_params = SgdParams(lr=0.001, batch=8, momentum=0)
	sgd_params.set_batch(8, [1, 2, 8, 16])
	builder.set_sgd_optimizer(sgd_params)

	#layers_to_update = manual_updatable_layers()
	layers_to_update = resnet_updatable()
	builder.make_updatable(layers_to_update)
	builder.set_categorical_cross_entropy_loss(name="lossLayer", input="classLabelProbs")


############################################

# Source
# https://machinethink.net/blog/coreml-training-part4/
# https://www.iosdevie.com/p/coreml3-updatable-retrainable-model
# https://coremltools.readme.io/docs/updatable-neural-network-classifier-on-mnist-dataset

#"./xception_imagenet.mlmodel"
model_path = "./Resnet50.mlmodel"
#"./UpdatableXception.mlmodel"
output_path = "./UpdatableResnetO.mlmodel"

model = coremltools.models.MLModel(model_path)
spec = model._spec
builder = NeuralNetworkBuilder(spec=spec)

# Set things
builderspec = builder.spec.description
input = builder.spec.description.input[0]
input.shortDescription = "Example training image"

builderspec.output[0].shortDescription = 'Probabilities of class'
builderspec.output[1].shortDescription = 'Predicted class'
#builderspec.trainingInput.extend([builderspec.input[0]])
#builderspec.trainingInput.extend([builderspec.output[0]])
#builderspec.trainingInput[0].shortDescription = "Training image"
#builderspec.trainingInput[1].shortDescription = "True label"

pdb.set_trace()
make_updatable(builder)

model.save(output_path)
