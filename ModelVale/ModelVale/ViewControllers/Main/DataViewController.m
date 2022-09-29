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
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    
    //XXX todo blocked here on refreshing without reloading immediately / waiting until fetch is done
//    [self.userDataCollectionView addSubview:refreshControl];
//    [refreshControl addTarget:self action:@selector(refreshData:) forControlEvents:UIControlEventValueChanged];

    self.modelLabels = [NSMutableArray new];
    self.userDataCollectionView.delegate = self;
    self.userDataCollectionView.dataSource = self;
    self.labelFetchStart = 0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initProgressBar];
    [self.loadingBar setHidden:NO];
    [self fetchSomeDataOfModel:^(float progress) {
        self.loadingBar.progress = progress;
    } allDataFetchedCompletion:^{
        [self.userDataCollectionView reloadData];
        [self.loadingBar setHidden:YES];
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

- (void) refreshData:(UIRefreshControl *)refreshControl {
    [refreshControl beginRefreshing];
    // Reset the query for labels if refreshing
    self.labelFetchStart = 0;
    self.model.labeledData = [NSMutableArray new];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.modelLabels = [NSMutableArray new];
        [self fetchSomeDataOfModel:nil allDataFetchedCompletion:^{
            [self.userDataCollectionView reloadData];
            [refreshControl endRefreshing];
        }];
    });
    return;
}

- (IBAction)didTapLoadMore:(id)sender {
    for(ModelLabel* label in self.modelLabels) {
        [self fetchAndCreateData:label queryLimit:kDataQueryLimit completion:^(NSError * error) {
            if(error) {
                [self presentError:@"Failed to fetch data" message:error.localizedDescription error:error];
            }
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
