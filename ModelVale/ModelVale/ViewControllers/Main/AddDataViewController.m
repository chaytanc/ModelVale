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

    //XXX Todo set the model property based on which model we selected initally in ModelViewController
    MLModel* model = [self.model getMLModelFromModelName];
    [self.labelField initPropertiesWithOptions: model.modelDescription.classLabels];
    [self.labelField addTarget:self action:@selector(didTapDropDown:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {
    if (pickerView.tag == 0) {
        self.label.testTrainType = dataTypeEnumToString(self.testTrainOptions[row]);
    }
}

- (void) didTapDropDown:(id) obj {
    [self.labelField wasTapped];
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

- (void) uploadModelDataWithCompletion: (PFBooleanResultBlock  _Nullable)completion  {
    self.label.label = self.labelField.text;
    // Save batch of all ModelData created from images selected
    [PFObject saveAllInBackground:self.data block:completion];
    self.label.labelModelData = self.data;
    [self saveModelLabelWithCompletion:completion];
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
            [label updateModelLabelWithCompletion:completion withVC:self];
            self.label = label;
            assert([self.model.labeledData containsObject:self.label]);
        }
        else {
            NSLog(@"Uploading new label");
            [self.label updateModelLabelWithCompletion:completion withVC:self];
            [self.model.labeledData addObject:self.label];
        }
        [self.model updateModel:self];
    }];
}

//XXX todo add data added to users' data in Parse, as well as test / train setting, the label they provided for the data
- (IBAction)didTapDone:(id)sender {
    // Get model object based on model we selected at main from database
    //XXX todo in AppDelegate make a method to create starterModel objects and upload to user database if it is their first time ever logging in (is that possible?)
//     For each image added, make a ModelData obj??
    // Upload ModelData obj to Parse
    // Add to corresponding ModelLabel in Model obj in Parse
    // If ModelLabel does not already exist, create and add to object
    //
    
}

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

// MARK: Multiple Select QBImagePicker
- (void) qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets {
    for(id asset in assets) {
        [self getImageFromPH:asset imageCompletion:^(UIImage *image) {
            ModelData* data = [ModelData initWithImage:image label:self.label];
            [self.data addObject:data];
            [self.label addLabelModelData:@[data]];
            [self.addDataCollView reloadData];
        }];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

// MARK: Camera Picker
// What to do with selection from camera roll or photo from camera
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    // Get the image captured by the UIImagePickerController
    UIImage *editedImage = info[UIImagePickerControllerEditedImage];
    ModelData* data = [ModelData initWithImage:editedImage label:self.label];
    [self.data addObject:data];
    [self.label addLabelModelData:@[data]];

    [self dismissViewControllerAnimated:YES completion:nil];
    [self.addDataCollView reloadData];
}

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

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.testTrainOptions.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
    return self.testTrainOptions[row];
}

@end
