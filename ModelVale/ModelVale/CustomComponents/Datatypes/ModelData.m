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

@interface ModelData()
 @property (retain) PFFileObject *imageFile;
@end

@implementation ModelData

@dynamic label;
//@dynamic image;
@dynamic imageFile;
@synthesize image = _image;

+ (nonnull NSString *)parseClassName {
    return @"ModelData";
}

+ (instancetype) initWithImage: (UIImage *)image label:(ModelLabel *)label {
    ModelData* md = [ModelData new];
    md.image = image;
    md.label = label;
    [label addLabelModelData:@[md]];
    return md;
}

+ (NSMutableArray*) initModelDataArrayFromArray: (NSArray*) array label: (ModelLabel*)label {
    NSMutableArray* modelDatas = [NSMutableArray new];
    for (id modelDataResponse in array) {
        ModelData* md = [ModelData new];
        //XXX todo may have to change way we do this if UIImage is not stored in response dict

        md.image = [UIImage imageWithData:modelDataResponse[@"image"]];
//        md.imageFile = [PFFileObject fileObjectWithName:@"image.png" data:modelDataResponse[@"image"]];
        md.label = label;
        [label addLabelModelData:@[md]];
        [modelDatas addObject:md];
    }
    return modelDatas;
}

-(UIImage *)image {
    if (!_image){
        [self fetchIfNeeded];
        _image = [UIImage imageWithData:[self.imageFile getData]];
    }
    return _image;
}

-(void)setImage:(UIImage *)image {
    _image = image;
    self.imageFile = [PFFileObject fileObjectWithData:UIImagePNGRepresentation(image)];
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
    MLFeatureValue* labelFeature = [MLFeatureValue featureValueWithString:self.label.label];
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
