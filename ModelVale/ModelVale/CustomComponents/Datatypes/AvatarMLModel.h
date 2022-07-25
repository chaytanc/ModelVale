//
//  AvatarMLModel.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/14/22.
//

#import <Foundation/Foundation.h>
#import "UpdatableSqueezeNet.h"
#import "Parse/Parse.h"
@class ModelLabel;

NS_ASSUME_NONNULL_BEGIN

@interface AvatarMLModel : PFObject<PFSubclassing>

@property (nonatomic, strong) NSString* modelName;
@property (nonatomic, strong) NSString* avatarName;
@property (nonatomic, assign) NSInteger health;
@property (nonatomic, strong) NSMutableArray<ModelLabel*>* labeledData;
@property (nonatomic, weak) PFUser* owner;

//XXX TODO add properties for database
// owner, labeledData, weights, architecture
//XXX todo update these properties in retrain and test
- (instancetype) initWithModelName: (NSString*)modelName avatarName: (NSString*)avatarName user: (PFUser*)user;
- (MLModel*) getMLModelFromModelName;
- (void) uploadModelToUserWithViewController: (PFUser*) user vc: (UIViewController*)vc;
- (void) updateModel: (UIViewController*)vc;

@end

NS_ASSUME_NONNULL_END
