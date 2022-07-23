//
//  User.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/11/22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CoreML/CoreML.h"
#import "Parse/Parse.h"
@class ModelLabel;

NS_ASSUME_NONNULL_BEGIN

// One piece of user data with the data it references and the label
@interface ModelData : PFObject<PFSubclassing>

@property (strong, nonatomic) ModelLabel* label;
@property (strong, nonatomic) UIImage* image;

- (ModelData*) initWithImage:(UIImage *)image label:(ModelLabel *)label;
- (MLDictionaryFeatureProvider*) getDictionaryFeatureProvider: (MLImageConstraint*) modelConstraints;
- (MLFeatureValue*) getImageFeatureValue: (MLImageConstraint*)modelConstraints;
- (MLDictionaryFeatureProvider*) getUpdatableDictionaryFeatureProvider: (MLImageConstraint*) modelConstraints;
+ (NSMutableArray*) initModelDataArrayFromArray: (NSArray*) array label: (ModelLabel*)label;


@end

NS_ASSUME_NONNULL_END
