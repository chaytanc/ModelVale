//
//  PopupView.h
//  ModelVale
//
//  Created by Chaytan Inman on 9/18/22.
//

#import <UIKit/UIKit.h>
@class AvatarMLModel;

NS_ASSUME_NONNULL_BEGIN

@protocol ModelPopupDelegate <NSObject>
- (void) modelMadeCompletion: (AvatarMLModel*)model;
@end

@interface ModelPopupView : UIView
@property (strong, nonatomic) UILabel* titleLabel;
@property (strong, nonatomic) UITextField* modelNameField;
@property (strong, nonatomic) UIButton* doneButton;
@property (strong, nonatomic) UIButton* cancelButton;
@property (strong, nonatomic) UIStackView* popupStackView;
@property (strong, nonatomic) AvatarMLModel* model;
@property (weak, nonatomic) id<ModelPopupDelegate> delegate;

- (instancetype) initWithModel: (AvatarMLModel*)model;
@end

NS_ASSUME_NONNULL_END
