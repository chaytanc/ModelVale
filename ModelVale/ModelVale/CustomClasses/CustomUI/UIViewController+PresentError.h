//
//  UIViewController+PresentError.h
//  Instagram
//
//  Created by Chaytan Inman on 6/24/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (PresentError)
- (void) presentError: (NSString*)title message:(NSString*)message error:(NSError* _Nullable)error ;
- (void) presentError: (NSString*)title message:(NSString*)message error:(NSError* _Nullable)error completion: (void(^)(UIAlertAction * action))completion;

@end

NS_ASSUME_NONNULL_END
