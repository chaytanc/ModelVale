//
//  ModelLabel.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/11/22.
//

#import <Foundation/Foundation.h>
#import "TestTrainEnum.h"
#import <UIKit/UIKit.h>
@import FirebaseFirestore;
@class ModelData;

NS_ASSUME_NONNULL_BEGIN

@interface ModelLabel : NSObject
@property (nonatomic, strong) NSString* label;
@property (nonatomic, assign) NSString* testTrainType;
@property (nonatomic, strong) NSMutableArray<ModelData*>* labelModelData; // Reference to all ModelData that has this label

- (ModelLabel*) initEmptyLabel: (NSString*)label testTrainType: (NSString*) testTrainType;
- (ModelLabel*) initWithData: (NSString*)label testTrainType: (NSString*)testTrainType data: (NSMutableArray*) data objectId: (NSString*)objectId;
- (instancetype)initWithDictionaryAndExistingData:(NSDictionary *)dict data: (NSMutableArray*)data;
//- (instancetype)initWithDictionary:(NSDictionary *)dict;

- (void) addLabelModelData:(NSArray *)objects;
- (void) updateModelLabelWithDatabase: (FIRFirestore*)db vc: (UIViewController*)vc;
- (void) saveNewModelLabelWithDatabase: (FIRFirestore*)db vc: (UIViewController*)vc;
@end

NS_ASSUME_NONNULL_END
