//
//  DataViewController.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/7/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DataViewController : UIViewController
- (NSArray*) getSection: (NSInteger)row;
// Array holding type ModelLabel at its particular section index, XXX working here to have each modelLabel contain an array of the userData it holds, no longer need allUserData
@property (strong, nonatomic) NSMutableArray* modelLabels;
@end

NS_ASSUME_NONNULL_END
