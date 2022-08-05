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

@interface FirebaseViewController ()
@property (nonatomic, strong) FIRAuth* userListener;
@end

@implementation FirebaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.uid = [FIRAuth auth].currentUser.uid;
    self.db = [FIRFirestore firestore];
    self.storage = [FIRStorage storage];
    self.userListener = [[FIRAuth auth]
        addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
        self.uid = [FIRAuth auth].currentUser.uid;
        if(self.uid) {
            // User persisted, do nothing
        }
        else {
            NSLog(@"User NOT %@ persisted", self.uid);
            [self performLogout];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated {
    [self detachUserListener];
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

-(void)transitionToModelVC {
    SceneDelegate *sceneDelegate = (SceneDelegate * ) UIApplication.sharedApplication.connectedScenes.allObjects.firstObject.delegate;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *modelViewController = (UINavigationController*) [storyboard instantiateViewControllerWithIdentifier:@"modelNavController"];
    [sceneDelegate.window setRootViewController:modelViewController];
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
