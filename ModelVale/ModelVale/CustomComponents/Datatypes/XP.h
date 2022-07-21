//
//  XP.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/19/22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XP : UIImageView //XXX todo make this subclass UIImageView
@property (nonatomic, strong) UIBezierPath* path;
@property (nonatomic, strong) CAShapeLayer* CALayer;

- (instancetype) initXP: (CGPoint)center path: (UIBezierPath*)path;
@end

NS_ASSUME_NONNULL_END
