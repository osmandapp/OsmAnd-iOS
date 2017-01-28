//
//  OAQuickSearchHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 27/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OASearchCoreFactory.h"

@class OASearchUICore, OASearchResultCollection;

@interface OASearchFavoritesAPI : OASearchBaseAPI

@end

@interface OASearchFavoritesCategoryAPI : OASearchBaseAPI

@end

@interface OASearchWptAPI : OASearchBaseAPI

@end

@interface OASearchHistoryAPI : OASearchBaseAPI

@end


@interface OAQuickSearchHelper : NSObject

- (OASearchUICore *) getCore;
- (OASearchResultCollection *) getResultCollection;
- (void) setResultCollection:(OASearchResultCollection *)resultCollection;
- (void) initSearchUICore;
- (void) refreshCustomPoiFilters;

@end
