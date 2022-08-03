//
//  ModelLabel.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/11/22.
//

#import "ModelLabel.h"
#import "ModelData.h"
#import "TestTrainEnum.h"
#import "UIViewController+PresentError.h"
#import "AvatarMLModel.h"

@implementation ModelLabel


- (instancetype) initEmptyLabel: (NSString*)label testTrainType: (NSString*)testTrainType {
    self = [super init];
    if (self) {
        self.label = label;
        self.testTrainType = testTrainType;
        self.labelModelData = [NSMutableArray new];
        //XXX todo not sure if better to set this or not since if it is not manually overwritten and user relies on this default it will error
//        self.firebaseRef = [FIRDocumentReference new];
    }
    return self;
}

+ (ModelLabel*) initWithDictionary: (NSDictionary*)dict {
    ModelLabel* l = [ModelLabel new];
    if (l) {
        l.label = dict[@"label"];
        l.testTrainType = dict[@"testTrainType"];
        //XXX todo this does not uphold labelModelData type inv of holdign obj instead of refs... need to switch to using refs and converting as needed instead of invariant being to hold objs due to recursive reads required to actually construct a model obj then modellabels then modeldata
        l.labelModelData = dict[@"labelModelData"];
//        l.firebaseRef = [FIRDocumentReference new];
    }
    return l;
}

- (void) addLabelModelData:(NSArray *)objects {
    [self.labelModelData addObjectsFromArray:objects];
}

// MARK: Firebase

+ (void) fetchFromReference: (FIRDocumentReference*)labelDocRef vc: (UIViewController*)vc completion:(void(^)(ModelLabel*))completion {
    [labelDocRef getDocumentWithCompletion:^(FIRDocumentSnapshot * _Nullable snapshot, NSError * _Nullable error) {
        if(error != nil) {
            [vc presentError:@"Failed to fetch ModelLabel" message:error.localizedDescription error:error];
        }
        else {
            ModelLabel* l = [ModelLabel initWithDictionary: snapshot.data];
            l.firebaseRef = labelDocRef;
//            [l initWithDictionary:snapshot.data storage:storage vc:<#(UIViewController *)#> completion:<#^(void)completion#>]
            completion(l);
        }
    }];
}

- (instancetype) initWithDictionary:(NSDictionary *)dict storage: (FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^)(void))completion{
    self = [super init];
    if(self) {
        self.label = dict[@"label"];
        self.testTrainType = dict[@"testTrainType"];
        [self setLabelModelDataFromRefList:storage fromFirestoreRefList:dict[@"labelModelData"] vc:vc completion:completion];
    }
    return self;
}

// Create an array of FIRDocRefs from the local data
- (NSMutableArray<FIRDocumentReference*>*) getModelDataRefList {
    NSMutableArray* refs = [NSMutableArray new];
    for(ModelData* data in self.labelModelData) {
        if(data.firebaseRef){
            [refs addObject:data.firebaseRef];
        }
        else {
            NSLog(@"Error: Nil firebaseRef in ModelData in labelModelData");
        }
    }
    return refs;
}

// Does not overwrite existing local data, assumes that it will ALWAYS contain ModelData objects
// Create an array of ModelData objects from a list of references to them
- (void) setLabelModelDataFromRefList: (FIRStorage*)storage
                 fromFirestoreRefList: (NSMutableArray<FIRDocumentReference*>*)fromFirestoreRefList
                                   vc: (UIViewController*)vc
                           completion:(void(^)(void))completion {
    
    dispatch_group_t prepareWaitingGroup = dispatch_group_create();
    for(FIRDocumentReference* ref in fromFirestoreRefList) {
        dispatch_group_enter(prepareWaitingGroup);
        [ModelData fetchFromReference:storage docRef:ref vc:vc completion:^(ModelData * _Nonnull modelData) {
            modelData.firebaseRef = ref;
            [self.labelModelData addObject:modelData];
            dispatch_group_leave(prepareWaitingGroup);
        }];
    }
    // At this point we have both the locally created ModelData objs and the objects from the fetched RefList, then we can reupload modelLabel
    dispatch_group_notify(prepareWaitingGroup, dispatch_get_main_queue(), ^{
        completion();
    });
}

- (void) updateModelLabelWithDatabase: (FIRStorage*)storage db: (FIRFirestore*)db vc: (UIViewController*)vc model: (AvatarMLModel*)model completion:(void(^)(NSError *error))completion {
    FIRQuery *query = [[db collectionWithPath:@"ModelLabel"] queryWhereField:@"label" isEqualTo:self.label];
    [query queryWhereField:@"testTrainType" isEqualTo:self.testTrainType];
    [query getDocumentsWithCompletion:^(FIRQuerySnapshot *snapshot, NSError *error) {
        if(error != nil) {
            [vc presentError:@"Failed to fetch labels" message:error.localizedDescription error:error];
        }
        else if (snapshot.documents.count > 0){
            FIRDocumentSnapshot* doc = snapshot.documents[0];
            NSDictionary* dict = doc.data;
            NSLog(@"Found %lu matching labels", (unsigned long)snapshot.documents.count);
            // Update locally, converting fetched refs in labelModelData to ModelData objects
            [self initWithDictionary:dict storage:storage vc:vc completion:^{
                [self uploadModelLabel:db docID:doc.documentID vc:vc];
            }];
        }
        else {
            [self saveNewModelLabelWithDatabase:db vc:vc completion:^{
                [model.labeledData addObject:self];
                [model updateModelLabeledDataWithDatabase:db vc:vc completion:^(NSError * _Nonnull error) {
                    if(error != nil) {
                        NSLog(@"Error in updateModelLabeledDataWithDatabase");
                    }
                }];
            }];
        }
        completion(error);
    }];
}

- (void) saveNewModelLabelWithDatabase: (FIRFirestore*)db vc: (UIViewController*)vc completion:(void(^)(void))completion {
    // Add a new ModelData with a generated id.
    __block FIRDocumentReference *ref =
        [[db collectionWithPath:@"ModelLabel"] addDocumentWithData:@{
          @"label": self.label,
          @"testTrainType": self.testTrainType,
          @"labelModelData" : [self getModelDataRefList]
        } completion:^(NSError * _Nullable error) {
          if (error != nil) {
              [vc presentError:@"Failed uploading new ModelLabel" message:error.localizedDescription error:error];
          }
          else {
              self.firebaseRef = ref;
              NSLog(@"ModelLabel added with ID: %@", ref.documentID);
              completion();
          }
        }];
}

// Update the label document found in Firestore with the given docID
- (void) uploadModelLabel: (FIRFirestore*)db docID: (NSString*)docID vc: (UIViewController*)vc {
    [[[db collectionWithPath:@"ModelLabel"] documentWithPath:docID]
     setData:@{ @"label": self.label,
                @"testTrainType" : self.testTrainType,
                @"labelModelData" : [self getModelDataRefList] }
         merge:YES
         completion:^(NSError * _Nullable error) {
                if(error != nil){
                    [vc presentError:@"Failed to update ModelLabel" message:error.localizedDescription error:error];
                }
                else {
                    NSLog(@"Uploaded ModelLabel to Firestore");
                }
    }];
}


@end
