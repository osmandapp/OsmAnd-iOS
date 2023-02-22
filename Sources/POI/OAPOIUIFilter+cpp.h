//
//  OAPOIUIFilter+cpp.h
//  OsmAnd Maps
//
//  Created by nnngrach on 16.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#include <OsmAndCore/Data/Amenity.h>

@interface OAAmenityExtendedNameFilter ()

typedef BOOL(^OAAmenityNameFilterAmenityAccept)(std::shared_ptr<const OsmAnd::Amenity> a, QHash<QString, QString> values, OAPOIType* type);

@property (nonatomic, strong) OAAmenityNameFilterAmenityAccept acceptAmenityFunction;

- (instancetype)initWithAcceptAmenityFunc:(OAAmenityNameFilterAmenityAccept)aFunction;

- (BOOL) acceptAmenity:(std::shared_ptr<const OsmAnd::Amenity>)a values:(QHash<QString, QString>)values type:(OAPOIType*)type;

@end
