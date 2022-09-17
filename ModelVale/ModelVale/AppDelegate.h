//
//  AppDelegate.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/3/22.
//

#import <UIKit/UIKit.h>
@import AppAuth;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong, nullable) id<OIDExternalUserAgentSession> currentAuthorizationFlow;

@end

