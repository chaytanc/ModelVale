//
//  LoginViewController.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/4/22.
//

#import "LoginViewController.h"
#import "SceneDelegate.h"
//#import "Parse/Parse.h"
#import "UIViewController+PresentError.h"
#import "RegisterViewController.h"
@import FirebaseCore;
@import FirebaseFirestore;
@import FirebaseAuth;

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;


@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)didTapCreate:(id)sender {
    NSLog(@"Tapped Create an Account");
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    UINavigationController* regVC = (UINavigationController*) [storyboard instantiateViewControllerWithIdentifier:@"registerNavController"];
    [self presentViewController:regVC animated:YES completion:nil];
}

- (IBAction)didTapLogin:(id)sender {
    NSString *email = self.usernameField.text;
    NSString *password = self.passwordField.text;
    [[FIRAuth auth] signInWithEmail:email
                           password:password
                         completion:^(FIRAuthDataResult * _Nullable authResult,
                                      NSError * _Nullable error) {
        if(error != nil) {
            [self presentError:@"Failed to login" message:error.localizedDescription error:error];
        }
        else {
            NSLog(@"User logged in successfully");
            
            SceneDelegate *sceneDelegate = (SceneDelegate * ) UIApplication.sharedApplication.connectedScenes.allObjects.firstObject.delegate;
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UINavigationController *modelViewController = (UINavigationController*) [storyboard instantiateViewControllerWithIdentifier:@"modelNavController"];

                
            [sceneDelegate.window setRootViewController:modelViewController];
        }
    }];
}

@end
