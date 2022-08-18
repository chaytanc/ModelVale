//
//  HealthBar.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/14/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
extern CGFloat const kWidthMarginMultiple;
extern CGFloat const kHeightMarginMultiple;

@interface HealthBarView : UIView
@property (nonatomic, strong) CAShapeLayer* barShapeLayer;
@property (nonatomic, strong) CAShapeLayer* healthShapeLayer;
@property (nonatomic, strong) UIBezierPath* barPath;
@property (nonatomic, strong) UIBezierPath* healthPath;
@property (nonatomic, assign) NSInteger barWidth;
@property (nonatomic, assign) NSInteger barHeight;
@property (nonatomic, assign) CGRect barRect;
@property (nonatomic, assign) CGPoint leftTopPoint;
@property (nonatomic, assign) CGPoint rightTopPoint;
@property (nonatomic, assign) CGPoint leftBottomPoint;
@property (nonatomic, assign) CGPoint rightBottomPoint;
@property (nonatomic, assign) CGPoint filledBarEndPoint;
@property (nonatomic, assign) CGPoint barCenter;
@property (nonatomic, assign) CGFloat health;
@property (nonatomic, assign) CGFloat maxHealth;
@property (nonatomic, assign) CGFloat filledHealthWidthPercent;
@property (nonatomic,assign) CGFloat animationDuration;

- (instancetype) initWithAnimationsOfDuration: (NSInteger) animationDuration maxHealth: (NSInteger)maxHealth health: (NSInteger)health;
- (void) animateFillingHealthBar: (CGFloat)startingWidthPercentage filledBarPath: (UIBezierPath*)filledBarPath layer: (CALayer*)layer;

@end

NS_ASSUME_NONNULL_END
