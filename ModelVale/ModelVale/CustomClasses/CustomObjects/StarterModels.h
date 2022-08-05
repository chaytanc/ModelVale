//
//  StarterModels.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/22/22.
//

#import <Foundation/Foundation.h>
#import "Parse/Parse.h"
@import FirebaseFirestore;
@class AvatarMLModel;

NS_ASSUME_NONNULL_BEGIN

@interface StarterModels : NSObject

@property (nonatomic, strong) NSMutableArray<AvatarMLModel*>* models;
-(instancetype) initStarterModels: (NSString*)uid;
-(void) uploadStarterModels: (NSString*)uid db: (FIRFirestore*)db vc: (UIViewController*)vc;

@end

NS_ASSUME_NONNULL_END