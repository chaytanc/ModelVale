//
//  HealthBar.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/14/22.
//

#import "HealthBarView.h"

@interface HealthBarView()
@property (nonatomic, strong) CAShapeLayer* shapeLayer;
@property (nonatomic, assign) NSInteger barWidth;
@property (nonatomic, assign) NSInteger barHeight;
@property (nonatomic, assign) CGRect barRect;
@property (nonatomic, assign) CGPoint leftTopPoint;
@property (nonatomic, assign) CGPoint rightTopPoint;
@property (nonatomic, assign) CGPoint leftBottomPoint;
@property (nonatomic, assign) CGPoint rightBottomPoint;
@property (nonatomic, assign) CGPoint topMidPoint;
@property (nonatomic, assign) CGPoint bottomMidPoint;

@end

@implementation HealthBarView



// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self initPoints];
    self.shapeLayer = [CAShapeLayer new];
//    self.shapeLayer.fillColor = UIColor.blueColor.CGColor;
    self.shapeLayer.fillColor = self.backgroundColor.CGColor;
    self.shapeLayer.strokeColor = UIColor.blueColor.CGColor ;
    self.shapeLayer.lineWidth = 1;
    // todo should be health bar view size
    self.shapeLayer.frame = CGRectMake(0, 0, 500, 500);
    
    // Todo make into function for drawing bar object
    // Draw the top line
//    [self drawLines:100 thickness:10.0];
    UIBezierPath* path = [UIBezierPath bezierPathWithRoundedRect:self.barRect cornerRadius:10];
    self.shapeLayer.path = path.CGPath;

    [self.layer addSublayer:self.shapeLayer];
}

- (void) initPoints {
    // Top left is 0,0
    // todo make these points represent the four corners of the health bar, not the frame
    NSInteger margin = 50; // todo calc margin based on width
    NSInteger top = self.bounds.origin.y + margin;
    NSInteger left = self.bounds.origin.x + margin;
    NSInteger bottom = self.bounds.size.height - margin;
    NSInteger right = self.bounds.size.width - margin;

    self.leftTopPoint = CGPointMake(left, top);
    self.rightTopPoint = CGPointMake(right, top);
    self.leftBottomPoint = CGPointMake(left, bottom);
    self.rightBottomPoint = CGPointMake(right, bottom);
    self.barWidth = right - left;
    self.barHeight = bottom - top;
    self.barRect = CGRectMake(left, top, self.barWidth, self.barHeight);

}

// https://stackoverflow.com/questions/50527832/how-to-draw-a-curved-line-using-cashapelayer-and-bezierpath-in-swift-4
- (void) drawLines: (CGFloat)endRoundness thickness: (CGFloat)thickness {
    
    CGPoint pointsCenter = CGPointMake((self.leftTopPoint.x+self.rightTopPoint.x)*0.5, (self.leftTopPoint.y+self.rightTopPoint.y)*0.5);
    NSLog(@"to: (%f, %f)",self.rightTopPoint.x, self.rightTopPoint.y);
    NSLog(@"from: (%f, %f)",self.leftTopPoint.x, self.leftTopPoint.y);
    NSLog(@"center: (%f, %f)",pointsCenter.x, pointsCenter.y);
    // XXX Hypothesis: displaces x by
//    CGPoint centerDisplacement = CGPointMake((from.y-to.y), (from.x-to.x));
    // Drawing from top left to top right then down and back around, clockwise
    CGPoint rightControlPoint = CGPointMake(self.rightTopPoint.x + endRoundness, self.rightTopPoint.y + self.barHeight*0.5);
    CGPoint leftControlPoint = CGPointMake(self.leftTopPoint.x - endRoundness, self.leftTopPoint.y + self.barHeight*0.5);
    
    UIBezierPath* path = [UIBezierPath new];
    [path moveToPoint:self.leftTopPoint];
    [path addLineToPoint:self.rightTopPoint];
    [path addQuadCurveToPoint:self.rightBottomPoint controlPoint:rightControlPoint];
    [path addLineToPoint:self.leftBottomPoint];
    [path addQuadCurveToPoint:self.leftTopPoint controlPoint:leftControlPoint];
//    [path addQuadCurveToPoint:endPoint controlPoint:CGPointMake(150, 0)];
//    [path addCurveToPoint:endPoint controlPoint1:CGPointMake(150, 0) controlPoint2:CGPointMake(170, 0)];
    
//    [path addQuadCurveToPoint:from controlPoint:pointsCenter];
    [path closePath];
    self.shapeLayer.path = path.CGPath;
}

@end
