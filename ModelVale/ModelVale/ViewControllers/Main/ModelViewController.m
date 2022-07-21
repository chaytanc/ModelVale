//
//  ModelViewController.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/4/22.
//

#import "ModelViewController.h"
#import "Parse/Parse.h"
#import "UIViewController+PresentError.h"
#import "LoginViewController.h"
#import "SceneDelegate.h"
#import "UpdatableSqueezeNet.h"
#import "CoreML/CoreML.h"
#import "HealthBarView.h"
#import "XPCluster.h"
#import "XP.h"
#import "GameplayKit/GameplayKit.h"

CGFloat const animationDuration = 2.5f;
NSInteger const xpSize = 20;
NSInteger const minXPPerCluster = 10;
BOOL const debugAnimations = YES;


@interface ModelViewController () <CAAnimationDelegate>
@property (weak, nonatomic) NSMutableArray* models;
@property (weak, nonatomic) IBOutlet HealthBarView *healthBarView;
@property (weak, nonatomic) IBOutlet UILabel *healthLabel;
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (weak, nonatomic) IBOutlet UIButton *trainButton;
@property (weak, nonatomic) IBOutlet UIButton *dataButton;

@property (nonatomic, assign) NSInteger numClusters;
@property (nonatomic, assign) CGPoint XPEndPoint;
@property (nonatomic,strong) NSMutableArray<XPCluster*>* clusters;
@property (nonatomic, assign) CGPoint seed; //XXX todo make public

@end

@implementation ModelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.testButton.layer.cornerRadius = 10;
    self.trainButton.layer.cornerRadius = 10;
    self.dataButton.layer.cornerRadius = 10;
    
    self.numClusters = 3;
    
    
    //XXX todo configure healthbarview
    [self initializeHealthBarView];
    [self.healthBarView initializeAnimationsWithDuration:animationDuration maxHealth:90 health:50];
    [self.healthBarView animateFillingHealthBar:self.healthBarView.healthPath layer:self.healthBarView.healthShapeLayer];
    
    // init imageviews of clusters
    // call animations on those image views
    

}

- (void) initializeHealthBarView {
    //XXX todo make an init to call for healthbarview

//    self.healthBarView.health =
//    self.healthBarView.maxHealth =
    self.seed = CGPointMake(self.view.frame.size.width - 15, self.view.frame.size.height -100);
    //XXX todo ensure that these get inited before we init endpoint using them
    CGFloat filledHealthXCoord = self.healthBarView.leftTopPoint.x + self.healthBarView.barWidth * self.healthBarView.filledHealthWidthPercent;
    CGFloat middleHealthYCoord = self.healthBarView.rightTopPoint.y + 0.5*self.healthBarView.barHeight;
    self.XPEndPoint = CGPointMake(self.view.bounds.origin.x + filledHealthXCoord, self.view.bounds.origin.y + middleHealthYCoord);
    [self initializeClusters:self.numClusters avgNumPerCluster:15 seed:self.seed];
}

//XXX todo, config model name, type, etc
- (void) configureModel {
    
}

- (IBAction)didTapLogout:(id)sender {
    NSLog(@"Logout Tapped");
    [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
        // PFUser.current() will now be nil
        if(error != nil) {
            [self presentError:@"Logout Failed" message:error.localizedDescription error:error];
        }
        else {
            SceneDelegate *sceneDelegate = (SceneDelegate * ) UIApplication.sharedApplication.connectedScenes.allObjects.firstObject.delegate;
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
            LoginViewController *loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"loginViewController"];

            [sceneDelegate.window setRootViewController:loginViewController];
        }
    }];
}

//MARK: XP animations

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

//MARK: XXX working here
// 1) init empty clusters w num xp in each defined
    // num xp per cluster will stay the same, center of cluster will change
// 2) Init the XP for each required XP of a cluster
//[self initializeClusters: self.numClusters avgNumPerCluster: 10 seed: self.seed];

// 2.5) calculate and set the center of each cluster
//center = [getClusterCenter: self.seed]
//[getXPStartsAroundCenter: center];

// 3) reanimate method to update the centers for each xp and calc the path and update, without reinitializing XP object
// 4) when animating from retrain or test completion block finishes, call reanimate to recalc centers, paths, and call animateXPClusters
// ** the init method can call getcenters, but getcenters shoudl not imply initing new objects **

- (void) reanimateXPClusters {
    for (XPCluster* cluster in self.clusters) {
        CGPoint clusterCenter = [self getClusterCenter:self.seed];
        cluster.center = clusterCenter;
        // Recalc centers and paths for each XP given new cluster center
        NSMutableArray* XPStarts = [self getXPStartsAroundCenter:cluster.cluster.count center:clusterCenter];
        for(int i=0; i< XPStarts.count; i++) {
            NSValue* centerValue = XPStarts[i];
            CGPoint center = centerValue.CGPointValue;
            XP* xp = cluster.cluster[i];
            UIBezierPath* XPPath = [self getXPLoopPath:center XPEnd:self.XPEndPoint];
            xp.path = XPPath;
            xp.center = center;
        }
    }
}

- (void) createAllClusterXPImViewAndLayer {
    for (XPCluster* cluster in self.clusters) {
        for (XP* xp in cluster.cluster) {
            xp.frame = CGRectMake(0, 0, xpSize, xpSize);
            xp.image = [UIImage imageNamed:@"xp"];
            [self.view addSubview: xp];
            CAShapeLayer* XPLayer = [self getXPBubbleLayer];
            if(debugAnimations) {
                XPLayer.strokeColor = [UIColor redColor].CGColor;
            }
            XPLayer.lineWidth = 3;
            [self.view.layer addSublayer:XPLayer];
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

- (NSMutableArray*) getXPStartsAroundCenter: (NSInteger) numXP center: (CGPoint) center {
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
    int sigma_x = self.view.frame.size.width / 5;
    int sigma_y = self.view.frame.size.height / 5;
    GKRandomSource* rand = [GKRandomSource new];
    GKGaussianDistribution* gaussian_x = [[GKGaussianDistribution new] initWithRandomSource:rand mean:seedOnUberview.x deviation:sigma_x];
    GKGaussianDistribution* gaussian_y = [[GKGaussianDistribution new] initWithRandomSource:rand mean:seedOnUberview.y deviation:sigma_y];
    CGPoint center = CGPointMake([gaussian_x nextInt], [gaussian_y nextInt]);
    return center;
}

// Given the desired number of clusters and the average number of XP per cluster and the seed, which is the center of ALL clusters, this function randomly chooses the number of XP in each cluster within +/- 7 of avgNumPerCluster, keeping in mind minXPPerCluster
- (NSMutableArray*) initializeClusters: (NSInteger)numClusters avgNumPerCluster: (NSInteger) avgNumPerCluster seed: (CGPoint)seed {
    int clusterHalfRange = 7;
    int numInCluster;
    NSMutableArray* XPClusters = [NSMutableArray new];

    // Construct an array of all clusters of XP by constructing each XP object that goes into each XPCluster object and adding each XPCluster to XPClusters
    for(int i=0; i < numClusters; i++) {
        // Randomly choose num XP in cluster
        numInCluster = (avgNumPerCluster-clusterHalfRange) + arc4random_uniform(clusterHalfRange*2);
        numInCluster = (numInCluster <= minXPPerCluster) ? minXPPerCluster : numInCluster;
        
        // Gets a randomly generated cluster probabilistically drawn based on distance from seed
        CGPoint clusterCenter = [self getClusterCenter:seed];
        NSMutableArray* XPStarts = [self getXPStartsAroundCenter:numInCluster center:clusterCenter];
        NSMutableArray* xpInCluster = [NSMutableArray new];
        for(NSValue* value in XPStarts) {
            CGPoint center = value.CGPointValue;
            UIBezierPath* XPPath = [self getXPLoopPath:center XPEnd:self.XPEndPoint];
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
