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
#import <GoogleAPIClientForREST/GTLRDrive.h>
#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>
#import <GTMSessionFetcher/GTMSessionFetcherService.h>
#import <GTMSessionFetcher/GTMSessionFetcherLogging.h>
#import <GoogleAPIClientForREST/GTLRUtilities.h>

#import "UIViewController+PresentError.h"

static NSString *const kClientID = @"482495501232-l6fn3jhv1v00co5jo7pm1os4glgjio58.apps.googleusercontent.com";
NSString *const kGTMAppAuthKeychainItemName = @"ModelVale: Google Drive. GTMAppAuth.";
static NSString *const kRedirectURI =
    @"com.googleusercontent.apps.482495501232-l6fn3jhv1v00co5jo7pm1os4glgjio58:/oauthredirect";

@interface ImportModelViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *modelsTableView;
@property (weak, nonatomic) IBOutlet UITextField *searchFilesField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (nonatomic, readonly) GTLRDriveService *driveService;
@property(nonatomic, strong, nullable) OIDAuthState *authState;
@property(nonatomic, strong, nullable) GTLRDrive_FileList* fileList;
@property(nonatomic, strong) NSMutableArray* fileNames; //XXX
@property(nonatomic, strong) GTLRDrive_File* selectedFile;

@end

@implementation ImportModelViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    id<GTMFetcherAuthorizationProtocol> authorization =
        [GTMAppAuthFetcherAuthorization authorizationFromKeychainForName:kGTMAppAuthKeychainItemName];
    self.driveService.authorizer = authorization;
    self.modelsTableView.delegate = self;
    self.modelsTableView.dataSource = self;
//    self.fileList = [NSMutableArray new];

    //XXX hide sign in if already signed in, otherwise, show
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

- (void)downloadFile:(GTLRDrive_File *)file
    isExportingToPDF:(BOOL)isExporting
    toDestinationURL:(NSURL *)destinationURL {
    
  GTLRDriveService *service = self.driveService;

  GTLRQuery *query;
  if (isExporting) {
    // Note: this will fail if the file type cannot be converted to PDF.
    query = [GTLRDriveQuery_FilesExport queryForMediaWithFileId:file.identifier
                                                       mimeType:@"application/pdf"];
  } else {
    // Download original file.  This will fail if the file type
    // cannot be downloaded in its native server format.
    query = [GTLRDriveQuery_FilesGet queryForMediaWithFileId:file.identifier];
  }

  // GTLR queries are suitable for downloading and exporting small files.
  //
  // For large files, apps typically will want to monitor the progress of a download
  // or to download with a Range request header to specify a subset of bytes.
  //
  // To download large files, get the full NSURLRequest from the GTLR query instead of
  // executing the query.
  //
  // Here's how to download with a GTMSessionFetcher. The fetcher will use the authorizer that's
  // attached to the GTLR service's fetcherService.
  //
  //  NSURLRequest *downloadRequest = [service requestForQuery:query];
  //  GTMSessionFetcher *fetcher = [service.fetcherService fetcherWithRequest:downloadRequest];
  //
  //  [fetcher setCommentWithFormat:@"Downloading %@", file.name];
  //  fetcher.destinationFileURL = destinationURL;
  //
  //  [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
  //    if (error == nil) {
  //      NSLog(@"Download succeeded.");
  //
  //      // With a destinationFileURL property set, the fetcher's callback
  //      // data parameter here will be nil.
  //    }
  //  }];

  [service executeQuery:query
      completionHandler:^(GTLRServiceTicket *callbackTicket,
                          GTLRDataObject *object,
                          NSError *callbackError) {
    NSError *errorToReport = callbackError;
    NSError *writeError;
    if (callbackError == nil) {
        //XXX need to figure out how to use CoreData to get url at which to save the file
      BOOL didSave = [object.data writeToURL:destinationURL
                                     options:NSDataWritingAtomic
                                       error:&writeError];
      if (!didSave) {
        errorToReport = writeError;
      }
    }
    if (errorToReport == nil) {
      // Successfully saved the file.
      //
      // Since a downloadPath property was specified, the data argument is
      // nil, and the file data has been written to disk.
        [self presentError:@"Downloaded" message:destinationURL.path error:nil];
    }
    else {
        [self presentError:@"Error Downloading File" message:errorToReport.localizedDescription error:errorToReport];
    }
  }];
}

- (void) downloadModelFile: (NSString*)fileID {
    //XXX Save in CoreData??
    
}

- (void)fetchFileList: (NSString*)searchTerm completion:(void (^)(NSError*))completion {
    self.fileList = nil;

    GTLRDriveService *service = self.driveService;

    //XXX search for specific files with this query
    GTLRDriveQuery_FilesList *query = [GTLRDriveQuery_FilesList query];
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
            //    self->_fileListFetchError = callbackError;
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
              //XXX Handle failed authentication
        }
    }];

}

//MARK: IBActions
- (IBAction)didTapSignIn:(id)sender {
    
    // get client id and client secret in order to access user's google drive files / ask for permission to do so
    [self runSignIn:^{
        NSLog(@"Ran handler after successful login!");
        [self.signInButton setHidden:YES];
    }];
}

- (void)updateUI {

}

- (IBAction)didTapSearchFiles:(id)sender {
    NSString* searchTerm = self.searchFilesField.text;
    [self fetchFileList:searchTerm completion:^(NSError* error){
        if(error) {
            
        }
        else {
            //XXX
//            if(self.fileList.count == 0) {
//                [self.fileList addObject:@"No results found"];
//            }
            [self.modelsTableView reloadData];
        }
    }];
}

- (IBAction)didTapImportModel:(id)sender {
    
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
//    self.selectedFile = self.fileList[indexPath.row];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fileList.files.count;
}
@end
