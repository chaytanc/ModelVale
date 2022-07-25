//
//  DataViewController.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/7/22.
//

#import <UIKit/UIKit.h>
@class AvatarMLModel;

NS_ASSUME_NONNULL_BEGIN

@interface DataViewController : UIViewController
// Array holding type ModelLabel at its particular section index
//@property (strong, nonatomic) NSMutableArray* modelLabels;
@property (strong, nonatomic) AvatarMLModel* model;

@end

NS_ASSUME_NONNULL_END
