//
//  OASharedSearchObjects.h
//  OsmAnd
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The objects a result of the shared search carries, as the app's own: the ones the C++ search puts into
 OASearchResult.object and relatedObject for the same kind of result.

 A city, street or house becomes an OACity, OAStreet or OABuilding; an amenity an OAPOI; a poi
 category, filter or type the OAPOIBaseType of the same key, and a top index filter an
 OATopIndexFilter; a point a CLLocation. Anything else - the objects the app hands the search itself,
 and the parsed points the C++ search already takes from OsmAndShared - comes back as it is.
 */
@interface OASharedSearchObjects : NSObject

/**
 nil when the app has no counterpart: an amenity of a type that is disabled or only drawn on the map,
 or a poi category, filter or type whose key the app's registry does not know. Such a result has no
 object the app can show, so it is left out.
 */
+ (nullable id)appObjectFor:(nullable id)sharedObject;

@end

NS_ASSUME_NONNULL_END
