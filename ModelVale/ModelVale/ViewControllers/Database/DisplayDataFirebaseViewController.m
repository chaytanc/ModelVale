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

NSInteger const kQueryLimit = 20;

@interface DisplayDataFirebaseViewController ()

@end

@implementation DisplayDataFirebaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

// MARK: Fetch data

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
    int labelFetchEnd = self.labelFetchStart + kQueryLimit;
    for(int i=self.labelFetchStart; i<labelFetchEnd && i<self.model.labeledData.count; i++) {
        FIRDocumentReference* ref = self.model.labeledData[i];
        dispatch_group_enter(prepareWaitingGroup);
        [ModelLabel fetchFromReference:ref vc:self completion:^(ModelLabel* _Nonnull modelLabel) {
            modelLabel.firebaseRef = ref;
            [self.modelLabels addObject:modelLabel];
            [self fetchLabelData:modelLabel completion:^{
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

- (void) fetchLabelData: (ModelLabel*)label completion:(void(^_Nullable)(void))completion {
    dispatch_group_t prepareWaitingGroup = dispatch_group_create();
    for(int i=0; i<label.labelModelData.count; i++) {
        FIRDocumentReference* ref = label.labelModelData[i];
        dispatch_group_enter(prepareWaitingGroup);
        NSLog(@"Fetching %@ data for label %@", ref.documentID, label.label);
        [ModelData fetchFromReference:ref storage: self.storage vc:self completion:^(ModelData* _Nonnull modelData) {
            modelData.firebaseRef = ref;
            [label.localData addObject:modelData];
            dispatch_group_leave(prepareWaitingGroup);
        }];
    }
    dispatch_group_notify(prepareWaitingGroup, dispatch_get_main_queue(), ^{
        NSLog(@"Fetched data for label %@", label.label);
        if(completion){
            completion();
        }
    });
}

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
@end
