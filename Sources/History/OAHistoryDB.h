//
//  OAHistoryDB.h
//  OsmAnd
//
//  Created by Alexey Kulish on 05/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAHistoryItem.h"

@interface OAHistoryDB : NSObject

- (void)addPoint:(double)latitude longitude:(double)longitude time:(NSTimeInterval)time name:(NSString *)name type:(OAHistoryType)type;

- (void)deletePoint:(int64_t)id;

- (NSArray *)getPoints:(NSString *)selectPostfix limit:(int)limit;
- (NSArray *)getSearchHistoryPoints:(int)count;
- (NSArray *)getPointsHavingKnownType:(int)count;

@end
