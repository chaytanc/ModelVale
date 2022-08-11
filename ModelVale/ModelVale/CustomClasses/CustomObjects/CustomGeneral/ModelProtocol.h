//
//  ModelProtocol.h
//  ModelVale
//
//  Created by Chaytan Inman on 8/8/22.
//

#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ModelProtocol <NSObject>

@property (nonatomic, strong) MLModel* model;
- (instancetype) initWithContentsOfURL: (nonnull NSURL *)url error:(NSError *__autoreleasing  _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
