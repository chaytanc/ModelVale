//
//  User.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/11/22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CoreML/CoreML.h"
@import FirebaseFirestore;

NS_ASSUME_NONNULL_BEGIN

// One piece of user data with the data it references and the label
@interface ModelData : NSObject

@property (strong, nonatomic) NSString* label;
@property (retain) NSString *imagePath;
@property (strong, nonatomic) UIImage* image;

+ (instancetype) initWithImage: (UIImage *)image label:(NSString *)label;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (void) saveNewModelDataWithDatabase: (FIRFirestore*)db vc: (UIViewController*)vc;
- (MLDictionaryFeatureProvider*) getDictionaryFeatureProvider: (MLImageConstraint*) modelConstraints;
- (MLFeatureValue*) getImageFeatureValue: (MLImageConstraint*)modelConstraints;
- (MLDictionaryFeatureProvider*) getUpdatableDictionaryFeatureProvider: (MLImageConstraint*) modelConstraints;
+ (NSMutableArray*) initModelDataArrayFromArray: (NSArray*) array label: (NSString*)label;


@end


NS_ASSUME_NONNULL_END
