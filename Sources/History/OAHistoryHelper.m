//
//  OAHistoryHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 05/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAHistoryHelper.h"
#import "OAHistoryDB.h"

@implementation OAHistoryHelper
{
    OAHistoryDB *_db;
}

+ (OAHistoryHelper*)sharedInstance
{
    static OAHistoryHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAHistoryHelper alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _destinationTypes = @[@(OAHistoryTypeDirection), @(OAHistoryTypeParking), @(OAHistoryTypeRouteWpt)];
        _searchTypes = @[@(OAHistoryTypeFavorite), @(OAHistoryTypePOI), @(OAHistoryTypeAddress), @(OAHistoryTypeWpt), @(OAHistoryTypeLocation)];

        _db = [[OAHistoryDB alloc] init];
        _historyPointAddObservable = [[OAObservable alloc] init];
        _historyPointRemoveObservable = [[OAObservable alloc] init];
        _historyPointsRemoveObservable = [[OAObservable alloc] init];
    }
    return self;
}

- (long) getMarkersHistoryLastModifiedTime
{
    return [_db getMarkersHistoryLastModifiedTime];
}

- (void) setMarkersHistoryLastModifiedTime:(long)lastModified
{
    [_db setMarkersHistoryLastModifiedTime:lastModified];
}

- (long)getHistoryLastModifiedTime
{
    return [_db getHistoryLastModifiedTime];
}

- (void)setHistoryLastModifiedTime:(long)lastModified
{
    [_db setHistoryLastModifiedTime:lastModified];
}

- (void)addPoint:(OAHistoryItem *)item
{
    [_db addPoint:item];
    [_historyPointAddObservable notifyEventWithKey:item];
}

- (void)removePoint:(OAHistoryItem *)item
{
    [_db deletePoint:item];
    [_historyPointRemoveObservable notifyEventWithKey:item];
}

- (void)removePoints:(NSArray *)items
{
    for (OAHistoryItem *item in items)
    {
        [_db deletePoint:item];
    }
    [_historyPointsRemoveObservable notifyEventWithKey:items];
}

- (NSArray<OAHistoryItem *> *)getAllPoints:(BOOL)ignoreDisabledResult
{
    return [_db getPoints:nil ignoreDisabledResult:ignoreDisabledResult limit:0];
}

- (NSArray<OAHistoryItem *> *)getSearchHistoryPoints:(int)limit
{
    return [_db getSearchHistoryPoints:limit];
}

- (NSArray<OAHistoryItem *> *)getPointsHavingTypes:(NSArray<NSNumber *> *)types limit:(int)limit
{
    return [_db getPointsHavingTypes:types limit:limit];
}

- (NSArray<OAHistoryItem *> *)getPointsHavingTypes:(NSArray<NSNumber *> *)types exceptNavigation:(BOOL)exceptNavigation limit:(int)limit
{
    return [_db getPointsHavingTypes:types exceptNavigation:exceptNavigation limit:limit];
}

- (NSInteger) getPointsCountHavingTypes:(NSArray<NSNumber *> *)types
{
    return [_db getPointsCountHavingTypes:types];
}

- (NSArray<OAHistoryItem *> *)getPointsFromNavigation:(int)limit
{
    return [_db getPointsFromNavigation:limit];
}

- (NSInteger)getPointsCountFromNavigation
{
    return [_db getPointsCountFromNavigation];
}

- (OAHistoryItem *)getPointByName:(NSString *)name fromNavigation:(BOOL)fromNavigation
{
    return [_db getPointByName:name fromNavigation:fromNavigation];
}

@end
