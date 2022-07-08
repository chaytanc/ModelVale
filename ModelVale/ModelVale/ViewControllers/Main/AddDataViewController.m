//
//  AddDataViewController.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/7/22.
//

#import "AddDataViewController.h"
#import "UIViewController+PresentError.h"
#import "AddDataCell.h"

@interface AddDataViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UIImagePickerController* imagePickerVC;
@property (nonatomic, strong) NSMutableArray* data;
@property (weak, nonatomic) IBOutlet UICollectionView *addDataCollView;

@end

@implementation AddDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imagePickerVC = [UIImagePickerController new];
    self.imagePickerVC.delegate = self;
    self.imagePickerVC.allowsEditing = YES;
    
    self.addDataCollView.delegate = self;
    self.addDataCollView.dataSource = self;
    self.data = [NSMutableArray new];
}
- (IBAction)didTapSelectData:(id)sender {
    NSLog(@"Select Data Tapped");
    self.imagePickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:self.imagePickerVC animated:YES completion:nil];
}
- (IBAction)didTapCreateData:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    else {
        [self presentError:@"Cannot access Camera" message:@"Please check that a camera is available and access is enabled." error:nil];
    }
    [self presentViewController:self.imagePickerVC animated:YES completion:nil];
}

// What to do with selection from camera roll
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    // Get the image captured by the UIImagePickerController
    UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
    UIImage *editedImage = info[UIImagePickerControllerEditedImage];

    [self.data addObject:editedImage];
//    [self.data insertObject:editedImage atIndex:0];
//    [self.picImageView setImage: editedImage];
    
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


@end
