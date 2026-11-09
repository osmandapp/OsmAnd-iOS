//
//  OASharedSearchObjects.h
//  OsmAnd
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAObjectType.h"

@class OASObjectType, OACustomSearchPoiFilter;
@protocol OASCustomSearchPoiFilter, OASResultMatcher;

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

/**
 The object the shared search takes for one the app puts into a result it makes itself: a poi category,
 filter or type the shared one of the same key, a poi filter of the app one the shared search can call,
 a CLLocation a point, and a city, street or house made of the shared search its own shared object.
 nil when the shared search has no counterpart, as for a top index filter the app made.
 */
+ (nullable id)sharedObjectFor:(nullable id)appObject;

/** The poi filter of the app as the shared search calls it, the same one for the same filter. */
+ (id<OASCustomSearchPoiFilter>)sharedPoiFilterFor:(OACustomSearchPoiFilter *)filter;

+ (EOAObjectType)appObjectType:(nullable OASObjectType *)type;
+ (nullable OASObjectType *)sharedObjectType:(EOAObjectType)type;

@end

/** A matcher of the shared search that runs the blocks it is given. */
@interface OASharedBlockResultMatcher : NSObject

+ (id<OASResultMatcher>)matcherWithPublish:(BOOL (^)(id _Nullable object))publish cancelled:(BOOL (^)(void))cancelled;

@end

NS_ASSUME_NONNULL_END
