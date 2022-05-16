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

- (void)addPoint:(OAHistoryItem *)item
{
    [_db deleteDuplicate:item];
    [_db addPoint:item.latitude longitude:item.longitude time:[item.date timeIntervalSince1970] name:item.name type:item.hType iconName:item.iconName typeName:item.typeName];
    [_historyPointAddObservable notifyEventWithKey:item];
}

- (void)removePoint:(OAHistoryItem *)item
{
    [_db deletePoint:item.hId];
    [_historyPointRemoveObservable notifyEventWithKey:item];
}

- (void)removePoints:(NSArray *)items
{
    for (OAHistoryItem *item in items)
        [_db deletePoint:item.hId];
    
    [_historyPointsRemoveObservable notifyEventWithKey:items];
}

- (NSArray *)getAllPoints
{
    return [_db getPoints:nil limit:0];
}

- (NSArray *)getSearchHistoryPoints:(int)limit
{
    return [_db getSearchHistoryPoints:limit];
}

- (NSArray *)getPointsHavingTypes:(NSArray<NSNumber *> *)types limit:(int)limit
{
    return [_db getPointsHavingTypes:types limit:limit];
}

- (OAHistoryItem *)getPointByName:(NSString *)name
{
    return [_db getPointByName:name];
}

@end
