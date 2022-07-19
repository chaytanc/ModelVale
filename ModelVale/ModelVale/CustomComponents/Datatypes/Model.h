//
//  Model.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/14/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Model : NSObject

@property (nonatomic, strong) NSString* name;
@property (nonatomic, assign) NSInteger health;

// TODO add properties for database
// owner, labeledData, weights, architecture
// TODO update these properties in retrain and test

@end

NS_ASSUME_NONNULL_END
