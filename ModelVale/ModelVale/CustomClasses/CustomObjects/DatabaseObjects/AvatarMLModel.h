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

NS_ASSUME_NONNULL_BEGIN

@interface AvatarMLModel : NSObject

@property (nonatomic, strong) NSString* modelName;
@property (nonatomic, strong) NSString* avatarName;
@property (nonatomic, assign) NSNumber* health;
// An array of ALL the ModelLabel references that an AvatarMLModel points to, but not the actual objects themselves
@property (nonatomic, strong) NSMutableArray<FIRDocumentReference*>* labeledData;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (instancetype) initWithModelName: (NSString*)modelName avatarName: (NSString*)avatarName uid: (NSString*)uid;
- (MLModel*) getMLModelFromModelName;
- (void) uploadModelToUserWithViewController: (NSString*) uid db: (FIRFirestore*)db vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion;
+ (void) fetchAndCreateAvatarMLModel: (FIRFirestore*)db documentPath: (NSString*)documentPath completion:(void(^_Nullable)(AvatarMLModel*))completion;
- (void) updateModelLabeledDataWithDatabase: (FIRFirestore*)db vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion;
- (NSURL*) loadModelURL: (NSString*) resource extension: (NSString*)extension;
- (UpdatableSqueezeNet*) loadModel: (NSString*) resource extension: (NSString*)extension;
- (UpdatableSqueezeNet*) loadModel: (NSURL*)url;

@end

NS_ASSUME_NONNULL_END
