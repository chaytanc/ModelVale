//
//  ModelViewController.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/4/22.
//

#import "ModelViewController.h"
#import "Parse/Parse.h"
#import "UIViewController+PresentError.h"
#import "LoginViewController.h"
#import "SceneDelegate.h"
#import "UpdatableSqueezeNet.h"
#import "CoreML/CoreML.h"

@interface ModelViewController ()
@property (weak, nonatomic) NSMutableArray* models;
@property (weak, nonatomic) IBOutlet UIView *healthBarView;
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (weak, nonatomic) IBOutlet UIButton *trainButton;
@property (weak, nonatomic) IBOutlet UIButton *dataButton;

@end

@implementation ModelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.testButton.layer.cornerRadius = 10;
    self.trainButton.layer.cornerRadius = 10;
    self.dataButton.layer.cornerRadius = 10;

}

- (void) configureModel {
    
}

- (IBAction)didTapLogout:(id)sender {
    NSLog(@"Logout Tapped");
    [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
        // PFUser.current() will now be nil
        if(error != nil) {
            [self presentError:@"Logout Failed" message:error.localizedDescription error:error];
        }
        else {
            SceneDelegate *sceneDelegate = (SceneDelegate * ) UIApplication.sharedApplication.connectedScenes.allObjects.firstObject.delegate;
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
            LoginViewController *loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"loginViewController"];

            [sceneDelegate.window setRootViewController:loginViewController];
        }
    }];
}

@end
