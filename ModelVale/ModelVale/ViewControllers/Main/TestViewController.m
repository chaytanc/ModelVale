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
#import "ModelViewController.h"

NSInteger const kDataPerLabel = 20;

@interface TestViewController () <UICollectionViewDelegate, UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UILabel *testLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *testCollView;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (weak, nonatomic) IBOutlet UILabel *statsLabel;
@property (strong, nonatomic) MLModel* mlmodel;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (nonatomic, assign) int totalCorrect;
@property (nonatomic, assign) int totalPreds;
@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self roundCorners];
    self.totalCorrect = 0;
    self.totalPreds = 0;
    self.testCollView.delegate = self;
    self.testCollView.dataSource = self;
    self.mlmodel = [self.model getMLModelFromModelName];
    self.testLabel.text = @"Testing Data";
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(back:)];
    self.navigationItem.leftBarButtonItem = newBackButton;

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initProgressBar];
    [self.loadingBar setHidden:NO];
    [self fetchAllDataOfModelWithType:Test dataPerLabel:kDataPerLabel progressCompletion:^(float progress) {
        self.loadingBar.progress = progress;
    } completion:^{
        [self.testCollView reloadData];
        [self.loadingBar setHidden:YES];
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

// Make a prediction for every data loaded in the collection view and add correct ones up as we go
- (IBAction)didTapTest:(id)sender {
    int numPredsSoFar = 0;
    self.totalCorrect = 0;
    
    //XXX todo not sure what kind of model would have multiple input descriptions, maybe multi-modal, but does not currently support that
    NSString* inputKey = self.mlmodel.modelDescription.inputDescriptionsByName.allKeys[0];
    NSString* outputKey = self.mlmodel.modelDescription.outputDescriptionsByName.allKeys[0]; // if array, could argmax the output
    MLImageConstraint* constraint = self.mlmodel.modelDescription.inputDescriptionsByName[inputKey].imageConstraint;
    for(ModelLabel* label in self.modelLabels) {
        for(ModelData* data in label.localData) {
            struct CGImage* cgImage = data.image.CGImage;
            MLFeatureValue* imFeature = [MLFeatureValue featureValueWithCGImage:cgImage constraint:constraint options:nil error:nil];
            NSMutableDictionary* featureDict = [[NSMutableDictionary alloc] init];
            featureDict[inputKey] = imFeature;
            MLDictionaryFeatureProvider* featureProv = (MLDictionaryFeatureProvider*)[[MLDictionaryFeatureProvider new] initWithDictionary:featureDict error:nil];
            // predict and set statslabel w prediction, update total correct label
            id<MLFeatureProvider> pred = [self.mlmodel predictionFromFeatures:featureProv error:nil];
            MLFeatureValue* output = [pred featureValueForName:outputKey];
            //XXX todo scrolling textView that adds prediction for each as we go
//            self.statsLabel.text = [NSString stringWithFormat:@"Prediction %i: %@", numPredsSoFar, output.stringValue];
            // add prediction to array of predictions for tableview datasource
            // reload tableview
            self.statsLabel.text = [NSString stringWithFormat:@"Latest Prediction: %@", output.stringValue];

            if([output.stringValue isEqualToString:data.label]) {
                self.totalCorrect += 1;
                self.totalLabel.text = [NSString stringWithFormat:@"Correct Predictions Out of Total: %i / %i ", self.totalCorrect, self.totalPreds];
            }
            numPredsSoFar += 1;
        }
    }

}

//XXX todo Make proper amount and XP of animations and send to mainvc
- (void) back:(UIBarButtonItem *)sender {
    if ([self.navigationController.parentViewController isKindOfClass:[ModelViewController class]]) {
        ModelViewController* targetController = (ModelViewController*) self.navigationController.presentingViewController;
        targetController.shouldAnimateXP = YES;
        targetController.earnedXP = self.totalCorrect;
    }
    [self.navigationController popViewControllerAnimated:YES];
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
    self.totalPreds += 1;
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
