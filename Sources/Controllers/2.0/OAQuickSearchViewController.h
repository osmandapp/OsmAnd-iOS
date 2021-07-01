//
//  OAQuickSearchViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 28/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OACommonTypes.h"

#include <OsmAndCore.h>

typedef NS_ENUM(NSInteger, BarActionType)
{
    BarActionNone = 0,
    BarActionShowOnMap,
    BarActionEditHistory,
    BarActionSelectTarget,
};

@class OAQuickSearchListItem;
@class OAPOIUIFilter;

@protocol OAQuickSearchDelegate <NSObject>

@required
- (void) onItemSelected:(OAQuickSearchListItem *)item;

@end

@interface OAQuickSearchViewController : OASuperViewController

@property (nonatomic, assign) BOOL searchNearMapCenter;
@property (nonatomic, assign) double distanceFromMyLocation;
@property (nonatomic, assign) OsmAnd::PointI myLocation;
@property (nonatomic, assign) OAQuickSearchType searchType;
@property (nonatomic, assign) NSInteger tabIndex;
@property (nonatomic) NSString* searchQuery;

@property (nonatomic, weak) id<OAQuickSearchDelegate> delegate;

- (void) setupBarActionView:(BarActionType)type title:(NSString *)title;
- (void) showToolbar;
- (void) showToolbar:(OAPOIUIFilter *)filter;

@end
