//
//  HealthBar.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/14/22.
//

#import "HealthBarView.h"
#import "GameplayKit/GameplayKit.h"
#include <stdlib.h>
#import "XPCluster.h"
#import "XP.h"

CGFloat const widthMarginMultiple = 0.12f;
CGFloat const heightMarginMultiple = 0.4f;
CGFloat const animationDuration = 2.5f;
NSInteger const xpSize = 20;
NSInteger const minXPPerCluster = 10;
BOOL const debug = NO;

@interface HealthBarView() <CAAnimationDelegate>
@property (nonatomic, strong) CAShapeLayer* barShapeLayer;
@property (nonatomic, strong) CAShapeLayer* healthShapeLayer;
@property (nonatomic, assign) NSInteger barWidth;
@property (nonatomic, assign) NSInteger barHeight;
@property (nonatomic, assign) CGRect barRect;
@property (nonatomic, assign) CGPoint leftTopPoint;
@property (nonatomic, assign) CGPoint rightTopPoint;
@property (nonatomic, assign) CGPoint leftBottomPoint;
@property (nonatomic, assign) CGPoint rightBottomPoint;
@property (nonatomic, assign) CGPoint barCenter;
@property (nonatomic, assign) CGFloat health;
@property (nonatomic, assign) CGFloat maxHealth;
@property (nonatomic, assign) CGFloat filledHealthWidthPercent;
@property (nonatomic, assign) CGPoint filledHealthRightMidPointRelativeToScreen;
@property (nonatomic, weak) UIView* uberview;
@property (nonatomic,strong) NSMutableArray<XPCluster*>* clusters;

@end

@implementation HealthBarView

//XXX todo init health and maxHealth properties

- (instancetype)init {
    self = [super init];
    if (self) {
        //XXX todo move initWithCoder initialization here when switching to programmatic instatiation in refactor
    }
    return self;
}

//XXX todo somehow override init and dependency inject frame so that we can move createAllClusterXPImViewAndLayer to here instead of layoutsubviews
- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.layer.cornerRadius = 24;
        self.clipsToBounds = TRUE;
        self.filledHealthWidthPercent = self.health / self.maxHealth;
        //XXX todo remove harded coded widthPercent once we have code to set self.health etc
        self.filledHealthWidthPercent = 0.75;
        [self initBarPoints];

    }
    return self;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    //XXX todo move XP up to ModelViewController so that uberview is not necessary anymore
    self.uberview = self.superview.superview.superview;
    
    CGPoint absOrigin = [self.uberview convertPoint:self.bounds.origin fromView:self];
    CGFloat adjustedRightX = self.leftTopPoint.x + self.barWidth * self.filledHealthWidthPercent;
    self.filledHealthRightMidPointRelativeToScreen = CGPointMake(absOrigin.x + adjustedRightX, absOrigin.y + self.rightTopPoint.y + 0.5*self.barHeight);
    
    //XXX todo createClusters needs to be moved to init, but needs the uberview frame
    CGPoint seed = CGPointMake(self.uberview.frame.size.width - 5, self.uberview.frame.size.height - 100);
    //XXX todo split out instantiation of imageviews and layers then move to init, but really XP should be initialized on VC
    NSMutableArray<XPCluster*>* XPClusters = [self getXPClusters:1 avgNumPerCluster:20 seed:seed];
    self.clusters = XPClusters;
    [self createAllClusterXPImViewAndLayer];
    
    //XXX todo move XP animtaions up to viewcontroller
    [self animateXPClusters:self.clusters];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    [self createBarShapeLayerWithWidthPercent:1];
    [self.layer addSublayer:self.barShapeLayer];

    //XXX todo move these animations to a function called by the ModelViewController when the view loads or we switch between models
    UIBezierPath* healthPath = [self createHealthShapeLayerWithWidthPercent];
    [self animateFillHealthBar:healthPath layer:self.healthShapeLayer];
    [self.layer addSublayer:self.healthShapeLayer];
    [self addGradientToHealthBar: self.healthShapeLayer gradWidth:self.barWidth*self.filledHealthWidthPercent];
}

//MARK: Bar Animations
- (void) initBarPoints {
    // Top left is 0,0
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
    self.barCenter = CGPointMake(self.barWidth*0.5 + widthMargin, self.barHeight*0.5 + heightMargin);
    self.barRect = CGRectMake(left, top, self.barWidth, self.barHeight);

}

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
    CGPoint rightTopPoint = CGPointMake(adjustedRightX, self.rightTopPoint.y);
    CGPoint rightMiddlePoint = CGPointMake(adjustedRightX, self.rightTopPoint.y + 0.5*self.barHeight);
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

- (void) animateFillHealthBar: (UIBezierPath*)filledBarPath layer: (CALayer*)layer {
    
    UIBezierPath* startPath = [self getBarPath:0];
    CABasicAnimation * pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    pathAnimation.fromValue = (__bridge id)[startPath CGPath];
    pathAnimation.toValue = (__bridge id)[filledBarPath CGPath];
    pathAnimation.duration = animationDuration;
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

//MARK: XP Animations

//XXX todo remove
- (UIImageView*) getXPImageView: (CGFloat) size label: (NSString*) label {
    UIImageView* xpImView = [UIImageView new];
    xpImView.frame = CGRectMake(0, 0, size, size);
    xpImView.image = [UIImage imageNamed:label];
    return xpImView;
}

- (CAShapeLayer*) getXPBubbleLayer {
    CAShapeLayer* XPLayer = [CAShapeLayer new];
    XPLayer.fillColor = [UIColor clearColor].CGColor;
    return XPLayer;
}

- (UIBezierPath*) getXPLoopPath: (CGPoint)XPStart XPEnd: (CGPoint) XPEnd {
    UIBezierPath* path = [UIBezierPath new];
    [path moveToPoint:XPStart];
    CGPoint controlOne = CGPointMake(XPEnd.x - 0.5*(XPStart.x - XPEnd.x), XPStart.y - 50);
    CGPoint controlTwo = CGPointMake(XPStart.x + 0.9*(XPStart.x - XPEnd.x), XPStart.y + 0.5*(XPStart.y - XPEnd.y));
    [path addCurveToPoint:XPEnd controlPoint1:controlOne controlPoint2:controlTwo];
    return path;
}

- (UIBezierPath*) getXPBigCurvePath: (CGPoint)XPStart XPEnd: (CGPoint) XPEnd {
    UIBezierPath* path = [UIBezierPath new];
    [path moveToPoint:XPStart];
    CGPoint controlOne = CGPointMake(XPStart.x + 300, XPStart.y - 300);
    CGPoint controlTwo = CGPointMake(XPEnd.x - 150, XPEnd.y + 200);
    [path addCurveToPoint:XPEnd controlPoint1:controlOne controlPoint2:controlTwo];
    return path;
}

- (void) addXPPathAnimation: (CALayer*) XPLayer path: (UIBezierPath*) XPPath {
    CAKeyframeAnimation * pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation.path = XPPath.CGPath;
    pathAnimation.duration = animationDuration;
    pathAnimation.fillMode = kCAFillModeForwards;
    pathAnimation.removedOnCompletion = NO;
    pathAnimation.delegate = self;
    [XPLayer addAnimation:pathAnimation forKey:@"flyingXP"];
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
    //XXX todo should hide singular xp at a time and pass into hideXP function which one to hide
}

- (void) createAllClusterXPImViewAndLayer {
    for (XPCluster* cluster in self.clusters) {
        for (XP* xp in cluster.cluster) {
            xp.frame = CGRectMake(0, 0, xpSize, xpSize);
            xp.image = [UIImage imageNamed:@"xp"];
            [self.uberview addSubview: xp];
            CAShapeLayer* XPLayer = [self getXPBubbleLayer];
            if(debug) {
                XPLayer.strokeColor = [UIColor redColor].CGColor;
            }
            XPLayer.lineWidth = 3;
            [self.uberview.layer addSublayer:XPLayer];
            xp.CALayer = XPLayer;
        }
    }
}

- (void) hideAllXPImageViews {
    for (XPCluster* cluster in self.clusters) {
        for (XP* xp in cluster.cluster) {
            [xp setHidden:YES];
        }
    }
}

- (void) showAllXPImageViews {
    for (XPCluster* cluster in self.clusters) {
        for (XP* xp in cluster.cluster) {
            [xp setHidden:NO];
        }
    }
}

- (void) animateXPCluster: (XPCluster*) XPCluster {
    for (XP* xp in XPCluster.cluster) {
        CAShapeLayer* XPLayer = xp.CALayer;
        UIBezierPath* XPPath = xp.path;
        [self addXPPathAnimation:xp.layer path:XPPath];
        XPLayer.path = XPPath.CGPath;
    }
}

- (void) animateXPClusters: (NSMutableArray<XPCluster*>*) XPClusters {
    [self showAllXPImageViews];
    for (XPCluster* XPCluster in XPClusters) {
        [self animateXPCluster:XPCluster];
    }
}

- (NSMutableArray*) getXPStartsAroundCentroid: (NSInteger) numXP center: (CGPoint) center {
    NSMutableArray* XPStarts = [NSMutableArray new];
    int xMax = 20;
    int yMax = 25;
    for(int i=0; i<numXP; i++) {
        int xOffset = -xMax + arc4random_uniform(xMax*2);
        int yOffset = -yMax + arc4random_uniform(yMax*2);
        CGPoint XPStart = CGPointMake(center.x + xOffset, center.y + yOffset);
        NSValue* v = [NSValue valueWithCGPoint: XPStart];
        [XPStarts addObject:v];
    }
    return XPStarts;
}

// This function generates a cluster center by sampling from normal distributions describing how far away the x and y are from the seed of all clusters. For example, if sigma_x=50 and the seed is (0,0) then according to the 68-95-99.7 rule of Gaussian (normal) distributions, center.x will be between range(-50, 50) 68% of the time, between range(-100, 100) 95% of the time, etc...
- (CGPoint) getClusterCenter: (CGPoint) seedOnUberview {
    //XXX todo move sigma_x and sigma_y to constants in ModelViewController when XP animation code is moved there
    int sigma_x = self.uberview.frame.size.width / 5;
    int sigma_y = self.uberview.frame.size.height / 5;
    GKRandomSource* rand = [GKRandomSource new];
    GKGaussianDistribution* gaussian_x = [[GKGaussianDistribution new] initWithRandomSource:rand mean:seedOnUberview.x deviation:sigma_x];
    GKGaussianDistribution* gaussian_y = [[GKGaussianDistribution new] initWithRandomSource:rand mean:seedOnUberview.y deviation:sigma_y];
    CGPoint center = CGPointMake([gaussian_x nextInt], [gaussian_y nextInt]);
    return center;
}

// Given the desired number of clusters and the average number of XP per cluster and the seed, which is the center of ALL clusters, this function randomly chooses the number of XP in each cluster within +/- 7 of avgNumPerCluster, keeping in mind minXPPerCluster
- (NSMutableArray*) getXPClusters: (NSInteger)numClusters avgNumPerCluster: (NSInteger) avgNumPerCluster seed: (CGPoint)seed {
    int clusterHalfRange = 7;
    int numInCluster;
    NSMutableArray* XPClusters = [NSMutableArray new];

    // Construct an array of all clusters of XP by constructing each XP object that goes into each XPCluster object and adding each XPCluster to XPClusters
    for(int i=0; i < numClusters; i++) {
        // Randomly choose num XP in cluster
        numInCluster = (avgNumPerCluster-clusterHalfRange) + arc4random_uniform(clusterHalfRange*2);
        numInCluster = (numInCluster <= minXPPerCluster) ? minXPPerCluster : numInCluster;
        
        CGPoint clusterCenter = [self getClusterCenter:seed];
        NSMutableArray* XPStarts = [self getXPStartsAroundCentroid:numInCluster center:clusterCenter];
        NSMutableArray* xpInCluster = [NSMutableArray new];
        for(NSValue* value in XPStarts) {
            CGPoint center = value.CGPointValue;
            UIBezierPath* XPPath = [self getXPLoopPath:center XPEnd:self.filledHealthRightMidPointRelativeToScreen];
            XP* xp = [[XP new] initXP:center path:XPPath];
            [xpInCluster addObject:xp];
        }
        XPCluster* cluster = [[XPCluster new] initEmptyCluster:clusterCenter];
        cluster.cluster = xpInCluster;
        cluster.center = clusterCenter;
        [XPClusters addObject:cluster];
    }
    return XPClusters;
}

@end


