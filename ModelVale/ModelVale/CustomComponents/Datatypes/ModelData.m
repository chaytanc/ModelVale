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

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if(self){
        self.label = dict[@"label"];
        self.imagePath = dict[@"imagePath"];
    }
    return self;
}

//MARK: Firebase
+ (void) fetchFromReference: (FIRStorage*)storage docRef: (FIRDocumentReference*)docRef vc: (UIViewController*)vc completion:(void(^)(ModelData*))completion {
    [docRef getDocumentWithCompletion:^(FIRDocumentSnapshot * _Nullable snapshot, NSError * _Nullable error) {
        if(error != nil) {
            [vc presentError:@"Failed to fetch ModelData" message:error.localizedDescription error:error];
        }
        else {
            ModelData* d = [ModelData initWithImage:nil label:snapshot.data[@"label"] imagePath:snapshot.data[@"imagePath"]];
            [d fetchAndSetImage:storage vc:vc];
            completion(d);
        }
    }];
}

- (void) fetchAndSetImage: (FIRStorage*)storage vc: (UIViewController*)vc {
    FIRStorageReference* imageRef = [[storage reference] child:self.imagePath];
    [imageRef dataWithMaxSize:1 * 1024 * 1024 completion:^(NSData *data, NSError *error){
        if (error != nil) {
            [vc presentError:@"Failed to download image" message:error.localizedDescription error:error];
        } else {
            UIImage *im = [UIImage imageWithData:data];
            self.image = im;
        }
    }];
}

- (void) saveNewModelDataWithDatabase: (FIRFirestore*)db storage:(FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^)(void))completion {
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
              self.firebaseRef = [self getFirestoreRef:db docID:ref.documentID];
              [self uploadImageToStorage:storage vc:vc];
              completion();
          }
        }];
}

- (FIRDocumentReference*) getFirestoreRef: (FIRFirestore*)db docID: (NSString*)docID {
//    NSString* refPath = [NSString stringWithFormat:@"%@/%@", self.label, docID];
    FIRDocumentReference* ref = [[db collectionWithPath:@"ModelData"] documentWithPath: docID];
    return ref;
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
    FIRStorageUploadTask *uploadTask = [storageRef putData:data
                                                  metadata:nil
                                                completion:^(FIRStorageMetadata *metadata,
                                                             NSError *error) {
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
