//
//  OAReplaceFavoriteViewController.h
//  OsmAnd Maps
//
//  Created by nnngrach on 12.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"
#import "OAFavoriteItem.h"
#import "OAGpxWptItem.h"

@class OAGPXDocument;

typedef NS_ENUM(NSInteger, EOAReplacePointType) {
    EOAReplacePointTypeFavorite = 0,
    EOAReplacePointTypeWaypoint
};

@protocol OAReplacePointDelegate <NSObject>

- (void)onFavoriteReplaced:(OAFavoriteItem *)favoriteItem;
- (void)onWaypointReplaced:(OAGpxWptItem *)waypointItem;

@end

@interface OAReplaceFavoriteViewController : OABaseTableViewController

@property (nonatomic, weak) id<OAReplacePointDelegate> delegate;

- (instancetype)initWithItemType:(EOAReplacePointType)replaceItemType gpxDocument:(OAGPXDocument *)gpxDocument;

@end
