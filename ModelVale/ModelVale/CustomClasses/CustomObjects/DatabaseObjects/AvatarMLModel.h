//
//  AvatarMLModel.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/14/22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UpdatableSqueezeNet.h"
@class ModelLabel;
#import "FirebaseFirestore.h"
#import "ModelProtocol.h"
@import FirebaseStorage;

NS_ASSUME_NONNULL_BEGIN

@interface AvatarMLModel : NSObject

@property (nonatomic, strong) NSString* modelName;
@property (nonatomic, strong) NSString* avatarName;
@property (nonatomic, assign) NSNumber* health;
@property (nonatomic, strong) UIImage* avatarImage;
@property (nonatomic, strong) NSString* avatarImagePath;
// URL to the locally stored model
@property (nonatomic, strong) NSURL* modelURL;
// An array of ALL the ModelLabel references that an AvatarMLModel points to, but not the actual objects themselves
@property (nonatomic, strong) NSMutableArray<FIRDocumentReference*>* labeledData;

//- (instancetype)initWithDictionary:(NSDictionary *)dict;
+ (void)initWithDictionary:(NSDictionary *)dict storage:(FIRStorage*)storage completion:(void(^_Nullable)(AvatarMLModel*))completion;
- (instancetype) initWithModelName: (NSString*)modelName avatarName: (NSString*)avatarName uid: (NSString*)uid;
- (MLModel*) getMLModelFromModelName;
- (void) uploadModelToUserWithViewController: (NSString*) uid db: (FIRFirestore*)db storage:(FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion;
+ (void) fetchAndReturnExistingModel: (FIRFirestore*)db storage: (FIRStorage*)storage documentPath: (NSString*)documentPath completion:(void(^_Nullable)(AvatarMLModel*))completion;
- (void) updateModelLabeledDataWithDatabase: (FIRFirestore*)db vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion;
- (id<ModelProtocol>) loadModel;

@end

NS_ASSUME_NONNULL_END
