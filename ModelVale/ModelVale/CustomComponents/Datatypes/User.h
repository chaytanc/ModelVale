//
//  User.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/27/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface User : NSObject

@property (nonatomic, strong) NSArray* models;
@property (nonatomic, strong) NSString* uid;

@end

NS_ASSUME_NONNULL_END
