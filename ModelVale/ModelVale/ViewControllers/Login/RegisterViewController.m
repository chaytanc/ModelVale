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
@property (strong, nonatomic) FIRFirestore* db;

@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.db = [FIRFirestore firestore];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [[FIRAuth auth]
//                   addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
//
//    }];
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
            [self presentError:@"Failed to login" message:error.localizedDescription error:error];
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
                    NSString* uid = [[FIRAuth auth] currentUser].uid;
                    StarterModels* starters = [[StarterModels new] initStarterModels:uid];
                    [starters uploadStarterModels:uid db:self.db vc:self];
                    [self transitionToModelVC];
                }
            }];
        }
    }];
}

-(void) transitionToModelVC {
    SceneDelegate *sceneDelegate = (SceneDelegate * ) UIApplication.sharedApplication.connectedScenes.allObjects.firstObject.delegate;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *modelViewController = (UINavigationController*) [storyboard instantiateViewControllerWithIdentifier:@"modelNavController"];
    [sceneDelegate.window setRootViewController:modelViewController];
}
@end
