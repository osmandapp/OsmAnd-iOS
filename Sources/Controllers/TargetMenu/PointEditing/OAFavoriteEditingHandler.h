//
//  OAFavoriteEditingHandler.h
//  OsmAnd Maps
//
//  Created by Paul on 01.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABasePointEditingHandler.h"

NS_ASSUME_NONNULL_BEGIN

@class OAFavoriteItem;

struct CLLocationCoordinate2D;

@interface OAFavoriteEditingHandler : OABasePointEditingHandler

- (instancetype) initWithItem:(OAFavoriteItem *)favorite;
- (instancetype) initWithLocation:(CLLocationCoordinate2D)location title:(NSString*)formattedTitle address:(NSString*)formattedLocation poi:(OAPOI *)poi;

- (OAFavoriteItem *) getFavoriteItem;

@end

NS_ASSUME_NONNULL_END
