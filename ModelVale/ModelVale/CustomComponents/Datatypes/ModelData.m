//
//  User.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/11/22.
//

#import "ModelData.h"
#import "ModelLabel.h"
#import "CoreML/CoreML.h"
#import "UpdatableSqueezeNet.h"
#import "UIViewController+PresentError.h"
@import FirebaseFirestore;

@interface ModelData()
@end

@implementation ModelData

//XXX todo remove and fix all use cases
+ (instancetype) initWithImage: (UIImage *)image label:(NSString *)label {
    ModelData* md = [ModelData new];
    md.image = image;
    md.label = label;
    return md;
}
//
//+ (NSMutableArray*) initModelDataArrayFromArray: (NSArray*) array label: (NSString*)label {
//    NSMutableArray* modelDatas = [NSMutableArray new];
//    for (id modelDataResponse in array) {
//        ModelData* md = [ModelData new];
//        //XXX todo may have to change way we do this if UIImage is not stored in response dict
//        md.image = [UIImage imageWithData:modelDataResponse[@"imageFile"]];
//        md.label = label;
//        [modelDatas addObject:md];
//    }
//    return modelDatas;
//}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if(self){
        self.label = dict[@"label"];
        self.imagePath = dict[@"imagePath"];
    }
    return self;
}

- (UIImage *)image {
    //XXX todo get from firebase storage
//    if (!_image){
//        [self fetchIfNeeded];
//        _image = [UIImage imageWithData:[self.imageFile getData]];
//    }
//    return _image;
    return [UIImage new];
}
//
//- (void)setImage:(UIImage *)image {
//    _image = image;
//    //XXX todo find better name
//    NSString* filename = @"image.png";
//    NSData* data = UIImagePNGRepresentation(image);
//    self.imageFile = [PFFileObject fileObjectWithName:filename data:data];
//}

- (void) saveNewModelDataWithDatabase: (FIRFirestore*)db vc: (UIViewController*)vc {
    // Add a new ModelData with a generated id.
    __block FIRDocumentReference *ref =
        [[db collectionWithPath:@"ModelData"] addDocumentWithData:@{
          @"label": self.label,
          @"imagePath": self.imagePath
        } completion:^(NSError * _Nullable error) {
          if (error != nil) {
            NSLog(@"Error adding ModelData: %@", error);
          } else {
            NSLog(@"ModelData added with ID: %@", ref.documentID);
          }
        }];
}


//MARK: CoreML
- (MLFeatureValue*) getImageFeatureValue: (MLImageConstraint*)modelConstraints {
    struct CGImage* cgtest = self.image.CGImage;
    MLFeatureValue* imageFeature = [MLFeatureValue featureValueWithCGImage:cgtest constraint:modelConstraints options:nil error:nil];
    return imageFeature;
}

- (MLDictionaryFeatureProvider*) getDictionaryFeatureProvider: (MLImageConstraint*) modelConstraints {
    MLFeatureValue* imageFeature = [self getImageFeatureValue:modelConstraints];
    if(imageFeature == nil) {
        [NSException raise:@"Invalid training data" format:@"Could not get imageFeature in getDictionaryFeatureProvider"];
    }
    NSMutableDictionary* featureDict = [[NSMutableDictionary alloc] init];
    featureDict[@"image"] = imageFeature;
    MLDictionaryFeatureProvider* featureProv = (MLDictionaryFeatureProvider*)[[MLDictionaryFeatureProvider new] initWithDictionary:featureDict error:nil];
    return featureProv;
}


- (MLDictionaryFeatureProvider*) getUpdatableDictionaryFeatureProvider: (MLImageConstraint*) modelConstraints {
    MLFeatureValue* imageFeature = [self getImageFeatureValue:modelConstraints];
    MLFeatureValue* labelFeature = [MLFeatureValue featureValueWithString:self.label];
    if(imageFeature == nil) {
        [NSException raise:@"Invalid training data" format:@"Could not get imageFeature in getDictionaryFeatureProvider"];
    }
    NSMutableDictionary* featureDict = [[NSMutableDictionary alloc] init];
    featureDict[@"image"] = imageFeature;
    featureDict[@"classLabel"] = labelFeature;
    MLDictionaryFeatureProvider* featureProv = (MLDictionaryFeatureProvider*)[[MLDictionaryFeatureProvider new] initWithDictionary:featureDict error:nil];
    return featureProv;
}

@end
