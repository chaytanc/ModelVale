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

@interface RetrainViewController () <UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, strong) TrainBatchData* trainBatch;
@property (weak, nonatomic) IBOutlet UICollectionView *retrainCollView;
@property (weak, nonatomic) IBOutlet UILabel *retrainLabel;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UILabel *statsLabel;
@property (strong, nonatomic) MLModel* mlmodel;
@property (weak, nonatomic) IBOutlet UIButton *retrainButton;
@property (strong, nonatomic) NSURL* modelURL;
@property (nonatomic, assign) int totalData;
@end

@implementation RetrainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self roundCorners];
    self.retrainCollView.delegate = self;
    self.retrainCollView.dataSource = self;
    self.mlmodel = [self.model getMLModelFromModelName];
    self.modelURL = [self.model loadModelURL:self.model.modelName extension:@"mlmodelc"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initProgressBar];
    [self.loadingBar setHidden:NO];
    [self fetchAllDataOfModelWithType:Test dataPerLabel:10000 progressCompletion:^(float progress) {
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
    
    NSLog(@"Retrain Tapped");
    
    MLImageConstraint* constraint = self.mlmodel.modelDescription.inputDescriptionsByName[@"image"].imageConstraint;
    TrainBatchData* trainBatchData = [[TrainBatchData new] initTrainBatch:constraint trainBatchLabels:self.modelLabels];
    
    void(^progHandler)(MLUpdateContext* _Nonnull context) = [self getRetrainingProgressHandler];
    void(^retrainFinishCompletion)(MLUpdateContext* _Nonnull context) = [self getFinishRetrainCompletion];
    
    MLArrayBatchProvider* batchProvider = trainBatchData.trainBatch;
    MLUpdateProgressHandlers* handlers = [[MLUpdateProgressHandlers alloc] initForEvents:MLUpdateProgressEventTrainingBegin | MLUpdateProgressEventMiniBatchEnd | MLUpdateProgressEventEpochEnd progressHandler:progHandler completionHandler:retrainFinishCompletion];
    
    MLUpdateTask* task = [MLUpdateTask updateTaskForModelAtURL:self.modelURL trainingData:batchProvider progressHandlers:handlers error:nil];
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
        // Write the retrained model to disk
        [context.model writeToURL:self.modelURL error:nil];
        self.mlmodel = [self.model loadModel:self.modelURL].model;
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
                weakSelf.statsLabel.text = [NSString stringWithFormat:@"Loss: %@", context.metrics[MLMetricKey.lossValue]];
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

@end
