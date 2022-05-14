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
- (void)removeDuplicates;

- (NSArray *)getAllPoints;
- (NSArray *)getSearchHistoryPoints:(int)limit;
- (NSArray *)getPointsHavingTypes:(NSArray<NSNumber *> *)types limit:(int)limit;
- (OAHistoryItem *)getPointByName:(NSString *)name;

@end
