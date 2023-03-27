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
#import "User.h"

@interface FirebaseViewController ()
@property (nonatomic, strong) FIRAuth* userListener;
@end

@implementation FirebaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.db = [FIRFirestore firestore];
    self.storage = [FIRStorage storage];
    self.user = [[User new] initUser:[FIRAuth auth].currentUser.uid username:@"" db: self.db];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void) deleteUser {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Are you sure?"
                                   message:@"This action will permanently delete your account."
                                   preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive
       handler:^(UIAlertAction * action) {
        NSLog(@"Deleting account!");

        // delete account
        FIRUser *user = [FIRAuth auth].currentUser;
        [user deleteWithCompletion:^(NSError *_Nullable error) {
          if (error) {
              [self presentError:@"An error occurred" message:error.debugDescription error:error];
          } else {
              // delete user data
              [[[self.db collectionWithPath:@"users"] documentWithPath:self.user.uid]
                  deleteDocumentWithCompletion:^(NSError * _Nullable error) {
                    if (error != nil) {
                        NSLog(@"Error removing document: %@", error);
                        [self presentError:@"An error occurred" message:error.debugDescription error:error];
                    } else {
                        NSLog(@"Document successfully removed!");
                        [FirebaseViewController transitionToLoginVC];
                    }
              }];
          }
        }];

    }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
       handler:^(UIAlertAction * action) {
        // dismiss alert
    }];

    [alert addAction:deleteAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
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

+ (void)transitionToLoginVC {
    SceneDelegate *sceneDelegate = (SceneDelegate *) UIApplication.sharedApplication.connectedScenes.allObjects.firstObject.delegate;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    UIViewController *loginViewController = (UIViewController*) [storyboard instantiateViewControllerWithIdentifier:@"loginViewController"];
    [sceneDelegate.window setRootViewController:loginViewController];
}

+ (void)transitionToModelVC: (NSMutableArray<AvatarMLModel*>* _Nullable)models uid: (NSString* _Nullable)uid {
    SceneDelegate *sceneDelegate = (SceneDelegate * ) UIApplication.sharedApplication.connectedScenes.allObjects.firstObject.delegate;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *modelNavController = (UINavigationController*) [storyboard instantiateViewControllerWithIdentifier:@"modelNavController"];
    if(models) {
        ModelViewController* modelViewController = (ModelViewController*) modelNavController.viewControllers.firstObject;
        modelViewController.models = models;
        if(uid){
            modelViewController.user.uid = uid;
        }
    }
    [sceneDelegate.window setRootViewController:modelNavController];
}


- (NSString*) getImageStoragePath: (ModelLabel*)label {
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
