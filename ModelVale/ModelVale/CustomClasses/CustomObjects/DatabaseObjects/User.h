//
//  User.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/27/22.
//

#import <Foundation/Foundation.h>
@import FirebaseFirestore;

NS_ASSUME_NONNULL_BEGIN

@interface User : NSObject

@property (nonatomic, strong) NSMutableArray<NSString*>* userModelDocRefs;
@property (nonatomic, strong) NSString* uid;

- (instancetype) initUser: (NSString*)uid db:(FIRFirestore*)db;
- (void) updateUserModelDocRefs: (FIRFirestore*)db vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion;
- (void) addNewUser: (FIRFirestore*)db vc: (UIViewController*)vc completion:(void(^)(NSError *error))completion;


@end

NS_ASSUME_NONNULL_END
