//
//  OAFavoritesHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 23/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAFavoriteItem;

@interface OAFavoritesHelper : NSObject

+ (NSArray<OAFavoriteItem *> *) getFavoriteItems;
+ (NSArray<OAFavoriteItem *> *) getVisibleFavoriteItems;

@end
