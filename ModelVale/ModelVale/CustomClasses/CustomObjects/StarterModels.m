//
//  StarterModels.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/22/22.
//

#import "StarterModels.h"
#import "AvatarMLModel.h"
@import FirebaseStorage;
#import "User.h"

@implementation StarterModels

- (instancetype) initStarterModels {
    NSMutableArray* models = [NSMutableArray new];
    AvatarMLModel* hal = [[AvatarMLModel new] initWithModelName:@"UpdatableSqueezeNet" avatarName: @"Hal"];
    AvatarMLModel* avril = [[AvatarMLModel new] initWithModelName: @"Xception" avatarName: @"Avril"];
    avril.avatarImage = [UIImage imageNamed:@"koala"];
    AvatarMLModel* orin = [[AvatarMLModel new] initWithModelName:@"UpdatableResnetO" avatarName:@"Orin"];
    orin.avatarImage = [UIImage imageNamed:@"rhinio"];
    [models addObject:orin];
    [models addObject:avril];
    [models addObject:hal];
    self.models = models;
    return self;
}

-(void) uploadStarterModels: (User*)user db: (FIRFirestore*)db storage: (FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion {
    dispatch_group_t modelsGroup = dispatch_group_create();
    for(AvatarMLModel* model in self.models) {
        // Fetch if the model exists, create it if not, then update local model objects to update self.models
        dispatch_group_enter(modelsGroup);
        __block NSError* uploadError;
        [model uploadModel:user db:db storage:storage vc:vc completion:^(NSError * _Nonnull error) {
            uploadError = error;
            dispatch_group_leave(modelsGroup);
        }];
        dispatch_group_notify(modelsGroup, dispatch_get_main_queue(), ^{
            completion(uploadError);
        });
    }
}

@end
