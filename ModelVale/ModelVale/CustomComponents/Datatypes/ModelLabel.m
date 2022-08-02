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

@implementation ModelLabel

- (instancetype)initWithDictionaryAndExistingData:(NSDictionary *)dict storage: (FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^)(void))completion{
    self = [super init];
    if(self){
        self.label = dict[@"label"];
        self.testTrainType = dict[@"testTrainType"];
        self.labelModelData = [NSMutableArray new];
        [self setLabelModelDataFromRefList:storage refList:dict[@"labelModelData"] vc:vc completion:completion];
//        [self.labelModelData addObjectsFromArray: dict[@"labelModelData"]];
//        [self.labelModelData addObjectsFromArray:data];
    }
    return self;
}

- (instancetype) initEmptyLabel: (NSString*)label testTrainType: (NSString*)testTrainType {
    if (self) {
        self.label = label;
        self.testTrainType = testTrainType;
        self.labelModelData = [NSMutableArray new];
    }
    return self;
}

- (void) addLabelModelData:(NSArray *)objects {
    [self.labelModelData addObjectsFromArray:objects];
}


// MARK: Firebase

- (NSMutableArray<FIRDocumentReference*>*) getModelDataRefList {
    NSMutableArray* refs = [NSMutableArray new];
    for(ModelData* data in self.labelModelData) {
        [refs addObject:data.firebaseRef];
    }
    return refs;
}

// Does not overwrite existing local data, assumes that it will ALWAYS contain ModelData objects
- (void) setLabelModelDataFromRefList: (FIRStorage*)storage refList: (NSMutableArray<FIRDocumentReference*> *)refList vc: (UIViewController*)vc completion:(void(^)(void))completion {
    for(FIRDocumentReference* ref in refList) {
        [ModelData fetchFromReference:storage docRef:ref vc:vc completion:^(ModelData * _Nonnull modelData) {
            [self.labelModelData addObject:modelData];
        }];
    }
    //XXX working here to make sure we finish fetching and setting modelLabel locally before using that local data to update the database
    completion();
}

- (void) saveNewModelLabelWithDatabase: (FIRFirestore*)db vc: (UIViewController*)vc {
    // Add a new ModelData with a generated id.
    __block FIRDocumentReference *ref =
        [[db collectionWithPath:@"ModelLabel"] addDocumentWithData:@{
          @"label": self.label,
          @"testTrainType": self.testTrainType,
          @"labelModelData" : [self getModelDataRefList]
        } completion:^(NSError * _Nullable error) {
          if (error != nil) {
            NSLog(@"Error adding ModelLabel: %@", error);
          } else {
            NSLog(@"ModelLabel added with ID: %@", ref.documentID);
          }
        }];
}

- (void) updateModelLabelWithDatabase: (FIRStorage*)storage db: (FIRFirestore*)db vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion {
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
            [self initWithDictionaryAndExistingData: dict storage:storage vc:vc completion:^{
                [self uploadModelLabel:db docID:doc.documentID vc:vc];
            }];
        }
        else {
            [self saveNewModelLabelWithDatabase:db vc:vc];
        }
        completion(error);
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
