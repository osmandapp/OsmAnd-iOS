//
//  OAHistoryHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 05/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAHistoryItem.h"

@interface OAHistoryHelper : NSObject

+ (OAHistoryHelper*)sharedInstance;

- (void)addPoint:(OAHistoryItem *)item;
- (void)deletePoint:(OAHistoryItem *)item;

- (NSArray *)getAllPoints;
- (NSArray *)getLastPointsWithLimit:(int)count;
- (NSArray *)getSearchHistoryPoints:(int)count;
- (NSArray *)getPointsHavingKnownType:(int)count;

@end
