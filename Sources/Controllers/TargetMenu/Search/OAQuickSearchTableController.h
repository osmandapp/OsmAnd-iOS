//
//  OAQuickSearchTableController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OACommonTypes.h"
#import "OAIconTextDescCell.h"

@class OAQuickSearchListItem, OASearchResult, OAHistoryItem;

@protocol OAQuickSearchTableDelegate <NSObject>

@required
- (void) didSelectResult:(OASearchResult *)result;
- (void) didShowOnMap:(OASearchResult *)result;

@end

@interface OAQuickSearchTableController : NSObject<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UITableView *tableView;
@property (weak, nonatomic) id<OAQuickSearchTableDelegate> delegate;
@property (nonatomic, readonly) BOOL searchNearMapCenter;
@property (nonatomic, readonly) CLLocationCoordinate2D mapCenterCoordinate;
@property (nonatomic, assign) OAQuickSearchType searchType;

- (instancetype) initWithTableView:(UITableView *)tableView;

- (void) updateDistanceAndDirection;

- (void) setMapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate;
- (void) resetMapCenterSearch;

- (void) updateData:(NSArray<NSArray<OAQuickSearchListItem *> *> *)data append:(BOOL)append;
- (void) addItem:(OAQuickSearchListItem *)item groupIndex:(NSInteger)groupIndex;
- (void) reloadData;
- (BOOL) isShowResult;
- (void) showOnMap:(OASearchResult *)searchResult searchType:(OAQuickSearchType)searchType delegate:(id<OAQuickSearchTableDelegate>)delegate;

+ (void) showHistoryItemOnMap:(OAHistoryItem *)item lang:(NSString *)lang transliterate:(BOOL)transliterate;
+ (OAIconTextDescCell *) getIconTextDescCell:(NSString *)name tableView:(UITableView *)tableView typeName:(NSString *)typeName icon:(UIImage *)icon;
+ (NSString *) applySynonyms:(OASearchResult *)res;

@end
