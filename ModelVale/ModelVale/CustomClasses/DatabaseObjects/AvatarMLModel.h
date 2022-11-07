//
//  AvatarMLModel.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/14/22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class ModelLabel;
#import "FirebaseFirestore.h"
@import FirebaseStorage;
@class User;
#import "CoreML/CoreML.h"

NS_ASSUME_NONNULL_BEGIN

@interface AvatarMLModel : NSObject

@property (nonatomic, strong) NSString* modelName;
@property (nonatomic, strong) NSString* avatarName;
@property (nonatomic, assign) NSNumber* health;
@property (nonatomic, strong) UIImage* avatarImage;
@property (nonatomic, strong) NSString* avatarImagePath;
@property (nonatomic, assign) NSNumber* duplicateCount;
//@property (nonatomic, assign)  NSError*  _Nullable modelError;
@property (nonatomic, assign)  NSString*  _Nullable modelError;


// URL to the locally stored model
@property (nonatomic, strong) NSURL* modelURL;
// An array of ALL the ModelLabel references that an AvatarMLModel points to, but not the actual objects themselves
@property (nonatomic, strong) NSMutableArray<FIRDocumentReference*>* labeledData;
@property (nonatomic, assign, class, readonly) NSNumber* maxHealth;

+ (void)initWithDictionary:(NSDictionary *)dict storage:(FIRStorage*)storage completion:(void(^_Nullable)(AvatarMLModel*))completion;
- (instancetype) initWithModelName: (NSString*)modelName avatarName: (NSString*)avatarName;
//- (MLModel*) getMLModelFromModelName;
- (void) getMLModelFromModelName:(void(^)(NSString * _Nullable error, MLModel* model))completion;
- (void) uploadModel: (User*)user db: (FIRFirestore*)db storage:(FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion;
- (void) uploadStarterModel: (User*)user db: (FIRFirestore*)db storage:(FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion;
+ (void) fetchAndReturnExistingModel: (FIRFirestore*)db storage: (FIRStorage*)storage documentPath: (NSString*)documentPath completion:(void(^_Nullable)(AvatarMLModel*))completion;
- (void) updateChangeableData: (FIRFirestore*)db completion:(void(^)(NSError *error))completion;
- (void) updateModelHealth: (User*)user db: (FIRFirestore*)db completion:(void(^)(NSError *error))completion;
+ (NSString*) getDefaultModelName;

@end

NS_ASSUME_NONNULL_END
