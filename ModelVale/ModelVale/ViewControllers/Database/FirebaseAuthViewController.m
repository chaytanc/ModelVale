//
//  FirebaseViewController.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/28/22.
//

#import "FirebaseAuthViewController.h"
@import FirebaseAuth;
@import FirebaseFirestore;
#import "UIViewController+PresentError.h"
#import "SceneDelegate.h"
#import "ModelLabel.h"
#import <QuartzCore/QuartzCore.h>

@interface FirebaseAuthViewController ()
@property (nonatomic, strong) FIRAuth* userListener;
@end

@implementation FirebaseAuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.uid = [FIRAuth auth].currentUser.uid;
    self.db = [FIRFirestore firestore];
    self.storage = [FIRStorage storage];
    self.userListener = [[FIRAuth auth]
        addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
        self.uid = [FIRAuth auth].currentUser.uid;
        if(self.uid) {
            NSLog(@"User %@ persisted", self.uid);
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
    NSNumber* dateNum = [NSNumber numberWithDouble: CACurrentMediaTime()];
    NSString* date = [dateNum stringValue];
    NSString* path = [NSString stringWithFormat:@"/%@/%@", label.testTrainType, date];
    return path;
}

@end
