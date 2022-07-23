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

@interface TestViewController ()
@property (weak, nonatomic) IBOutlet UILabel *testLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *testCollView;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (weak, nonatomic) IBOutlet UILabel *statsLabel;

@property (strong, nonatomic) UpdatableSqueezeNet* model;

@end

@implementation TestViewController

//XXX TODO send testVC which model to test with from modelVC
- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL* modelURL = [[NSBundle mainBundle] URLForResource:@"SqueezeNetInt8LUT" withExtension:@"mlmodelc"];
    self.model = [[UpdatableSqueezeNet alloc] initWithContentsOfURL:modelURL error:nil];
}
- (IBAction)didTapTest:(id)sender {
    UIImage* testImage = [UIImage imageNamed:@"mountain"];
    struct CGImage* cgtest = testImage.CGImage;

//    NSLog(@"%@", self.model.model.modelDescription);
//    NSLog(@"%@", self.model.modelDescription);

    MLImageConstraint* constraint = self.model.model.modelDescription.inputDescriptionsByName[@"image"].imageConstraint;

    // Create fake data to predict on using CoreML classes like MLFeatureProvider
    MLFeatureValue* imageFeature = [MLFeatureValue featureValueWithCGImage:cgtest constraint:constraint options:nil error:nil];
    NSMutableDictionary* featureDict = [[NSMutableDictionary alloc] init];
    featureDict[@"image"] = imageFeature;
    MLDictionaryFeatureProvider* featureProv = (MLDictionaryFeatureProvider*)[[MLDictionaryFeatureProvider new] initWithDictionary:featureDict error:nil];

    id<MLFeatureProvider> pred = [self.model.model predictionFromFeatures:featureProv error:nil];
    MLFeatureValue* output = [pred featureValueForName:@"classLabel"];
    self.statsLabel.text = output.stringValue;

}

@end
