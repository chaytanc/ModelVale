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
//XXX not sure we want section ind rn
@property (nonatomic, assign) NSInteger sectionInd;

@property (nonatomic, weak) NSString* label;
@property (nonatomic, assign) NSInteger numPerLabel; // Number of data objects associated with this label XXX todo update with adding more data
@property (nonatomic, assign) testTrain testTrainType;
// Add reference to which model the label belongs?? only if we reuse same label among diff models, which if they contain data, we don't
@property (nonatomic, strong) NSMutableArray* labelModelData; // Array of ModelData


- (ModelLabel*) initEmptyLabel: (NSString*)label testTrainType: (testTrain) testTrainType sectionInd: (NSInteger) sectionInd;

//Todo, also increment numPerLabel
- (void) addLabelModelData:(NSArray *)objects;

@end

NS_ASSUME_NONNULL_END
