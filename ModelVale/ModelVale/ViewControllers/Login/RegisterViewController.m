//
//  RegisterViewController.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/4/22.
//

#import "RegisterViewController.h"
#import "Parse/Parse.h"
#import "UIViewController+PresentError.h"
#import "SceneDelegate.h"

@interface RegisterViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (IBAction)didTapCreate:(id)sender {
    [self registerUser];
}

- (void)registerUser {
    // init a user object
    PFUser *newUser = [PFUser user];

    // set user properties
    newUser.username = self.usernameField.text;
    newUser.email = self.emailField.text;
    newUser.password = self.passwordField.text;

    // call sign up function on the object
    [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
        if (error != nil) {
            NSLog(@"Error: %@", error.localizedDescription);
            [self presentError:@"Registration Failed" message:error.localizedDescription error:error];
        }
        else {
            NSLog(@"User registered successfully");
            
            SceneDelegate *sceneDelegate = (SceneDelegate * ) UIApplication.sharedApplication.connectedScenes.allObjects.firstObject.delegate;
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UINavigationController *modelViewController = (UINavigationController*) [storyboard instantiateViewControllerWithIdentifier:@"modelNavController"];

            [sceneDelegate.window setRootViewController:modelViewController];
        }
    }];
}

@end
