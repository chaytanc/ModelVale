//
//  User.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/11/22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ModelLabel.h"

NS_ASSUME_NONNULL_BEGIN

// One piece of user data with the data it references and the label
@interface ModelData : NSObject

@property (strong, nonatomic) ModelLabel* label;
@property (strong, nonatomic) UIImage* image;

- (ModelData*) initWithImage: (UIImage*)image label: (ModelLabel*) label;

@end

NS_ASSUME_NONNULL_END
