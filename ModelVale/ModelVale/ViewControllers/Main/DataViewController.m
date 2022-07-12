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

@interface DataViewController () <UICollectionViewDelegate, UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UICollectionView *userDataCollectionView;
@end

@implementation DataViewController

// Need two section headers (or rather, testTrainTypeArray.count from TestTrainEnum.h) for each label
- (void)viewDidLoad {
    [super viewDidLoad];
    self.modelLabels = [NSMutableArray new];
    self.userDataCollectionView.delegate = self;
    self.userDataCollectionView.dataSource = self;
    
    ModelLabel* fakeLabel = [[ModelLabel new] initEmptyLabel:@"mountain" testTrainType:Train];
    UIImage* testImage = [UIImage imageNamed:@"mountain"];
    ModelData* fakeData = [[ModelData new] initWithImage:testImage label:fakeLabel]; // Note: adds itself to the label passed
    testImage = [UIImage imageNamed:@"rivermountain"];
    fakeData = [[ModelData new] initWithImage:testImage label:fakeLabel];
    [self.modelLabels addObject:fakeLabel];
    // Add one mountain to the label "hill" and add to dvc
    fakeLabel = [[ModelLabel new] initEmptyLabel:@"hill" testTrainType:Train];
    testImage = [UIImage imageNamed:@"snowymountains"];
    fakeData = [[ModelData new] initWithImage:testImage label:fakeLabel];
    [self.modelLabels addObject:fakeLabel];
    [self.userDataCollectionView reloadData];
}

// Return the index of the section we're in given the row
// Used to turn an indexPath.row that does *not* reset after a section into which section we're in etc...
// Useful if you don't know that you can just do indexPath.section
- (NSArray*) getSectionFromRow: (NSInteger)row {

    NSInteger sectionInd = 0;
    NSInteger dataSoFar = ((ModelLabel*) self.modelLabels[0]).numPerLabel;
    NSInteger numPerLabel = ((ModelLabel*) self.modelLabels[0]).numPerLabel;
    while(dataSoFar <= row) { // Have to have the = since dataSoFar ind @ 1 and row ind @ 0
        sectionInd += 1;
        ModelLabel* section = self.modelLabels[sectionInd];
        numPerLabel = section.numPerLabel;
        dataSoFar += numPerLabel;
    }
    dataSoFar -= numPerLabel; // After overshooting dataSoFar to find which section, subtract it again
    NSNumber *secInd = [NSNumber numberWithInteger:sectionInd];
    NSNumber *dataBeforeSection = [NSNumber numberWithInteger:dataSoFar];
    // dataBeforeSection is noninclusive of the data in the current section
    return @[secInd, dataBeforeSection];
}

// MARK: Collection view
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UserDataCell* cell = [self.userDataCollectionView dequeueReusableCellWithReuseIdentifier:@"userDataCell" forIndexPath:indexPath];
    ModelLabel* sectionLabel = self.modelLabels[indexPath.section];
    ModelData* rowData = sectionLabel.labelModelData[indexPath.row];
    [cell.userDataImageView setImage:rowData.image];
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    ModelLabel* label = self.modelLabels[section];
    return label.numPerLabel;
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
        NSString* dataType = [dataTypeEnumToString(label.testTrainType) stringByAppendingString:@": "];
        sectionHeader.userDataLabel.text = [dataType stringByAppendingString: label.label];
        return sectionHeader;
    }
    else {
        [self presentError:@"Cannot load collection" message:@"Header object type incorrect" error:nil];
        return nil;
    }
}


@end
