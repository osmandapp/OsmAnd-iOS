//
//  OATravelGuidesHelper.h
//  OsmAnd
//
//  Created by nnngrach on 08.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@class OAWptPt, OAPOI;


@interface OATravelGuidesHelper : NSObject


//TODO: replace OAPOI & OAWptPt to adapters

+ (NSArray<OAPOI *> *) searchAmenity:(double)lat lon:(double)lon radius:(double)radius searchFilter:(NSString *)searchFilter;

+ (OAWptPt *) createWptPt:(OAPOI *)amenity lang:(NSString *)lang;

@end
