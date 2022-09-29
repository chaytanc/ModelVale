//
//  ImportModelViewController.m
//  ModelVale
//
//  Created by Chaytan Inman on 9/12/22.
//

//@import AppAuth;
//@import GTMAppAuth;

#import "ImportModelViewController.h"
#import "ImportModelCell.h"
#import "AppDelegate.h"
#import "SceneDelegate.h"
#import <GoogleAPIClientForREST/GTLRDrive.h>
#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>
#import <GTMSessionFetcher/GTMSessionFetcherService.h>
#import <GTMSessionFetcher/GTMSessionFetcherLogging.h>
#import <GoogleAPIClientForREST/GTLRUtilities.h>

#import "UIViewController+PresentError.h"
#import "ModelPopupView.h"
#import "ModelViewController.h"
#import "User.h"

static NSString *const kClientID = @"482495501232-l6fn3jhv1v00co5jo7pm1os4glgjio58.apps.googleusercontent.com";
NSString *const kGTMAppAuthKeychainItemName = @"ModelVale: Google Drive. GTMAppAuth.";
static NSString *const kRedirectURI =
    @"com.googleusercontent.apps.482495501232-l6fn3jhv1v00co5jo7pm1os4glgjio58:/oauthredirect";
static NSString* const kNoFilesString = @"No files found.";

@interface ImportModelViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, ModelPopupDelegate>
@property (weak, nonatomic) IBOutlet UITableView *modelsTableView;
@property (weak, nonatomic) IBOutlet UITextField *searchFilesField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *searchFilesButton;
@property (weak, nonatomic) IBOutlet UIButton *importButton;
@property (nonatomic, readonly) GTLRDriveService *driveService;
@property(nonatomic, strong, nullable) OIDAuthState *authState;
@property(nonatomic, strong, nullable) GTLRDrive_FileList* fileList;
@property(nonatomic, strong) GTLRDrive_File* selectedFile;

@end

@implementation ImportModelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    id<GTMFetcherAuthorizationProtocol> authorization =
        [GTMAppAuthFetcherAuthorization authorizationFromKeychainForName:kGTMAppAuthKeychainItemName];
    self.driveService.authorizer = authorization;
    if(authorization.canAuthorize) {
        [self.signInButton setHidden:YES];
    }
    else {
        [self.signInButton setHidden:NO];
    }
    self.searchFilesField.delegate = self;
    self.modelsTableView.delegate = self;
    self.modelsTableView.dataSource = self;
    self.signInButton.layer.cornerRadius = 10;
    self.searchFilesButton.layer.cornerRadius = 10;
    self.importButton.layer.cornerRadius = 10;
}

// Dismiss keyboard when return button is hit
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (GTLRDriveService *)driveService {
  static GTLRDriveService *service;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    service = [[GTLRDriveService alloc] init];
    // Turn on the library's shouldFetchNextPages feature to ensure that all items
    // are fetched.  This applies to queries which return an object derived from
    // GTLRCollectionObject.
    service.shouldFetchNextPages = YES;
    // Have the service object set tickets to retry temporary error conditions
    // automatically
    service.retryEnabled = YES;
  });
  return service;
}

- (void)fetchFileList: (NSString*)searchTerm completion:(void (^)(NSError*))completion {
    self.fileList = nil;

    GTLRDriveService *service = self.driveService;
    GTLRDriveQuery_FilesList *query = [GTLRDriveQuery_FilesList query];
    // Searches for the term in the searchField
    query.q = [NSString stringWithFormat:@"name contains '%@'", searchTerm];

    // Because GTLRDrive_FileList is derived from GTLCollectionObject and the service
    // property shouldFetchNextPages is enabled, this may do multiple fetches to
    // retrieve all items in the file list.

    // Google APIs typically allow the fields returned to be limited by the "fields" property.
    // The Drive API uses the "fields" property differently by not sending most of the requested
    // resource's fields unless they are explicitly specified.
    query.fields = @"kind,nextPageToken,files(mimeType,id,kind,name,webViewLink,thumbnailLink,trashed)";

    GTLRServiceTicket* fileListTicket = [service executeQuery:query
                        completionHandler:^(GTLRServiceTicket *callbackTicket,
                                            GTLRDrive_FileList *fileList,
                                            NSError *callbackError) {
        if(callbackError) {
            [self presentError:@"Error searching Drive files" message:callbackError.localizedDescription error:callbackError];
        }
        else {
            self.fileList = fileList;
            completion(callbackError);
        }
    }];
}

// Docs: https://github.com/openid/AppAuth-iOS
- (void) runSignIn: (void (^)(void))handler {
    
    NSURL *redirectURI = [NSURL URLWithString:kRedirectURI];
    // Builds authentication request.
    OIDServiceConfiguration *configuration =
        [GTMAppAuthFetcherAuthorization configurationForGoogle];
    // Applications that only need to access files created by this app should
    // use the kGTLRAuthScopeDriveFile scope.
    NSArray<NSString *> *scopes = @[ kGTLRAuthScopeDrive, OIDScopeEmail ];
    OIDAuthorizationRequest *request =
        [[OIDAuthorizationRequest alloc] initWithConfiguration:configuration
                                                      clientId:kClientID
                                                        scopes:scopes
                                                   redirectURL:redirectURI
                                                  responseType:OIDResponseTypeCode
                                          additionalParameters:nil];

    // performs authentication request
    AppDelegate *appDelegate =
        (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.currentAuthorizationFlow =
        [OIDAuthState authStateByPresentingAuthorizationRequest:request
            presentingViewController:self
                            callback:^(OIDAuthState *_Nullable authState,
                                       NSError *_Nullable error) {
        if (authState) {
            NSLog(@"Got authorization tokens. Access token: %@",
                  authState.lastTokenResponse.accessToken);
            [self setAuthState:authState];
              // Creates a GTMAppAuthFetcherAuthorization object for authorizing requests.
              GTMAppAuthFetcherAuthorization *gtmAuthorization =
                  [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:authState];

              // Sets the authorizer on the GTLRYouTubeService object so API calls will be authenticated.
              self.driveService.authorizer = gtmAuthorization;

              // Serializes authorization to keychain in GTMAppAuth format.
              [GTMAppAuthFetcherAuthorization saveAuthorization:gtmAuthorization
                                              toKeychainForName:kGTMAppAuthKeychainItemName];

              // Executes post sign-in handler.
              if (handler) handler();
        }
        else {
            NSLog(@"Authorization error: %@", [error localizedDescription]);
            [self setAuthState:nil];
            [self presentError:@"Authentication failed" message:error.localizedDescription error:error];
        }
    }];

}

//MARK: Download
- (NSURL*) getFileDestination: (GTLRDrive_File*)file {
    NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsURL = [paths lastObject];
    NSURL* destURL = [documentsURL URLByAppendingPathComponent:file.name];
    //XXX alert if overwriting existing file
    return destURL;
}

- (BOOL) checkMLModelFile:(GTLRDrive_File *)file {
    if([file.name containsString:@"mlmodel"]) {
        return YES;
    }
    return NO;
}

- (void)downloadFile:(GTLRDrive_File *)file completion:(void (^)(NSURL* destinationURL))completion {
    
    GTLRDriveService *service = self.driveService;
    GTLRQuery *query;
    // Download original file.  This will fail if the file type
    // cannot be downloaded in its native server format.
    query = [GTLRDriveQuery_FilesGet queryForMediaWithFileId:file.identifier];

    [service executeQuery:query
      completionHandler:^(GTLRServiceTicket *callbackTicket,
                          GTLRDataObject *object,
                          NSError *callbackError) {
        NSError *errorToReport = callbackError;
        NSError *writeError;
        NSURL* destinationURL = [self getFileDestination:file];
        if (callbackError == nil) {
            BOOL didSave = [object.data writeToURL:destinationURL
                                         options:NSDataWritingAtomic
                                           error:&writeError];
            if (!didSave) {
                errorToReport = writeError;
            }
        }
        if (errorToReport == nil) {
            NSString* success = [NSString stringWithFormat:@"Successfully downloaded file %@", file.name];
            [self presentError:success message:destinationURL.path error:nil];
            completion(destinationURL);
        }
        else {
            [self presentError:@"Error downloading File" message:errorToReport.localizedDescription error:errorToReport];
        }
    }];
}

- (void) makePopup: (NSURL*)modelURL {
    AvatarMLModel* model = [[AvatarMLModel new] initWithModelName:self.selectedFile.name avatarName:@""];
    ModelPopupView* popup = [ModelPopupView new];
    model.modelURL = modelURL;
    popup.model = model;
    popup.modelNameField.delegate = self;
    popup.delegate = self;
    [UIView animateWithDuration:1 animations:^{
        popup.alpha = 0.95;
    }];
    int frameHeight = self.view.frame.size.height * 0.45;
    int frameWidth = self.view.frame.size.width * 0.80;
    popup.frame = CGRectMake(self.view.center.x - (frameWidth/2), self.view.center.y - (frameHeight/2), frameWidth, frameHeight);
    [self.view addSubview:popup];
}

//MARK: IBActions
- (IBAction)didTapSignIn:(id)sender {
    
    // get client id and client secret in order to access user's google drive files / ask for permission to do so
    [self runSignIn:^{
        NSLog(@"Ran handler after successful login!");
        [self.signInButton setHidden:YES];
    }];
}

- (IBAction)didTapHelp:(id)sender {
    NSString* message = @"To run models on iOS, you can convert Keras and PyTorch models into compatible .mlmodel files. Click Ok for an external tutorial.";
    NSString* title = @"Learn how to create Apple CoreML models";
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                   message:message
                                   preferredStyle:UIAlertControllerStyleAlert];

    NSURL* url = [NSURL URLWithString: @"https://coremltools.readme.io/docs/unified-conversion-api"];
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault
       handler:^(UIAlertAction * action) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
            if (success) {
                NSLog(@"Opened CoreMLTools help");
            }
        }];
    }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
       handler:^(UIAlertAction * action) {}];

    [alert addAction:okAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)didTapSearchFiles:(id)sender {
    NSString* searchTerm = self.searchFilesField.text;
    [self fetchFileList:searchTerm completion:^(NSError* error){
        if(error) {
            
        }
        else {
            // A little magic to make empty searches display no files found message
            if(self.fileList.files.count == 0) {
                GTLRDrive_File* fakeFile = [GTLRDrive_File new];
                [fakeFile setName:kNoFilesString];
                GTLRDrive_FileList* fakeFiles = [GTLRDrive_FileList new];
                [fakeFiles setFiles:[NSArray arrayWithObject:fakeFile]];
                self.fileList = fakeFiles;
            }
            [self.modelsTableView reloadData];
        }
    }];
}

- (IBAction)didTapImportModel:(id)sender {
    if([self checkMLModelFile:self.selectedFile]) {
        [self downloadFile:self.selectedFile completion:^ (NSURL* destinationURL){
            [self makePopup: destinationURL];
        }];
    }
    else {
        [self presentError:@"Incompatible file type" message:@"Please select a .mlmodel file type" error:nil];
    }
}

- (void)modelMadeCompletion:(nonnull AvatarMLModel *)model {
    [model uploadModel:self.user db:self.db storage:self.storage vc:self completion:^(NSError * _Nonnull error) {
        // Transition to main if no error
        if(error) {
            [self presentError:@"Error, please try again" message:error.localizedDescription error:error];
        }
        else {
            [self presentError:@"Successfully uploaded new model" message:@"Yay!" error:nil];
            [self.user.userModelDocRefs addObject:model.avatarName];
            [self.user updateUserModelDocRefs:self.db vc:self completion:^(NSError *updateError) {
                SceneDelegate *sceneDelegate = (SceneDelegate *) UIApplication.sharedApplication.connectedScenes.allObjects.firstObject.delegate;
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                UINavigationController *modelVC = (UINavigationController*) [storyboard instantiateViewControllerWithIdentifier:@"modelNavController"];
                [sceneDelegate.window setRootViewController:modelVC];
            }];
        }
    }];
}

//MARK: Tableview

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ImportModelCell* cell = [self.modelsTableView dequeueReusableCellWithIdentifier:@"importModelCell"];
    GTLRDrive_File *item = self.fileList.files[indexPath.row];
    cell.modelFileLabel.text = item.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    GTLRDrive_File *item = self.fileList.files[indexPath.row];
    self.selectedFile = item;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fileList.files.count;
}

@end
