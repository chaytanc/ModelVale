//
//  AvatarMLModel.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/14/22.
//

#import "AvatarMLModel.h"
#import "CoreML/CoreML.h"
//#import "Parse/Parse.h"
#import "UIViewController+PresentError.h"
@import FirebaseFirestore;

NSNumber* const MAXHEALTH = @500;

@implementation AvatarMLModel

- (instancetype) initWithModelName: (NSString*)modelName avatarName: (NSString*)avatarName uid: (NSString*)uid {
    self = [super init];
    if(self){
        self.modelName = modelName;
        self.avatarName = avatarName;
        self.health = MAXHEALTH;
        self.labeledData = [NSMutableArray new];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if(self){
        self.modelName = dict[@"modelName"];
        self.avatarName = dict[@"avatarName"];
        self.health = dict[@"health"];
        self.labeledData = dict[@"labeledData"];
    }
    return self;
}

//XXX todo only works with SqueezeNet rn
- (MLModel*) getMLModelFromModelName {
    NSURL* modelURL = [[NSBundle mainBundle] URLForResource:self.modelName withExtension:@"mlmodelc"];
    MLModel* model = [[UpdatableSqueezeNet alloc] initWithContentsOfURL:modelURL error:nil].model;
    return model;
}

// Checks if the model with the avatarName and owner already exists, if not, uploads the new model and updates user.models as well
- (void) uploadModelToUserWithViewController: (NSString*) uid db: (FIRFirestore*)db vc: (UIViewController*)vc {

    FIRDocumentReference *docRef = [[db collectionWithPath:@"Model"] documentWithPath:uid];
    [docRef getDocumentWithCompletion:^(FIRDocumentSnapshot *snapshot, NSError *error) {
        if(error != nil) {
            [vc presentError:@"Failed to fetch models" message:error.localizedDescription error:error];
        }
        else if(snapshot.data != nil) {
            [self initWithDictionary:snapshot.data];
        }
        [self updateModel:uid db:db vc:vc];
    }];

    //XXX todo is there a way to upload the Model obj directly like in swift setData(from:)
//    [[[db collectionWithPath:@"Model"] documentWithPath:uid]
//     setData:<#(nonnull NSDictionary<NSString *,id> *)#> merge:<#(BOOL)#> completion:<#^(NSError * _Nullable error)completion#>
//    }];
    
    //XXX todo make function where UpdatableSqueezeNet and baseline models are automatically uploaded to Model and added to user.models
    docRef = [[db collectionWithPath:@"users"] documentWithPath:uid];
    [docRef getDocumentWithCompletion:^(FIRDocumentSnapshot *snapshot, NSError *error) {
        NSMutableArray* userModels = snapshot.data[@"models"];
        if(userModels == nil) { //XXX todo once we upload startermodels, we can guarantee this won't be nil
            userModels = [NSMutableArray new];
        }
        [userModels addObject:self];
        [self updateUserModels:uid db:db userModels:userModels vc:vc];
    }];

}

- (void) updateUserModels: (NSString*)uid db: (FIRFirestore*)db userModels: (NSMutableArray*)userModels vc: (UIViewController*)vc {
    // Reuploaded modified user.uid.models data
    [[[db collectionWithPath:@"users"] documentWithPath:uid]
     setData:@{ @"models": userModels }
         merge:YES
         completion:^(NSError * _Nullable error) {
                if(error != nil){
                    [vc presentError:@"Failed to update users" message:error.localizedDescription error:error];
                }
                else {
                    NSLog(@"Updated models in users");
                }
    }];
}

- (void) updateModel: (NSString*)uid db: (FIRFirestore*)db vc: (UIViewController*)vc {
    [[[db collectionWithPath:@"Model"] documentWithPath:self.avatarName]
     setData:@{ @"avatarName": self.avatarName, @"modelName" : self.modelName, @"health" : self.health, @"labeledData" : self.labeledData }
         merge:YES
         completion:^(NSError * _Nullable error) {
                if(error != nil){
                    [vc presentError:@"Failed to update Model" message:error.localizedDescription error:error];
                }
                else {
                    NSLog(@"Uploaded Model to Firestore");
                }
    }];
}

@end
