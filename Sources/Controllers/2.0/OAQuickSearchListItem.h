//
//  OAQuickSearchListItem.h
//  OsmAnd
//
//  Created by Alexey Kulish on 28/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <OsmAndCore/Data/DataCommonTypes.h>

@class OASearchResult;

@interface OAQuickSearchListItem : NSObject

- (OASearchResult *) getSearchResult;
+ (NSString *) getCityTypeStr:(OsmAnd::ObfAddressStreetGroupSubtype)type;
- (NSString *) getName;
+ (NSString *) getName:(OASearchResult *)searchResult;
+ (NSString *) getTypeName:(OASearchResult *)searchResult;

@end
