//
//  DisplayDataFirebaseViewController.h
//  ModelVale
//
//  Created by Chaytan Inman on 8/3/22.
//

#import "FirebaseViewController.h"
#import "TestTrainEnum.h"
@class AvatarMLModel;


extern NSInteger const kLabelQueryLimit;
extern NSInteger const kDataQueryLimit;

NS_ASSUME_NONNULL_BEGIN

@interface DisplayDataFirebaseViewController : FirebaseViewController
@property (strong, nonatomic) AvatarMLModel* model;
@property (strong, nonatomic) NSMutableArray<ModelLabel*>* modelLabels;
@property (nonatomic, assign) int labelFetchStart;
// All VCs that display data have potentially loadingBar-needed long wait times
@property (strong, nonatomic) UIProgressView* loadingBar;

- (void) initProgressBar;
- (void) fetchSomeDataOfModel: (void(^_Nullable)(float progress))progressCompletion allDataFetchedCompletion:(void(^_Nullable)(void))completion;
- (void) fetchAndCreateData: (ModelLabel*)label queryLimit: (NSInteger)queryLimit completion:(void(^_Nullable)(void))completion;
- (void) fetchAllDataOfModelWithType: (testTrain)testTrainType dataPerLabel: (NSInteger)dataPerLabel progressCompletion: (void(^_Nullable)(float progress))progressCompletion completion: (void(^_Nullable)(void))completion;
-(void) createFakeData: (NSMutableArray<ModelLabel*>*)modelArray;
@end

NS_ASSUME_NONNULL_END
