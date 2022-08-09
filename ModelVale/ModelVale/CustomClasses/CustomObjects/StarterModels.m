//
//  StarterModels.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/22/22.
//

#import "StarterModels.h"
#import "AvatarMLModel.h"
@import FirebaseStorage;

@implementation StarterModels

-(instancetype) initStarterModels: (NSString*)uid {
    NSMutableArray* models = [NSMutableArray new];
    AvatarMLModel* hal = [[AvatarMLModel new] initWithModelName:@"UpdatableSqueezeNet" avatarName: @"Hal" uid: uid];
    AvatarMLModel* avril = [[AvatarMLModel new] initWithModelName: @"Xception" avatarName: @"Avril" uid: uid];
    avril.avatarImage = [UIImage imageNamed:@"koala"];
    [models addObject: avril];
    [models addObject:hal];
    self.models = models;
    return self;
}

-(void) uploadStarterModels: (NSString*)uid db: (FIRFirestore*)db storage: (FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion {
    for(AvatarMLModel* model in self.models) {
        [model uploadModelToUserWithViewController:uid db:db storage:storage vc:vc completion:completion];
    }
}

@end
