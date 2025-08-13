//
//  OAReplaceFavoriteViewController.h
//  OsmAnd Maps
//
//  Created by nnngrach on 12.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"
#import "OAFavoriteItem.h"
#import "OAGpxWptItem.h"

@class OASGpxFile;

typedef NS_ENUM(NSInteger, EOAReplacePointType) {
    EOAReplacePointTypeFavorite = 0,
    EOAReplacePointTypeWaypoint
};

@protocol OAReplacePointDelegate <NSObject>

- (void)onFavoriteReplaced:(OAFavoriteItem *)favoriteItem;
- (void)onWaypointReplaced:(OAGpxWptItem *)waypointItem;

@end

@interface OAReplaceFavoriteViewController : OABaseNavbarViewController

@property (nonatomic, weak) id<OAReplacePointDelegate> delegate;

- (instancetype)initWithItemType:(EOAReplacePointType)replaceItemType gpxDocument:(OASGpxFile *)gpxDocument;

@end
