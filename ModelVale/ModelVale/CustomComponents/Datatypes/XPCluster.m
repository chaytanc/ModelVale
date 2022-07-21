//
//  XPCluster.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/19/22.
//

#import "XPCluster.h"

@implementation XPCluster

- (instancetype) initCluster: (CGPoint)center XPCenters: (NSMutableArray*)XPCenters paths: (NSMutableArray<UIBezierPath*>*)paths {
    self = [super init];
    if(self) {
        self.center = center;
        for(int i=0; i < XPCenters.count; i++) {
            NSValue* centerVal = XPCenters[i];
            CGPoint center = centerVal.CGPointValue;
            [self.cluster addObject:[[XP new] initXP:center path:paths[i]]];
        }
    }
    return self;
}

- (instancetype) initEmptyCluster: (CGPoint)seed {
    self = [super init];
    if(self) {
        self.center = seed;
        self.cluster = [NSMutableArray new];
    }
    return self;
}

@end
