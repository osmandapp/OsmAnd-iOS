//
//  OAQuickSearchListItem.h
//  OsmAnd
//
//  Created by Alexey Kulish on 28/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OADistanceDirection.h"
#import "OACity.h"

@class OASearchResult, OAPointDescription, OASGpxDataItem;

typedef NS_ENUM(NSInteger, EOAQuickSearchListItemType)
{
    SEARCH_RESULT,
    HEADER,
    BUTTON,
    SEARCH_MORE,
    EMPTY_SEARCH,
    ACTION_BUTTON
    //SELECT_ALL,
};

@interface OAQuickSearchListItem : NSObject

- (instancetype)initWithSearchResult:(OASearchResult *)searchResult;

- (EOAQuickSearchListItemType)getType;

- (OASearchResult *)getSearchResult;
- (NSString *)getName;
+ (NSString *)getName:(OASearchResult *)searchResult;
+ (NSString *)getIconName:(OASearchResult *)searchResult;
+ (NSString *)getItemIcon:(OAPointDescription *)pd;
+ (NSString *)getTypeName:(OASearchResult *)searchResult;
// the type of a poi without its address or city, for a list that shows the address on a line of its own
+ (NSString *)getPoiTypeNameWithoutAddress:(OASearchResult *)searchResult;


- (OADistanceDirection *)getEvaluatedDistanceDirection:(BOOL)decelerating;
- (void)setMapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate;
- (void)resetMapCenterSearch;

@end
