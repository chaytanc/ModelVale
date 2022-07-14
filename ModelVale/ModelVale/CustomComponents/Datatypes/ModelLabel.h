//
//  ModelLabel.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/11/22.
//

#import <Foundation/Foundation.h>
#import "TestTrainEnum.h"
@class ModelData;

NS_ASSUME_NONNULL_BEGIN

@interface ModelLabel : NSObject {
    testTrain mode;
}
@property (nonatomic, weak) NSString* label;
@property (nonatomic, assign) NSInteger numPerLabel;
@property (nonatomic, assign) NSString* testTrainType;
@property (nonatomic, strong) NSMutableArray<ModelData*>* labelModelData; // Reference to all ModelData that has this label

- (ModelLabel*) initEmptyLabel: (NSString*)label testTrainType: (NSString*) testTrainType;
- (ModelLabel*) initWithData: (NSString*)label testTrainType: (NSString*)testTrainType data: (NSMutableArray*) data;

- (void) addLabelModelData:(NSArray *)objects;

@end

NS_ASSUME_NONNULL_END
