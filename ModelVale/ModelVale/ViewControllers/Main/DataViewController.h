//
//  DataViewController.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/7/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DataViewController : UIViewController
// Array holding type ModelLabel at its particular section index
@property (strong, nonatomic) NSMutableArray* modelLabels;
@end

NS_ASSUME_NONNULL_END
