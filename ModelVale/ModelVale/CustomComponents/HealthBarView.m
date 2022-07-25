//
//  HealthBar.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/14/22.
//

#import "HealthBarView.h"
#import "GameplayKit/GameplayKit.h"
#include <stdlib.h>

CGFloat const widthMarginMultiple = 0.12f;
CGFloat const heightMarginMultiple = 0.4f;
//UIColor* const violet = [UIColor colorWithRed:125.0f/255.0f green:65.0f/255.0f blue:205.0f/255.0f alpha:1.0f];

@interface HealthBarView() <CAAnimationDelegate>
@end

@implementation HealthBarView

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.layer.cornerRadius = 24;
        self.clipsToBounds = TRUE;
    }
    return self;
}

- (instancetype) initWithAnimationsOfDuration: (NSInteger) animationDuration maxHealth: (NSInteger)maxHealth health: (NSInteger)health {
    self = [super init];
    if(self) {
        self.animationDuration = animationDuration;
        self.health = health;
        self.maxHealth = maxHealth;
        self.filledHealthWidthPercent = self.health / self.maxHealth;
        [self initBarPoints];
        self.barPath = [self createBarShapeLayerWithWidthPercent:1];
        [self.layer addSublayer:self.barShapeLayer];
        self.healthPath = [self createHealthShapeLayerWithWidthPercent];
        [self.layer addSublayer:self.healthShapeLayer];
        [self addGradientToHealthBar: self.healthShapeLayer gradWidth:self.barWidth*self.filledHealthWidthPercent];
    }
    return self;
}

- (void) initBarPoints {
    // Top left is 0,0
    NSInteger widthMargin = self.bounds.size.width * widthMarginMultiple;
    NSInteger heightMargin = self.bounds.size.height * heightMarginMultiple;
    NSInteger top = self.frame.origin.y + heightMargin;
    NSInteger left = self.frame.origin.x + widthMargin;
    NSInteger bottom = self.frame.size.height - heightMargin;
    NSInteger right = self.frame.size.width - widthMargin;

    self.leftTopPoint = CGPointMake(left, top);
    self.rightTopPoint = CGPointMake(right, top);
    self.leftBottomPoint = CGPointMake(left, bottom);
    self.rightBottomPoint = CGPointMake(right, bottom);
    self.barWidth = right - left;
    self.barHeight = bottom - top;
    self.barCenter = CGPointMake(self.barWidth*0.5 + widthMargin, self.barHeight*0.5 + heightMargin);
    self.barRect = CGRectMake(left, top, self.barWidth, self.barHeight);
    CGFloat adjustedRightX = self.leftTopPoint.x + self.barWidth * self.filledHealthWidthPercent;
    self.filledBarEndPoint = CGPointMake(adjustedRightX, self.rightTopPoint.y + 0.5*self.barHeight);

}

//MARK: Bar Animations
- (UIBezierPath*) createBarShapeLayerWithWidthPercent: (CGFloat) widthPercent {
    self.barShapeLayer = [CAShapeLayer new];
    self.barShapeLayer.strokeColor = UIColor.blackColor.CGColor;
    self.barShapeLayer.lineWidth = 1;
    self.barShapeLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    UIBezierPath* barPath = [self getBarPath: 1];
    self.barShapeLayer.path = barPath.CGPath;
    return barPath;
}

- (UIBezierPath*) createHealthShapeLayerWithWidthPercent {
    self.healthShapeLayer = [CAShapeLayer new];
    self.healthShapeLayer.fillColor = [UIColor systemGreenColor].CGColor;
    self.healthShapeLayer.lineWidth = 0;
    self.healthShapeLayer.strokeColor = [UIColor clearColor].CGColor;
    UIBezierPath* healthPath = [self getBarPath: self.filledHealthWidthPercent];
    self.healthShapeLayer.path = healthPath.CGPath;
    return healthPath;
}

- (UIBezierPath*) getBarPath: (CGFloat)widthPercent {
    // The left side of the arc always begins at the same place, but partially filled progress bars end at different x positions on the right based on widthPercent
    CGFloat adjustedRightX = self.leftTopPoint.x + self.barWidth * widthPercent;
    CGPoint rightMiddlePoint = CGPointMake(adjustedRightX, self.rightTopPoint.y + 0.5*self.barHeight);
    CGPoint rightTopPoint = CGPointMake(adjustedRightX, self.rightTopPoint.y);
    CGPoint leftMiddlePoint = CGPointMake(self.leftTopPoint.x, self.leftTopPoint.y + 0.5*self.barHeight);
    
    UIBezierPath* path = [UIBezierPath new];
    [path moveToPoint:self.leftTopPoint];
    [path addLineToPoint:rightTopPoint];
    // Obj-C angles increase in the clockwise direction
    [path addArcWithCenter:rightMiddlePoint radius:self.barHeight*0.5 startAngle:3*M_PI_2 endAngle:M_PI_2 clockwise:YES];
    [path addLineToPoint:self.leftBottomPoint];
    [path addArcWithCenter:leftMiddlePoint radius:self.barHeight*0.5 startAngle:M_PI_2 endAngle:3*M_PI_2 clockwise:YES];
    [path closePath];
    return path;
}

- (void) animateFillingHealthBar: (UIBezierPath*)filledBarPath layer: (CALayer*)layer {
    
    UIBezierPath* startPath = [self getBarPath:0];
    CABasicAnimation * pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    pathAnimation.fromValue = (__bridge id)[startPath CGPath];
    pathAnimation.toValue = (__bridge id)[filledBarPath CGPath];
    pathAnimation.duration = self.animationDuration;
    [layer addAnimation:pathAnimation forKey:@"fillBar"];
}

- (void) addGradientToHealthBar: (CAShapeLayer*)healthBarLayer gradWidth: (NSInteger)gradWidth {
    
    CAGradientLayer* gradient = [CAGradientLayer new];
    CGPoint start = CGPointMake(0, 0);
    CGPoint end = CGPointMake(1, 0);
    gradient.startPoint = start;
    gradient.endPoint = end;
    gradient.frame = self.bounds;
    UIColor* violet = [UIColor colorWithRed:125.0f/255.0f green:65.0f/255.0f blue:205.0f/255.0f alpha:1.0f];
    gradient.colors = [NSArray arrayWithObjects:(id) violet.CGColor, (id) [UIColor systemTealColor].CGColor, (id) [UIColor systemGreenColor].CGColor, nil];
    gradient.mask = healthBarLayer;
    [self.layer addSublayer:gradient];
}

@end


