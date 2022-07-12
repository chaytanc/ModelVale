//
//  ClassifierLabel.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/11/22.
//

#import "ModelLabel.h"
#import "TestTrainEnum.h"

@implementation ModelLabel

- (ModelLabel*) initEmptyLabel: (NSString*)label testTrainType: (testTrain)testTrainType sectionInd: (NSInteger)sectionInd {
    self.numPerLabel = 0;
    self.label = label;
    self.testTrainType = testTrainType;
    self.sectionInd = sectionInd;
    self.labelModelData = [NSMutableArray new];
    return self;
}

- (ModelLabel*) initWithData: (NSString*)label testTrainType: (testTrain)testTrainType sectionInd: (NSInteger)sectionInd data: (NSMutableArray*) data {
    self.numPerLabel = data.count;
    self.label = label;
    self.testTrainType = testTrainType;
    self.sectionInd = sectionInd;
    self.labelModelData = data;
    return self;
}

- (void) addLabelModelData:(NSArray *)objects {
    [self.labelModelData addObjectsFromArray:objects];
    self.numPerLabel += objects.count;
}

@end
