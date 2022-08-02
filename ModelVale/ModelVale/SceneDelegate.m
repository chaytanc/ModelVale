//
//  SceneDelegate.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/3/22.
//

#import "SceneDelegate.h"
@import FirebaseAuth;
@import FirebaseFirestore;

@interface SceneDelegate ()
@property (nonatomic, strong) FIRAuth* userListener;
@property (nonatomic, readwrite) FIRFirestore *db;
@property (nonatomic, strong) NSString* uid;
@end

@implementation SceneDelegate


- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    self.userListener = [[FIRAuth auth]
        addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
        self.uid = [FIRAuth auth].currentUser.uid;
        self.db = [FIRFirestore firestore];
        if(self.uid) {
            NSLog(@"User %@ persisted", self.uid);
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            self.window.rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"modelNavController"];
        }
        else {
            NSLog(@"User NOT %@ persisted", self.uid);
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
            
            self.window.rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"loginViewController"];
        }
    }];
}


- (void)sceneDidDisconnect:(UIScene *)scene {
    [[FIRAuth auth] removeAuthStateDidChangeListener:self.userListener];
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
}


- (void)sceneWillResignActive:(UIScene *)scene {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
}


@end
