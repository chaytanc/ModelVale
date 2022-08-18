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
#import "ResultsCell.h"

NSInteger const kDataPerLabel = 20;

@interface TestViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UILabel *testLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *testCollView;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (strong, nonatomic) MLModel* mlmodel;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (nonatomic, assign) int totalCorrect;
@property (nonatomic, assign) int totalPreds;
@property (weak, nonatomic) IBOutlet UITableView *resultsTableView;
@property (strong, nonatomic) NSMutableArray<NSString*>* resultsArray;
@property (nonatomic, assign) int XPClustersEarned;
@property (nonatomic, assign) float XPEarned;

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self roundCorners];
    self.resultsArray = [NSMutableArray new];
    self.totalCorrect = 0;
    self.totalPreds = 0;
    self.XPClustersEarned = 0;
    self.XPEarned = 0;
    self.testCollView.delegate = self;
    self.testCollView.dataSource = self;
    self.resultsTableView.delegate = self;
    self.resultsTableView.dataSource = self;
    self.mlmodel = [self.model getMLModelFromModelName];
    self.testLabel.text = @"Testing Data"; // Is hidden
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(back:)];
    self.navigationItem.leftBarButtonItem = newBackButton;
    [self.resultsTableView setHidden:YES];

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
    [self.resultsTableView setHidden:NO];
    int numPredsSoFar = 0;
    self.totalCorrect = 0;
    
    //Note: not sure what kind of model would have multiple input descriptions, maybe multi-modal, but does not currently support that
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
            NSString* latestPred = [NSString stringWithFormat:@"Prediction: %@\nLabel: %@", output.stringValue, data.label];
            [self.resultsArray addObject:latestPred];
            [self.resultsTableView reloadData];

            if([data.label containsString:output.stringValue]) {
                self.totalCorrect += 1;
                self.totalLabel.text = [NSString stringWithFormat:@"Correct Predictions Out of Total: %i / %i ", self.totalCorrect, self.totalPreds];
            }
            numPredsSoFar += 1;
        }
    }
    [self updateXPClustersEarned];
    [self.delegate earnXP:self.XPClustersEarned];
}

// Updates self.XPEarned to reflect latest testing results
- (void) calcXPEarned {
    float currentXPEarned;
    int incorrect = self.totalPreds - self.totalCorrect;
    currentXPEarned = self.totalCorrect * 0.25 - incorrect;
    // Minimum XP earned is 0, or 1 if correct preds outnumber incorrect
    if(currentXPEarned < 1) {
        currentXPEarned = (self.totalCorrect > incorrect) ? 1 : 0;
    }
    self.XPEarned += currentXPEarned;
}

- (void) updateXPClustersEarned {
    [self calcXPEarned];
    self.XPClustersEarned = round(self.XPEarned);
}

//XXX todo Fix this to be regular back button?? Since we're using delegate protocol now?
- (void) back:(UIBarButtonItem *)sender {
    if ([self.navigationController.parentViewController isKindOfClass:[ModelViewController class]]) {
        ModelViewController* targetController = (ModelViewController*) self.navigationController.presentingViewController;
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

// MARK: Tableview

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ResultsCell* cell = [self.resultsTableView dequeueReusableCellWithIdentifier:@"resultsCell"];
    cell.statsLabel.text = self.resultsArray[indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.resultsArray.count;
}

@end
