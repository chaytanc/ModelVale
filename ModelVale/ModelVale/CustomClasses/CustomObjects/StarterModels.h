//
//  StarterModels.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/22/22.
//

#import <Foundation/Foundation.h>
@import FirebaseFirestore;
@import FirebaseStorage;
@class AvatarMLModel;
@class User;

NS_ASSUME_NONNULL_BEGIN

@interface StarterModels : NSObject

@property (nonatomic, strong) NSMutableArray<AvatarMLModel*>* models;
-(instancetype) initStarterModels;
-(void) uploadStarterModels: (User*)user db: (FIRFirestore*)db storage: (FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
