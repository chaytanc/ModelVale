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

@interface AddDataViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, QBImagePickerControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) QBImagePickerController* imagePickerVC;
@property (nonatomic, strong) UIImagePickerController* cameraPickerVC;
@property (nonatomic, strong) NSMutableArray* data;
@property (weak, nonatomic) IBOutlet UIPickerView *testTrainPickerView;
@property (strong, nonatomic) NSArray* testTrainOptions;
@property (weak, nonatomic) IBOutlet UICollectionView *addDataCollView;
@property (strong, nonatomic) PHImageManager* phManager;

@end

//XXX TODO crashes from unrecognized selector, plus button on manageData; I redid the segue from the plus button but didn't fix it
@implementation AddDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
    self.testTrainOptions = (NSArray*) testTrainTypeArray;
    
    self.data = [NSMutableArray new];
    self.phManager = [PHImageManager new];
    
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
            [self.data addObject:image];
            [self.addDataCollView reloadData];
        }];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

// MARK: Camera Picker
// What to do with selection from camera roll or photo from camera
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    // Get the image captured by the UIImagePickerController
    UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
    UIImage *editedImage = info[UIImagePickerControllerEditedImage];

    [self.data addObject:editedImage];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.addDataCollView reloadData];
}

//XXX todo add data added to users' data in Parse, as well as test / train setting, the label they provided for the data

//XXX todo stretch add Google Drive integration
- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    AddDataCell* cell = [self.addDataCollView dequeueReusableCellWithReuseIdentifier:@"addDataCell" forIndexPath:indexPath];
    [cell.addDataImageView setImage:self.data[indexPath.row]];
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
