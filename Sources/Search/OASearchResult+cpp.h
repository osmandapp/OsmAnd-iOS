//
//  OASearchPhrase+cpp.h
//  OsmAnd
//
//  Created by Max Kojin on 27/02/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OASearchResult.h"

#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/IFavoriteLocation.h>

@interface OASearchResult(cpp)

- (std::shared_ptr<const OsmAnd::Amenity>) amenity;
- (void) setAmenity:(std::shared_ptr<const OsmAnd::Amenity>)amenity;

- (std::shared_ptr<const OsmAnd::IFavoriteLocation>) favorite;
- (void) setFavorite:(std::shared_ptr<const OsmAnd::IFavoriteLocation>)favorite;

@end
