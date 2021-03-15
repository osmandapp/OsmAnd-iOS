//
//  OAReplaceFavoriteViewController.h
//  OsmAnd Maps
//
//  Created by nnngrach on 12.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"
#import "OAFavoriteItem.h"

@protocol OAReplaceFavoriteDelegate <NSObject>

- (void) onReplaced:(OAFavoriteItem *)favoriteItem;

@end

@interface OAReplaceFavoriteViewController : OABaseTableViewController

@property (nonatomic, weak) id<OAReplaceFavoriteDelegate> delegate;

@end
