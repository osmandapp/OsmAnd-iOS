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
        _db = [[OAHistoryDB alloc] init];
    }
    return self;
}

- (void)addPoint:(OAHistoryItem *)item
{
    [_db addPoint:item.latitude longitude:item.longitude time:[item.date timeIntervalSince1970] name:item.name type:item.hType];
}

- (void)deletePoint:(OAHistoryItem *)item
{
    [_db deletePoint:item.hId];
}

- (NSArray *)getAllPoints
{
    return [_db getPoints:nil limit:0];
}

- (NSArray *)getLastPointsWithLimit:(int)count
{
    return [_db getPoints:nil limit:count];
}

- (NSArray *)getSearchHistoryPoints:(int)count
{
    return [_db getSearchHistoryPoints:count];
}

- (NSArray *)getPointsHavingKnownType:(int)count
{
    return [_db getPointsHavingKnownType:count];
}

@end
