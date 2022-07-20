//
//  XPCluster.h
//  ModelVale
//
//  Created by Chaytan Inman on 7/19/22.
//

#import <Foundation/Foundation.h>
#import "XP.h"
NS_ASSUME_NONNULL_BEGIN

@interface XPCluster : NSObject

@property (nonatomic, strong) NSMutableArray<XP*>* cluster;
@property (nonatomic, assign) CGPoint seed;

- (instancetype) initCluster: (CGPoint)seed centers: (NSMutableArray*)centers paths: (NSMutableArray<UIBezierPath*>*)paths;

- (instancetype) initEmptyCluster: (CGPoint)seed;

@end

NS_ASSUME_NONNULL_END
