//
//  OATravelGuidesHelper.h
//  OsmAnd
//
//  Created by nnngrach on 08.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAPOIAdapter.h"
#import "OAGPXDocumentPrimitivesAdapter.h"

@interface OATravelGuidesHelper : NSObject

+ (NSArray<OAPOIAdapter *> *) searchAmenity:(double)lat lon:(double)lon radius:(int)radius searchFilter:(NSString *)searchFilter;

+ (OAWptPtAdapter *) createWptPt:(OAPOIAdapter *)amenity lang:(NSString *)lang;

@end
