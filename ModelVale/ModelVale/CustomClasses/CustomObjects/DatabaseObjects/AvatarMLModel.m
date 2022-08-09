//
//  AvatarMLModel.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/14/22.
//

#import "AvatarMLModel.h"
#import "CoreML/CoreML.h"
#import "UIViewController+PresentError.h"
#import "Xception.h"
@import FirebaseFirestore;
#import "ModelLabel.h"
#import "ModelProtocol.h"

//XXX todo standardize this constant across VCs (modelVC)
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
        self.avatarImage = [UIImage imageNamed:@"racoonavatar_glow"];
        self.modelURL = [self modelURL];
    }
    return self;
}

+ (void)initWithDictionary:(NSDictionary *)dict storage: (FIRStorage*)storage completion:(void(^_Nullable)(AvatarMLModel*))completion{
    AvatarMLModel* model = [AvatarMLModel new];
    model.modelName = dict[@"modelName"];
    model.avatarName = dict[@"avatarName"];
    model.health = dict[@"health"];
    model.labeledData = dict[@"labeledData"];
    model.modelURL = [model modelURL];
    [model fetchAvatarImage:storage completion:^{
        if(completion) {
            completion(model);
        }
    }];
}

- (NSString*) avatarImagePath {
    NSString* fullPath = [NSString stringWithFormat:@"/avatars/%@", self.avatarName];
    return fullPath;
}

- (MLModel*) getMLModelFromModelName {
    id<ModelProtocol> modelClassInstance = [self loadModel];
    MLModel* model = modelClassInstance.model;
//    MLModel* model = [[ModelClass alloc] initWithContentsOfURL:modelURL error:nil].model;
    return model;
}

- (NSURL*) modelURL {
    NSURL* url = [[NSBundle mainBundle] URLForResource:self.modelName withExtension:@"mlmodelc"];
    return url;
}

// As long as no functions specfic to either Squeezeable or other networks are needed, this should work
- (id<ModelProtocol>) loadModel {
    id<ModelProtocol> modelClassInstance = [[NSClassFromString(self.modelName) alloc] initWithContentsOfURL:self.modelURL error:nil];
    return modelClassInstance;
}

//MARK: Firebase

// Checks if the model with the avatarName and owner already exists, if not, uploads the new model and updates user.models as well
- (void) uploadModelToUserWithViewController: (NSString*) uid db: (FIRFirestore*)db storage: (FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion {

    FIRDocumentReference *docRef = [[db collectionWithPath:@"Model"] documentWithPath:self.avatarName];
    [docRef getDocumentWithCompletion:^(FIRDocumentSnapshot *snapshot, NSError *error) {
        if(error != nil) {
            [vc presentError:@"Failed to fetch models" message:error.localizedDescription error:error];
        }
        // If a model already exists under that avatarName, update local properties, then update the database model
        else if(snapshot.data != nil) {
//            [self initWithDictionary:snapshot.data];
            [AvatarMLModel initWithDictionary:snapshot.data storage:storage completion:^(AvatarMLModel * model) {
                [model uploadNewModel:uid db:db storage:storage vc:vc completion:completion];
            }];
        }
    }];
}

- (void) updateUserModelDocRefs: (NSString*)uid db: (FIRFirestore*)db userModelDocRefs: (NSMutableArray*)userModelDocRefs vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion {
    
    // Get the existing document, get its models, update local data to have remote + self.avatarName, finally update remote
    FIRDocumentReference* docRef = [[db collectionWithPath:@"users"] documentWithPath:uid];
    [docRef getDocumentWithCompletion:^(FIRDocumentSnapshot *snapshot, NSError *error) {
        NSMutableArray* remoteModels = snapshot.data[@"models"];
        NSMutableArray* userModelDocRefs = (remoteModels) ? remoteModels : [NSMutableArray new];
        if(![userModelDocRefs containsObject:self.avatarName]) {
            [userModelDocRefs addObject:self.avatarName];
            self.userModelDocRefs = userModelDocRefs;
            [self addUserModelDocRefs:uid db:db userModelDocRefs:userModelDocRefs vc:vc completion:completion];
        }
    }];
}

- (void) addUserModelDocRefs: (NSString*)uid db: (FIRFirestore*)db userModelDocRefs: (NSMutableArray*)userModelDocRefs vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion {
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
        completion(error);
    }];
}

- (void) uploadNewModel: (NSString*)uid db: (FIRFirestore*)db storage: (FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion {
    [[[db collectionWithPath:@"Model"] documentWithPath:self.avatarName]
     setData:@{
        @"avatarName": self.avatarName,
        @"modelName" : self.modelName,
        @"health" : self.health,
        @"labeledData" : self.labeledData,
        @"avatarImagePath" : self.avatarImagePath
    }
         merge:YES
         completion:^(NSError * _Nullable error) {
                if(error != nil){
                    [vc presentError:@"Failed to update Model" message:error.localizedDescription error:error];
                }
                else {
                    NSLog(@"Uploaded Model to Firestore");
                    [self.userModelDocRefs addObject:self.avatarName];
                    [self updateUserModelDocRefs:uid db:db userModelDocRefs:self.userModelDocRefs vc:vc completion:completion];
                    [self uploadImageToStorage:storage vc:vc];
                }
    }];
}

- (void)updatePropsLocallyWithDict:(NSDictionary *)dict vc: (UIViewController*)vc completion:(void(^)(void))completion{
    self.modelName = dict[@"modelName"];
    self.avatarName = dict[@"avatarName"];
    self.health = dict[@"health"];
    self.labeledData = dict[@"labeledData"];
    self.avatarImagePath = dict[@"avatarImagePath"];
}

+ (void) fetchAndReturnExistingModel: (FIRFirestore*)db storage:(FIRStorage*)storage documentPath:(NSString*)documentPath completion:(void(^_Nullable)(AvatarMLModel*))completion {
    FIRDocumentReference *docRef = [[db collectionWithPath:@"Model"] documentWithPath:documentPath];
    [docRef getDocumentWithCompletion:^(FIRDocumentSnapshot *snapshot, NSError *error) {
       if (snapshot.exists) {
           NSLog(@"Model exists with data: %@", snapshot.data);
//           AvatarMLModel* model = [[AvatarMLModel new] initWithDictionary: snapshot.data];
           [AvatarMLModel initWithDictionary:snapshot.data storage:storage completion:^(AvatarMLModel * model) {
               completion(model);
           }];
       }
       else {
           NSLog(@"Model does not exist");
       }
     }];
}

- (void) updateModelLabeledDataWithDatabase: (FIRFirestore*)db vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion {
    
    FIRDocumentReference *modelRef = [[db collectionWithPath:@"Model"] documentWithPath:self.avatarName];
    [modelRef updateData:@{
      @"labeledData": [FIRFieldValue fieldValueForArrayUnion:self.labeledData]
    } completion:^(NSError * _Nullable error) {
        completion(error);
    }];
}

// Mark: Avatar Image
//XXX todo subclass so that both ModelData and AvatarMLModel could access these functions
- (FIRStorageReference*) getStorageRef: (FIRStorage*)storage {
    FIRStorageReference* storageRef = [storage reference];
    storageRef = [storageRef child:self.avatarImagePath];
    return storageRef;
}

- (void) fetchAvatarImage: (FIRStorage*)storage completion:(void(^_Nullable)(void))completion {
    // Max size is roughly 150 MB per avatar
    [[self getStorageRef:storage] dataWithMaxSize:10 * 4096 * 4096 completion:^(NSData *data, NSError *error){
        if (error != nil) {
            NSLog(@"%@", error.localizedDescription);
            NSLog(@"Failed to set UIImage on Model.avatarImage property");
        }
        else {
            UIImage *im = [UIImage imageWithData:data];
            self.avatarImage = im;
        }
        if(completion){
            completion();
        }
    }];
}

- (void) uploadImageToStorage: (FIRStorage*)storage vc: (UIViewController*)vc  {
    FIRStorageReference* storageRef = [self getStorageRef:storage];
    NSData *data = UIImagePNGRepresentation(self.avatarImage);
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

@end
