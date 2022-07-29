//
//  FirebaseViewController.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/28/22.
//

#import <UIKit/UIKit.h>
@import FirebaseFirestore;

NS_ASSUME_NONNULL_BEGIN

@interface FirebaseAuthViewController : UIViewController
@property (nonatomic, readwrite) FIRFirestore *db;
@property (nonatomic, strong) NSString* uid;

- (void)performLogout;
-(void)transitionToLoginVC;
-(void)transitionToModelVC;
@end

NS_ASSUME_NONNULL_END
