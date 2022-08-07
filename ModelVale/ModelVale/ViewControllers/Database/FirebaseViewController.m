//
//  FirebaseViewController.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/28/22.
//

#import "FirebaseViewController.h"
@import FirebaseAuth;
@import FirebaseFirestore;
#import "UIViewController+PresentError.h"
#import "SceneDelegate.h"
#import "ModelLabel.h"
#import <QuartzCore/QuartzCore.h>
#import "ModelViewController.h"

@interface FirebaseViewController ()
@property (nonatomic, strong) FIRAuth* userListener;
@end

@implementation FirebaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if(self.uid == nil) {
        self.uid = [FIRAuth auth].currentUser.uid;
    }
    self.db = [FIRFirestore firestore];
    self.storage = [FIRStorage storage];
//    self.userListener = [[FIRAuth auth]
//        addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
//        self.uid = user.uid;
//        if(self.uid) {
//            // User persisted, do nothing
//        }
//        else {
//            NSLog(@"User NOT %@ persisted", self.uid);
//            [self performLogout];
//        }
//    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated {
//    [self detachUserListener];
}

- (void)performLogout {
    NSError *signOutError;
    BOOL status = [[FIRAuth auth] signOut:&signOutError];
    if (!status) {
        [self presentError:@"Failed to logout" message:signOutError.localizedDescription error:signOutError];
        return;
    }
}

- (void)detachUserListener {
  [[FIRAuth auth] removeAuthStateDidChangeListener:self.userListener];
}

-(void)transitionToLoginVC {
    SceneDelegate *sceneDelegate = (SceneDelegate *) UIApplication.sharedApplication.connectedScenes.allObjects.firstObject.delegate;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    UIViewController *loginViewController = (UIViewController*) [storyboard instantiateViewControllerWithIdentifier:@"loginViewController"];
    [sceneDelegate.window setRootViewController:loginViewController];
}

-(void)transitionToModelVC: (NSMutableArray<AvatarMLModel*>* _Nullable)models uid: (NSString* _Nullable)uid {
    SceneDelegate *sceneDelegate = (SceneDelegate * ) UIApplication.sharedApplication.connectedScenes.allObjects.firstObject.delegate;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *modelNavController = (UINavigationController*) [storyboard instantiateViewControllerWithIdentifier:@"modelNavController"];
    if(models) {
        ModelViewController* modelViewController = (ModelViewController*) modelNavController.viewControllers.firstObject;
        modelViewController.models = models;
        if(uid){
            modelViewController.uid = uid;
        }
    }
    [sceneDelegate.window setRootViewController:modelNavController];
}

-(NSString*) getImageStoragePath: (ModelLabel*)label {
//    NSNumber* dateNum = [NSNumber numberWithDouble: CACurrentMediaTime()];
//    NSString* date = [dateNum stringValue];
    //XXX todo human readable date
    double timestamp = [[NSDate date] timeIntervalSince1970];
    int64_t timeInMilisInt64 = (int64_t)(timestamp*1000);
    NSNumber* dateNum = [NSNumber numberWithDouble:timeInMilisInt64];
    NSString* date = [dateNum stringValue];
    NSString* path = [NSString stringWithFormat:@"/%@/%@", label.testTrainType, date];
    return path;
}

@end
