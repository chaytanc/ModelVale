//
//  SettingsViewController.m
//  ModelVale
//
//  Created by Chaytan Inman on 3/26/23.
//

#import "SettingsViewController.h"
#import "UIViewController+PresentError.h"
#import "User.h"
@import FirebaseAuth;

@interface SettingsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.emailLabel.text = [FIRAuth auth].currentUser.email;
    self.usernameLabel.text = self.username;
}

- (IBAction)didTapDelete:(id)sender {
    // Are you sure alert
    // Deletes user in users database
    // delete account
    // logout
    [self deleteUser];
    
}


@end
