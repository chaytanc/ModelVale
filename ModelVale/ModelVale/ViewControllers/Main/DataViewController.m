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
@property (weak, nonatomic) IBOutlet UICollectionView *userDataCollectionView;
@end

@implementation DataViewController

// Need two section headers (or rather, testTrainTypeArray.count from TestTrainEnum.h) for each label
- (void)viewDidLoad {
    [super viewDidLoad];
    //XXX todo remove modelLabel
//    self.modelLabels = [NSMutableArray new];
    self.userDataCollectionView.delegate = self;
    self.userDataCollectionView.dataSource = self;
    
    NSMutableArray* modelLabels = self.model.labeledData;
    //XXX todo fetch and display
//
//    ModelLabel* fakeLabel = [[ModelLabel new] initEmptyLabel:@"mountain" testTrainType:dataTypeEnumToString(Train)];
//    UIImage* testImage = [UIImage imageNamed:@"mountain"];
//    ModelData* fakeData = [ModelData initWithImage:testImage label:fakeLabel.label imagePath:@"1"]; // Note: DOES NOT add itself to the label passed
//    [fakeLabel addLabelModelData:@[fakeData]];
//    testImage = [UIImage imageNamed:@"rivermountain"];
//    fakeData = [ModelData initWithImage:testImage label:fakeLabel.label imagePath:@"2"];
//    [fakeLabel addLabelModelData:@[fakeData]];
//    [modelLabels addObject:fakeLabel];
//    // Add one mountain to the label "hill" and add to dvc
//    fakeLabel = [[ModelLabel new] initEmptyLabel:@"hill" testTrainType:dataTypeEnumToString(Train)];
//    testImage = [UIImage imageNamed:@"snowymountains"];
//    fakeData = [ModelData initWithImage:testImage label:fakeLabel.label imagePath:@"1"];
//    [fakeLabel addLabelModelData:@[fakeData]];
//    [modelLabels addObject:fakeLabel];
    [self.userDataCollectionView reloadData];
}

// MARK: Firebase

//XXX todo paginate
- (void) fetchUserData {
    // get all labeledData from Hal
    // for each label, get labelModelData until we reach some page display limit
    // next query picks up where we left off to keep displaying
}


// MARK: Collection view
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UserDataCell* cell = [self.userDataCollectionView dequeueReusableCellWithReuseIdentifier:@"userDataCell" forIndexPath:indexPath];
    ModelLabel* sectionLabel = self.model.labeledData[indexPath.section];
    ModelData* rowData = sectionLabel.labelModelData[indexPath.row];
    [cell.userDataImageView setImage:rowData.image];
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    ModelLabel* label = self.model.labeledData[section];
    return label.labelModelData.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {

    return self.model.labeledData.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    
    if([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UserDataSectionHeader* sectionHeader = [self.userDataCollectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"userDataSectionHeader" forIndexPath:indexPath];
        ModelLabel* label = self.model.labeledData[indexPath.section];
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
