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
    self.modelURL = [self loadModelURL:self.model.modelName extension:@"mlmodelc"];
    self.retrainLabel.text = @"Unused Retraining Data";
    [self fetchAllDataOfModelWithType:Train dataPerLabel:10000 completion:^{
        [self.retrainCollView reloadData];
        self.totalData = 0;
    }];
}

- (void) fetchUnusedTrainingData {
    //XXX todo, parameter for only retraining on new data
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

// XXX todo move these two funcs to model class
-(NSURL*) loadModelURL: (NSString*) resource extension: (NSString*)extension {
    NSURL* modelURL = [[NSBundle mainBundle] URLForResource:resource withExtension:extension];
    return modelURL;
}

- (UpdatableSqueezeNet*) loadModel: (NSString*) resource extension: (NSString*)extension {
    NSURL* modelURL = [self loadModelURL:resource extension:extension];
    UpdatableSqueezeNet* model = [[UpdatableSqueezeNet alloc] initWithContentsOfURL:modelURL error:nil];
    return model;
}

- (UpdatableSqueezeNet*) loadModel: (NSURL*)url {
    UpdatableSqueezeNet* model = [[UpdatableSqueezeNet alloc] initWithContentsOfURL:url error:nil];
    return model;
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
//XXX todo use retrain data passed to this controller or found with query to retrain
// https://betterprogramming.pub/how-to-train-a-core-ml-model-on-your-device-cccd0bee19d
- (IBAction)didTapRetrain:(id)sender {
    
    NSLog(@"Retrain Tapped");
    
    MLImageConstraint* constraint = self.mlmodel.modelDescription.inputDescriptionsByName[@"image"].imageConstraint;
    TrainBatchData* trainBatchData = [[TrainBatchData new] initTrainBatch:constraint trainBatchLabels:self.modelLabels];
    
    void(^progHandler)(MLUpdateContext* _Nonnull context) = [self getRetrainingProgressHandler];
    void(^retrainFinishCompletion)(MLUpdateContext* _Nonnull context) = [self getFinishRetrainCompletion];
    
    MLArrayBatchProvider* batchProvider = trainBatchData.trainBatch;
    MLUpdateProgressHandlers* handlers = [[MLUpdateProgressHandlers alloc] initForEvents:MLUpdateProgressEventTrainingBegin | MLUpdateProgressEventMiniBatchEnd | MLUpdateProgressEventEpochEnd progressHandler:progHandler completionHandler:retrainFinishCompletion];
    
    //XXX todo can use dispatch main to update stuff after this async call finishes
    MLUpdateTask* task = [MLUpdateTask updateTaskForModelAtURL:self.modelURL trainingData:batchProvider progressHandlers:handlers error:nil];
    //XXX Todo Can define other model parameters with MLParameterKey here
    [task resume];
}

- (void(^)(MLUpdateContext* _Nonnull context)) getFinishRetrainCompletion {
    void(^finalCompletion)(MLUpdateContext* _Nonnull context) = ^(MLUpdateContext* _Nonnull context) {
        if(context.event == MLUpdateProgressEventMiniBatchEnd) {
            //XXX todo handle events
            NSLog(@"batch end");
        }
        NSLog(@"train end");
        NSLog(@"metrics: %@", context.metrics);
        if(context.task.state == MLTaskStateFailed) {
            [NSException raise:@"Model retrain failed" format:@"Error: %@", context.task.error];
        }
        // Write the retrained model to disk
        [context.model writeToURL:self.modelURL error:nil];
        self.mlmodel = [self loadModel:self.modelURL].model;
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
