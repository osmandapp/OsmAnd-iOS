//
//  OAPOIFiltersHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//
//  revision 878491110c391829cc1f42eace8dc582cb35e08e

#import <Foundation/Foundation.h>

@class OAPOIUIFilter;

@interface OAPOIFiltersHelper : NSObject

+ (OAPOIFiltersHelper *)sharedInstance;

- (OAPOIUIFilter *) getSearchByNamePOIFilter;
- (OAPOIUIFilter *) getCustomPOIFilter;
- (OAPOIUIFilter *) getLocalWikiPOIFilter;
- (OAPOIUIFilter *) getShowAllPOIFilter;
- (OAPOIUIFilter *) getFilterById:(NSString *)filterId;
- (void) reloadAllPoiFilters;
- (NSArray<OAPOIUIFilter *> *) getUserDefinedPoiFilters;
- (NSArray<OAPOIUIFilter *> *) getSearchPoiFilters;
- (NSArray<OAPOIUIFilter *> *) getTopDefinedPoiFilters;
- (BOOL) removePoiFilter:(OAPOIUIFilter *)filter;
- (BOOL) createPoiFilter:(OAPOIUIFilter *)filter;
- (BOOL) editPoiFilter:(OAPOIUIFilter *)filter;
- (NSSet<OAPOIUIFilter *> *) getSelectedPoiFilters;
- (void) addSelectedPoiFilter:(OAPOIUIFilter *)filter;
- (void) removeSelectedPoiFilter:(OAPOIUIFilter *)filter;
- (BOOL) isShowingAnyPoi;
- (void) clearSelectedPoiFilters;
- (void) hidePoiFilters;
- (NSString *) getFiltersName:(NSSet<OAPOIUIFilter *> *)filters;
- (NSString *) getSelectedPoiFiltersName;
- (BOOL) isPoiFilterSelected:(OAPOIUIFilter *)filter;
- (BOOL) isPoiFilterSelectedByFilterId:(NSString *)filterId;
- (void) loadSelectedPoiFilters;
- (void) saveSelectedPoiFilters;


@end
