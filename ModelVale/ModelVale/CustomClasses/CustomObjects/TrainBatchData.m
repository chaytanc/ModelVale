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

//XXX TODO add beenUsed boolean field to modelData to make sure we can't keep retraining on the same data
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
    NSMutableArray* featureArray = [NSMutableArray new];
    if(self.trainBatchLabels == nil) {
        [NSException raise:@"Invalid training data" format:@"self.trainBatchLabels was empty in TrainBatchData"];
    }
    for (id label in self.trainBatchLabels) {
        ModelLabel* l = ((ModelLabel*) label);
        for (id data in l.localData) {
            ModelData* d = (ModelData*) data;
            MLDictionaryFeatureProvider* featureProv = [d getUpdatableDictionaryFeatureProvider:imageConstraint];
            [featureArray addObject:featureProv];
        }
    }
    self.trainBatch = [[MLArrayBatchProvider new] initWithFeatureProviderArray:featureArray];
}

@end
