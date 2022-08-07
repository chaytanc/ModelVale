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
@property (strong, nonatomic) UIProgressView* loadingBar;
@end

@implementation DataViewController

// Make two section headers (or rather, testTrainTypeArray.count from TestTrainEnum.h) for each label
- (void)viewDidLoad {
    [super viewDidLoad];
    [self roundCorners];
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [self.userDataCollectionView addSubview:refreshControl];
    [refreshControl addTarget:self action:@selector(refreshData:) forControlEvents:UIControlEventValueChanged];

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

- (void) initProgressBar {
    self.loadingBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.loadingBar.progress = 0;
    self.loadingBar.tintColor = [UIColor colorWithRed:125.0f/255.0f green:65.0f/255.0f blue:205.0f/255.0f alpha:1.0f];;
    self.loadingBar.backgroundColor = [UIColor systemGray5Color];
    [self.loadingBar.layer setCornerRadius:10];
    self.loadingBar.layer.masksToBounds = TRUE;
    self.loadingBar.clipsToBounds = TRUE;
    CGAffineTransform transform = CGAffineTransformMakeScale(2.0f, 1.5f);
    self.loadingBar.transform = transform;
    [self.loadingBar setCenter:CGPointMake(self.view.layer.frame.size.width/2, self.view.layer.frame.size.height/2)];
    [self.view addSubview: self.loadingBar];
}

- (void) refreshData:(UIRefreshControl *)refreshControl {
//    [refreshControl beginRefreshing];
    // Reset the query for labels if refreshing
    self.labelFetchStart = 0;
//    self.model.labeledData = [NSMutableArray new];
    self.modelLabels = [NSMutableArray new];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self fetchSomeDataOfModel:nil allDataFetchedCompletion:^{
            [self.userDataCollectionView reloadData];
            [refreshControl endRefreshing];
        }];
    });
    return;
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
