//
//  OASearchHistoryTableItem.m
//  OsmAnd Maps
//
//  Created by Dmytro Svetlichnyi on 02.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OASearchHistoryTableItem.h"

@interface OASearchHistoryTableItem ()

@end

@implementation OASearchHistoryTableItem
{
    OADistanceDirection *_distanceDirection;
}

- (instancetype)initWithItem:(OAHistoryItem *)item
{
    self = [super init];
    if (self)
    {
        _item = item;
        _distanceDirection = [[OADistanceDirection alloc] initWithLatitude:item.latitude longitude:item.longitude];
    }
    return self;
}

- (instancetype)initWithItem:(OAHistoryItem *)item mapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate
{
    self = [super init];
    if (self)
    {
        _item = item;
        _distanceDirection = [[OADistanceDirection alloc] initWithLatitude:item.latitude longitude:item.longitude mapCenterCoordinate:mapCenterCoordinate];
    }
    return self;
}

-(void)setItem:(OAHistoryItem *)item
{
    _item = item;
    _distanceDirection = [[OADistanceDirection alloc] initWithLatitude:item.latitude longitude:item.longitude];
}

- (OADistanceDirection *) getEvaluatedDistanceDirection:(BOOL)decelerating
{
    if (_distanceDirection)
        [_distanceDirection evaluateDistanceDirection:decelerating];
    
    return _distanceDirection;
}

- (void) setMapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate
{
    if (_distanceDirection)
        [_distanceDirection setMapCenterCoordinate:mapCenterCoordinate];
}

- (void) resetMapCenterSearch
{
    if (_distanceDirection)
        [_distanceDirection resetMapCenterSearch];
}

@end
