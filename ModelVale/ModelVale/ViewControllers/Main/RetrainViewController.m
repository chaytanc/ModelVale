//
//  RetrainViewController.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/7/22.
//

#import "RetrainViewController.h"
#import "CoreML/CoreML.h"
#import "ModelLabel.h"
#import "ModelData.h"
#import "UpdatableSqueezeNet.h"
#import "TrainBatchData.h"
#import "AvatarMLModel.h"
#import "AddDataViewController.h"
#import "RetrainDataCell.h"
#import "RetrainDataSectionHeader.h"
#import "RetrainResultsCell.h"

@interface RetrainViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) TrainBatchData* trainBatch;
@property (weak, nonatomic) IBOutlet UICollectionView *retrainCollView;
@property (weak, nonatomic) IBOutlet UILabel *retrainLabel;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UIButton *retrainButton;
@property (weak, nonatomic) IBOutlet UITableView *resultsTableView;
@property (strong, nonatomic) MLModel* mlmodel;
@property (nonatomic, assign) int totalData;
@property (nonatomic, strong) NSMutableArray<NSString*>* resultsArray;
@end

@implementation RetrainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self roundCorners];
    [self.resultsTableView setHidden:YES];
    self.resultsArray = [NSMutableArray new];
    self.resultsTableView.delegate = self;
    self.resultsTableView.dataSource = self;
    self.retrainCollView.delegate = self;
    self.retrainCollView.dataSource = self;
    self.mlmodel = [self.model getMLModelFromModelName];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initProgressBar];
    [self.loadingBar setHidden:NO];
    [self fetchAllDataOfModelWithType:Train dataPerLabel:10000 progressCompletion:^(float progress) {
        self.loadingBar.progress = progress;
    } completion:^{
        self.totalData = 0;
        [self.retrainCollView reloadData];
        [self.loadingBar setHidden:YES];
    }];
}

- (void) fetchUnusedTrainingData {
    //XXX todo, parameter for only retraining on new data using field in
}

- (void) roundCorners {
    self.retrainCollView.layer.cornerRadius = 10;
    self.retrainCollView.layer.masksToBounds = YES;
    self.retrainLabel.layer.cornerRadius = 10;
    self.retrainLabel.layer.masksToBounds = YES;
    self.contentView.layer.cornerRadius = 10;
    self.contentView.layer.masksToBounds = YES;
    self.retrainButton.layer.cornerRadius = 10;
    self.retrainButton.layer.masksToBounds = YES;
}

- (IBAction)didTapData:(id)sender {
    [self performSegueWithIdentifier:@"retrainToData" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier] isEqualToString:@"retrainToData"]) {
        AddDataViewController* targetController = (AddDataViewController*) [segue destinationViewController];
        targetController.model = self.model;
    }
}

//MARK: CoreML
- (IBAction)didTapRetrain:(id)sender {
    [self.resultsTableView setHidden:NO];
    NSString* inputKey = self.mlmodel.modelDescription.inputDescriptionsByName.allKeys[0];
    
    MLImageConstraint* constraint = self.mlmodel.modelDescription.inputDescriptionsByName[inputKey].imageConstraint;
    TrainBatchData* trainBatchData = [[TrainBatchData new] initTrainBatch:constraint trainBatchLabels:self.modelLabels];
    
    void(^progHandler)(MLUpdateContext* _Nonnull context) = [self getRetrainingProgressHandler];
    void(^retrainFinishCompletion)(MLUpdateContext* _Nonnull context) = [self getFinishRetrainCompletion];
    
    MLArrayBatchProvider* batchProvider = trainBatchData.trainBatch;
    MLUpdateProgressHandlers* handlers = [[MLUpdateProgressHandlers alloc] initForEvents:MLUpdateProgressEventTrainingBegin | MLUpdateProgressEventMiniBatchEnd | MLUpdateProgressEventEpochEnd progressHandler:progHandler completionHandler:retrainFinishCompletion];
    
    MLUpdateTask* task = [MLUpdateTask updateTaskForModelAtURL:self.model.modelURL trainingData:batchProvider progressHandlers:handlers error:nil];
    if(task == nil) {
        [self presentError:@"Cannot retrain model" message:@"There is an error with the updatability of the model." error:nil];
    }
    [task resume];
}

- (void(^)(MLUpdateContext* _Nonnull context)) getFinishRetrainCompletion {
    void(^finalCompletion)(MLUpdateContext* _Nonnull context) = ^(MLUpdateContext* _Nonnull context) {
        if(context.event == MLUpdateProgressEventMiniBatchEnd) {
            NSLog(@"batch end");
        }
        NSLog(@"train end");
        NSLog(@"metrics: %@", context.metrics);
        if(context.task.state == MLTaskStateFailed) {
            [NSException raise:@"Model retrain failed" format:@"Error: %@", context.task.error];
        }
        // Write the retrained model to disk and set the copy in memory to have that data
        [context.model writeToURL:self.model.modelURL error:nil];
        self.mlmodel = [self.model loadModel].model;
    };
    return finalCompletion;
}

- (void(^)(MLUpdateContext* _Nonnull context)) getRetrainingProgressHandler {
    void(^progHandler)(MLUpdateContext* _Nonnull context) = ^void(MLUpdateContext * _Nonnull context) {
        if(context.event == MLUpdateProgressEventTrainingBegin) {
            NSLog(@"train start");
        }
        else if(context.event == MLUpdateProgressEventEpochEnd) {
            NSLog(@"epoch end");
            NSLog(@"metrics: %@", context.metrics);
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString* latestPred = [NSString stringWithFormat:@"Epoch %@\n\t%@", context.metrics[MLMetricKey.epochIndex], context.metrics[MLMetricKey.lossValue]];
                [weakSelf.resultsArray addObject:latestPred];
                [weakSelf.resultsTableView reloadData];
            });
        }
    };
    return progHandler;
}

// MARK: Collection view
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RetrainDataCell* cell = [self.retrainCollView dequeueReusableCellWithReuseIdentifier:@"retrainDataCell" forIndexPath:indexPath];
    ModelLabel* sectionLabel = self.modelLabels[indexPath.section];
    ModelData* rowData = sectionLabel.localData[indexPath.row];
    [cell.retrainDataCellImageView setImage:rowData.image];
    self.totalData += 1;
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
        RetrainDataSectionHeader* sectionHeader = [self.retrainCollView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"retrainDataSectionHeader" forIndexPath:indexPath];
        ModelLabel* label = self.modelLabels[indexPath.section];
        NSString* dataType = [label.testTrainType stringByAppendingString:@": "];
        sectionHeader.retrainDataLabel.text = [dataType stringByAppendingString: label.label];
        return sectionHeader;
    }
    else {
        [self presentError:@"Cannot load collection" message:@"Header object type incorrect" error:nil];
        return nil;
    }
}

// MARK: Tableview

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RetrainResultsCell* cell = [self.resultsTableView dequeueReusableCellWithIdentifier:@"retrainResultsCell"];
    cell.lossLabel.text = self.resultsArray[indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.resultsArray.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return @"Loss";
    }
    return @"";
}

@end
