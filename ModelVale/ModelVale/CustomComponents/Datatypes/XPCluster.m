//
//  XPCluster.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/19/22.
//

#import "XPCluster.h"

@implementation XPCluster

- (instancetype) initCluster: (CGPoint)seed centers: (NSMutableArray*)centers paths: (NSMutableArray<UIBezierPath*>*)paths {
    self = [super init];
    if(self) {
        self.seed = seed;
        for(int i=0; i < centers.count; i++) {
            NSValue* centerVal = centers[i];
            CGPoint center = centerVal.CGPointValue;
            [self.cluster addObject:[[XP new] initXP:center path:paths[i]]];
        }
    }
    return self;
}

- (instancetype) initEmptyCluster: (CGPoint)seed {
    self = [super init];
    if(self) {
        self.seed = seed;
        self.cluster = [NSMutableArray new];
    }
    return self;
}

@end
