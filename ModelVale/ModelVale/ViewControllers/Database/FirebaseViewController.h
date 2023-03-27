//
//  FirebaseViewController.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/28/22.
//

#import <UIKit/UIKit.h>
@import FirebaseFirestore;
@import FirebaseStorage;
#import "UIViewController+PresentError.h"
@class ModelLabel;
@class AvatarMLModel;
@class User;

NS_ASSUME_NONNULL_BEGIN

@interface FirebaseViewController : UIViewController
@property (nonatomic, strong) User* user;
@property (nonatomic, readwrite) FIRFirestore *db;
@property (nonatomic, strong) FIRStorage* storage;

- (void)performLogout;
+ (void)transitionToLoginVC;
+ (void)transitionToModelVC: ( NSMutableArray<AvatarMLModel*>* _Nullable )models uid: (NSString* _Nullable)uid;
- (NSString*) getImageStoragePath: (ModelLabel*)label;
- (void) deleteUser;

@end

NS_ASSUME_NONNULL_END
