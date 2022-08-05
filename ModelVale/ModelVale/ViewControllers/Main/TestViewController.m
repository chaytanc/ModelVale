//
//  TestViewController.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/7/22.
//

#import "TestViewController.h"
#import "UpdatableSqueezeNet.h"
#import "CoreML/CoreML.h"
#import "Vision/Vision.h"
#import "DataViewController.h"
#import "AvatarMLModel.h"
#import "TestTrainEnum.h"
#import "ModelData.h"
#import "ModelLabel.h"
#import "TestDataSectionHeader.h"
#import "TestDataCell.h"

NSInteger const kDataPerLabel = 20;

@interface TestViewController () <UICollectionViewDelegate, UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UILabel *testLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *testCollView;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (weak, nonatomic) IBOutlet UILabel *statsLabel;
@property (strong, nonatomic) MLModel* mlmodel;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self roundCorners];
    self.testCollView.delegate = self;
    self.testCollView.dataSource = self;
    self.mlmodel = [self.model getMLModelFromModelName];
    self.testLabel.text = @"Testing Data";
    [self fetchAllDataOfModelWithType:Test dataPerLabel:kDataPerLabel completion:^{
        [self.testCollView reloadData];
    }];
}

- (void) roundCorners {
    self.testCollView.layer.cornerRadius = 10;
    self.testCollView.layer.masksToBounds = YES;
    self.testButton.layer.cornerRadius = 10;
    self.testButton.layer.masksToBounds = YES;
    self.contentView.layer.cornerRadius = 10;
    self.contentView.layer.masksToBounds = YES;
}


- (IBAction)didTapData:(id)sender {
    [self performSegueWithIdentifier:@"testToData" sender:nil];
}

- (IBAction)didTapTest:(id)sender {
    UIImage* testImage = [UIImage imageNamed:@"mountain"];
    struct CGImage* cgtest = testImage.CGImage;
    MLImageConstraint* constraint = self.mlmodel.modelDescription.inputDescriptionsByName[@"image"].imageConstraint;

    // Create fake data to predict on using CoreML classes like MLFeatureProvider
    MLFeatureValue* imageFeature = [MLFeatureValue featureValueWithCGImage:cgtest constraint:constraint options:nil error:nil];
    NSMutableDictionary* featureDict = [[NSMutableDictionary alloc] init];
    featureDict[@"image"] = imageFeature;
    MLDictionaryFeatureProvider* featureProv = (MLDictionaryFeatureProvider*)[[MLDictionaryFeatureProvider new] initWithDictionary:featureDict error:nil];
    
    id<MLFeatureProvider> pred = [self.mlmodel predictionFromFeatures:featureProv error:nil];
    MLFeatureValue* output = [pred featureValueForName:@"classLabel"];
    self.statsLabel.text = output.stringValue;

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier] isEqualToString:@"testToData"]) {
        DataViewController* targetController = (DataViewController*) [segue destinationViewController];
        targetController.model = self.model;
    }
}

// MARK: Collection view
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TestDataCell* cell = [self.testCollView dequeueReusableCellWithReuseIdentifier:@"testDataCell" forIndexPath:indexPath];
    ModelLabel* sectionLabel = self.modelLabels[indexPath.section];
    ModelData* rowData = sectionLabel.localData[indexPath.row];
    [cell.testDataCellImageView setImage:rowData.image];
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
        TestDataSectionHeader* sectionHeader = [self.testCollView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"testDataSectionHeader" forIndexPath:indexPath];
        ModelLabel* label = self.modelLabels[indexPath.section];
        NSString* dataType = [label.testTrainType stringByAppendingString:@": "];
        sectionHeader.testDataLabel.text = [dataType stringByAppendingString: label.label];
        return sectionHeader;
    }
    else {
        [self presentError:@"Cannot load collection" message:@"Header object type incorrect" error:nil];
        return nil;
    }
}

@end
