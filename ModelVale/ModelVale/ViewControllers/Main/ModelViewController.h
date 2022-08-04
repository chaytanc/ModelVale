//
//  ModelViewController.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/4/22.
//

#import <UIKit/UIKit.h>
#import "FirebaseAuthViewController.h"
@class AvatarMLModel;

NS_ASSUME_NONNULL_BEGIN

@interface ModelViewController : FirebaseAuthViewController
@property (nonatomic, assign) CGPoint seed;
@property (nonatomic, strong) NSMutableArray<AvatarMLModel*>* models;
- (void) fetchAndSetVCModels;
@end

NS_ASSUME_NONNULL_END
