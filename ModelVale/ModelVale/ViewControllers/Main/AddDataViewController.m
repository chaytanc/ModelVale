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
#import "SceneDelegate.h"
#import "FirebaseViewController.h"

@interface AddDataViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, QBImagePickerControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) QBImagePickerController* imagePickerVC;
@property (nonatomic, strong) UIImagePickerController* cameraPickerVC;
@property (nonatomic, strong) NSMutableArray<ModelData*>* data;
@property (weak, nonatomic) IBOutlet UIPickerView *testTrainPickerView;
@property (strong, nonatomic) NSArray* testTrainOptions;
@property (weak, nonatomic) IBOutlet UICollectionView *addDataCollView;
@property (strong, nonatomic) PHImageManager* phManager;
@property (weak, nonatomic) IBOutlet DropDownTextField *labelField;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIButton *selectDataButton;
@property (weak, nonatomic) IBOutlet UIButton *createDataButton;
@property (weak, nonatomic) IBOutlet UIView *addDataView;
@property (strong, nonatomic) ModelLabel* modelLabel;
@end

@implementation AddDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self roundCorners];
    self.testTrainOptions = (NSArray*) testTrainTypeArray;
    self.data = [NSMutableArray new];
    self.phManager = [PHImageManager new];
    self.testTrainPickerView.tag = 0;
    self.modelLabel = [[ModelLabel new] initEmptyLabel:self.labelField.text testTrainType:dataTypeEnumToString(Train)];

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

    self.modelLabel.testTrainType = self.testTrainOptions[0];
    MLModel* model = [self.model getMLModelFromModelName];
    [self.labelField initPropertiesWithOptions: model.modelDescription.classLabels];
    [self.labelField addTarget:self action:@selector(didTapDropDown:) forControlEvents:UIControlEventTouchUpInside];
    [self.labelField addTarget:self action:@selector(didChangeLabel:) forControlEvents:UIControlEventEditingDidEnd];
    [self.labelField addTarget:self action:@selector(didChangeLabel:) forControlEvents:UIControlEventEditingDidEndOnExit];
}

- (void) roundCorners {
    self.addDataCollView.layer.cornerRadius = 10;
    self.addDataCollView.layer.masksToBounds = YES;
    self.contentView.layer.cornerRadius = 10;
    self.contentView.layer.masksToBounds = YES;
    self.selectDataButton.layer.cornerRadius = 10;
    self.selectDataButton.layer.masksToBounds = YES; self.createDataButton.layer.cornerRadius = 10;
    self.createDataButton.layer.masksToBounds = YES;    self.addDataView.layer.cornerRadius = 10;
    self.addDataView.layer.masksToBounds = YES;
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

//MARK: Firebase

- (void) uploadModelDataSubColl: (FIRDocumentReference*) labelRef completion:(void(^)(void))completion {
    dispatch_group_t prepareWaitingGroup = dispatch_group_create();
    for(ModelData* data in self.data) {
        dispatch_group_enter(prepareWaitingGroup);
        [data saveModelDataInSubColl:labelRef db:self.db storage:self.storage vc:self completion:^{
            NSLog(@"Uploaded data");
            dispatch_group_leave(prepareWaitingGroup);
        }];
    }
    dispatch_group_notify(prepareWaitingGroup, dispatch_get_main_queue(), ^{
        completion();
    });
}

- (IBAction)didTapDone:(id)sender {
    self.modelLabel.label = self.labelField.text;
    [self.modelLabel updateModelLabelWithDatabase:self.db vc:self model:self.model completion:^(FIRDocumentReference * _Nonnull labelRef, NSError * _Nonnull error) {
        [self uploadModelDataSubColl:labelRef completion:^{
            if(error != nil) {
                [self presentError:@"Failed to update data" message:error.localizedDescription error:error];
            }
            else {
                [self transitionToModelVC: nil];
            }
        }];
    }];
}

// MARK: Multiple Select QBImagePicker
- (void) getImageFromPH: (PHAsset*)asset imageCompletion: (void (^) (UIImage* image))completion {
    PHImageRequestOptions* opts = [PHImageRequestOptions new];
    opts.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    [self.phManager requestImageForAsset:asset
                    targetSize: CGSizeMake(asset.pixelWidth, asset.pixelHeight)
                    contentMode: PHImageContentModeAspectFill
                    options:opts
                    resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
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
            NSString* path = [self getImageStoragePath: self.modelLabel];
            ModelData* data = [ModelData initWithImage:image label:self.labelField.text imagePath:path];
            [self.data addObject:data];
            [self.addDataCollView reloadData];
        }];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

// MARK: Camera Picker
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    // Get the image captured by the UIImagePickerController
    UIImage *editedImage = info[UIImagePickerControllerEditedImage];
    NSString* path = [self getImageStoragePath: self.modelLabel];
    ModelData* data = [ModelData initWithImage:editedImage label:self.modelLabel.label imagePath:path];
    [self.data addObject:data];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.addDataCollView reloadData];
}

//MARK: Collection View
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
        self.modelLabel.testTrainType = self.testTrainOptions[row];
    }
}

@end
