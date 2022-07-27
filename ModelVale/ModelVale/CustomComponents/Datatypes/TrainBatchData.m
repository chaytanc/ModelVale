//
//  TrainBatchData.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/12/22.
//

#import "TrainBatchData.h"
#import "CoreML/CoreML.h"
#import "ModelData.h"
#import "ModelLabel.h"
#import "UpdatableSqueezeNet.h"

// This gets all the training data available for one model
//TODO XXX add beenUsed boolean field to modelData to make sure we can't keep retraining on the same data
@implementation TrainBatchData

- (TrainBatchData*) initTrainBatch: (MLImageConstraint*) imageConstraint {
    //XXX TODO use data from query instead of fake data
    
    self.trainBatchLabels = [NSMutableArray new];
    // We create two labels, the first has two images the second has one image, this represents all the training data that was
    ModelLabel* fakeLabel = [[ModelLabel new] initEmptyLabel:@"alp" testTrainType:dataTypeEnumToString(Train)];
    UIImage* testImage = [UIImage imageNamed:@"mountain"];
    ModelData* fakeData = [ModelData initWithImage:testImage label:fakeLabel.label];
    [fakeLabel addLabelModelData:@[fakeData]];
    testImage = [UIImage imageNamed:@"rivermountain"];
    fakeData = [ModelData initWithImage:testImage label:fakeLabel.label];
    [fakeLabel addLabelModelData:@[fakeData]];
    [self.trainBatchLabels addObject:fakeLabel];
    fakeLabel = [[ModelLabel new] initEmptyLabel:@"vulture" testTrainType:dataTypeEnumToString(Train)];
    testImage = [UIImage imageNamed:@"snowymountains"];
    fakeData = [ModelData initWithImage:testImage label:fakeLabel.label];
    [fakeLabel addLabelModelData:@[fakeData]];
    [self.trainBatchLabels addObject:fakeLabel];
    
    [self setBatchFeatureProvider:imageConstraint];
    
    return self;
}

// Sets fetch data from Parse with Train type and set trainBatch with it
- (void) fetchData: (void (^) (NSArray*))completion {
    // Todo XXX
}

- (void) setBatchFeatureProvider: (MLImageConstraint*) imageConstraint {
    NSMutableArray* featureArray = [NSMutableArray new];
    if(self.trainBatchLabels == nil) {
        [NSException raise:@"Invalid training data" format:@"self.trainBatchLabels was empty in TrainBatchData"];
    }
    for (id label in self.trainBatchLabels) {
        ModelLabel* l = ((ModelLabel*) label);
        for (id data in l.labelModelData) {
            ModelData* d = (ModelData*) data;
            MLDictionaryFeatureProvider* featureProv = [d getUpdatableDictionaryFeatureProvider:imageConstraint];
            [featureArray addObject:featureProv];
        }
    }
    self.trainBatch = [[MLArrayBatchProvider new] initWithFeatureProviderArray:featureArray];
}

@end
