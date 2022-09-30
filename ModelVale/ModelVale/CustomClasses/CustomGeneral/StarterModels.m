//
//  StarterModels.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/22/22.
//

#import "StarterModels.h"
#import "AvatarMLModel.h"
#import "StarterConstants.h"
@import FirebaseStorage;
#import "User.h"

@implementation StarterModels

- (instancetype) initStarterModels {
    self.models = [NSMutableArray new];
    [self addStarters];

    return self;
}

- (void) addStarters {
    for(int i=0; i < kStarterNames.count; i ++) {
        NSString* name = kStarterNames[i];
        NSString* imageName = kImagesList[i];
        NSString* modelType = kModelTypes[i];
        AvatarMLModel* model = [[AvatarMLModel new] initWithModelName:modelType avatarName:name];
        model.avatarImage = [UIImage imageNamed:imageName];
        [self.models addObject:model];
    }
}

-(void) uploadStarterModels: (User*)user db: (FIRFirestore*)db storage: (FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion {
    dispatch_group_t modelsGroup = dispatch_group_create();
    for(AvatarMLModel* model in self.models) {
        // Fetch if the model exists, create it if not, then update local model objects to update self.models
        dispatch_group_enter(modelsGroup);
        __block NSError* uploadError;
        [model uploadStarterModel:user db:db storage:storage vc:vc completion:^(NSError * _Nonnull error) {
            uploadError = error;
            [user.userModelDocRefs addObject:model.avatarName];
            dispatch_group_enter(modelsGroup);
            [user updateUserModelDocRefs:db vc:vc completion:^(NSError * _Nonnull error) {
                uploadError = error;
                dispatch_group_leave(modelsGroup);
            }];
            dispatch_group_leave(modelsGroup);
        }];

        dispatch_group_notify(modelsGroup, dispatch_get_main_queue(), ^{
            completion(uploadError);
        });
    }
}

@end
