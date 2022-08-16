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
@import FirebaseStorage;

@interface ModelData()
@end

@implementation ModelData

+ (instancetype) initWithImage: (UIImage* _Nullable)image label:(NSString *)label imagePath: (NSString*)imagePath {
    ModelData* md = [ModelData new];
    if(image != nil) {
        md.image = image;
    }
    else {
        md.image = [UIImage new];
    }
    md.label = label;
    md.imagePath = imagePath;
    return md;
}

+ (instancetype)initWithDictionary:(NSDictionary *)dict storage: (FIRStorage*)storage completion:(void(^_Nullable)(ModelData*))completion{
    ModelData* md = [ModelData new];
    md.label = dict[@"label"];
    md.imagePath = dict[@"imagePath"];
    [md fetchAndSetImage:storage completion:^{
        if(completion) {
            completion(md);
        }
    }];
    return md;
}

//MARK: Firebase
+ (void) fetchFromReference: (FIRDocumentReference*)docRef storage: (FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^)(ModelData*))completion {
    [docRef getDocumentWithCompletion:^(FIRDocumentSnapshot * _Nullable snapshot, NSError * _Nullable error) {
        if(error != nil) {
            [vc presentError:@"Failed to fetch ModelData" message:error.localizedDescription error:error];
        }
        else {
            ModelData* d = [ModelData initWithImage:nil label:snapshot.data[@"label"] imagePath:snapshot.data[@"imagePath"]];
            [d fetchAndSetImage:storage completion:^{
                completion(d);
            }];
        }
    }];
}

- (void) fetchAndSetImage: (FIRStorage*)storage completion:(void(^_Nullable)(void))completion {
    // Max size is roughly 150 MB per image
    [[self getStorageRef:storage] dataWithMaxSize:10 * 4096 * 4096 completion:^(NSData *data, NSError *error){
        if (error != nil) {
            //XXX todo error handling without passing vc
            NSLog(@"Failed to set UIImage on ModelData.image property");
        }
        else {
            UIImage *im = [UIImage imageWithData:data];
            self.image = im;
            if(completion){
                completion();
            }
        }
    }];
}

- (void) saveModelDataInSubCollection: (FIRDocumentReference*)labelRef db: (FIRFirestore*)db storage:(FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^)(void))completion {
    __block FIRDocumentReference *ref = [[labelRef collectionWithPath:@"ModelData"] addDocumentWithData:@{
      @"label": self.label,
      @"imagePath": self.imagePath
    }
    completion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Error adding ModelData: %@", error);
        }
        else {
            NSLog(@"ModelData added with ID: %@", ref.documentID);
            self.firebaseRef = ref;
            [self uploadImageToStorage:storage vc:vc];
            completion();
        }
    }];
}

- (FIRStorageReference*) getStorageRef: (FIRStorage*)storage {
    FIRStorageReference* storageRef = [storage reference];
    NSString* storagePath = [self.label stringByAppendingString:self.imagePath];
    storageRef = [storageRef child:storagePath];
    return storageRef;
}

- (void) uploadImageToStorage: (FIRStorage*)storage vc: (UIViewController*)vc  {
    FIRStorageReference* storageRef = [self getStorageRef:storage];
    NSData *data = UIImagePNGRepresentation(self.image);
    [storageRef putData:data
                metadata:nil
                completion:^(FIRStorageMetadata *metadata, NSError *error) {
        if (error != nil) {
          [vc presentError:@"Firebase Storage image upload failed" message:error.localizedDescription error:error];
        }
        else {
          NSLog(@"Completed Storage upload");
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
