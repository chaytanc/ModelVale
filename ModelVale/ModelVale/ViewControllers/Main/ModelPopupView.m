//
//  PopupView.m
//  ModelVale
//
//  Created by Chaytan Inman on 9/18/22.
//

#import "ModelPopupView.h"
#import "AvatarMLModel.h"

/*
 This view pops up and makes a model using the information inputted.
 It uploads this model to the database after creating it and dismisses when successful
 It then calls the modelCreatedCompletion of its delegate when the local model has been made. The delegate could then transition to an appropriate VC, also passing the newly created model to the delegate
 */
@implementation ModelPopupView

- (instancetype)init
{
    self = [super init];
    if (self) {
                
        self.alpha = 0.5;
        self.backgroundColor = UIColor.greenColor;
        self.layer.cornerRadius = 24;
        if (@available(iOS 15.0, *)) {
            [self.layer setShadowColor:[[UIColor systemCyanColor] CGColor]];
        } else {
            [self.layer setShadowColor:[[UIColor systemTealColor] CGColor]];
        }
        [self.layer setShadowOffset:CGSizeMake(5, 5)];
        [self.layer setShadowRadius:5];
        [self.layer setShadowOpacity:0.9];
        
        // Create UI components
        [self formatTitleLabel];
        [self formatModelNameField];
        [self formatDoneButton];
        [self formatCancelButton];
        [self formatPopupStackView];
           
    }
    return self;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    // Frame based layouts here
    [self setStackViewConstraints];
}

- (void) formatTitleLabel {
    self.titleLabel = [UILabel new];
    self.titleLabel.text = @"Give your model a name";
    [UIFontDescriptor new];
    UIFont* font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:19];
    [self.titleLabel setFont:font];
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.minimumScaleFactor = 0.6;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (void) formatModelNameField {
    self.modelNameField = [UITextField new];
    self.modelNameField.placeholder = [AvatarMLModel getDefaultModelName];
}

- (void) formatDoneButton {
    self.doneButton = [UIButton new];
    self.doneButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.doneButton setTitle:@"Create Model" forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor systemBlueColor] forState: UIControlStateNormal];
    [self.doneButton addTarget:self
                        action:@selector(doneTapped:)
                        forControlEvents:UIControlEventTouchUpInside];
}

- (void) formatCancelButton {
    self.cancelButton = [UIButton new];
    self.cancelButton.titleLabel.textColor = [UIColor systemBlueColor];
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor systemBlueColor] forState: UIControlStateNormal];
    [self.cancelButton addTarget:self
                        action:@selector(cancelTapped:)
                        forControlEvents:UIControlEventTouchUpInside];
}

- (void) formatPopupStackView {
    self.popupStackView = [UIStackView new];
    [self.popupStackView addArrangedSubview:self.titleLabel];
    [self.popupStackView addArrangedSubview:self.modelNameField];
    [self.popupStackView addArrangedSubview: self.doneButton];
    [self.popupStackView addArrangedSubview: self.cancelButton];

    self.popupStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.popupStackView.distribution = UIStackViewDistributionFillEqually;
    self.popupStackView.backgroundColor = [UIColor whiteColor];

    
    [self addSubview:self.popupStackView];
}

- (void) setStackViewConstraints {
    self.popupStackView.axis = UILayoutConstraintAxisVertical;
    [self.popupStackView setLayoutMargins:UIEdgeInsetsMake(8, 8, 8, 8)];
    [self.popupStackView setLayoutMarginsRelativeArrangement:YES];
    
    // Constrain to sides
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:self.popupStackView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self.popupStackView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:self.popupStackView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:0];
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:self.popupStackView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    [self addConstraints:@[left, top, right, bottom]];
}

- (void) setLocalModel {
    //XXX implement user sets the picture of the model as well
    NSString* name = self.modelNameField.text;
    if([name isEqualToString:@""]) {
        self.model.avatarName = self.modelNameField.placeholder;
    }
    else {
        self.model.avatarName = name;
    }
}

//MARK: Actions
- (void) cancelTapped: (UIButton *) button {
    NSLog(@"Cancel tapped!!!");
    [self removeFromSuperview];
}

- (void) doneTapped: (UIButton *) button {
    NSLog(@"Create model tapped!!!");
    // if create user succeeds dismiss and go to home, otherwise present error and go to login
    [self setLocalModel];
    [self.delegate modelMadeCompletion:self.model];
}

@end
