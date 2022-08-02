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
//@import FirebaseFirestore;
#import "FirebaseFirestore.h"

NS_ASSUME_NONNULL_BEGIN

@interface AvatarMLModel : NSObject

@property (nonatomic, strong) NSString* modelName;
@property (nonatomic, strong) NSString* avatarName;
@property (nonatomic, assign) NSNumber* health;
@property (nonatomic, strong) NSMutableArray* labeledData;

//XXX todo update these properties in retrain and test
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (instancetype) initWithModelName: (NSString*)modelName avatarName: (NSString*)avatarName uid: (NSString*)uid;
- (MLModel*) getMLModelFromModelName;
- (void) uploadModelToUserWithViewController: (NSString*) uid db: (FIRFirestore*)db vc: (UIViewController*)vc;
+ (void) fetchAndCreateAvatarMLModel: (FIRFirestore*)db documentPath: (NSString*)documentPath completion:(void(^_Nullable)(AvatarMLModel*))completion;

@end

NS_ASSUME_NONNULL_END
