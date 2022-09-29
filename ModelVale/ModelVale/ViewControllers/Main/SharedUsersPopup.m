//
//  SharedUsersPopup.m
//  ModelVale
//
//  Created by Chaytan Inman on 9/27/22.
//

#import "SharedUsersPopup.h"
#import "AvatarMLModel.h"
#import "User.h"

@interface SharedUsersPopup () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSMutableArray* users;
@end

@implementation SharedUsersPopup


- (instancetype)init
{
    self = [super init];
    if (self) {
                
        self.layer.cornerRadius = 24;
        self.clipsToBounds = YES;
        self.translatesAutoresizingMaskIntoConstraints = YES;
        
        // Create UI components
        [self formatTitleLabel];
        [self formatUsersTableView];
        [self formatPopupStackView];
        self.usersTableView.delegate = self;
        self.usersTableView.dataSource = self;
        self.users = [NSMutableArray new];

    }
    return self;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    // Frame based layouts here
    [self setStackViewConstraints];
    [self setTitleLabelConstraints];
}

- (void) setTitleLabelConstraints {
    [self.titleLabel addConstraint: [NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:30]];
}

- (void) formatTitleLabel {
    self.titleLabel = [UILabel new];
    self.titleLabel.text = @"Model Teammates";
    [UIFontDescriptor new];
    UIFont* font = [UIFont fontWithName:@"Trebuchet MS" size:12];
    [self.titleLabel setFont:font];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.minimumScaleFactor = 0.6;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (void) formatUsersTableView {
    self.usersTableView = [UITableView new];
    [self.usersTableView setBackgroundColor:[UIColor blackColor]];
}

- (void) formatPopupStackView {
    self.popupStackView = [UIStackView new];
    [self.popupStackView addArrangedSubview:self.titleLabel];
    [self.popupStackView addArrangedSubview:self.usersTableView];

    self.popupStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.popupStackView.backgroundColor = [UIColor blackColor];

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

- (void) getModelSharedUsersWithCompletion:(void(^)(NSError *error))completion {
    FIRQuery* query = [[self.db collectionWithPath:@"users"] queryWhereField:@"models" arrayContains:self.model.avatarName];
    [query getDocumentsWithCompletion:^(FIRQuerySnapshot * _Nullable snapshot, NSError * _Nullable error) {
        if(error) {
            completion(error);
        }
        else {
            for(FIRQueryDocumentSnapshot* doc in snapshot.documents) {
                NSString* username = doc.data[@"username"];
                username = [NSString stringWithFormat:@"@%@", username];
                [self.users addObject:username];
            }
            completion(error);
        }
    }];
}

// MARK: Tableview


- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    cell.textLabel.text = self.users[indexPath.row];
    UIFont* font = [UIFont fontWithName:@"Trebuchet MS" size:10];
    cell.backgroundColor = [UIColor blackColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    [cell.textLabel setFont:font];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.users.count;
}

@end
