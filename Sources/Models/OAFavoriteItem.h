//
//  OAFavoriteItem.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 07.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OALocationPoint.h"
#include <OsmAndCore/IFavoriteLocation.h>


@interface OAFavoriteItem : NSObject<OALocationPoint>

@property std::shared_ptr<OsmAnd::IFavoriteLocation> favorite;
@property CGFloat direction;
@property NSString* distance;
@property double distanceMeters;

- (NSString *) getFavoriteName;
- (void) setFavoriteName:(NSString *)name;

- (NSString *) getFavoriteDesc;
- (void) setFavoriteDesc:(NSString *)desc;

- (NSString *) getFavoriteAddress;
- (void) setFavoriteAddress:(NSString *)address;

- (NSString *) getFavoriteIcon;
- (void) setFavoriteIcon:(NSString *)icon;

- (NSString *) getFavoriteBackground;
- (void) setFavoriteBackground:(NSString *)background;

- (UIColor *) getFavoriteColor;
- (void) setFavoriteColor:(UIColor *)color;

- (BOOL) getFavoriteHidden;
- (void) setFavoriteHidden:(BOOL)isHidden;

- (NSString *) getFavoriteGroup;
- (void) setFavoriteGroup:(NSString *)groupName;

@end
