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
#import "OASimpleTableViewCell.h"

@class OAQuickSearchListItem, OASearchResult, OAHistoryItem, OAPOI, SearchDownloadingCellResourceHelper;

@protocol OAQuickSearchTableDelegate <NSObject>

@required
- (void) didSelectResult:(OASearchResult *)result;
- (void) didShowOnMap:(OASearchResult *)result;
- (void)closeSearch;

@end

@interface OAQuickSearchTableController : NSObject<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UITableView *tableView;
@property (weak, nonatomic) id<OAQuickSearchTableDelegate> delegate;
@property (nonatomic, readonly) BOOL searchNearMapCenter;
@property (nonatomic, readonly) CLLocationCoordinate2D mapCenterCoordinate;
@property (nonatomic, assign) OAQuickSearchType searchType;
@property (nonatomic, readonly) SearchDownloadingCellResourceHelper *downloadingCellResourceHelper;

- (instancetype) initWithTableView:(UITableView *)tableView;

- (void) updateDistanceAndDirection;

- (void) setMapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate;
- (void) resetMapCenterSearch;

- (void) updateData:(NSArray<NSArray<OAQuickSearchListItem *> *> *)data append:(BOOL)append;
- (void) addItem:(OAQuickSearchListItem *)item groupIndex:(NSInteger)groupIndex;
- (OAQuickSearchListItem *)itemAtIndexPath:(NSIndexPath *)indexPath;
- (void) reloadData;
- (BOOL) isShowResult;
- (void) showOnMap:(OASearchResult *)searchResult searchType:(OAQuickSearchType)searchType delegate:(id<OAQuickSearchTableDelegate>)delegate;

+ (void) showHistoryItemOnMap:(OAHistoryItem *)item lang:(NSString *)lang transliterate:(BOOL)transliterate preferredZoom:(float)preferredZoom;
+ (OASimpleTableViewCell *) getIconTextDescCell:(NSString *)name tableView:(UITableView *)tableView typeName:(NSString *)typeName icon:(UIImage *)icon;
+ (NSString *) applySynonyms:(OASearchResult *)res;
+ (UIImage *)iconForSearchResult:(OASearchResult *)searchResult NS_SWIFT_NAME(icon(for:));
+ (UIImage *)routeShieldForSearchResult:(OASearchResult *)searchResult NS_SWIFT_NAME(routeShield(for:));
+ (NSString *)poiTypeNameForSearchResult:(OASearchResult *)searchResult NS_SWIFT_NAME(poiTypeName(for:));
+ (NSString *)poiTypeNameForPoi:(OAPOI *)poi NS_SWIFT_NAME(poiTypeName(forPoi:));
+ (NSString *)addressTitleForSearchResult:(OASearchResult *)searchResult NS_SWIFT_NAME(addressTitle(for:));
+ (NSString *)addressDescriptionForSearchResult:(OASearchResult *)searchResult NS_SWIFT_NAME(addressDescription(for:));
+ (NSString *)distanceToCityForSearchResult:(OASearchResult *)searchResult NS_SWIFT_NAME(distanceToCity(for:));

@end
