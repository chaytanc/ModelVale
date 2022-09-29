//
//  DisplayDataFirebaseViewController.m
//  ModelVale
//
//  Created by Chaytan Inman on 8/3/22.
//

#import "DisplayDataFirebaseViewController.h"
#import "AvatarMLModel.h"
#import "ModelLabel.h"
#import "ModelData.h"
#import "TestTrainEnum.h"

NSInteger const kLabelQueryLimit = 20;
NSInteger const kDataQueryLimit = 2;

@interface DisplayDataFirebaseViewController ()
@end

@implementation DisplayDataFirebaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void) createFakeData: (NSMutableArray<ModelLabel*>*)modelArray {
    // We create two labels, the first has two images the second has one image, this represents all the training data that was
    ModelLabel* fakeLabel = [[ModelLabel new] initEmptyLabel:@"alp" testTrainType:dataTypeEnumToString(Train)];
    UIImage* testImage = [UIImage imageNamed:@"mountain"];
    ModelData* fakeData = [ModelData initWithImage:testImage label:fakeLabel.label imagePath:@"1"];
    [fakeLabel.localData addObject:fakeData];
    testImage = [UIImage imageNamed:@"rivermountain"];
    fakeData = [ModelData initWithImage:testImage label:fakeLabel.label imagePath:@"2"];
    [fakeLabel.localData addObject:fakeData];
    [modelArray addObject:fakeLabel];
    fakeLabel = [[ModelLabel new] initEmptyLabel:@"vulture" testTrainType:dataTypeEnumToString(Train)];
    testImage = [UIImage imageNamed:@"snowymountains"];
    fakeData = [ModelData initWithImage:testImage label:fakeLabel.label imagePath:@"1"];
    [fakeLabel.localData addObject:fakeData];
    [modelArray addObject:fakeLabel];
}

- (void) initProgressBar {
    self.loadingBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.loadingBar.progress = 0;
    self.loadingBar.tintColor = [UIColor colorWithRed:125.0f/255.0f green:65.0f/255.0f blue:205.0f/255.0f alpha:1.0f];;
    self.loadingBar.backgroundColor = [UIColor systemGray5Color];
    [self.loadingBar.layer setCornerRadius:10];
    self.loadingBar.layer.masksToBounds = TRUE;
    self.loadingBar.clipsToBounds = TRUE;
    CGAffineTransform transform = CGAffineTransformMakeScale(2.0f, 1.5f);
    self.loadingBar.transform = transform;
    [self.loadingBar setCenter:CGPointMake(self.view.layer.frame.size.width/2, self.view.layer.frame.size.height/2)];
    [self.view addSubview: self.loadingBar];
}

// MARK: Fetch data

// Stores as arrays of ModelData accessible in self.modelLabels[X].localData[Y]
// First fetches the Model in order to get its associated labels (since multiple users can add to the model, so we can't rely on local data to be up to date)
// Then fetches a limited number of labels based on the references the model contained
// Fetches all data from each of those labels and displays it
- (void) fetchSomeDataOfModel: (void(^_Nullable)(float progress))progressCompletion allDataFetchedCompletion:(void(^_Nullable)(void))completion {
    [self fetchModelWithCompletion:^{
        [self fetchSomeLabelsWithCompletion:progressCompletion allDataFetchedCompletion:completion];
    }];
}

// Adds labels fetched to self.modelLabels
// Stores as arrays of ModelData accessible in self.modelLabels[X].localData[Y]
- (void) fetchAllDataOfModelWithType: (testTrain)testTrainType dataPerLabel: (NSInteger)dataPerLabel progressCompletion: (void(^_Nullable)(float progress))progressCompletion completion: (void(^_Nullable)(void))completion {
    self.modelLabels = [NSMutableArray new];
    [self fetchModelWithCompletion:^{
        [self fetchAllLabelsWithType:testTrainType dataPerLabel:dataPerLabel progressCompletion:progressCompletion completion:^{
            if(completion){
                completion();
            }
        }];
    }];
}

- (void) fetchModelWithCompletion:(void(^)(void))completion {
    FIRDocumentReference *modelRef = [[self.db collectionWithPath:@"Model"] documentWithPath:self.model.avatarName];
    [modelRef getDocumentWithCompletion:^(FIRDocumentSnapshot * _Nullable snapshot, NSError * _Nullable error) {
        [AvatarMLModel initWithDictionary:snapshot.data storage:self.storage completion:^(AvatarMLModel * model) {
            completion();
        }];
    }];
}

// Updates label objects created to the self.modelLabels property
- (void) fetchSomeLabelsWithCompletion:(void(^_Nullable)(float progress))progressCompletion allDataFetchedCompletion:(void(^_Nullable)(void))completion {
    
    int originalLabelFetchStart = self.labelFetchStart;
    float labelFetchEnd = self.labelFetchStart + kLabelQueryLimit;
    __block float labelsToFetch = MIN(labelFetchEnd, self.model.labeledData.count);
    __block int labelsFetched = 0;
    dispatch_group_t prepareWaitingGroup = dispatch_group_create();
    // Loop through all labels this model holds refs to, up to the kLabelQueryLimit, and create those ModelLabel objects
    for(int i=self.labelFetchStart; i<labelsToFetch; i++) {
        FIRDocumentReference* ref = self.model.labeledData[i];
        dispatch_group_enter(prepareWaitingGroup);
        // Create the ModelLabel object from the fetched data
        [ModelLabel fetchFromReference:ref vc:self completion:^(ModelLabel* _Nonnull modelLabel) {
            modelLabel.firebaseRef = ref;
            [self.modelLabels addObject:modelLabel];
            // Fetch the data on each ModelLabel and then increment the number of labels fetched when done with self.labelFetchStart
            [self fetchAndCreateData:modelLabel queryLimit:kDataQueryLimit completion:^(NSError * error) {
                if(error) {
                    labelsToFetch -= 1;
                }
                else {
                    if(progressCompletion) {
                        labelsFetched += 1;
                        float progress = labelsFetched / labelsToFetch;
                        progressCompletion(progress);
                    }
                    self.labelFetchStart += 1;
                }
                dispatch_group_leave(prepareWaitingGroup);
            }];
        }];
    }
    // At this point we have locally created ModelLabel objs AND all data from the models references and can continue
    dispatch_group_notify(prepareWaitingGroup, dispatch_get_main_queue(), ^{
        NSLog(@"Fetched group of labels %d to %f", originalLabelFetchStart, labelFetchEnd);
        if(completion){
            completion();
        }
    });
}

// Fetches all ModelData documents in the subcollection on ModelLabel and creates those objects locally by updating fetched data on the label.localData property
// Query is paginated so that only kDataQueryLimit data are fetched per label
- (void) fetchAndCreateData: (ModelLabel*)label queryLimit: (NSInteger)queryLimit completion:(void(^_Nullable)(NSError*))completion {
    
    // Have to make initial query if self.lastSnapshot is not yet set, otherwise, query should use self.lastSnapshot to pick up where the last query left off
    FIRQuery* dataQuery = (label.lastDataSnapshot == nil) ? [[[label.firebaseRef collectionWithPath:@"ModelData"] queryOrderedByField:@"imagePath"] queryLimitedTo:queryLimit] :
    [[[[label.firebaseRef collectionWithPath:@"ModelData"] queryOrderedByField:@"imagePath"] queryLimitedTo:queryLimit]
        queryStartingAfterDocument:label.lastDataSnapshot];
    dispatch_group_t initDocsWaitingGroup = dispatch_group_create();

    __block NSError* queryError;
    [dataQuery getDocumentsWithCompletion:^(FIRQuerySnapshot * _Nullable snapshot, NSError * _Nullable error) {
        if(error != nil) {
            NSLog(@"Error querying more data");
            queryError = error;
        }
        else {
            if(snapshot.documents == nil) {
                NSLog(@"No more data to fetch");
            }
            for(FIRQueryDocumentSnapshot* doc in snapshot.documents) {
                label.lastDataSnapshot = snapshot.documents.lastObject;
                dispatch_group_enter(initDocsWaitingGroup);
                NSDictionary* dict = doc.data;
                NSString* errorMessage = [NSString stringWithFormat:@"Fetching %@ data for label %@", doc.documentID, label.label];
                [ModelData initWithDictionary:dict storage:self.storage completion:^(NSError* error, ModelData * _Nonnull modelData) {
                    if(error) {
                        queryError = error;
                        [self presentError:@"Failed to fetch data" message:errorMessage error:error];
                    }
                    else {
                        modelData.firebaseRef = doc.reference;
                        [label.localData addObject:modelData];
                    }
                    dispatch_group_leave(initDocsWaitingGroup);
                }];
            }
            // At this point we got all the data for a label
            dispatch_group_notify(initDocsWaitingGroup, dispatch_get_main_queue(), ^{
                NSLog(@"Fetched data.");
                if(completion){
                    completion(queryError);
                }
            });
        }
    }];
}


// Fetches all labels, assumes small-ish number of labels relative to number of data
//XXX todo add model referencing field or make a subcollection of Model in order to just get data needed and speed up queries
- (void) fetchAllLabelsWithType: (testTrain)testTrainType dataPerLabel: (NSInteger)dataPerLabel progressCompletion: (void(^_Nullable)(float progress))progressCompletion completion: (void(^)(void))completion {
    
    dispatch_group_t prepareWaitingGroup = dispatch_group_create();
    __block float labelsFetched = 0;
    float labelsToFetch = self.model.labeledData.count;
    // Loop through all available labels that the model holds references to
    for(int i=0; i<labelsToFetch; i++) {
        FIRDocumentReference* ref = self.model.labeledData[i];
        dispatch_group_enter(prepareWaitingGroup);
        // Fetch and create the ModelLabel object from that reference
        [ModelLabel fetchFromReference:ref vc:self completion:^(ModelLabel* _Nonnull modelLabel) {
            modelLabel.firebaseRef = ref;
            if([modelLabel.testTrainType isEqualToString: dataTypeEnumToString(testTrainType)]){
                [self.modelLabels addObject:modelLabel];
                // Fetch the data on each ModelLabel and then increment the number of labels fetched when done with self.labelFetchStart
                [self fetchAndCreateData:modelLabel queryLimit:dataPerLabel completion:^(NSError* error) {
                    if(error) {
                        [self presentError:@"Failed to fetch data" message:error.localizedDescription error:error];
                    }
                    else {
                        if(progressCompletion) {
                            labelsFetched += 1;
                            float progress = labelsFetched / labelsToFetch;
                            progressCompletion(progress);
                        }
                    }
                    dispatch_group_leave(prepareWaitingGroup);
                }];
            }
            else {
                dispatch_group_leave(prepareWaitingGroup);
            }
        }];
    }
    // At this point we have locally created ModelLabel objs from the models references and can continue
    dispatch_group_notify(prepareWaitingGroup, dispatch_get_main_queue(), ^{
        NSLog(@"Fetched %@ labels.", dataTypeEnumToString(testTrainType));
        completion();
    });
}

@end
