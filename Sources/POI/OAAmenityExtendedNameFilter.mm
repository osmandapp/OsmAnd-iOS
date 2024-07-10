//
//  OAAmenityUIFilter.m
//  OsmAnd
//
//  Created by nnngrach on 23.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAAmenityExtendedNameFilter.h"
#import "OAPOI.h"
#import "OAPOICategory.h"
#import "OAPOIType.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <openingHoursParser.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/Data/ObfMapObject.h>

@implementation OAAmenityExtendedNameFilter

-(BOOL)acceptAmenity:(std::shared_ptr<const OsmAnd::Amenity>)a values:(QHash<QString, QString>)values type:(OAPOIType *)type
{
    if (_acceptAmenityFunction)
        return _acceptAmenityFunction(a, values, type);
    
    return NO;
}

- (instancetype)initWithAcceptAmenityFunc:(OAAmenityNameFilterAmenityAccept)aFunction
{
    self = [super init];
    if (self) {
        _acceptAmenityFunction = aFunction;
    }
    return self;
}

@end
