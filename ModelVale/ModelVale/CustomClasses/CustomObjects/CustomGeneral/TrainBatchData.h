//
//  TrainBatchData.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/12/22.
//

#import <Foundation/Foundation.h>
#import "CoreML/CoreML.h"
@class ModelLabel;

NS_ASSUME_NONNULL_BEGIN

@interface TrainBatchData : NSObject
@property (nonatomic, strong) MLArrayBatchProvider* trainBatch;
@property (nonatomic, strong) NSMutableArray* trainBatchLabels; // Array of ModelLabel

- (instancetype) initTrainBatch: (MLImageConstraint*) imageConstraint trainBatchLabels: (NSMutableArray<ModelLabel*>*)trainBatchLabels;
- (instancetype) initEmptyTrainBatch: (MLImageConstraint*) imageConstraint;
- (void) setBatchFeatureProvider: (MLImageConstraint*) imageConstraint;


@end

NS_ASSUME_NONNULL_END
