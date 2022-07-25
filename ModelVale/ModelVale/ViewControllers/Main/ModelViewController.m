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
BOOL const debugAnimations = NO;
NSInteger const seedXOffset = 15;
NSInteger const seedYOffset = 100;
NSInteger const maxHealth = 100;
NSInteger const sigma_xDivisor = 6;
NSInteger const sigma_yDivisor = 6;

@interface ModelViewController () <CAAnimationDelegate>
@property (weak, nonatomic) NSMutableArray* models;
@property (weak, nonatomic) IBOutlet UIView *detailsView;
@property (weak, nonatomic) IBOutlet UIStackView *avatarStackView;
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
    
    self.numClusters = 2;
    NSInteger avgNumXPPerCluster = 20;
    
    [self.healthBarView initWithAnimationsOfDuration:animationDuration maxHealth:maxHealth health:80];
    [self.healthBarView animateFillingHealthBar:self.healthBarView.healthPath layer:self.healthBarView.healthShapeLayer];
    
    [self setHealthBarPropsForXP];
    self.clusters = [self initializeXPClusters:self.numClusters avgNumPerCluster:avgNumXPPerCluster seed:self.seed];
    [self animateXPClusters:self.clusters];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reanimateXPClusters];
}

- (void) setHealthBarPropsForXP {
    self.seed = CGPointMake(self.view.frame.size.width - seedXOffset, self.view.frame.size.height - seedYOffset);
    //XXX todo this calculation is slightly off (to the left and up too much)
    // Hierarchy
    // self.view --> self.detailsView --> self.avatarStackView --> self.healthBarView
    CGPoint healthBarViewOrigin1 = [self.view convertRect:self.avatarStackView.frame fromView:self.detailsView].origin; // Is actually the avatarStackView origin
    CGPoint healthBarViewOrigin2 = [self.view convertRect:self.healthBarView.barRect fromView:self.avatarStackView].origin;
    
    CGFloat filledHealthXCoord = self.healthBarView.filledBarEndPoint.x + 8; //XXX todo this is a magic number that makes it work with healthBarOrigin1. 8 seems like a layoutMargin constant, but as for the 18.5, I have no idea
    CGFloat middleHealthYCoord = self.healthBarView.filledBarEndPoint.y + 18.5; //XXX todo magic healthBarOrigin1 offset that makes it centered...
    
    self.XPEndPoint = CGPointMake(healthBarViewOrigin1.x + filledHealthXCoord, healthBarViewOrigin1.y + middleHealthYCoord);

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

- (void) addXPPathAnimation: (XP*)xp {
    CAKeyframeAnimation * pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation.path = xp.path.CGPath;
    pathAnimation.duration = animationDuration;
    pathAnimation.fillMode = kCAFillModeForwards;
    pathAnimation.removedOnCompletion = NO;
    pathAnimation.delegate = xp;
    [xp.layer addAnimation:pathAnimation forKey:@"flyingXP"];
}

- (void) addXPSubview: (XP*) xp {
    xp.frame = CGRectMake(0, 0, xpSize, xpSize);
    xp.image = [UIImage imageNamed:@"xp"];
    [self.view addSubview: xp];
    CAShapeLayer* XPLayer = [self getXPBubbleLayer];
    XPLayer.lineWidth = 0;
    if(debugAnimations) {
        XPLayer.strokeColor = [UIColor redColor].CGColor;
        XPLayer.lineWidth = 3;
    }
    [self.view.layer addSublayer:XPLayer];
    xp.CALayer = XPLayer;
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
        
        [self addXPPathAnimation:xp];
        ((CAShapeLayer*)xp.CALayer).path = xp.path.CGPath;
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
- (CGPoint) getClusterCenter: (CGPoint) seed {
    int sigma_x = self.view.frame.size.width / sigma_xDivisor;
    int sigma_y = self.view.frame.size.height / sigma_yDivisor;
    GKRandomSource* rand = [GKRandomSource new];
    GKGaussianDistribution* gaussian_x = [[GKGaussianDistribution new] initWithRandomSource:rand mean:seed.x deviation:sigma_x];
    GKGaussianDistribution* gaussian_y = [[GKGaussianDistribution new] initWithRandomSource:rand mean:seed.y deviation:sigma_y];
    CGPoint center = CGPointMake([gaussian_x nextInt], [gaussian_y nextInt]);
    return center;
}

// Given the desired number of clusters and the average number of XP per cluster and the seed, which is the center of ALL clusters, this function randomly chooses the number of XP in each cluster within +/- 7 of avgNumPerCluster, keeping in mind minXPPerCluster
- (NSMutableArray*) initializeXPClusters: (NSInteger)numClusters avgNumPerCluster: (NSInteger) avgNumPerCluster seed: (CGPoint)seed {
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
            [self addXPSubview:xp];
        }
        XPCluster* cluster = [[XPCluster new] initEmptyCluster:clusterCenter];
        cluster.cluster = xpInCluster;
        cluster.center = clusterCenter;
        [XPClusters addObject:cluster];
    }
    return XPClusters;
}

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
            [self addXPPathAnimation:xp];
        }
    }
}

@end
