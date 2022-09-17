//
//  TestViewController.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/7/22.
//

#import <UIKit/UIKit.h>
@class AvatarMLModel;
#import "DisplayDataFirebaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TestVCDelegate <NSObject>
- (void) earnXP: (int) XPClustersEarned;
@end

@interface TestViewController : DisplayDataFirebaseViewController
@property (nonatomic, weak) id<TestVCDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
