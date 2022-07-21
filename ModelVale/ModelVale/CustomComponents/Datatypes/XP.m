//
//  XP.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/19/22.
//

#import "XP.h"

@implementation XP

- (instancetype) initXP: (CGPoint)center path: (UIBezierPath*)path {
    self = [super init];
    if (self) {
        self.center = center;
        self.path = path;
        self.XPImView = [UIImageView new]; //XXX todo refactor when subclassing imageview
        self.CALayer = [CAShapeLayer new];
    }
    return self;
}

@end
