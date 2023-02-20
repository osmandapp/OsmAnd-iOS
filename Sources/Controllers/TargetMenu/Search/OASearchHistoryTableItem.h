//
//  OASearchHistoryTableItem.h
//  OsmAnd Maps
//
//  Created by Dmytro Svetlichnyi on 02.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAHistoryItem.h"
#import "OADistanceDirection.h"

@interface OASearchHistoryTableItem : NSObject

@property (nonatomic) OAHistoryItem *item;

- (OADistanceDirection *) getEvaluatedDistanceDirection:(BOOL)decelerating;
- (void) setMapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate;
- (void) resetMapCenterSearch;

- (instancetype)initWithItem:(OAHistoryItem *)item;
- (instancetype)initWithItem:(OAHistoryItem *)item mapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate;

@end
