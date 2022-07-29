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

@interface FirebaseAuthViewController ()
@property (nonatomic, strong) FIRAuth* userListener;
@end

@implementation FirebaseAuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.userListener = [[FIRAuth auth]
        addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
        self.uid = [FIRAuth auth].currentUser.uid;
        self.db = [FIRFirestore firestore];
        if(self.uid) {
            NSLog(@"User %@ persisted", self.uid);
        }
        else {
            NSLog(@"User NOT %@ persisted", self.uid);
            [self performLogout];
        }
    }];
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


@end
