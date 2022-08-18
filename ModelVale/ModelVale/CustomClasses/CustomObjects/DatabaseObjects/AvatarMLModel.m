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
#import "User.h"

NSNumber* const kMaxHealth = @500;
@interface AvatarMLModel ()
@end

@implementation AvatarMLModel

static NSNumber* maxHealth = kMaxHealth;
+ (NSNumber*)maxHealth {
    return maxHealth;
}

- (instancetype) initWithModelName: (NSString*)modelName avatarName: (NSString*)avatarName {
    self = [super init];
    if(self){
        self.modelName = modelName;
        self.avatarName = avatarName;
        self.health = AvatarMLModel.maxHealth;
        self.labeledData = [NSMutableArray new];
        self.avatarImage = [UIImage imageNamed:@"racoonavatar_glow"];
        self.modelURL = [self modelURL];
    }
    return self;
}

// Assumes that model and avatarImage already exist in Firebase
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

// Checks if the model with the avatarName and owner already exists, if not, uploads the new model, then creates local copies of the remote and returns in a completion. Updates user.models locally and remotely as well
- (void) uploadModel: (User*)user db: (FIRFirestore*)db storage: (FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion {

    FIRDocumentReference *docRef = [[db collectionWithPath:@"Model"] documentWithPath:self.avatarName];
    [docRef getDocumentWithCompletion:^(FIRDocumentSnapshot *snapshot, NSError *error) {
        if(error != nil) {
            [vc presentError:@"Failed to fetch models" message:error.localizedDescription error:error];
            completion(error);
        }
        else {
            // If a model already exists under that avatarName, update this model's local props and then update remote to match labeledData
            if(snapshot.data != nil) {
                NSLog(@"Found existing model");
                [self updateFromExistingRemoteModel:user db:db vc:vc snapshot:snapshot completion:completion];
            }
            else {
                NSLog(@"Did not find existing model in user models");
                [self uploadNewModel:user db:db storage:storage vc:vc completion:completion];
            }

        }
    }];
}

- (void) updateFromExistingRemoteModel: (User*)user db: (FIRFirestore*)db vc: (UIViewController*)vc snapshot: (FIRDocumentSnapshot*) snapshot completion:(void(^)(NSError *error))completion {
    // First update this local model to reflect the remote changes it might be missing, then upload the updated version fo this model
    dispatch_group_t updateGroup = dispatch_group_create();
    dispatch_group_enter(updateGroup);
    [self updatePropsLocallyWithDict:snapshot.data];
    __block NSError* error;
    [self updateChangeableData:db vc:vc completion:^(NSError * _Nonnull updateError) {
        error = updateError;
        dispatch_group_leave(updateGroup);
    }];
    dispatch_group_enter(updateGroup);
    // While model might already exist, since users can share models we still have to update user model refs
    [user.userModelDocRefs addObject:self.avatarName];
    [user updateUserModelDocRefs:db vc:vc completion:^(NSError *updateError) {
        error = updateError;
        dispatch_group_leave(updateGroup);
    }];
    dispatch_group_notify(updateGroup, dispatch_get_main_queue(), ^{
        completion(error);
    });
}

- (void) uploadNewModel: (User*)user db: (FIRFirestore*)db storage: (FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion {
    
    dispatch_group_t uploadModelGroup = dispatch_group_create();
    // Set the remote data, upload the avatar icon, and update the user's model references to include this model
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
                    [user.userModelDocRefs addObject:self.avatarName];
                    dispatch_group_enter(uploadModelGroup);
                    [user updateUserModelDocRefs:db vc:vc completion:^(NSError *updateError) {
                        dispatch_group_leave(uploadModelGroup);
                    }];
                    dispatch_group_enter(uploadModelGroup);
                    [self uploadImageToStorage:storage vc:vc completion:^{
                        dispatch_group_leave(uploadModelGroup);
                    }];
                    dispatch_group_notify(uploadModelGroup, dispatch_get_main_queue(), ^{
                        completion(error);
                    });
                }
    }];
}

- (void) updateModelHealth: (User*)user db: (FIRFirestore*)db completion:(void(^)(NSError *error))completion {
    [[[db collectionWithPath:@"Model"] documentWithPath:self.avatarName]
        setData:@{@"health" : self.health,}
        merge:YES
        completion:completion];
}

- (void)updatePropsLocallyWithDict:(NSDictionary *)dict {
    self.modelName = dict[@"modelName"];
    self.avatarName = dict[@"avatarName"];
    self.health = dict[@"health"];
    for(id data in dict[@"labeledData"]) {
        if(![self.labeledData containsObject:data]) {
            [self.labeledData addObject:data];
        }
    }
    self.avatarImagePath = dict[@"avatarImagePath"];
}

+ (void) fetchAndReturnExistingModel: (FIRFirestore*)db storage:(FIRStorage*)storage documentPath:(NSString*)documentPath completion:(void(^_Nullable)(AvatarMLModel*))completion {
    FIRDocumentReference *docRef = [[db collectionWithPath:@"Model"] documentWithPath:documentPath];
    [docRef getDocumentWithCompletion:^(FIRDocumentSnapshot *snapshot, NSError *error) {
       if (snapshot.exists) {
           NSLog(@"Model exists with data: %@", snapshot.data);
           [AvatarMLModel initWithDictionary:snapshot.data storage:storage completion:^(AvatarMLModel * model) {
               completion(model);
           }];
       }
       else {
           NSLog(@"Model does not exist");
       }
     }];
}

- (void) updateChangeableData: (FIRFirestore*)db vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion {
    
    FIRDocumentReference *modelRef = [[db collectionWithPath:@"Model"] documentWithPath:self.avatarName];
    [modelRef updateData:@{
        //XXX not sure that we can update normal int fields in updateData like this
        @"health" : self.health,
        @"labeledData": [FIRFieldValue fieldValueForArrayUnion:self.labeledData]
    } completion:completion];
}

// Mark: Avatar Image
//XXX todo subclass so that both ModelData and AvatarMLModel could access these functions
- (FIRStorageReference*) getStorageRef: (FIRStorage*)storage {
    FIRStorageReference* storageRef = [storage reference];
    storageRef = [storageRef child:self.avatarImagePath];
    return storageRef;
}

- (void) fetchAvatarImage: (FIRStorage*)storage completion:(void(^_Nullable)(void))completion {
    // Max size is roughly 75 MB per avatar
    [[self getStorageRef:storage] dataWithMaxSize:5 * 4096 * 4096 completion:^(NSData *data, NSError *error){
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

- (void) uploadImageToStorage: (FIRStorage*)storage vc: (UIViewController*)vc completion:(void(^_Nullable)(void))completion {
    
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
        if(completion){
            completion();
        }
    }];
}

@end
