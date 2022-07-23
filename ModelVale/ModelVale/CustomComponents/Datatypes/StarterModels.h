//
//  StarterModels.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/22/22.
//

#import <Foundation/Foundation.h>
#import "Parse/Parse.h"
@class AvatarMLModel;

NS_ASSUME_NONNULL_BEGIN

@interface StarterModels : NSObject

@property (nonatomic, strong) NSMutableArray<AvatarMLModel*>* models;
-(instancetype) initStarterModels: (PFUser*)user;

@end

NS_ASSUME_NONNULL_END
