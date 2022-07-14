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

@implementation ModelData

- (ModelData*) initWithImage:(UIImage *)image label:(ModelLabel *)label {
    self.image = image;
    // Update reference within data to the label and then update the label's labelModelData list with the new datapoint
    self.label = label;
    [label addLabelModelData:@[self]];
    return self;
}

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

+ (NSMutableArray*) initModelDataArrayFromArray: (NSArray*) array label: (ModelLabel*)label {
    NSMutableArray* modelDatas = [NSMutableArray new];
    for (id modelDataResponse in array) {
        ModelData* md = [ModelData new];
        //XXX todo may have to change way we do this if UIImage is not stored in response dict
    //        PFFileObject* imageObj = (PFFileObject*) self.user[@"profilePic"];
    //        NSString *URLString = imageObj.url;
    //        NSURL *url = [NSURL URLWithString:URLString];
        md.image = modelDataResponse[@"image"];
        md.label = label;
        [label addLabelModelData:@[md]];
        [modelDatas addObject:md];
    }
    return modelDatas;
}

@end
