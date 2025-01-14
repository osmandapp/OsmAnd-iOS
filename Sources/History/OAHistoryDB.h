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

- (void)addPoint:(OAHistoryItem *)item;
- (void)deletePoint:(OAHistoryItem *)item;

- (OAHistoryItem *)getPointByName:(NSString *)name fromNavigation:(BOOL)fromNavigation;
- (NSArray<OAHistoryItem *> *)getPoints:(NSString *)selectPostfix limit:(int)limit;
- (NSArray<OAHistoryItem *> *)getPoints:(NSString *)selectPostfix ignoreDisabledResult:(BOOL)ignoreDisabledResult limit:(int)limit;
- (NSArray<OAHistoryItem *> *)getSearchHistoryPoints:(int)count;
- (NSArray<OAHistoryItem *> *)getPointsHavingTypes:(NSArray<NSNumber *> *)types limit:(int)limit;
- (NSArray<OAHistoryItem *> *)getPointsHavingTypes:(NSArray<NSNumber *> *)types exceptNavigation:(BOOL)exceptNavigation limit:(int)limit;
- (NSInteger)getPointsCountHavingTypes:(NSArray<NSNumber *> *)types;
- (NSArray<OAHistoryItem *> *)getPointsFromNavigation:(int)limit;
- (NSInteger)getPointsCountFromNavigation;

- (long)getMarkersHistoryLastModifiedTime;
- (void)setMarkersHistoryLastModifiedTime:(long)lastModified;
- (long)getHistoryLastModifiedTime;
- (void)setHistoryLastModifiedTime:(long)lastModified;

@end
