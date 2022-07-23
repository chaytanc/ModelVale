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
#import "AvatarMLModel.h"
#import "StarterModels.h"


@interface ModelViewController ()
@property (weak, nonatomic) NSMutableArray<AvatarMLModel*>* models;
@property (nonatomic, assign) NSInteger modelInd;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *healthBarView;
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (weak, nonatomic) IBOutlet UIButton *trainButton;
@property (weak, nonatomic) IBOutlet UIButton *dataButton;
@property (nonatomic, strong) PFUser* user;

@end

@implementation ModelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.testButton.layer.cornerRadius = 10;
    self.trainButton.layer.cornerRadius = 10;
    self.dataButton.layer.cornerRadius = 10;
    self.modelInd = 0;
    self.user = [PFUser currentUser];
    self.models = [[StarterModels new] initStarterModels: self.user]; //XXX todo upload baseline models to user in registration
    [self configureModel];

}

- (AvatarMLModel*) getCurrModel: (NSInteger) ind {
    NSInteger relInd = ind % self.models.count;
    return self.models[relInd];
}

- (void) configureModel {
    NSString* name = self.nameLabel.text;
    AvatarMLModel* model = [[AvatarMLModel new] initWithModelName:@"UpdatableSqueezeNet" avatarName: name user: self.user];
    [self.models addObject:model];
    [model uploadModelToUserWithViewController:self.user vc:self];
}
- (IBAction)didTapLeftNext:(id)sender {
    self.modelInd -= 1;
    //XXX todo update which model is showing by fetching etc

}
- (IBAction)didTapRightNext:(id)sender {
    self.modelInd += 1;
    //XXX todo update which model is showing by fetching etc
}

- (IBAction)didTapLogout:(id)sender {
    NSLog(@"Logout Tapped");
    [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
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

