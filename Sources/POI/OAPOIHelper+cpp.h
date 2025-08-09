//
//  OAPOIHelper+cpp.h
//  OsmAnd
//
//  Created by Max Kojin on 04/12/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#include <OsmAndCore.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/MapObject.h>

#import "OrderedDictionary.h"

NS_ASSUME_NONNULL_BEGIN

@class OASearchPoiTypeFilter, OATopIndexFilter;

@interface OAPOIHelper(cpp)

+ (void) fetchValuesContentPOIByAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity poi:(OAPOI *)poi;

+ (NSString *) processLocalizedNames:(const QHash<QString, QString> &)localizedNames nativeName:(const QString &)nativeName names:(NSMutableDictionary *)names;
+ (void) processDecodedValues:(const QList<OsmAnd::Amenity::DecodedValue> &)decodedValues content:(nullable MutableOrderedDictionary *)content values:(nullable MutableOrderedDictionary *)values;

@end

NS_ASSUME_NONNULL_END
