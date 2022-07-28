//
//  AvatarMLModel.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/14/22.
//

#import "AvatarMLModel.h"
#import "CoreML/CoreML.h"
#import "Parse/Parse.h"
#import "UIViewController+PresentError.h"

NSNumber* const MAXHEALTH = @500;

@implementation AvatarMLModel

@dynamic avatarName;
@dynamic modelName;
@dynamic health;
@dynamic labeledData;
@dynamic owner;

+ (nonnull NSString *)parseClassName {
    return @"Model";
}

//XXX what is difference between doing this and having a class method that makes an instance, sets these, and returns that instance
- (instancetype) initWithModelName: (NSString*)modelName avatarName: (NSString*)avatarName user: (PFUser*)user {
    self = [super init];
    if(self){
        self.modelName = modelName;
        self.avatarName = avatarName;
        self.health = MAXHEALTH;
        self.labeledData = [NSMutableArray new];
        self.owner = user;
        //XXX todo this shouldn't be necessary for a subclass
        self[@"modelName"] = modelName;
        self[@"avatarName"] = avatarName;
        self[@"health"] = MAXHEALTH;
        self[@"labeledData"] = [NSMutableArray new];
        self[@"owner"] = user;
    }
    return self;
}

//XXX todo only works with SqueezeNet rn
- (MLModel*) getMLModelFromModelName {
    NSURL* modelURL = [[NSBundle mainBundle] URLForResource:self.modelName withExtension:@"mlmodelc"];
    MLModel* model = [[UpdatableSqueezeNet alloc] initWithContentsOfURL:modelURL error:nil].model;
    return model;
}

- (void) uploadModelToUserWithViewController: (PFUser*) user vc: (UIViewController*)vc {
    //XXX todo make function where UpdatableSqueezeNet and baseline models are automatically uploaded to Model and added to user.models
    NSMutableArray* userModels = user[@"models"];
    if(userModels == nil) { //XXX todo once we upload startermodels, we can guarantee this won't be nil
        userModels = [NSMutableArray new];
    }
    
    // Checks if the model with the avatarName and owner already exists, if not, uploads the new model and updates user.models as well
    PFQuery *query = [PFQuery queryWithClassName:@"Model"];
    query = [query whereKey:@"avatarName" equalTo:self.avatarName];
    query = [query whereKey:@"owner" equalTo:user];
    [query findObjectsInBackgroundWithBlock:^(NSArray *models, NSError *error) {
        if(error != nil){
            NSLog(@"%@", error.localizedDescription);
            [vc presentError:@"Failed to retrieve models" message:error.localizedDescription error:error];
        }
        else if (models.count != 0) {
            [vc presentError:@"Duplicate Avatar Name" message:@"Be more creative!" error:nil];
        }
        // Model didn't already exist and there was no error querying means we need to create model and add to user
        else {
            [self updateUserModels:user userModels:userModels vc:vc];
            [self updateModel: vc];
        }
    }];
}

- (void) updateUserModels: (PFUser*)user userModels: (NSMutableArray*)userModels vc: (UIViewController*)vc {
    [userModels addObject:self];
    user[@"models"] = userModels;
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if(succeeded) {
                NSLog(@"User.models updated");
            }
            else {
                [vc presentError:@"Failed to upload model to User" message:error.localizedDescription error:error];
            }
    }];
}

- (void) updateModel: (UIViewController*)vc {
    [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if(succeeded) {
            NSLog(@"Model uploaded!");
        }
        else {
            [vc presentError:@"Failed to create Model" message:error.localizedDescription error:error];
        }
    }];
}

- (void) updateExistingModel {
    PFQuery* query = [PFQuery queryWithClassName:@"Model"];
    //XXX todo, object id changes when new instance is created with starterModels. Unless i serialize, will have diff obj id, or I can explicitly save the user obj ids in userdefaults
    [query whereKey:@"avatarName" equalTo:self.avatarName];
    [query whereKey:@"owner" equalTo:self.owner];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        assert(objects.count <= 1);
        AvatarMLModel* m = (AvatarMLModel*) objects[0];
        m.health = self.health;
        m[@"labeledData"] = self.labeledData;
        [m saveInBackground];
    }];
}

@end
