//
//  OACustomSearchPoiFilter.h
//  OsmAnd
//
//  Created by Alexey Kulish on 23/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OASearchPoiTypeFilter.h"
#import "OAResultMatcher.h"
#import "OASearchSettings.h"

@class OAPOI;

@interface OACustomSearchPoiFilter : OASearchPoiTypeFilter

- (NSString *) getFilterId;
- (NSString *) getName;

- (NSObject *) getIconResource;

- (OAResultMatcher<OAPOI *> *) wrapResultMatcher:(OAResultMatcher<OAPOI *> *)matcher;

- (instancetype)initWithAcceptFunc:(OASearchPoiTypeFilterAccept)aFunction emptyFunction:(OASearchPoiTypeFilterIsEmpty)eFunction getTypesFunction:(OASearchPoiTypeFilterGetTypes)tFunction;
- (OASearchSortType) getDefaultSearchType;

@end
