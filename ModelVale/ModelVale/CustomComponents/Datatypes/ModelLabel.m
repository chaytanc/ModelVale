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
#import "UIViewController+PresentError.h"

@implementation ModelLabel

+ (nonnull NSString *)parseClassName {
    return @"ModelLabel";
}

@dynamic label;
@dynamic testTrainType;
@dynamic labelModelData;
@dynamic numPerLabel;


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

- (void) addLabelModelData:(NSArray *)objects {
    [self.labelModelData addObjectsFromArray:objects];
    self.numPerLabel += objects.count;
}


- (void) updateModelLabelWithCompletion: (PFBooleanResultBlock  _Nullable)completion withVC: (UIViewController*)vc {
    [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if(succeeded) {
            NSLog(@"ModelLabel saved!");
        }
        else {
            [vc presentError:@"Failed to update label" message:error.localizedDescription error:error];
        }
        completion(succeeded, error);
    }];
}


@end
