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

CGFloat const kAnimationDuration = 2.5f;
NSInteger const kXPSize = 20;
NSInteger const kMinXPPerCluster = 10;
BOOL const kDebugAnimations = NO;
NSInteger const kSeedXOffset = 30;
NSInteger const kSeedYOffset = 100;
NSInteger const kMaxHealth = 100;
NSInteger const kSigmaXDivisor = 6;
NSInteger const kSigmaYDivisor = 6;

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
@end

@implementation ModelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.testButton.layer.cornerRadius = 10;
    self.trainButton.layer.cornerRadius = 10;
    self.dataButton.layer.cornerRadius = 10;
    
    self.numClusters = 5;
    NSInteger avgNumXPPerCluster = 20;
    
    [self.healthBarView initWithAnimationsOfDuration:kAnimationDuration maxHealth:kMaxHealth health:80];
    [self.healthBarView animateFillingHealthBar:self.healthBarView.healthPath layer:self.healthBarView.healthShapeLayer];
    self.clusters = [self initializeXPClustersOnSubViewAtZero:self.numClusters avgNumPerCluster:avgNumXPPerCluster];

}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self setHealthBarPropsForXP];
    [self setXPPathsAndClusterCenters:self.seed reanimate:FALSE];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self animateXPClusters:self.clusters];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void) setHealthBarPropsForXP {
    self.seed = CGPointMake(self.view.frame.size.width - kSeedXOffset, self.view.frame.size.height - kSeedYOffset);
    // Hierarchy
    // self.view --> self.detailsView --> self.avatarStackView --> self.healthBarView
    // Since healthBarView is the top view of avatarStackView, they share an origin
    CGPoint healthBarViewOrigin1 = [self.view convertRect:self.avatarStackView.frame fromView:self.detailsView].origin;
    CGFloat filledHealthXCoord = self.healthBarView.filledBarEndPoint.x;
    CGFloat middleHealthYCoord = self.healthBarView.filledBarEndPoint.y;
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
    pathAnimation.duration = kAnimationDuration;
    pathAnimation.fillMode = kCAFillModeForwards;
    pathAnimation.removedOnCompletion = NO;
    pathAnimation.delegate = xp;
    [xp.layer addAnimation:pathAnimation forKey:@"flyingXP"];
}

- (void) createAndAddXPSubview: (XP*) xp {
    xp.frame = CGRectMake(0, 0, kXPSize, kXPSize);
    xp.image = [UIImage imageNamed:@"xp"];
    [self.view addSubview: xp];
    CAShapeLayer* XPLayer = [self createXPLayer];
    XPLayer.lineWidth = 0;
    if(kDebugAnimations) {
        XPLayer.strokeColor = [UIColor redColor].CGColor;
        XPLayer.lineWidth = 3;
    }
    [self.view.layer addSublayer:XPLayer];
    xp.CALayer = XPLayer;
}

- (CAShapeLayer*) createXPLayer {
    CAShapeLayer* XPLayer = [CAShapeLayer new];
    XPLayer.fillColor = [UIColor clearColor].CGColor;
    return XPLayer;
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
    int sigma_x = self.view.frame.size.width / kSigmaXDivisor;
    int sigma_y = self.view.frame.size.height / kSigmaYDivisor;
    GKRandomSource* rand = [GKRandomSource new];
    GKGaussianDistribution* gaussian_x = [[GKGaussianDistribution new] initWithRandomSource:rand mean:seed.x deviation:sigma_x];
    GKGaussianDistribution* gaussian_y = [[GKGaussianDistribution new] initWithRandomSource:rand mean:seed.y deviation:sigma_y];
    CGPoint center = CGPointMake([gaussian_x nextInt], [gaussian_y nextInt]);
    return center;
}

// Given the seed, which is the center of ALL clusters, this function calculates centers of the clusters, and the XP centers and paths within those clusters
- (void) setXPPathsAndClusterCenters:(CGPoint)seed reanimate: (BOOL)reanimate {

    for(XPCluster* cluster in self.clusters) {
        CGPoint clusterCenter = [self getClusterCenter:seed];
        cluster.center = clusterCenter;
        NSMutableArray* XPStarts = [self getXPStartsAroundCenter:cluster.cluster.count center:clusterCenter];
        for(int i=0; i<cluster.cluster.count; i++) {
            XP* xp = cluster.cluster[i];
            CGPoint center = ((NSValue*) XPStarts[i]).CGPointValue;
            UIBezierPath* XPPath = [self getXPLoopPath:center XPEnd:self.XPEndPoint];
            xp.center = center;
            xp.path = XPPath;
            if(reanimate) {
                [self addXPPathAnimation:xp];
            }
        }
    }
}

// Given the desired number of clusters and the average number of XP per cluster, this function randomly chooses the number of XP in each cluster within +/- 7 of avgNumPerCluster, keeping in mind minXPPerCluster. It initializes created XP centers at 0
- (NSMutableArray<XPCluster*>*) initializeXPClustersOnSubViewAtZero: (NSInteger)numClusters avgNumPerCluster: (NSInteger) avgNumPerCluster {
    int clusterHalfRange = 7;
    int numInCluster;
    NSMutableArray* XPClusters = [NSMutableArray new];
    for(int i=0; i<numClusters; i++) {

        // Randomly choose num XP in cluster
        numInCluster = (avgNumPerCluster-clusterHalfRange) + arc4random_uniform(clusterHalfRange*2);
        numInCluster = (numInCluster <= kMinXPPerCluster) ? kMinXPPerCluster : numInCluster;
        NSMutableArray* xpInCluster = [NSMutableArray new];
        for(int j=0; j<numInCluster; j++) {
            XP* xp = [[XP new] initXP:CGPointZero path:[UIBezierPath new]];
            [xpInCluster addObject:xp];
            [self createAndAddXPSubview:xp];
        }
        XPCluster* cluster = [[XPCluster new] initEmptyCluster:CGPointZero];
        cluster.cluster = xpInCluster;
        [XPClusters addObject:cluster];
    }
    return XPClusters;
}

@end
