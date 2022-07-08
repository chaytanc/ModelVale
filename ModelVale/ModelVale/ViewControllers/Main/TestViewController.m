//
//  TestViewController.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/7/22.
//

#import "TestViewController.h"
#import "SqueezeNetInt8LUT.h"
#import "CoreML/CoreML.h"
#import "Vision/Vision.h"

@interface TestViewController ()
@property (weak, nonatomic) IBOutlet UILabel *testLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *testCollView;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (weak, nonatomic) IBOutlet UILabel *statsLabel;

//@property (strong, nonatomic) MLModel* model;
@property (strong, nonatomic) SqueezeNetInt8LUT* model;
//@property (strong, nonatomic) VNCoreMLModel* model;


@end

@implementation TestViewController

// TODO send testVC which model to test with from modelVC
- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL* modelURL = [[NSBundle mainBundle] URLForResource:@"SqueezeNetInt8LUT" withExtension:@"mlmodelc"];
    MLModelConfiguration* config = [MLModelConfiguration new];
//    NSError* error;
    self.model = [[SqueezeNetInt8LUT alloc] initWithContentsOfURL:modelURL error:nil];
    
//    self.model = [TestViewController createImageClassifier];
}
- (IBAction)didTapTest:(id)sender {
//    NSURL* imageURL = [[NSBundle mainBundle] URLForResource:@"mountain" withExtension:@"jpg"];

    UIImage* testImage = [UIImage imageNamed:@"mountain"];
    struct CGImage* cgtest = testImage.CGImage;

//    NSLog(@"%@", self.model.model.modelDescription);
//    NSLog(@"%@", self.model.modelDescription);

    MLImageConstraint* constraint = self.model.model.modelDescription.inputDescriptionsByName[@"image"].imageConstraint;

    MLFeatureValue* imageFeature = [MLFeatureValue featureValueWithCGImage:cgtest constraint:constraint options:nil error:nil];
    NSMutableDictionary* featureDict = [[NSMutableDictionary alloc] init];
    featureDict[@"image"] = imageFeature;
    MLDictionaryFeatureProvider* featureProv = (MLDictionaryFeatureProvider*)[[MLDictionaryFeatureProvider new] initWithDictionary:featureDict error:nil];

    id<MLFeatureProvider> pred = [self.model.model predictionFromFeatures:featureProv error:nil];
    MLFeatureValue* output = [pred featureValueForName:@"classLabel"];
    self.statsLabel.text = output.stringValue;

}

//XXX Not sure what Vision lib is or if it is necessary for things later
//+ (VNCoreMLModel*) createImageClassifier {
//    // Use a default model configuration.
//    MLModelConfiguration* defaultConfig = [MLModelConfiguration new];
//    // Create an instance of the image classifier's wrapper class.
//    SqueezeNetInt8LUT* sqWrapper = [[SqueezeNetInt8LUT new] initWithConfiguration:defaultConfig error:nil];
//    // Get the underlying model instance.
//    MLModel* model = sqWrapper.model;
//    VNCoreMLModel* visionModel = [VNCoreMLModel modelForMLModel:model error:nil];
//    return visionModel;
//}



@end
