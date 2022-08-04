//
//  AvatarMLModel.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/14/22.
//

#import "AvatarMLModel.h"
#import "CoreML/CoreML.h"
#import "UIViewController+PresentError.h"
@import FirebaseFirestore;

NSNumber* const MAXHEALTH = @500;
@interface AvatarMLModel ()
@property (nonatomic, strong) NSMutableArray<NSString*>* userModelDocRefs;
@end

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

    FIRDocumentReference *docRef = [[db collectionWithPath:@"Model"] documentWithPath:self.avatarName];
    [docRef getDocumentWithCompletion:^(FIRDocumentSnapshot *snapshot, NSError *error) {
        if(error != nil) {
            [vc presentError:@"Failed to fetch models" message:error.localizedDescription error:error];
        }
        // If a model already exists under that avatarName, update local properties, then update the database model
        else if(snapshot.data != nil) {
            [self initWithDictionary:snapshot.data];
            
        }
        [self updateModel:uid db:db vc:vc];
    }];
}

- (void) updateUserModelDocRefs: (NSString*)uid db: (FIRFirestore*)db userModelDocRefs: (NSMutableArray*)userModelDocRefs vc: (UIViewController*)vc {
    
    FIRDocumentReference* docRef = [[db collectionWithPath:@"users"] documentWithPath:uid];
    [docRef getDocumentWithCompletion:^(FIRDocumentSnapshot *snapshot, NSError *error) {
        NSMutableArray* userModelDocRefs = snapshot.data[@"models"];
        if(![userModelDocRefs containsObject:self.avatarName]) {
            [userModelDocRefs addObject:self.avatarName];
            [self addUserModelDocRefs:uid db:db userModelDocRefs:userModelDocRefs vc:vc];
        }
    }];
}

- (void) addUserModelDocRefs: (NSString*)uid db: (FIRFirestore*)db userModelDocRefs: (NSMutableArray*)userModelDocRefs vc: (UIViewController*)vc {
    // Reuploaded modified user.uid.models data
    [[[db collectionWithPath:@"users"] documentWithPath:uid]
     setData:@{ @"models": userModelDocRefs }
         merge:YES
         completion:^(NSError * _Nullable error) {
                if(error != nil){
                    [vc presentError:@"Failed to update users" message:error.localizedDescription error:error];
                }
                else {
                    NSLog(@"Added model in users.models");
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
                    [self.userModelDocRefs addObject:self.avatarName];
                    [self updateUserModelDocRefs:uid db:db userModelDocRefs:self.userModelDocRefs vc:vc];
                }
    }];
}

+ (void) fetchAndCreateAvatarMLModel: (FIRFirestore*)db documentPath: (NSString*)documentPath completion:(void(^_Nullable)(AvatarMLModel*))completion {
    FIRDocumentReference *docRef = [[db collectionWithPath:@"Model"] documentWithPath:documentPath];
    [docRef getDocumentWithCompletion:^(FIRDocumentSnapshot *snapshot, NSError *error) {
       if (snapshot.exists) {
           NSLog(@"Model data: %@", snapshot.data);
           AvatarMLModel* model = [[AvatarMLModel new] initWithDictionary: snapshot.data];
           completion(model);
       } else {
         NSLog(@"Model does not exist");
       }
     }];
}

@end
