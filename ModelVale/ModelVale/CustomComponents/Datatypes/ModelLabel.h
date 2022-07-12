//
//  ClassifierLabel.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/11/22.
//

#import <Foundation/Foundation.h>
#import "TestTrainEnum.h"

NS_ASSUME_NONNULL_BEGIN

@interface ModelLabel : NSObject {
    testTrain mode;
}
@property (nonatomic, weak) NSString* label;
@property (nonatomic, assign) NSInteger numPerLabel;
@property (nonatomic, assign) testTrain testTrainType;
@property (nonatomic, strong) NSMutableArray* labelModelData; // Array of ModelData


- (ModelLabel*) initEmptyLabel: (NSString*)label testTrainType: (testTrain) testTrainType;
- (ModelLabel*) initWithData: (NSString*)label testTrainType: (testTrain)testTrainType data: (NSMutableArray*) data;

- (void) addLabelModelData:(NSArray *)objects;

@end

NS_ASSUME_NONNULL_END
