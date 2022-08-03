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
@property (nonatomic, assign) NSString* testTrainType;
@property (nonatomic, strong) NSMutableArray<ModelData*>* labelModelData; // Array of all ModelData with this label
@property (strong, nonatomic) FIRDocumentReference* firebaseRef;

- (ModelLabel*) initEmptyLabel: (NSString*)label testTrainType: (NSString*) testTrainType;

- (void) addLabelModelData:(NSArray *)objects;
- (void) updateModelLabelWithDatabase: (FIRStorage*)storage db: (FIRFirestore*)db vc: (UIViewController*)vc model: (AvatarMLModel*)model completion:(void(^)(NSError *error))completion;
- (void) saveNewModelLabelWithDatabase: (FIRFirestore*)db vc: (UIViewController*)vc;
+ (void) fetchFromReference: (FIRDocumentReference*)labelDocRef vc: (UIViewController*)vc completion:(void(^)(ModelLabel*))completion;
@end

NS_ASSUME_NONNULL_END
