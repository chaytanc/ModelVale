//
//  StarterModels.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/22/22.
//

#import "StarterModels.h"
#import "AvatarMLModel.h"
#import "Parse/Parse.h"

@implementation StarterModels

-(instancetype) initStarterModels: (PFUser*)user {
    NSMutableArray* models = [NSMutableArray new];
    AvatarMLModel* hal = [[AvatarMLModel new] initWithModelName:@"UpdatableSqueezeNet" avatarName: @"Hal" user: user];
    [models addObject:hal];
    self.models = models;
    return self;
}

@end
