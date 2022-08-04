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

@interface TestViewController ()
@property (weak, nonatomic) IBOutlet UILabel *testLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *testCollView;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (weak, nonatomic) IBOutlet UILabel *statsLabel;

@property (strong, nonatomic) MLModel* mlmodel;

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mlmodel = [self.model getMLModelFromModelName];
}
- (IBAction)didTapData:(id)sender {
    [self performSegueWithIdentifier:@"testToData" sender:nil];
}

- (IBAction)didTapTest:(id)sender {
    UIImage* testImage = [UIImage imageNamed:@"mountain"];
    struct CGImage* cgtest = testImage.CGImage;

//    NSLog(@"%@", self.model.model.modelDescription);
//    NSLog(@"%@", self.model.modelDescription);
    MLImageConstraint* constraint = self.mlmodel.modelDescription.inputDescriptionsByName[@"image"].imageConstraint;

    // Create fake data to predict on using CoreML classes like MLFeatureProvider
    MLFeatureValue* imageFeature = [MLFeatureValue featureValueWithCGImage:cgtest constraint:constraint options:nil error:nil];
    NSMutableDictionary* featureDict = [[NSMutableDictionary alloc] init];
    featureDict[@"image"] = imageFeature;
    MLDictionaryFeatureProvider* featureProv = (MLDictionaryFeatureProvider*)[[MLDictionaryFeatureProvider new] initWithDictionary:featureDict error:nil];
    
    id<MLFeatureProvider> pred = [self.mlmodel predictionFromFeatures:featureProv error:nil];
    MLFeatureValue* output = [pred featureValueForName:@"classLabel"];
    self.statsLabel.text = output.stringValue;

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier] isEqualToString:@"testToData"]) {
        DataViewController* targetController = (DataViewController*) [segue destinationViewController];
        targetController.model = self.model;
    }
}


@end
