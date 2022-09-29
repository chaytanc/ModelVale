//
//  ModelData.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/11/22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CoreML/CoreML.h"
@import FirebaseFirestore;
@import FirebaseStorage;

NS_ASSUME_NONNULL_BEGIN

// One piece of user data with the data it references and the label
@interface ModelData : NSObject

@property (strong, nonatomic) NSString* label;
@property (retain) NSString *imagePath;
@property (strong, nonatomic) UIImage* image;
@property (strong, nonatomic) FIRDocumentReference* firebaseRef;
@property (strong, nonatomic) NSNumber* testedCount;

+ (instancetype) initWithImage: (UIImage * _Nullable)image label:(NSString *)label imagePath: (NSString*)imagePath;
+ (instancetype)initWithDictionary:(NSDictionary *)dict storage: (FIRStorage*)storage completion:(void(^_Nullable)(NSError*, ModelData*))completion;
- (void) saveModelDataInSubCollection: (FIRDocumentReference*)labelRef db: (FIRFirestore*)db storage:(FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^)(void))completion;
- (MLFeatureValue*) getImageFeatureValue: (MLImageConstraint*)modelConstraints;
- (MLDictionaryFeatureProvider*) getUpdatableDictionaryFeatureProvider: (MLImageConstraint*) modelConstraints;
+ (void) fetchFromReference: (FIRDocumentReference*)docRef storage: (FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^ _Nullable)(NSError*, ModelData*))completion;
- (void) incrementTestedCount: (FIRFirestore*)db labelRef: (FIRDocumentReference*)labelRef completion:( void(^ _Nullable )(NSError *error))completion;


@end


NS_ASSUME_NONNULL_END
