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
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *createButton;


@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loginButton.layer.cornerRadius = 10;
    self.createButton.layer.cornerRadius = 10;
    self.loginButton.clipsToBounds = YES;
    self.createButton.clipsToBounds = YES;
}

- (IBAction)didTapCreate:(id)sender {
    NSLog(@"Tapped Create an Account");
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    UINavigationController* regVC = (UINavigationController*) [storyboard instantiateViewControllerWithIdentifier:@"registerNavController"];
    [self presentViewController:regVC animated:YES completion:nil];
}

- (IBAction)didTapLogin:(id)sender {
    NSString *email = self.emailField.text;
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
