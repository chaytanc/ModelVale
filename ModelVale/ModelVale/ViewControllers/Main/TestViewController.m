//
//  TestViewController.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/7/22.
//

#import "TestViewController.h"
#import "SqueezeNetInt8LUT.h"
#import "CoreML/CoreML.h"

@interface TestViewController ()
@property (weak, nonatomic) IBOutlet UILabel *testLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *testCollView;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (weak, nonatomic) IBOutlet UILabel *statsLabel;

//@property (strong, nonatomic) MLModel* model;
@property (strong, nonatomic) SqueezeNetInt8LUT* model;


@end

@implementation TestViewController

// TODO send testVC which model to test with from modelVC
- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL* modelURL = [[NSBundle mainBundle] URLForResource:@"SqueezeNetInt8LUT" withExtension:@"mlmodelc"];
    MLModelConfiguration* config = [MLModelConfiguration new];
//    NSError* error;
    self.model = [[SqueezeNetInt8LUT alloc] initWithContentsOfURL:modelURL error:nil];

//    SqueezeNetInt8LUT* imageClassif = [[SqueezeNetInt8LUT init] initWithConfiguration:config];
    
    //    let imageClassifierWrapper = try? AnimalClassifier(configuration: defaultConfig)

}
- (IBAction)didTapTest:(id)sender {
//    NSURL* imageURL = [[NSBundle mainBundle] URLForResource:@"mountain" withExtension:@"jpg"];

    UIImage* testImage = [UIImage imageNamed:@"mountain"];
    struct CGImage* cgtest = testImage.CGImage;
//    CIImage* testCIImage = [CIImage image:testImage];
//    CGImage* ref = [testImage initWithCGImage:testImage];
//    CGPixelBufferRef ref = testImage;
//    struct CGImage* testCIImage = [[CGImage new] initWithImage:testImage];
    NSLog(@"%@", self.model.model.modelDescription);
    MLImageConstraint* constraint = self.model.model.modelDescription.inputDescriptionsByName[@"image"].imageConstraint;

    MLFeatureValue* imageFeature = [MLFeatureValue featureValueWithCGImage:cgtest constraint:constraint options:nil error:nil];
    NSMutableDictionary* featureDict = [[NSMutableDictionary alloc] init];
    featureDict[@"mountain"] = imageFeature;
    id<MLFeatureProvider> featureProv = [[MLDictionaryFeatureProvider new] initWithDictionary:featureDict error:nil];
//    id<MLFeatureProvider> featureProv = [[MLFea]]
//    MLDictionaryFeatureProvider* pred = [self.model predictionFromFeatures:featureProv error:nil];
    id<MLFeatureProvider> pred = [self.model.model predictionFromFeatures:featureProv error:nil];

    
    
}

@end
