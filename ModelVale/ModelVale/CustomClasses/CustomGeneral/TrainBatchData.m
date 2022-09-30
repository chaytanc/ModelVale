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

// Given the ModelLabels to use, this provides an interface to use those data to retrain models with CoreML's MLArrayBatchProvider
@implementation TrainBatchData

- (instancetype) initTrainBatch: (MLImageConstraint*) imageConstraint trainBatchLabels: (NSMutableArray<ModelLabel*>*)trainBatchLabels {
    self = [super init];
    if(self) {
        self.trainBatchLabels = trainBatchLabels;
        [self setBatchFeatureProvider:imageConstraint];
    }
    return self;
}

- (instancetype) initEmptyTrainBatch: (MLImageConstraint*) imageConstraint {
    self = [super init];
    if(self) {
        self.trainBatchLabels = [NSMutableArray new];
        [self setBatchFeatureProvider:imageConstraint];
    }
    return self;
}

- (void) setBatchFeatureProvider: (MLImageConstraint*) imageConstraint {
    if(self.trainBatchLabels == nil) {
        [NSException raise:@"Invalid training data" format:@"self.trainBatchLabels was empty in TrainBatchData"];
    }
    // Make a MLDictionaryFeatureProvider for each label and data pair and add to array of them
    NSMutableArray* featureArray = [NSMutableArray new];
    for (ModelLabel* l in self.trainBatchLabels) {
        for (ModelData* data in l.localData) {
            MLDictionaryFeatureProvider* featureProv = [data getUpdatableDictionaryFeatureProvider:imageConstraint];
            [featureArray addObject:featureProv];
        }
    }
    self.trainBatch = [[MLArrayBatchProvider new] initWithFeatureProviderArray:featureArray];
}

@end
