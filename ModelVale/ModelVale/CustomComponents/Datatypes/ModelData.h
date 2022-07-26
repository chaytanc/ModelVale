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
@class NSString;

NS_ASSUME_NONNULL_BEGIN

// One piece of user data with the data it references and the label
@interface ModelData : PFObject<PFSubclassing>

@property (strong, nonatomic) NSString* label;
//@property (strong, nonatomic) UIImage* image;
@property (retain) UIImage *image;

+ (instancetype) initWithImage: (UIImage *)image label:(NSString *)label;
- (void) uploadDataOnVC: (UIViewController*)vc completion: (PFBooleanResultBlock  _Nullable)completion;
- (MLDictionaryFeatureProvider*) getDictionaryFeatureProvider: (MLImageConstraint*) modelConstraints;
- (MLFeatureValue*) getImageFeatureValue: (MLImageConstraint*)modelConstraints;
- (MLDictionaryFeatureProvider*) getUpdatableDictionaryFeatureProvider: (MLImageConstraint*) modelConstraints;
+ (NSMutableArray*) initModelDataArrayFromArray: (NSArray*) array label: (NSString*)label;


@end


NS_ASSUME_NONNULL_END
