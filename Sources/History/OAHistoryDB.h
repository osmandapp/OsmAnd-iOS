//
//  OAHistoryDB.h
//  OsmAnd
//
//  Created by Alexey Kulish on 05/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAHistoryItem.h"

@class OAHistoryItem;

@interface OAHistoryDB : NSObject

- (void)addPoint:(double)latitude longitude:(double)longitude time:(NSTimeInterval)time name:(NSString *)name type:(OAHistoryType)type iconName:(NSString *)iconName typeName:(NSString *)typeName;

- (void)deletePoint:(int64_t)id;

- (OAHistoryItem *)getPointByName:(NSString *)name;
- (NSArray *)getPoints:(NSString *)selectPostfix limit:(int)limit;
- (NSArray *)getSearchHistoryPoints:(int)count;
- (NSArray *)getPointsHavingTypes:(NSArray<NSNumber *> *)types limit:(int)limit;

@end
