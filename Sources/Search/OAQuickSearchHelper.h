//
//  OAQuickSearchHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 27/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OASearchCoreFactory.h"

#include <OsmAndCore.h>
#include <OsmAndCore/GpxDocument.h>

@class OASearchUICore, OASearchResultCollection, OASearchResult, QuadRect;

@interface OASearchFavoritesAPI : OASearchBaseAPI

@end

@interface OASearchFavoritesCategoryAPI : OASearchBaseAPI

@end

@interface OASearchGpxAPI : OASearchBaseAPI

@end

@interface OASearchWptAPI : OASearchBaseAPI

- (void) setWptData:(QList<std::shared_ptr<const OsmAnd::GpxDocument>>&)geoDocList paths:(NSArray *)paths;

@end

@interface OASearchHistoryAPI : OASearchBaseAPI

@end


@interface OAQuickSearchHelper : NSObject

+ (OAQuickSearchHelper *)instance;

- (OASearchUICore *) getCore;
- (OASearchResultCollection *) getResultCollection;
- (void) setResultCollection:(OASearchResultCollection *)resultCollection;
- (void) refreshCustomPoiFilters;
- (void) cancelSearch:(BOOL)sync;

- (void) searchCityLocations:(NSString *)text
          searchLocation:(CLLocation *)searchLocation
            searchBBox31:(QuadRect *)searchBBox31
            allowedTypes:(NSArray<NSString *> *)allowedTypes
                   limit:(NSInteger)limit
              onComplete:(void (^)(NSArray<OASearchResult *> *searchResults))onComplete;


- (void)cancelSearchCities;
- (void)searchCities:(NSString *)text
      searchLocation:(CLLocation *)searchLocation
        allowedTypes:(NSArray<NSString *> *)allowedTypes
           cityLimit:(NSInteger)cityLimit
          onComplete:(void (^)(NSMutableArray *amenities))onComplete;

@end
