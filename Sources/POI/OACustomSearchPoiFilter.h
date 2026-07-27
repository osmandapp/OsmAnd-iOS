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

NS_ASSUME_NONNULL_BEGIN

@interface OACustomSearchPoiFilter : OASearchPoiTypeFilter

- (nullable NSString *) getFilterId;
- (nullable NSString *) getName;

- (nullable NSObject *) getIconResource;

- (nullable OAResultMatcher<OAPOI *> *) wrapResultMatcher:(nullable OAResultMatcher<OAPOI *> *)matcher;

- (instancetype)initWithAcceptFunc:(OASearchPoiTypeFilterAccept)aFunction emptyFunction:(OASearchPoiTypeFilterIsEmpty)eFunction getTypesFunction:(nullable OASearchPoiTypeFilterGetTypes)tFunction;
- (OASearchSortType) getDefaultSearchType;

@end

NS_ASSUME_NONNULL_END
