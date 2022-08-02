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
    [models addObject:hal];
    self.models = models;
    return self;
}

-(void) uploadStarterModels: (NSString*)uid db: (FIRFirestore*)db vc: (UIViewController*)vc {
    for(AvatarMLModel* model in self.models) {
        [model uploadModelToUserWithViewController:uid db:db vc:vc];
    }
}

@end
