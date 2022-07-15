//
//  HealthBar.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/14/22.
//

#import "HealthBarView.h"

@interface HealthBarView()
@property (nonatomic, strong) CAShapeLayer* shapeLayer;
@property (nonatomic, assign) NSInteger width;
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
    self.shapeLayer.fillColor = UIColor.blueColor.CGColor;
    self.shapeLayer.frame = CGRectMake(0, 0, 500, 500);
    
    [self drawLines:self.leftTopPoint to:self.rightTopPoint bendFactor:0.5 thickness:10.0];
//    [self.shapeLayer.frame ]
    [self.layer addSublayer:self.shapeLayer];
}

- (void) initPoints {
    // Top left is 0,0
    NSInteger margin = 10; // todo calc margin based on width
    NSInteger top = self.frame.origin.y + margin;
    NSInteger left = self.frame.origin.x + margin;
    NSInteger bottom = self.frame.size.height - margin;
    NSInteger right = self.frame.size.width - margin;

    self.leftTopPoint = CGPointMake(left, top);
    self.rightTopPoint = CGPointMake(right, top);
    self.leftBottomPoint = CGPointMake(left, bottom);
    self.rightBottomPoint = CGPointMake(right, bottom);
}

// https://stackoverflow.com/questions/50527832/how-to-draw-a-curved-line-using-cashapelayer-and-bezierpath-in-swift-4
- (void) drawLines: (CGPoint)from to: (CGPoint)to bendFactor: (CGFloat)bendFactor thickness: (CGFloat)thickness {
    CGPoint pointsCenter = CGPointMake((from.x+to.x)*0.5, (from.y+to.y)*0.5);
    // XXX Hypothesis: displaces x by
//    CGPoint centerDisplacement = CGPointMake((from.y-to.y), (from.x-to.x));
    
    UIBezierPath* path = [UIBezierPath new];
    [path moveToPoint:to];
    [path addQuadCurveToPoint:to controlPoint:pointsCenter];
    [path addQuadCurveToPoint:from controlPoint:pointsCenter];
    [path closePath];
    self.shapeLayer.path = path.CGPath;
}

@end
