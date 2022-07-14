//
//  ClassifierLabel.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/11/22.
//

#import "ModelLabel.h"
#import "ModelData.h"
#import "TestTrainEnum.h"
#import "Parse/Parse.h"

@implementation ModelLabel

- (instancetype) initEmptyLabel: (NSString*)label testTrainType: (NSString*)testTrainType {
    self = [super init];
    if (self) {
        self.numPerLabel = 0;
        self.label = label;
        self.testTrainType = testTrainType;
        self.labelModelData = [NSMutableArray new];
    }
    return self;
}

- (instancetype) initWithData: (NSString*)label testTrainType: (NSString*)testTrainType
                         data: (NSMutableArray*) data {
    self = [super init];
    if(self) {
        self.numPerLabel = data.count;
        self.label = label;
        self.testTrainType = testTrainType;
        self.labelModelData = data;
    }
    return self;
}

// Init from database response
//XXX todo check that Parse response is actually pfobject, maybe rename argument better
- (instancetype) initWithResponse: (PFObject*) response {
    self = [super init];
    if(self) {
        self.numPerLabel = response[@"numPerLabel"];
        self.label = response[@"label"];
        self.testTrainType = response[@"testTrainType"];
        NSMutableArray* dataArray = response[@"labelModelData"]; // TODO XXX verify that Parse has ModelData type in this array
        self.labelModelData = [ModelData initModelDataArrayFromArray:dataArray label:self];
    }
    return self;
}

- (void) addLabelModelData:(NSArray *)objects {
    [self.labelModelData addObjectsFromArray:objects];
    self.numPerLabel += objects.count;
}

@end
