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

@end
