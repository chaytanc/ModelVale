//
//  ImportModelViewController.h
//  ModelVale
//
//  Created by Chaytan Inman on 9/12/22.
//

#import <UIKit/UIKit.h>
#import "AvatarMLModel.h"
#import "FirebaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ImportModelViewController : FirebaseViewController
@property (strong, nonatomic) AvatarMLModel* model;
@end

NS_ASSUME_NONNULL_END
