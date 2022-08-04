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
        self.localData = [NSMutableArray new];
        self.labelModelData = [NSMutableArray new];
    }
    return self;
}

+ (ModelLabel*) initWithDictionary: (NSDictionary*)dict {
    ModelLabel* l = [ModelLabel new];
    if (l) {
        l.label = dict[@"label"];
        l.testTrainType = dict[@"testTrainType"];
        l.labelModelData = dict[@"labelModelData"];
        l.localData = [NSMutableArray new];

    }
    return l;
}

- (void) updateWithDictionary: (NSDictionary*)dict {
    self.label = dict[@"label"];
    self.testTrainType = dict[@"testTrainType"];
    for(FIRDocumentReference* dataRef in dict[@"labelModelData"]) {
        [self.labelModelData addObject:dataRef];
    }
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
            completion(l);
        }
    }];
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
            // Update locally, adding fetched refs to existing refs for labelModelData
            [self updateWithDictionary:dict];
            [self uploadModelLabel:db docID:doc.documentID vc:vc];
        }
        else {
            [self saveNewModelLabelWithDatabase:db vc:vc completion:^{
                // Update the model stored references when a new label is added
                [model.labeledData addObject:self.firebaseRef];
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
    __block FIRDocumentReference* ref =
        [[db collectionWithPath:@"ModelLabel"] addDocumentWithData:@{
          @"label": self.label,
          @"testTrainType": self.testTrainType,
          @"labelModelData" : self.labelModelData
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
                @"labelModelData" : self.labelModelData
             }
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
