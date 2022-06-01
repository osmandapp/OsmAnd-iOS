//
//  OACollapsableNearestPoiTypeView.h
//  OsmAnd
//
//  Created by nnngrach on 17.08.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACollapsableView.h"

@class OAPOIType, OAPOI, OAPOIUIFilter;
@class OARowInfo;

@interface OACollapsableNearestPoiTypeView : OACollapsableView

@property (nonatomic, readonly) BOOL hasItems;

- (void) setData:(NSArray<OAPOIType *> *)poiTypes
         amenity:(OAPOI *)amenity
             lat:(double)lat
             lon:(double)lon
 isPoiAdditional:(BOOL)isPoiAdditional
         textRow:(OARowInfo *)textRow;

@end
