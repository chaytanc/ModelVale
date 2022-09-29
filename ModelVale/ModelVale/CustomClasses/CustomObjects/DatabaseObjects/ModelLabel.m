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

// Query for existing labels and fetch, update locally, then push if one existed, or create a new label instead
- (void) updateModelLabelWithDatabase: (FIRFirestore*)db vc: (UIViewController*)vc model: (AvatarMLModel*)model completion:(void(^)(FIRDocumentReference* labelRef, NSError *error))completion {
    FIRQuery *query = [[db collectionWithPath:@"ModelLabel"] queryWhereField:@"label" isEqualTo:self.label];
    [query queryWhereField:@"testTrainType" isEqualTo:self.testTrainType];
    [query getDocumentsWithCompletion:^(FIRQuerySnapshot *snapshot, NSError *error) {
        if(error != nil) {
            [vc presentError:@"Failed to fetch labels" message:error.localizedDescription error:error];
        }
        else {

            // If the modelLabel already exists in the database, we want to update it, not save a new one
            if (snapshot.documents.count > 0){
                FIRDocumentSnapshot* doc = snapshot.documents[0];
                NSDictionary* dict = doc.data;
                NSLog(@"Found %lu matching labels", (unsigned long)snapshot.documents.count);
                [self updateWithDictionary:dict];
                [self uploadModelLabel:db labelRef:doc.reference vc:vc completion:^(NSError *error) {
                    // Update the local model stored references if necessary
                    if(![model.labeledData containsObject:doc.reference]) {
                        [model.labeledData addObject:doc.reference];
                    }
                    // In both cases, update the Model labeledData field to reflect labeled data that it references since models may share labels. Therefore the label may exist already, but the model doesn't yet reference it.
                    [model updateChangeableData:db completion:^(NSError * _Nonnull error) {
                        if(error != nil) {
                            NSLog(@"Error in updateModelLabeledDataWithDatabase");
                        }
                        else {
                            completion(doc.reference, error);
                        }
                    }];
                }];
            }
            else {
                [self saveNewModelLabelWithDatabase:db vc:vc completion:^(FIRDocumentReference *ref) {
                    [model.labeledData addObject:ref];
                    // Always update model labeledData
                    [model updateChangeableData:db completion:^(NSError * _Nonnull error) {
                        if(error != nil) {
                            NSLog(@"Error in updateModelLabeledDataWithDatabase");
                        }
                        else {
                            completion(ref, error);
                        }
                    }];
                }];
            }
        }
    }];
}

- (void) saveNewModelLabelWithDatabase: (FIRFirestore*)db vc: (UIViewController*)vc completion:(void(^)(FIRDocumentReference* ref))completion {
    // Add a new ModelLabel with generated id.
    __block FIRDocumentReference* ref =
        [[db collectionWithPath:@"ModelLabel"] addDocumentWithData:@{
          @"label": self.label,
          @"testTrainType": self.testTrainType,
        } completion:^(NSError * _Nullable error) {
          if (error != nil) {
              [vc presentError:@"Failed uploading new ModelLabel" message:error.localizedDescription error:error];
          }
          else {
              self.firebaseRef = ref;
              NSLog(@"ModelLabel added with ID: %@", ref.documentID);
              completion(ref);
          }
        }];
}

// Update the label document found in Firestore with the given docID
- (void) uploadModelLabel: (FIRFirestore*)db labelRef: (FIRDocumentReference*)labelRef vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion {
    
    [labelRef setData:@{
        @"label": self.label,
        @"testTrainType" : self.testTrainType,
    }
         merge:YES
         completion:^(NSError * _Nullable error) {
            if(error != nil){
                [vc presentError:@"Failed to update ModelLabel" message:error.localizedDescription error:error];
            }
            else {
                NSLog(@"Uploaded ModelLabel to Firestore");
            }
            completion(error);
    }];
}


@end
