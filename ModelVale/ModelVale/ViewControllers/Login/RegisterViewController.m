//
//  RegisterViewController.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/4/22.
//

#import "RegisterViewController.h"
@import FirebaseAuth;
#import "UIViewController+PresentError.h"
#import "SceneDelegate.h"
#import "StarterModels.h"
@import FirebaseFirestore;

@interface RegisterViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *createButton;

@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.createButton.layer.cornerRadius = 10;
    self.createButton.clipsToBounds = YES;
}

- (IBAction)didTapCreate:(id)sender {
    [self registerUser];
}

- (void)registerUser {
    [[FIRAuth auth] createUserWithEmail:self.emailField.text
                               password:self.passwordField.text
                             completion:^(FIRAuthDataResult * _Nullable authResult,
                                          NSError * _Nullable error) {
        if(error != nil) {
            [self presentError:@"Failed to register" message:error.localizedDescription error:error];
        }
        else {
            FIRUserProfileChangeRequest *changeRequest = [[FIRAuth auth].currentUser profileChangeRequest];
            changeRequest.displayName = self.usernameField.text;
            [changeRequest commitChangesWithCompletion:^(NSError *_Nullable error) {
                
                if(error != nil) {
                    [self presentError:@"Failed to add username" message:error.localizedDescription error:error];
                }
                else {
                    
                    NSLog(@"User registered successfully");
                    NSString* uid = authResult.user.uid;
                    StarterModels* starters = [[StarterModels new] initStarterModels:uid];
                    [starters uploadStarterModels:uid db:self.db storage:self.storage vc:self completion:^(NSError * _Nonnull error) {
                        if(error != nil) {
                            [self presentError:@"Error making models for new user" message:error.localizedDescription error:error];
                        }
                        else {
                            [self transitionToModelVC:starters.models uid:uid];
                        }
                    }];
                }
            }];
        }
    }];
}

@end
