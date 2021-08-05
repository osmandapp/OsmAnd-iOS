//
//  OACollapsableNearestPoiWikiView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACollapsableView.h"

@class OAPOI;
@class OAPOIUIFilter;

@interface OACollapsableNearestPoiWikiView : OACollapsableView

@property (nonatomic, readonly) NSArray<OAPOI *> *nearestItems;
@property (nonatomic, readonly) BOOL hasItems;

- (void)setData:(NSArray<OAPOI *> *)nearestItems hasItems:(BOOL)hasItems latitude:(double)latitude longitude:(double)longitude filter:(OAPOIUIFilter *)filter;

@end
