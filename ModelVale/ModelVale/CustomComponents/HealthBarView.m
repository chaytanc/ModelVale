//
//  HealthBar.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/14/22.
//

#import "HealthBarView.h"

CGFloat const widthMarginMultiple = 0.12f;
CGFloat const heightMarginMultiple = 0.4f;

@interface HealthBarView()
@property (nonatomic, strong) CAShapeLayer* barShapeLayer;
@property (nonatomic, strong) CAShapeLayer* healthShapeLayer;
@property (nonatomic, assign) NSInteger barWidth;
@property (nonatomic, assign) NSInteger barHeight;
@property (nonatomic, assign) CGRect barRect;
@property (nonatomic, assign) CGPoint leftTopPoint;
@property (nonatomic, assign) CGPoint rightTopPoint;
@property (nonatomic, assign) CGPoint leftBottomPoint;
@property (nonatomic, assign) CGPoint rightBottomPoint;
//XXX todo are these midpoint properties necessary
@property (nonatomic, assign) CGPoint topMidPoint;
@property (nonatomic, assign) CGPoint bottomMidPoint;
@property (nonatomic, assign) CGFloat health;
@property (nonatomic, assign) CGFloat maxHealth;

@end

@implementation HealthBarView

//XXX todo init health and maxHealth properties


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self initPoints];
    self.barShapeLayer = [CAShapeLayer new];
    self.barShapeLayer.strokeColor = UIColor.blackColor.CGColor ;
    self.barShapeLayer.lineWidth = 1;
    self.barShapeLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);

    self.healthShapeLayer = [CAShapeLayer new];
    self.healthShapeLayer.fillColor = [UIColor redColor].CGColor;
    self.healthShapeLayer.lineWidth = 0;
    self.healthShapeLayer.strokeColor = [UIColor colorWithWhite:1 alpha:0].CGColor; // transparent
    // shapeLayer.frame is the drawable area
    UIBezierPath* barPath = [self getBarPath:10 withWidthPercent:1];
    self.barShapeLayer.path = barPath.CGPath;
    CGFloat widthPercent = self.health / self.maxHealth;
    UIBezierPath* healthPath = [self getBarPath:10 withWidthPercent:0.5];
    [self fillProgressBar:healthPath];
    self.healthShapeLayer.path = healthPath.CGPath;
    
    [self.layer addSublayer:self.barShapeLayer];
    [self.layer addSublayer:self.healthShapeLayer];
}

- (void) initPoints {
    // Top left is 0,0
    // todo make these points represent the four corners of the health bar, not the frame
    NSInteger widthMargin = self.bounds.size.width * widthMarginMultiple; // todo calc margin based on width
    NSInteger heightMargin = self.bounds.size.height * heightMarginMultiple;
    NSInteger top = self.bounds.origin.y + heightMargin;
    NSInteger left = self.bounds.origin.x + widthMargin;
    NSInteger bottom = self.bounds.size.height - heightMargin;
    NSInteger right = self.bounds.size.width - widthMargin;

    self.leftTopPoint = CGPointMake(left, top);
    self.rightTopPoint = CGPointMake(right, top);
    self.leftBottomPoint = CGPointMake(left, bottom);
    self.rightBottomPoint = CGPointMake(right, bottom);
    self.barWidth = right - left;
    self.barHeight = bottom - top;
    self.barRect = CGRectMake(left, top, self.barWidth, self.barHeight);

}

// https://stackoverflow.com/questions/50527832/how-to-draw-a-curved-line-using-cashapelayer-and-bezierpath-in-swift-4
- (UIBezierPath*) getBarPath: (CGFloat)endRoundness withWidthPercent: (CGFloat)widthPercent {
    // The left side of the arc always begins at the same place, but partially filled progress bars end at different x positions on the right based on widthPercent
    CGFloat adjustedRightX = self.leftTopPoint.x + self.barWidth * widthPercent;
    CGPoint rightTopPoint = CGPointMake(adjustedRightX, self.rightTopPoint.y);
    CGPoint leftMiddlePoint = CGPointMake(self.leftTopPoint.x, self.leftTopPoint.y + 0.5*self.barHeight);
    CGPoint rightMiddlePoint = CGPointMake(adjustedRightX, self.rightTopPoint.y + 0.5*self.barHeight);
    
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

//XXX todo , issue with healthShapeLayer needign slightly different controlpoint due to width... do not know how to calc
- (UIBezierPath*) getArchedBarPath: (CGFloat)endRoundness withWidthPercent: (CGFloat)widthPercent {
    // The left side of the arc always begins at the same place, but partially filled progress bars end at different x positions on the right based on widthPercent
    CGFloat adjustedRightX = self.leftTopPoint.x + self.barWidth * widthPercent;
    CGPoint rightTopPoint = CGPointMake(adjustedRightX, self.rightTopPoint.y);
    CGPoint leftMiddlePoint = CGPointMake(self.leftTopPoint.x, self.leftTopPoint.y + 0.5*self.barHeight);
    CGPoint rightMiddlePoint = CGPointMake(adjustedRightX, self.rightTopPoint.y + 0.5*self.barHeight);
    CGFloat midX = (self.leftTopPoint.x + self.rightTopPoint.x) * 0.5;
    CGPoint topMiddlePoint = CGPointMake(midX, self.leftTopPoint.y - 20);
    CGPoint bottomMiddlePoint = CGPointMake(midX, self.leftBottomPoint.y - 20);

    
    UIBezierPath* path = [UIBezierPath new];
    [path moveToPoint:self.leftTopPoint];
    [path addQuadCurveToPoint:rightTopPoint controlPoint:topMiddlePoint];
    [path addArcWithCenter:rightMiddlePoint radius:self.barHeight*0.5 startAngle:3*M_PI_2 endAngle:M_PI_2 clockwise:YES];
    [path addQuadCurveToPoint:self.leftBottomPoint controlPoint:bottomMiddlePoint];
    [path addArcWithCenter:leftMiddlePoint radius:self.barHeight*0.5 startAngle:M_PI_2 endAngle:3*M_PI_2 clockwise:YES];
    [path closePath];
    return path;
}


//XXX todo
- (void) drawArchedHealthBar {
    // Draw bezier path of inner / filled health
        // width calculated based on health percentage of max -- done
    UIBezierPath* startPath = [self getBarPath:10 withWidthPercent:0];
    CABasicAnimation * pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    pathAnimation.fromValue = (__bridge id)[startPath CGPath];
//    pathAnimation.toValue = (__bridge id)[filledBarPath CGPath];
    pathAnimation.duration = 3.0f;
    [self.healthShapeLayer addAnimation:pathAnimation forKey:@"archBar"];
    [self.barShapeLayer addAnimation:pathAnimation forKey:@"archBar"];
}

- (void) fillProgressBar: (UIBezierPath*) filledBarPath {

    UIBezierPath* startPath = [self getBarPath:10 withWidthPercent:0];
    CABasicAnimation * pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    pathAnimation.fromValue = (__bridge id)[startPath CGPath];
    pathAnimation.toValue = (__bridge id)[filledBarPath CGPath];
    pathAnimation.duration = 3.0f;
    [self.healthShapeLayer addAnimation:pathAnimation forKey:@"fillBar"];
}

@end
