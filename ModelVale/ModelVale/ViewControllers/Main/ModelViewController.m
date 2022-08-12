//
//  ModelViewController.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/4/22.
//

#import "ModelViewController.h"
#import "UIViewController+PresentError.h"
#import "LoginViewController.h"
#import "SceneDelegate.h"
#import "UpdatableSqueezeNet.h"
#import "CoreML/CoreML.h"
#import "AvatarMLModel.h"
#import "DataViewController.h"
#import "RetrainViewController.h"
#import "TestViewController.h"
#import "HealthBarView.h"
#import "XPCluster.h"
#import "XP.h"
#import "GameplayKit/GameplayKit.h"
@import FirebaseAuth;
@import FirebaseFirestore;


CGFloat const kAnimationDuration = 1.9f;
NSInteger const kXPSize = 20;
NSInteger const kMinXPPerCluster = 15;
BOOL const kDebugAnimations = NO;
NSInteger const kSeedXOffset = 30;
NSInteger const kSeedYOffset = 100;
NSInteger const kSigmaXDivisor = 6;
NSInteger const kSigmaYDivisor = 6;
// UI consts
NSInteger const kCornerRadius = 10;

@interface ModelViewController () <CAAnimationDelegate>
@property (weak, nonatomic) IBOutlet UILabel *modelNameLabel;
@property (nonatomic, assign) NSInteger modelIndex;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *detailsView;
@property (weak, nonatomic) IBOutlet UIStackView *avatarStackView;
@property (weak, nonatomic) IBOutlet HealthBarView *healthBarView;
@property (weak, nonatomic) IBOutlet UILabel *healthLabel;
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (weak, nonatomic) IBOutlet UIButton *trainButton;
@property (weak, nonatomic) IBOutlet UIButton *dataButton;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;

@property (strong, nonatomic) AvatarMLModel* model;
@property (nonatomic, assign) NSInteger numClusters;
@property (nonatomic, assign) CGPoint XPEndPoint;
@property (nonatomic,strong) NSMutableArray<XPCluster*>* clusters;

@end

@implementation ModelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.testButton.layer.cornerRadius = kCornerRadius;
    self.trainButton.layer.cornerRadius = kCornerRadius;
    self.dataButton.layer.cornerRadius = kCornerRadius;
    self.modelIndex = 0;
    self.earnedXP = 0;
    self.shouldAnimateXP = YES;
    
    self.numClusters = 3;
    NSInteger avgNumXPPerCluster = 100;
    
    self.models = [NSMutableArray new];
    //XXX todo refactor to rely on self.models always being set before transition and catch error and refetch if not, or log out. Then only refetch when we know new models are uploaded. Does need to update once when the app first launches to initially get all the models the user has access to in userModelRefs
    [self fetchAndSetVCModels:^{
        [self configUIBasedOnModel];
        [self.healthBarView initWithAnimationsOfDuration:kAnimationDuration maxHealth:AvatarMLModel.maxHealth.integerValue health:[self getCurrModel:self.modelIndex].health.integerValue];
        [self.healthBarView animateFillingHealthBar:self.healthBarView.healthPath layer:self.healthBarView.healthShapeLayer];
        //XXX todo make clusters hidden until we want to animate them
        self.clusters = [self initializeXPClustersOnSubViewAtZero:self.numClusters avgNumPerCluster:avgNumXPPerCluster];
        [self hideAllXPImageViews];
    }];

}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self setHealthBarPropsForXP];
    [self setXPPathsAndClusterCenters:self.seed reanimate:FALSE];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(self.shouldAnimateXP && self.clusters) {
        [self showAllXPImageViews];
        [self animateXPClusters:self.clusters];
    }
}

// Gets models that the user has access to and adds them to the local array of AvatarMLModels, self.models
- (void) fetchAndSetVCModels: (void(^_Nullable)(void))completion {
    FIRDocumentReference* docRef = [[self.db collectionWithPath:@"users"] documentWithPath:self.uid];
    [docRef getDocumentWithCompletion:^(FIRDocumentSnapshot *snapshot, NSError *error) {
        if(error != nil) {
            [self presentError:@"Failed to fetch user models" message:error.localizedDescription error:error];
        }
        else {
            NSMutableArray* userModelDocRefs = snapshot.data[@"models"];
            [self setLocalModels:userModelDocRefs completion:^{
                completion();
            }];
        }
    }];
}

- (void) setLocalModels: (NSMutableArray<NSString*>*)userModelDocRefs completion: (void(^_Nullable)(void))completion {
    dispatch_group_t asyncGroup = dispatch_group_create();
    for(NSString* modelName in userModelDocRefs) {
        dispatch_group_enter(asyncGroup);
        [AvatarMLModel fetchAndReturnExistingModel:self.db storage: self.storage documentPath:modelName completion:^(AvatarMLModel * _Nonnull model) {
            [self.models addObject:model];
            dispatch_group_leave(asyncGroup);
        }];
    }
    dispatch_group_notify(asyncGroup, dispatch_get_main_queue(), ^{
        completion();
    });
}

- (AvatarMLModel*) getCurrModel: (NSInteger) ind {
    NSInteger relInd = ind % self.models.count;
    if(self.models.count == 0) {
        [self performLogout];
//        [self transitionToLoginVC];
        NSLog(@"No models found, logging out");
        return [AvatarMLModel new];
    }
    else {
        return self.models[relInd];
    }
}

- (void) configUIBasedOnModel {
    self.model = [self getCurrModel:self.modelIndex];
    self.avatarImageView.image = self.model.avatarImage;
    self.nameLabel.text = self.model.avatarName;
    self.modelNameLabel.text = self.model.modelName;
}
- (IBAction)didTapLeftNext:(id)sender {
    self.modelIndex -= 1;
    [self configUIBasedOnModel];
    //XXX todo could refactor to avoid fully reinitializing and only redrawing the layer that has the gradient, but marginal difference
    [self.healthBarView initWithAnimationsOfDuration:kAnimationDuration maxHealth:AvatarMLModel.maxHealth.integerValue health:self.model.health.integerValue];
    [self.healthBarView animateFillingHealthBar:self.healthBarView.healthPath layer:self.healthBarView.healthShapeLayer];
}
- (IBAction)didTapRightNext:(id)sender {
    self.modelIndex += 1;
    [self configUIBasedOnModel];
    [self.healthBarView initWithAnimationsOfDuration:kAnimationDuration maxHealth:AvatarMLModel.maxHealth.integerValue health:self.model.health.integerValue];
    [self.healthBarView animateFillingHealthBar:self.healthBarView.healthPath layer:self.healthBarView.healthShapeLayer];
}

- (IBAction)didTapLogout:(id)sender {
    NSLog(@"Logout Tapped");
    [self performLogout];
    [self transitionToLoginVC];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier] isEqualToString:@"modelToData"]) {
        DataViewController* targetController = (DataViewController*) [segue destinationViewController];
        targetController.model = self.model;
    }
    else if ([segue.identifier isEqualToString:@"modelToTest"]) {
        TestViewController* target = (TestViewController*) [segue destinationViewController];
        target.model = self.model;
    }
    else if ([segue.identifier isEqualToString:@"modelToRetrain"]) {
        RetrainViewController* target = (RetrainViewController*) [segue destinationViewController];
        target.model = self.model;
    }
}
//MARK: XP animations

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

