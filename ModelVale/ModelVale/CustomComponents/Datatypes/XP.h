//
//  XP.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/19/22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XP : UIImageView <CAAnimationDelegate>
@property (nonatomic, strong) UIBezierPath* path;
@property (nonatomic, strong) CAShapeLayer* CALayer;

- (instancetype) initXP: (CGPoint)center path: (UIBezierPath*)path;
//- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag;

@end

NS_ASSUME_NONNULL_END
