//
//  SharedUsersPopup.h
//  ModelVale
//
//  Created by Chaytan Inman on 9/27/22.
//

#import <UIKit/UIKit.h>
@import FirebaseFirestore;
@class AvatarMLModel;
@class User;

NS_ASSUME_NONNULL_BEGIN

@interface SharedUsersPopup : UIView
@property (strong, nonatomic) UILabel* titleLabel;
@property (strong, nonatomic) UITableView* usersTableView;
@property (strong, nonatomic) UIStackView* popupStackView;
// Set these properties when calling the popup
@property (strong, nonatomic) AvatarMLModel* model;
@property (strong, nonatomic) User* user;
@property (nonatomic, readwrite) FIRFirestore *db;
- (void) getModelSharedUsersWithCompletion:(void(^)(NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
