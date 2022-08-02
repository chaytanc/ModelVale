//
//  AddDataViewController.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/7/22.
//

#import <UIKit/UIKit.h>
@class DropDownTextField;
@class AvatarMLModel;
#import "FirebaseAuthViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface AddDataViewController : FirebaseAuthViewController
@property (strong, nonatomic) AvatarMLModel* model;

@end

NS_ASSUME_NONNULL_END
