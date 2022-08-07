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

NS_ASSUME_NONNULL_BEGIN

@interface FirebaseViewController : UIViewController
@property (nonatomic, readwrite) FIRFirestore *db;
@property (nonatomic, strong) NSString* uid;
@property (nonatomic, strong) FIRStorage* storage;

- (void)performLogout;
-(void)transitionToLoginVC;
-(void)transitionToModelVC: ( NSMutableArray<AvatarMLModel*>* _Nullable )models;
- (NSString*) getImageStoragePath: (ModelLabel*)label;

@end

NS_ASSUME_NONNULL_END
