//
//  RetrainViewController.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/7/22.
//

#import <UIKit/UIKit.h>
@class AvatarMLModel;

NS_ASSUME_NONNULL_BEGIN

@interface RetrainViewController : UIViewController
@property (nonatomic, strong) AvatarMLModel* model;
@end

NS_ASSUME_NONNULL_END
