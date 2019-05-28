//
//  NCCFRunLoopWorkDistribution.h
//  RunLoop
//
//  Created by niuchao on 2018/3/15.
//  Copyright © 2018年 niuchao. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef BOOL(^NCCFRunLoopWorkDistributionUnit)(void);

@interface NCCFRunLoopWorkDistribution : NSObject

@property (nonatomic, assign) NSUInteger maximumQueueLength;

+ (instancetype)sharedRunLoopWorkDistribution;

- (void)addTask:(NCCFRunLoopWorkDistributionUnit)unit withKey:(id)key;

- (void)removeAllTasks;

@end

@interface UITableViewCell (NCCFRunLoopWorkDistribution)

@property (nonatomic, strong) NSIndexPath *currentIndexPath;

@end

