//
//  SettingsViewController.h
//  ModelVale
//
//  Created by Chaytan Inman on 3/26/23.
//

#import <UIKit/UIKit.h>
#import "DisplayDataFirebaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SettingsViewController : DisplayDataFirebaseViewController

@property (nonatomic, weak) NSString* username;

@end

NS_ASSUME_NONNULL_END
