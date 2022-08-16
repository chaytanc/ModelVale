//
//  ModelLabel.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/11/22.
//

#import <Foundation/Foundation.h>
#import "TestTrainEnum.h"
#import <UIKit/UIKit.h>
@import FirebaseFirestore;
@import FirebaseStorage;
@class AvatarMLModel;
@class ModelData;

NS_ASSUME_NONNULL_BEGIN

@interface ModelLabel : NSObject
@property (nonatomic, strong) NSString* label;
// Data can be one of the options in the TestTrainEnum. Typically ML classifies data as either testing, training, or validation, but only test and train are currently supported.
@property (nonatomic, assign) NSString* testTrainType;
// localData is the data stored on a as-needed basis after fetches
@property (nonatomic, strong) NSMutableArray<ModelData*>* localData;
// An array of ALL the ModelData references that a label points to, but not the actual objects themselves so that we don't have to create thousands of images that might be contained in a label
@property (nonatomic, strong) NSMutableArray<FIRDocumentReference*>* labelModelData;
@property (strong, nonatomic) FIRDocumentReference* firebaseRef;
// Each label keeps track of the last data that was fetched so that a paginated query can pick up where it left off
@property (nonatomic, strong) FIRDocumentSnapshot* lastDataSnapshot;


- (ModelLabel*) initEmptyLabel: (NSString*)label testTrainType: (NSString*) testTrainType;
- (void) addLabelModelData:(NSArray *)objects;
- (void) updateModelLabelWithDatabase: (FIRFirestore*)db vc: (UIViewController*)vc model: (AvatarMLModel*)model completion:(void(^)(FIRDocumentReference* labelRef, NSError *error))completion;
- (void) saveNewModelLabelWithDatabase: (FIRFirestore*)db vc: (UIViewController*)vc;
+ (void) fetchFromReference: (FIRDocumentReference*)labelDocRef vc: (UIViewController*)vc completion:(void(^)(ModelLabel*))completion;
@end

NS_ASSUME_NONNULL_END
