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
        self.CALayer = [CAShapeLayer new];
    }
    return self;
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
    [self setHidden:YES];
}

- (void) addXPFadeOutAnimation: (XP*)xp {
    CAKeyframeAnimation * fadeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    fadeAnimation.duration = 1.5;
    fadeAnimation.autoreverses = NO;
    fadeAnimation.keyTimes = [NSArray arrayWithObjects:  [NSNumber numberWithFloat:0.0],
                                                            [NSNumber numberWithFloat:1.5], nil];

    fadeAnimation.values = [NSArray arrayWithObjects:    [NSNumber numberWithFloat:1.0],
                                                    [NSNumber numberWithFloat:0.0], nil];
    fadeAnimation.removedOnCompletion = YES;
    [xp.layer addAnimation:fadeAnimation forKey:@"fadeOut"];
}
@end
