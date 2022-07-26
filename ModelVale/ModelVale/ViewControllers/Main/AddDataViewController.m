//
//  AddDataViewController.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/7/22.
//

#import "AddDataViewController.h"
#import "UIViewController+PresentError.h"
#import "AddDataCell.h"
#import "QBImagePickerController/QBImagePickerController.h"
#import "TestTrainEnum.h"
#import "ModelVale-Swift.h"
#import "AvatarMLModel.h"
#import "ModelData.h"
#import "ModelLabel.h"

@interface AddDataViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, QBImagePickerControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) QBImagePickerController* imagePickerVC;
@property (nonatomic, strong) UIImagePickerController* cameraPickerVC;
@property (nonatomic, strong) NSMutableArray<ModelData*>* data;
@property (weak, nonatomic) IBOutlet UIPickerView *testTrainPickerView;
@property (strong, nonatomic) NSArray* testTrainOptions;
@property (weak, nonatomic) IBOutlet UICollectionView *addDataCollView;
@property (strong, nonatomic) PHImageManager* phManager;
@property (weak, nonatomic) IBOutlet DropDownTextField *labelField;
@property (strong, nonatomic) ModelLabel* label;

@end

@implementation AddDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.testTrainOptions = (NSArray*) testTrainTypeArray;
    self.data = [NSMutableArray new];
    self.phManager = [PHImageManager new];
    self.testTrainPickerView.tag = 0;
    self.label = [[ModelLabel new] initEmptyLabel:self.labelField.text testTrainType:dataTypeEnumToString(Train)];

    self.imagePickerVC = [QBImagePickerController new];
    self.imagePickerVC.delegate = self;
    self.imagePickerVC.showsNumberOfSelectedAssets = YES;
    self.imagePickerVC.allowsMultipleSelection = YES;
    self.imagePickerVC.maximumNumberOfSelection = 10000;
    
    self.cameraPickerVC = [UIImagePickerController new];
    self.cameraPickerVC.delegate = self;
    self.cameraPickerVC.allowsEditing = YES;
    
    self.addDataCollView.delegate = self;
    self.addDataCollView.dataSource = self;
    self.testTrainPickerView.dataSource = self;
    self.testTrainPickerView.delegate = self;

    self.label.testTrainType = self.testTrainOptions[0];
    //XXX Todo set the model property based on which model we selected initally in ModelViewController
    MLModel* model = [self.model getMLModelFromModelName];
    [self.labelField initPropertiesWithOptions: model.modelDescription.classLabels];
    [self.labelField addTarget:self action:@selector(didTapDropDown:) forControlEvents:UIControlEventTouchUpInside];
    [self.labelField addTarget:self action:@selector(didChangeLabel:) forControlEvents:UIControlEventEditingDidEnd];
    [self.labelField addTarget:self action:@selector(didChangeLabel:) forControlEvents:UIControlEventEditingDidEndOnExit];
}

- (void) didTapDropDown:(id) obj {
    [self.labelField wasTapped];
}

- (void) didChangeLabel:(id) obj {
    [self.labelField labelChangedWithAllData:self.data];
}

- (IBAction)didTapSelectData:(id)sender {
    [self presentViewController:self.imagePickerVC animated:YES completion:nil];
}

- (IBAction)didTapCreateData:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.cameraPickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    else {
        [self presentError:@"Cannot access Camera" message:@"Please check that a camera is available and access is enabled." error:nil];
    }
    [self presentViewController:self.cameraPickerVC animated:YES completion:nil];
}

//MARK: Parse
- (void) uploadModelDataWithCompletion: (PFBooleanResultBlock  _Nullable)completion  {
    self.label.label = self.labelField.text;
    self.label.labelModelData = self.data;
    for(ModelData* data in self.data) {
        [data uploadDataOnVC:self completion:nil];
    }
}

- (void) uploadModelDataBatchWithCompletion:(PFBooleanResultBlock  _Nullable)completion  {
    self.label.label = self.labelField.text;
    self.label.labelModelData = self.data;
    // Save batch of all ModelData created from images selected
    [PFObject saveAllInBackground:self.data block:^(BOOL succeeded, NSError * _Nullable error) {
        if(error != nil){
            [self presentError:@"Failed to save ModelData" message:error.localizedDescription error:error];
        }
        else {
            NSLog(@"Saved model data!");
        }
    }];
}

- (void) saveModelLabelWithCompletion: (PFBooleanResultBlock  _Nullable)completion {
    
    // Label is the same if the .label and .testTrainType match
    PFQuery* query = [PFQuery queryWithClassName:@"ModelLabel"];
    query = [query whereKey:@"label" matchesText:self.label.label];
    query = [query whereKey:@"testTrainType" matchesText:self.label.testTrainType];
    // Find duplicate label if it exists and update its data, otherwise create a new label
    [query findObjectsInBackgroundWithBlock:^(NSArray *labels, NSError *error) {
        if(error != nil){
            [self presentError:@"Failed to retrieve labels" message:error.localizedDescription error:error];
        }
        else if (labels.count != 0) {
            NSLog(@"Label already exists, updating properties");
            ModelLabel* label = labels[0];
            label.labelModelData = self.label.labelModelData;
            label.numPerLabel = self.label.numPerLabel;
            [label updateModelLabel:self completion:nil];
            self.label = label;
            assert([self.model.labeledData containsObject:self.label]);
        }
        else {
            NSLog(@"Uploading new label");
            [self.label updateModelLabel: self completion:^(BOOL succeeded, NSError * _Nullable error) {
                if(error != nil) {
                    [self presentError:@"Failed to upload new ModelLabel" message:error.localizedDescription error:error];
                }
                else {
//                    [self.model.labeledData addObject:self.label];
//                    [self.model updateModel:self];
                }
            }];
        }
    }];
}

- (IBAction)didTapDone:(id)sender {
    self.label.label = self.labelField.text;
    [self saveModelLabelWithCompletion:nil];
}

// MARK: Multiple Select QBImagePicker
- (void) getImageFromPH: (PHAsset*)asset imageCompletion: (void (^) (UIImage* image))completion {
    PHImageRequestOptions* opts = [PHImageRequestOptions new];
    opts.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    [self.phManager requestImageForAsset:asset targetSize: CGSizeMake(asset.pixelWidth, asset.pixelHeight)
                             contentMode: PHImageContentModeAspectFill
                                 options:opts resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if(result == nil) {
            NSLog(@"Nil image from asset");
        }
        else {
            completion(result);
        }
    }];
}

- (void) qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets {
    for(id asset in assets) {
        [self getImageFromPH:asset imageCompletion:^(UIImage *image) {
            ModelData* data = [ModelData initWithImage:image label:self.label.label];
            [self.data addObject:data];
            [self.label addLabelModelData:@[data]];
            [self.addDataCollView reloadData];
        }];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

// MARK: Camera Picker
// What to do with selection from camera roll or photo from camera
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    // Get the image captured by the UIImagePickerController
    UIImage *editedImage = info[UIImagePickerControllerEditedImage];
    ModelData* data = [ModelData initWithImage:editedImage label:self.label.label];
    [self.data addObject:data];
    [self.label addLabelModelData:@[data]];

    [self dismissViewControllerAnimated:YES completion:nil];
    [self.addDataCollView reloadData];
}

//MARK: Collection View
//XXX todo stretch add Google Drive integration
- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    AddDataCell* cell = [self.addDataCollView dequeueReusableCellWithReuseIdentifier:@"addDataCell" forIndexPath:indexPath];
    [cell.addDataImageView setImage:self.data[indexPath.row].image];
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.data.count;
}

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView {
    return 1;
}

//MARK: TestTrainPickerView
- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.testTrainOptions.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
    return self.testTrainOptions[row];
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {
    if (pickerView.tag == 0) {
        self.label.testTrainType = self.testTrainOptions[row];
    }
}

@end
