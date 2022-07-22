//
//  AvatarMLModel.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/14/22.
//

#import "AvatarMLModel.h"

CGFloat const MAXHEALTH = 500;

@implementation AvatarMLModel

//XXX what is difference between doing this and having a class method that makes an instance, sets these, and returns that instance
- (instancetype) initWithName: (NSString*)name model: (UpdatableSqueezeNet*)model {
    self = [super init];
    if(self){
        self.name = name;
        self.health = MAXHEALTH;
        self.model = model;
    }
    return self;
}

@end
