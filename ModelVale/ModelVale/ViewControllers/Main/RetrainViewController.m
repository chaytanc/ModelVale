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

@interface RetrainViewController ()
@property (nonatomic, strong) TrainBatchData* trainBatch;
@property (weak, nonatomic) IBOutlet UILabel *retrainLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *testCollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UILabel *statsLabel;
@property (strong, nonatomic) MLModel* mlmodel;
@property (strong, nonatomic) NSURL* modelURL;
@end

@implementation RetrainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self roundCorners];
    self.mlmodel = [self.model getMLModelFromModelName];
    self.modelURL = [self loadModelURL:self.model.modelName extension:@"mlmodelc"];
    self.retrainLabel.text = @"Unused Retraining Data";
}

- (void) fetchUnusedTrainingData {
    //XXX todo
}

- (void) roundCorners {
    self.testCollView.layer.cornerRadius = 10;
    self.testCollView.layer.masksToBounds = YES;
    self.retrainLabel.layer.cornerRadius = 10;
    self.retrainLabel.layer.masksToBounds = YES;
    self.contentView.layer.cornerRadius = 10;
    self.contentView.layer.masksToBounds = YES;
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

//XXX todo use retrain data passed to this controller or found with query to retrain
// https://betterprogramming.pub/how-to-train-a-core-ml-model-on-your-device-cccd0bee19d
- (IBAction)didTapRetrain:(id)sender {
    
    NSLog(@"Retrain Tapped");
    
    MLImageConstraint* constraint = self.mlmodel.modelDescription.inputDescriptionsByName[@"image"].imageConstraint;
    TrainBatchData* trainBatchData = [[TrainBatchData new] initTrainBatch: constraint];
    
    //XXX todo move these to their own functions??
    void(^progHandler)(MLUpdateContext* _Nonnull context) = ^void(MLUpdateContext * _Nonnull context) {
        if(context.event == MLUpdateProgressEventTrainingBegin) {
            // todo handle events
            NSLog(@"train start");
        }
        else if(context.event == MLUpdateProgressEventEpochEnd) {
            NSLog(@"epoch end");
            NSLog(@"metrics: %@", context.metrics);
            
        }
        //XXX todo can't do this UI update on not the main thread
        // https://stackoverflow.com/questions/58639685/how-do-i-solve-this-uilabel-text-must-be-used-from-main-thread-only
//        self.statsLabel.text = context.metrics[MLMetricKey.lossValue];
    };
    
    void(^finalProgressCompletion)(MLUpdateContext* _Nonnull context) = ^(MLUpdateContext* _Nonnull context) {
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
    
    MLArrayBatchProvider* batchProvider = trainBatchData.trainBatch;
    MLUpdateProgressHandlers* handlers = [[MLUpdateProgressHandlers alloc] initForEvents:MLUpdateProgressEventTrainingBegin | MLUpdateProgressEventMiniBatchEnd | MLUpdateProgressEventEpochEnd progressHandler:progHandler completionHandler:finalProgressCompletion];
    
    MLUpdateTask* task = [MLUpdateTask updateTaskForModelAtURL:self.modelURL trainingData:batchProvider progressHandlers:handlers error:nil];
    //XXX Todo Can define other model parameters with MLParameterKey here
    [task resume];
    NSLog(@"Async Training");
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier] isEqualToString:@"retrainToData"]) {
        AddDataViewController* targetController = (AddDataViewController*) [segue destinationViewController];
        targetController.model = self.model;
    }
}

@end
