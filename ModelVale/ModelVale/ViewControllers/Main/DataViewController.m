//
//  DataViewController.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/7/22.
//

#import "DataViewController.h"
#import "UserDataCell.h"
#import "UserDataSectionHeader.h"
#import "ModelData.h"
#import "ModelLabel.h"
#import "TestTrainEnum.h"
#import "UIViewController+PresentError.h"
#import "AvatarMLModel.h"
#import "AddDataViewController.h"

//XXX todo constant is redeclared, make global or limit use to one file
//NSInteger const kDataQueryLimit = 2;

@interface DataViewController () <UICollectionViewDelegate, UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UIButton *loadMoreButton;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UICollectionView *userDataCollectionView;
@end

@implementation DataViewController

// Make two section headers (or rather, testTrainTypeArray.count from TestTrainEnum.h) for each label
- (void)viewDidLoad {
    [super viewDidLoad];
    [self roundCorners];
    self.modelLabels = [NSMutableArray new];
    self.userDataCollectionView.delegate = self;
    self.userDataCollectionView.dataSource = self;
    self.labelFetchStart = 0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fetchSomeDataOfModel:^{
        [self.userDataCollectionView reloadData];
    }];
}

- (void) roundCorners {
    self.userDataCollectionView.layer.cornerRadius = 10;
    self.userDataCollectionView.layer.masksToBounds = YES;
    self.contentView.layer.cornerRadius = 10;
    self.contentView.layer.masksToBounds = YES;
    self.loadMoreButton.layer.cornerRadius = 10;
    self.loadMoreButton.layer.masksToBounds = YES;
}

- (IBAction)didTapLoadMore:(id)sender {
    for(ModelLabel* label in self.modelLabels) {
        [self fetchAndCreateData:label queryLimit:2 completion:^{
            [self.userDataCollectionView reloadData];
        }];
    }
}

// MARK: Collection view
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UserDataCell* cell = [self.userDataCollectionView dequeueReusableCellWithReuseIdentifier:@"userDataCell" forIndexPath:indexPath];
    ModelLabel* sectionLabel = self.modelLabels[indexPath.section];
    ModelData* rowData = sectionLabel.localData[indexPath.row];
    [cell.userDataImageView setImage:rowData.image];
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    // One section per label, with labelModelData number of data in that section
    ModelLabel* label = self.modelLabels[section];
    return label.localData.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.modelLabels.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    
    if([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UserDataSectionHeader* sectionHeader = [self.userDataCollectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"userDataSectionHeader" forIndexPath:indexPath];
        ModelLabel* label = self.modelLabels[indexPath.section];
        NSString* dataType = [label.testTrainType stringByAppendingString:@": "];
        sectionHeader.userDataLabel.text = [dataType stringByAppendingString: label.label];
        return sectionHeader;
    }
    else {
        [self presentError:@"Cannot load collection" message:@"Header object type incorrect" error:nil];
        return nil;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier] isEqualToString:@"dataToAddData"]) {
        AddDataViewController* targetController = (AddDataViewController*) [segue destinationViewController];
        targetController.model = self.model;
    }
}


@end
