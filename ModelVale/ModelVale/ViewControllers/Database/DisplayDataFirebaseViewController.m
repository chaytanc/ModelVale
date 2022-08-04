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

NSInteger const kLabelQueryLimit = 20;
NSInteger const kDataQueryLimit = 2;

@interface DisplayDataFirebaseViewController ()
@property (nonatomic, strong) FIRDocumentSnapshot* lastSnapshot;
@end

@implementation DisplayDataFirebaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

// MARK: Fetch data

// First fetches the Model in order to get its associated labels (since multiple users can add to the model, so we can't rely on local data to be up to date)
// Then fetches a limited number of labels based on the references the model contained
// Fetches all data from each of those labels and displays it
- (void) fetchLocalData: (void(^_Nullable)(void))completion {
    [self fetchModelWithCompletion:^{
        [self fetchSomeLabelsWithCompletion:^{
            if(completion){
                completion();
            }
        }];
    }];
}

- (void) fetchModelWithCompletion:(void(^)(void))completion {
    FIRDocumentReference *modelRef = [[self.db collectionWithPath:@"Model"] documentWithPath:self.model.avatarName];
    [modelRef getDocumentWithCompletion:^(FIRDocumentSnapshot * _Nullable snapshot, NSError * _Nullable error) {
        self.model = [self.model initWithDictionary:snapshot.data];
        completion();
    }];
}

// Fetches all labels, assumes small-ish number of labels relative to number of data
- (void) fetchSomeLabelsWithCompletion:(void(^)(void))completion {
    int originalLabelFetchStart = self.labelFetchStart;
    dispatch_group_t prepareWaitingGroup = dispatch_group_create();
    int labelFetchEnd = self.labelFetchStart + kLabelQueryLimit;
    for(int i=self.labelFetchStart; i<labelFetchEnd && i<self.model.labeledData.count; i++) {
        FIRDocumentReference* ref = self.model.labeledData[i];
        dispatch_group_enter(prepareWaitingGroup);
        [ModelLabel fetchFromReference:ref vc:self completion:^(ModelLabel* _Nonnull modelLabel) {
            modelLabel.firebaseRef = ref;
            [self.modelLabels addObject:modelLabel];
            [self fetchAndCreateData:modelLabel completion:^{
                self.labelFetchStart += 1;
                dispatch_group_leave(prepareWaitingGroup);
            }];
        }];
    }
    // At this point we have locally created ModelLabel objs from the models references and can continue
    dispatch_group_notify(prepareWaitingGroup, dispatch_get_main_queue(), ^{
        NSLog(@"Fetched group of labels %d to %d", originalLabelFetchStart, labelFetchEnd);
        completion();
    });
}

// Fetches all ModelData documents in the subcollection on ModelLabel and creates those objects locally
// Query is paginated so that only kDataQueryLimit data are fetched per label
- (void) fetchAndCreateData: (ModelLabel*)label completion:(void(^_Nullable)(void))completion {
    
    // Have to make initial query if self.lastSnapshot is not yet set, otherwise, query should use self.lastSnapshot to pick up where the last query left off
    FIRQuery* dataQuery = (self.lastSnapshot == nil) ? [[[label.firebaseRef collectionWithPath:@"ModelData"] queryOrderedByField:@"imagePath"] queryLimitedTo:kDataQueryLimit] :
    [[[[label.firebaseRef collectionWithPath:@"ModelData"] queryOrderedByField:@"imagePath"] queryLimitedTo:kDataQueryLimit]
        queryStartingAtDocument:self.lastSnapshot];

    [dataQuery getDocumentsWithCompletion:^(FIRQuerySnapshot * _Nullable snapshot, NSError * _Nullable error) {
        for(FIRQueryDocumentSnapshot* doc in snapshot.documents) {
            NSDictionary* dict = doc.data;
            NSLog(@"Fetching %@ data for label %@", doc.documentID, label.label);
            [ModelData initWithDictionary:dict storage:self.storage completion:^(ModelData * _Nonnull modelData) {
                modelData.firebaseRef = doc.reference;
                [label.localData addObject:modelData];
                self.lastSnapshot = snapshot.documents.lastObject;
                if(completion){
                    completion();
                }
            }];
        }
    }];
}

@end
