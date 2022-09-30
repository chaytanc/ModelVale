//
//  AppDelegate.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/3/22.
//

#import "AppDelegate.h"


@import UIKit;
@import FirebaseCore;
@import FirebaseAuth;
@import FirebaseFirestore;

@interface AppDelegate ()
@property (nonatomic, strong) FIRAuth* userListener;
@property (nonatomic, readwrite) FIRFirestore *db;
@property (nonatomic, strong) NSString* uid;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [FIRApp configure];
    return YES;
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<NSString *, id> *)options {
    // Sends the URL to the current authorization flow (if any) which will
    // process it if it relates to an authorization response.
    if ([_currentAuthorizationFlow resumeExternalUserAgentFlowWithURL:url]) {
      _currentAuthorizationFlow = nil;
      return YES;
    }

    // Your additional URL handling (if any) goes here.

    return NO;
}

#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
