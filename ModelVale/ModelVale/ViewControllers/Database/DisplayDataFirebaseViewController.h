//
//  DisplayDataFirebaseViewController.h
//  ModelVale
//
//  Created by Chaytan Inman on 8/3/22.
//

#import "FirebaseViewController.h"
@class AvatarMLModel;

NS_ASSUME_NONNULL_BEGIN

@interface DisplayDataFirebaseViewController : FirebaseViewController
@property (strong, nonatomic) AvatarMLModel* model;
@property (strong, nonatomic) NSMutableArray<ModelLabel*>* modelLabels;
@property (nonatomic, assign) int labelFetchStart;

- (void) fetchLocalData: (void(^_Nullable)(void))completion;
@end

NS_ASSUME_NONNULL_END
