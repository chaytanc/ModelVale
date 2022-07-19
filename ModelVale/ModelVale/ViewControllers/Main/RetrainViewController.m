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

@interface RetrainViewController ()
@property (nonatomic, strong) TrainBatchData* trainBatch;
@property (nonatomic, strong) UpdatableSqueezeNet* model;
@property (weak, nonatomic) IBOutlet UILabel *retrainLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *testCollView;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UILabel *statsLabel;

@end

@implementation RetrainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL* modelURL = [[NSBundle mainBundle] URLForResource:@"UpdatableSqueezeNet" withExtension:@"mlmodelc"];
    self.model = [[UpdatableSqueezeNet alloc] initWithContentsOfURL:modelURL error:nil];
}

// XXX todo move these two funcs to model class
-(NSURL*) loadModelURL: (NSString*) resource extension: (NSString*)extension {
    NSURL* modelURL = [[NSBundle mainBundle] URLForResource:resource withExtension:extension];


    //XXX Todo check that the updated model gets saved correctly without using FileManager
//    NSFileManager* fm = [NSFileManager defaultManager];
//    NSURL* dirURL = [fm URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
//    NSString* extended = [resource stringByAppendingFormat:@".%@", extension];
//    modelURL = [dirURL URLByAppendingPathComponent:extended];
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

//XXX todo use retrain data passed to this controller or found with query to retrain
// https://betterprogramming.pub/how-to-train-a-core-ml-model-on-your-device-cccd0bee19d
- (IBAction)didTapRetrain:(id)sender {
    
    NSLog(@"Retrain Tapped");
    
    MLImageConstraint* constraint = self.model.model.modelDescription.inputDescriptionsByName[@"image"].imageConstraint;
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
            // todo handle events
            NSLog(@"batch end");
        }
        NSLog(@"train end");
        NSLog(@"metrics: %@", context.metrics);
        if(context.task.state == MLTaskStateFailed) {
            [NSException raise:@"Model retrain failed" format:@"Error: %@", context.task.error];
        }
        // Write the retrained model to disk
        NSURL* modelURL = [self loadModelURL:@"UpdatableSqueezeNet" extension:@"mlmodelc"];
        [context.model writeToURL:modelURL error:nil];
        self.model = [self loadModel:modelURL];
    };
    
    MLArrayBatchProvider* batchProvider = trainBatchData.trainBatch;
    MLUpdateProgressHandlers* handlers = [[MLUpdateProgressHandlers alloc] initForEvents:MLUpdateProgressEventTrainingBegin | MLUpdateProgressEventMiniBatchEnd | MLUpdateProgressEventEpochEnd progressHandler:progHandler completionHandler:finalProgressCompletion];
    
    NSURL* modelURL = [self loadModelURL:@"UpdatableSqueezeNet" extension:@"mlmodelc"];
    MLUpdateTask* task = [MLUpdateTask updateTaskForModelAtURL:modelURL trainingData:batchProvider progressHandlers:handlers error:nil];
    // Todo Can define other model parameters with MLParameterKey here if wanted
    [task resume];
    NSLog(@"Async Training");
}

@end
