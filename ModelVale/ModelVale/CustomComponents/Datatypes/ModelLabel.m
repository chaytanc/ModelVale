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

- (instancetype) initEmptyLabel: (NSString*)label testTrainType: (NSString*)testTrainType {
    self = [ModelLabel object];
    if (self) {
        self.label = label;
        self.testTrainType = testTrainType;
        [self addObjectsFromArray:@[] forKey:@"labelModelData"];

    }
    return self;
}

- (instancetype) initWithData: (NSString*)label testTrainType: (NSString*)testTrainType
                         data: (NSMutableArray*)data objectId: (NSString*)objectId {
    self = [ModelLabel object];
    if(self) {
        self.label = label;
        self.testTrainType = testTrainType;
        [self addObjectsFromArray:data forKey:@"labelModelData"];
        self.objectId = objectId;
    }
    return self;
}

//XXX todo remove this func
- (void) addLabelModelData:(NSArray *)objects {
    [self.labelModelData addObjectsFromArray:objects];
}


- (void) updateModelLabel: (UIViewController*)vc completion: (PFBooleanResultBlock  _Nullable)completion {
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
