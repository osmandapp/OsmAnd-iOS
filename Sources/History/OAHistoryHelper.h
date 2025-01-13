//
//  OAHistoryHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 05/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAHistoryItem.h"
#import "OAObservable.h"

@class OAHistoryItem;

@interface OAHistoryHelper : NSObject

@property (readonly) OAObservable* historyPointAddObservable;
@property (readonly) OAObservable* historyPointRemoveObservable;
@property (readonly) OAObservable* historyPointsRemoveObservable;

@property (readonly, nonatomic) NSArray<NSNumber *> *destinationTypes;
@property (readonly, nonatomic) NSArray<NSNumber *> *searchTypes;

+ (OAHistoryHelper*)sharedInstance;

- (void)addPoint:(OAHistoryItem *)item;
- (void)removePoint:(OAHistoryItem *)item;
- (void)removePoints:(NSArray *)items;

- (NSArray<OAHistoryItem *> *)getAllPoints:(BOOL)ignoreDisabledResult;
- (NSArray<OAHistoryItem *> *)getSearchHistoryPoints:(int)limit;
- (NSArray<OAHistoryItem *> *)getPointsHavingTypes:(NSArray<NSNumber *> *)types limit:(int)limit;
- (NSArray<OAHistoryItem *> *)getPointsHavingTypes:(NSArray<NSNumber *> *)types exceptNavigation:(BOOL)exceptNavigation limit:(int)limit;
- (NSInteger) getPointsCountHavingTypes:(NSArray<NSNumber *> *)types;
- (NSArray<OAHistoryItem *> *)getPointsFromNavigation:(int)limit;
- (NSInteger)getPointsCountFromNavigation;
- (OAHistoryItem *)getPointByName:(NSString *)name fromNavigation:(BOOL)fromNavigation;

- (long)getMarkersHistoryLastModifiedTime;
- (void)setMarkersHistoryLastModifiedTime:(long)lastModified;
- (long)getHistoryLastModifiedTime;
- (void)setHistoryLastModifiedTime:(long)lastModified;

@end
