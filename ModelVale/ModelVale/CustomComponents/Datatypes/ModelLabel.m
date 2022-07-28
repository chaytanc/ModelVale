//
//  ClassifierLabel.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/11/22.
//

#import "ModelLabel.h"
#import "ModelData.h"
#import "TestTrainEnum.h"
//#import "Parse/Parse.h"
#import "UIViewController+PresentError.h"

@implementation ModelLabel


- (instancetype)initWithDictionaryAndExistingData:(NSDictionary *)dict data: (NSMutableArray*)data {
    self = [super init];
    if(self){
        self.label = dict[@"label"];
        self.testTrainType = dict[@"testTrainType"];
        self.labelModelData = [NSMutableArray new];
        [self.labelModelData addObjectsFromArray: dict[@"labelModelData"]];
        [self.labelModelData addObjectsFromArray:data];
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

- (instancetype) initWithData: (NSString*)label testTrainType: (NSString*)testTrainType
                         data: (NSMutableArray*)data objectId: (NSString*)objectId {
    if(self) {
        self.label = label;
        self.testTrainType = testTrainType;
        self.labelModelData = [NSMutableArray new];
        [self.labelModelData addObjectsFromArray:data];
    }
    return self;
}

- (void) addLabelModelData:(NSArray *)objects {
    [self.labelModelData addObjectsFromArray:objects];
}


// MARK: Firebase
- (void) saveNewModelLabelWithDatabase: (FIRFirestore*)db vc: (UIViewController*)vc {
    // Add a new ModelData with a generated id.
    __block FIRDocumentReference *ref =
        [[db collectionWithPath:@"ModelLabel"] addDocumentWithData:@{
          @"label": self.label,
          @"testTrainType": self.testTrainType,
          @"labelModelData" : self.labelModelData
        } completion:^(NSError * _Nullable error) {
          if (error != nil) {
            NSLog(@"Error adding ModelLabel: %@", error);
          } else {
            NSLog(@"ModelLabel added with ID: %@", ref.documentID);
          }
        }];
}

- (void) updateModelLabelWithDatabase: (FIRFirestore*)db vc: (UIViewController*)vc {
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
            // Update locally
            [self initWithDictionaryAndExistingData:dict data:self.labelModelData];

            // Update the document found in Firestore
            [[[db collectionWithPath:@"ModelLabel"] documentWithPath:doc.documentID]
             setData:@{ @"label": self.label,
                        @"testTrainType" : self.testTrainType,
                        @"labelModelData" : self.labelModelData }
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
        else {
            [self saveNewModelLabelWithDatabase:db vc:vc];
        }
    }];
}


@end
