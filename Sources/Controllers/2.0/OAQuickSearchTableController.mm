//
//  OAQuickSearchTableController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAQuickSearchTableController.h"
#import "OAQuickSearchListItem.h"
#import "OAQuickSearchMoreListItem.h"
#import "OAQuickSearchButtonListItem.h"
#import "OAQuickSearchHeaderListItem.h"
#import "OAQuickSearchEmptyResultListItem.h"
#import "OASearchResult.h"
#import "OASearchPhrase.h"
#import "OASearchSettings.h"
#import "OAMapLayers.h"
#import "OAPOILayer.h"
#import "OAPOI.h"
#import "OAPOIHelper.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OANativeUtilities.h"
#import "OAHistoryItem.h"
#import "OsmAndApp.h"
#import "OAUtilities.h"
#import "OAFavoriteItem.h"
#import "OAGpxWptItem.h"
#import "OABuilding.h"
#import "OAStreet.h"
#import "OACity.h"
#import "OAStreetIntersection.h"
#import "OAGPXDocument.h"
#import "OAGpxWptItem.h"
#import "Localization.h"
#import "OADistanceDirection.h"
#import "OAPOIUIFilter.h"
#import "OADefaultFavorite.h"
#import "OAPOILocationType.h"
#import "OAPOISearchHelper.h"
#import "OAPointDescription.h"
#import "OATargetPointsHelper.h"
#import "OAReverseGeocoder.h"

#import "OAIconTextTableViewCell.h"
#import "OASearchMoreCell.h"
#import "OAPointDescCell.h"
#import "OAIconTextDescCell.h"
#import "OAIconButtonCell.h"
#import "OAMenuSimpleCell.h"
#import "OAEmptySearchCell.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Search/AmenitiesInAreaSearch.h>
#include <OsmAndCore/FunctorQueryController.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Data/Address.h>
#include <OsmAndCore/Data/Street.h>
#include <OsmAndCore/Data/StreetGroup.h>
#include <OsmAndCore/Data/StreetIntersection.h>

#define kDefaultZoomOnShow 16.0f

@implementation OAQuickSearchTableController
{
    NSMutableArray<NSMutableArray<OAQuickSearchListItem *> *> *_dataGroups;
    BOOL _decelerating;
    
    BOOL _showResult;
}

- (instancetype) initWithTableView:(UITableView *)tableView
{
    self = [super init];
    if (self)
    {
        _dataGroups = [NSMutableArray array];
        _tableView = tableView;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorInset = UIEdgeInsetsMake(0, 62, 0, 0);
        _tableView.estimatedRowHeight = 48.0;
        _tableView.rowHeight = UITableViewAutomaticDimension;
    }
    return self;
}

- (void) updateDistanceAndDirection
{
    if (!_decelerating)
        [self.tableView reloadData];
}

+ (void) goToPoint:(double)latitude longitude:(double)longitude
{
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    OATargetPoint *targetPoint = [mapVC.mapLayers.contextMenuLayer getUnknownTargetPoint:latitude longitude:longitude];
    targetPoint.centerMap = YES;
    [[OARootViewController instance].mapPanel showContextMenu:targetPoint saveState:NO];}

+ (void) goToPoint:(OAPOI *)poi
{
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    OATargetPoint *targetPoint = [mapVC.mapLayers.poiLayer getTargetPoint:poi];
    targetPoint.centerMap = YES;
    NSString *addr = [[OAReverseGeocoder instance] lookupAddressAtLat:poi.latitude lon:poi.longitude];
    targetPoint.addressFound = addr && addr.length > 0;
    targetPoint.titleAddress = addr;
    [[OARootViewController instance].mapPanel showContextMenu:targetPoint saveState:NO];
}

+ (OAPOI *) findAmenity:(NSString *)name lat:(double)lat lon:(double)lon lang:(NSString *)lang transliterate:(BOOL)transliterate
{
    auto keyword = QString::fromNSString(name);
    OsmAnd::PointI pointI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    const auto& searchCriteria = std::make_shared<OsmAnd::AmenitiesInAreaSearch::Criteria>();
    searchCriteria->bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(15, pointI);
    
    const auto& obfsCollection = [OsmAndApp instance].resourcesManager->obfsCollection;
    const auto search = std::make_shared<const OsmAnd::AmenitiesInAreaSearch>(obfsCollection);

    std::shared_ptr<const OsmAnd::Amenity> amenity;
    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([self, &amenity]
                                                  (const OsmAnd::IQueryController* const controller)
                                                  {
                                                      return amenity != nullptr;
                                                  }));
    search->performSearch(*searchCriteria,
                          [self, &amenity, &keyword]
                          (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                              auto a = ((OsmAnd::AmenitiesInAreaSearch::ResultEntry&)resultEntry).amenity;
                              if (a->nativeName == keyword || a->localizedNames.contains(keyword))
                                  amenity = qMove(a);
        
                          }, ctrl);
    if (amenity)
        return [OAPOIHelper parsePOIByAmenity:amenity];

    return nil;
}

+ (void) showHistoryItemOnMap:(OAHistoryItem *)item lang:(NSString *)lang transliterate:(BOOL)transliterate
{
    OsmAndAppInstance app = [OsmAndApp instance];
    BOOL originFound = NO;
    if (item.hType == OAHistoryTypePOI)
    {
        OAPOI *poi = [self.class findAmenity:item.name lat:item.latitude lon:item.longitude lang:lang transliterate:transliterate];
        if (poi)
        {
            [self.class goToPoint:poi];
            originFound = YES;
        }
    }
    else if (item.hType == OAHistoryTypeFavorite)
    {
        for (const auto& point : app.favoritesCollection->getFavoriteLocations())
        {
            OsmAnd::LatLon latLon = point->getLatLon();
            if ([OAUtilities isCoordEqual:latLon.latitude srcLon:latLon.longitude destLat:item.latitude destLon:item.longitude] && [item.name isEqualToString:point->getTitle().toNSString()])
            {
                OAFavoriteItem *fav = [[OAFavoriteItem alloc] initWithFavorite:point];
                [[OARootViewController instance].mapPanel openTargetViewWithFavorite:fav pushed:NO saveState:NO];
                originFound = YES;
                break;
            }
        }
    }
    else if (item.hType == OAHistoryTypeWpt)
    {
        CLLocationCoordinate2D point = CLLocationCoordinate2DMake(item.latitude, item.longitude);
        OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
        if ([mapVC findWpt:point])
        {
            OAGpxWpt *wpt = mapVC.foundWpt;
            NSArray *foundWptGroups = mapVC.foundWptGroups;
            NSString *foundWptDocPath = mapVC.foundWptDocPath;
            
            OAGpxWptItem *wptItem = [[OAGpxWptItem alloc] init];
            wptItem.point = wpt;
            wptItem.groups = foundWptGroups;
            wptItem.docPath = foundWptDocPath;
            
            [[OARootViewController instance].mapPanel openTargetViewWithWpt:wptItem pushed:NO showFullMenu:NO saveState:NO];
            originFound = YES;
        }
    }
    if (!originFound)
        [[OARootViewController instance].mapPanel openTargetViewWithHistoryItem:item pushed:NO showFullMenu:NO];
}

- (BOOL) isShowResult
{
    return _showResult;
}

- (void) setMapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate
{
    _mapCenterCoordinate = mapCenterCoordinate;
    _searchNearMapCenter = YES;
    for (NSMutableArray<OAQuickSearchListItem *> *items in _dataGroups)
        for (OAQuickSearchListItem *item in items)
            [item setMapCenterCoordinate:mapCenterCoordinate];
}

- (void) resetMapCenterSearch
{
    _searchNearMapCenter = NO;
    for (NSMutableArray<OAQuickSearchListItem *> *items in _dataGroups)
        for (OAQuickSearchListItem *item in items)
            [item resetMapCenterSearch];
}

- (void) updateData:(NSArray<NSArray<OAQuickSearchListItem *> *> *)data append:(BOOL)append
{
    _dataGroups = [NSMutableArray arrayWithArray:data];
    if (self.searchNearMapCenter)
    {
        for (NSMutableArray<OAQuickSearchListItem *> *items in _dataGroups)
            for (OAQuickSearchListItem *item in items)
                [item setMapCenterCoordinate:self.mapCenterCoordinate];
    }
    _tableView.separatorInset = UIEdgeInsetsMake(0, 62, 0, 0);
    [_tableView reloadData];
    if (!append && _dataGroups.count > 0 && _dataGroups[0].count > 0)
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

- (void) addItem:(OAQuickSearchListItem *)item groupIndex:(NSInteger)groupIndex
{
    if (item)
    {
        if ([item isKindOfClass:[OAQuickSearchMoreListItem class]])
        {
            for (NSMutableArray<OAQuickSearchListItem *> *items in _dataGroups)
                for (OAQuickSearchListItem *it in items)
                    if ([it isKindOfClass:[OAQuickSearchMoreListItem class]])
                        return;
        }
        if ([item isKindOfClass:[OAQuickSearchEmptyResultListItem class]])
            _tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);

        if (groupIndex < _dataGroups.count)
            [_dataGroups[groupIndex] addObject:item];
    }
}

- (void) reloadData
{
    [self.tableView reloadData];
}

- (void) showOnMap:(OASearchResult *)searchResult searchType:(OAQuickSearchType)searchType delegate:(id<OAQuickSearchTableDelegate>)delegate
{
    _showResult = NO;
    if (searchResult.location)
    {
        double latitude = DBL_MAX;
        double longitude = DBL_MAX;
        OAPointDescription *pointDescription = nil;
        
        switch (searchResult.objectType)
        {
            case POI:
            {
                OAPOI *poi = (OAPOI *)searchResult.object;
                if (searchType == OAQuickSearchType::REGULAR)
                {
                    [self.class goToPoint:poi];
                }
                else if (searchType == OAQuickSearchType::START_POINT || searchType == OAQuickSearchType::DESTINATION || searchType == OAQuickSearchType::INTERMEDIATE || searchType == OAQuickSearchType::HOME || searchType == OAQuickSearchType::WORK)
                {
                    latitude = poi.latitude;
                    longitude = poi.longitude;
                    pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_POI typeName:poi.type.name name:poi.name];
                }
                break;
            }
            case RECENT_OBJ:
            {
                OAHistoryItem *item = (OAHistoryItem *) searchResult.object;
                if (searchType == OAQuickSearchType::REGULAR)
                {
                    NSString *lang = [[searchResult.requiredSearchPhrase getSettings] getLang];
                    BOOL transliterate = [[searchResult.requiredSearchPhrase getSettings] isTransliterate];
                    [self.class showHistoryItemOnMap:item lang:lang transliterate:transliterate];
                }
                else if (searchType == OAQuickSearchType::START_POINT || searchType == OAQuickSearchType::DESTINATION || searchType == OAQuickSearchType::INTERMEDIATE || searchType == OAQuickSearchType::HOME || searchType == OAQuickSearchType::WORK)
                {
                    latitude = item.latitude;
                    longitude = item.longitude;
                    pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION typeName:item.typeName name:item.name];
                }
                break;
            }
            case FAVORITE:
            {
                auto favorite = std::const_pointer_cast<OsmAnd::IFavoriteLocation>(searchResult.favorite);
                OAFavoriteItem *fav = [[OAFavoriteItem alloc] initWithFavorite:favorite];
                
                if (searchType == OAQuickSearchType::REGULAR)
                {
                    [[OARootViewController instance].mapPanel openTargetViewWithFavorite:fav pushed:NO saveState:NO];
                }
                else if (searchType == OAQuickSearchType::START_POINT || searchType == OAQuickSearchType::DESTINATION || searchType == OAQuickSearchType::INTERMEDIATE || searchType == OAQuickSearchType::HOME || searchType == OAQuickSearchType::WORK)
                {
                    latitude = fav.favorite->getLatLon().latitude;
                    longitude = fav.favorite->getLatLon().longitude;
                    pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE name:fav.favorite->getTitle().toNSString()];
                }
                break;
            }
            case CITY:
            case STREET:
            case VILLAGE:
            {
                OAAddress *address = (OAAddress *)searchResult.object;
                if (searchType == OAQuickSearchType::REGULAR)
                {
                    [[OARootViewController instance].mapPanel openTargetViewWithAddress:address name:[OAQuickSearchListItem getName:searchResult] typeName:[OAQuickSearchListItem getTypeName:searchResult] pushed:NO];
                }
                else if (searchType == OAQuickSearchType::START_POINT || searchType == OAQuickSearchType::DESTINATION || searchType == OAQuickSearchType::INTERMEDIATE || searchType == OAQuickSearchType::HOME || searchType == OAQuickSearchType::WORK)
                {
                    latitude = address.latitude;
                    longitude = address.longitude;
                    pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_ADDRESS typeName:[OAQuickSearchListItem getTypeName:searchResult] name:[OAQuickSearchListItem getName:searchResult]];
                }
                break;
            }
            case HOUSE:
            {
                OABuilding *building = (OABuilding *)searchResult.object;
                NSString *typeNameHouse;
                NSString *name = searchResult.localeName;
                if ([searchResult.relatedObject isKindOfClass:[OACity class]])
                {
                    OACity *city = (OACity * )searchResult.relatedObject;
                    name = [NSString stringWithFormat:@"%@ %@", [city getName:[[searchResult.requiredSearchPhrase getSettings] getLang] transliterate:[[searchResult.requiredSearchPhrase getSettings] isTransliterate]], name];
                }
                else if ([searchResult.relatedObject isKindOfClass:[OAStreet class]])
                {
                    OAStreet *street = (OAStreet * )searchResult.relatedObject;
                    NSString *s = [street getName:[[searchResult.requiredSearchPhrase getSettings] getLang] transliterate:[[searchResult.requiredSearchPhrase getSettings] isTransliterate]];
                    typeNameHouse = [street.city getName:[[searchResult.requiredSearchPhrase getSettings] getLang] transliterate:[[searchResult.requiredSearchPhrase getSettings] isTransliterate]];
                    name = [NSString stringWithFormat:@"%@ %@", s, name];
                }
                else if (searchResult.localeRelatedObjectName)
                {
                    name = [NSString stringWithFormat:@"%@ %@", searchResult.localeRelatedObjectName, name];
                }
                
                if (searchType == OAQuickSearchType::REGULAR)
                {
                    [[OARootViewController instance].mapPanel openTargetViewWithAddress:building name:name typeName:typeNameHouse pushed:NO saveState:NO];
                }
                else if (searchType == OAQuickSearchType::START_POINT || searchType == OAQuickSearchType::DESTINATION || searchType == OAQuickSearchType::INTERMEDIATE || searchType == OAQuickSearchType::HOME || searchType == OAQuickSearchType::WORK)
                {
                    latitude = building.latitude;
                    longitude = building.longitude;
                    pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_ADDRESS typeName:typeNameHouse name:name];
                }
                break;
            }
            case STREET_INTERSECTION:
            {
                OAStreetIntersection *streetIntersection = (OAStreetIntersection *)searchResult.object;
                NSString *typeNameIntersection = [OAQuickSearchListItem getTypeName:searchResult];
                if (typeNameIntersection.length == 0)
                    typeNameIntersection = nil;
                
                if (searchType == OAQuickSearchType::REGULAR)
                {
                    [[OARootViewController instance].mapPanel openTargetViewWithAddress:streetIntersection name:[OAQuickSearchListItem getName:searchResult] typeName:typeNameIntersection pushed:NO saveState:NO];
                }
                else if (searchType == OAQuickSearchType::START_POINT || searchType == OAQuickSearchType::DESTINATION || searchType == OAQuickSearchType::INTERMEDIATE || searchType == OAQuickSearchType::HOME || searchType == OAQuickSearchType::WORK)
                {
                    latitude = streetIntersection.latitude;
                    longitude = streetIntersection.longitude;
                    pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_ADDRESS typeName:typeNameIntersection name:[OAQuickSearchListItem getName:searchResult]];
                }
                break;
            }
            case LOCATION:
            {
                if (searchResult.location)
                {
                    if (searchType == OAQuickSearchType::REGULAR)
                    {
                        [self.class goToPoint:searchResult.location.coordinate.latitude longitude:searchResult.location.coordinate.longitude];
                    }
                    else if (searchType == OAQuickSearchType::START_POINT || searchType == OAQuickSearchType::DESTINATION || searchType == OAQuickSearchType::INTERMEDIATE || searchType == OAQuickSearchType::HOME || searchType == OAQuickSearchType::WORK)
                    {
                        latitude = searchResult.location.coordinate.latitude;
                        longitude = searchResult.location.coordinate.longitude;
                        pointDescription = [[OAPointDescription alloc] initWithLatitude:latitude longitude:longitude];
                    }
                }
                break;
            }
            case WPT:
            {
                if (searchResult.wpt)
                {
                    const auto& gpxWpt = std::dynamic_pointer_cast<const OsmAnd::GpxDocument::GpxWpt>(searchResult.wpt);
                    OAGpxWpt *wpt = [OAGPXDocument fetchWpt:gpxWpt];
                    OAGpxWptItem *wptItem = [[OAGpxWptItem alloc] init];
                    wptItem.point = wpt;

                    if (searchType == OAQuickSearchType::REGULAR)
                    {
                        [[OARootViewController instance].mapPanel openTargetViewWithWpt:wptItem pushed:NO showFullMenu:NO saveState:NO];
                    }
                    else if (searchType == OAQuickSearchType::START_POINT || searchType == OAQuickSearchType::DESTINATION || searchType == OAQuickSearchType::INTERMEDIATE || searchType == OAQuickSearchType::HOME || searchType == OAQuickSearchType::WORK)
                    {
                        latitude = wpt.position.latitude;
                        longitude = wpt.position.longitude;
                        pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_WPT typeName:wpt.type name:wpt.name];
                    }
                }
                break;
            }
            default:
                break;
        }
                
        if (delegate)
            [delegate didShowOnMap:searchResult];
        
        if ((searchType == OAQuickSearchType::START_POINT || searchType == OAQuickSearchType::DESTINATION || searchType == OAQuickSearchType::INTERMEDIATE) && latitude != DBL_MAX)
        {
            [[OARootViewController instance].mapPanel setRouteTargetPoint:searchType == OAQuickSearchType::DESTINATION intermediate:searchType == OAQuickSearchType::INTERMEDIATE latitude:latitude longitude:longitude pointDescription:pointDescription];
        }
        else if (searchType == OAQuickSearchType::HOME && latitude != DBL_MAX)
        {
            [[OATargetPointsHelper sharedInstance] setHomePoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] description:pointDescription];
            [[OARootViewController instance].mapPanel updateRouteInfo];
        }
        else if (searchType == OAQuickSearchType::WORK && latitude != DBL_MAX)
        {
            [[OATargetPointsHelper sharedInstance] setWorkPoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] description:pointDescription];
            [[OARootViewController instance].mapPanel updateRouteInfo];
        }
    }
}

- (OAPointDescCell *) getPointDescCell
{
    OAPointDescCell* cell;
    cell = (OAPointDescCell *)[self.tableView dequeueReusableCellWithIdentifier:[OAPointDescCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointDescCell getCellIdentifier] owner:self options:nil];
        cell = (OAPointDescCell *)[nib objectAtIndex:0];
    }
    return cell;
}

- (void) setCellDistanceDirection:(OAPointDescCell *)cell item:(OAQuickSearchListItem *)item
{
    OADistanceDirection *distDir = [item getEvaluatedDistanceDirection:_decelerating];
    [cell.distanceView setText:distDir.distance];
    if (self.searchNearMapCenter)
    {
        cell.directionImageView.hidden = YES;
        cell.distanceViewLeadingOutlet.constant = 16;
    }
    else
    {
        cell.directionImageView.hidden = NO;
        cell.distanceViewLeadingOutlet.constant = 34;
        cell.directionImageView.transform = CGAffineTransformMakeRotation(distDir.direction);
    }
}

+ (OAIconTextDescCell *) getIconTextDescCell:(NSString *)name tableView:(UITableView *)tableView typeName:(NSString *)typeName icon:(UIImage *)icon
{
    OAIconTextDescCell* cell;
    cell = (OAIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:[OAIconTextDescCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextDescCell getCellIdentifier] owner:self options:nil];
        cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
        cell.textView.numberOfLines = 0;
    }
    if (cell)
    {
        [cell.textView setText:name];
        if (typeName.length == 0)
        {
            cell.descView.hidden = YES;
        }
        else
        {
            [cell.descView setText:typeName];
            cell.descView.hidden = NO;
        }
        [cell.iconView setImage:icon];
        cell.arrowIconView.image = [cell.arrowIconView.image imageFlippedForRightToLeftLayoutDirection];
    }
    if ([cell needsUpdateConstraints])
        [cell updateConstraints];
    return cell;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _dataGroups.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [OAPOISearchHelper getHeightForHeader];
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return section == _dataGroups.count - 1 ? [OAPOISearchHelper getHeightForFooter] : 0.01;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section < _dataGroups.count)
        return _dataGroups[section].count;
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    NSArray<OAQuickSearchListItem *> *dataArray = nil;
    if (indexPath.section < _dataGroups.count)
        dataArray = _dataGroups[indexPath.section];
    
    if (!dataArray || row >= dataArray.count)
        return nil;
    
    OAQuickSearchListItem *item = dataArray[indexPath.row];
    OASearchResult *res = [item getSearchResult];
    
    if (res)
    {
        switch (res.objectType)
        {
            case LOCATION:
            case PARTIAL_LOCATION:
            {
                OAPointDescCell* cell = [self getPointDescCell];
                if (cell)
                {
                    [cell.titleView setText:[item getName]];
                    cell.titleIcon.image = [[UIImage imageNamed:@"ic_action_world_globe"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                    [cell.descView setText:[OAQuickSearchListItem getTypeName:res]];
                    cell.openingHoursView.hidden = YES;
                    cell.timeIcon.hidden = YES;
                    
                    [self setCellDistanceDirection:cell item:item];
                }
                return cell;
            }
            case FAVORITE:
            {
                OAPointDescCell* cell = [self getPointDescCell];
                if (cell)
                {
                    const auto& favorite = res.favorite;
                    UIColor* color = [UIColor colorWithRed:favorite->getColor().r/255.0 green:favorite->getColor().g/255.0 blue:favorite->getColor().b/255.0 alpha:1.0];
                    
                    OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];

                    [cell.titleView setText:[item getName]];
                    cell.titleIcon.image = favCol.icon;
                    [cell.descView setText:[OAQuickSearchListItem getTypeName:res]];
                    cell.openingHoursView.hidden = YES;
                    cell.timeIcon.hidden = YES;
                    
                    [self setCellDistanceDirection:cell item:item];
                }
                return cell;
            }
            case WPT:
            {
                OAPointDescCell* cell = [self getPointDescCell];
                if (cell)
                {
                    [cell.titleView setText:[item getName]];
                    cell.titleIcon.image = [UIImage imageNamed:[OAQuickSearchListItem getIconName:res]];
                    [cell.descView setText:[OAQuickSearchListItem getTypeName:res]];
                    cell.openingHoursView.hidden = YES;
                    cell.timeIcon.hidden = YES;
                    
                    [self setCellDistanceDirection:cell item:item];
                }
                return cell;
            }
            case CITY:
            case VILLAGE:
            case POSTCODE:
            case STREET:
            case HOUSE:
            case STREET_INTERSECTION:
            {
                OAPointDescCell* cell = [self getPointDescCell];
                if (cell)
                {
                    OAAddress *address = (OAAddress *)res.object;
                    [cell.titleView setText:[item getName]];
                    cell.titleIcon.image = [address icon];
                    [cell.descView setText:[OAQuickSearchListItem getTypeName:res]];
                    cell.openingHoursView.hidden = YES;
                    cell.timeIcon.hidden = YES;
                    
                    [self setCellDistanceDirection:cell item:item];
                }
                return cell;
            }
            case POI:
            {
                OAPointDescCell* cell = [self getPointDescCell];
                if (cell)
                {
                    OAPOI *poi = (OAPOI *)res.object;
                    [cell.titleView setText:[item getName]];
                    cell.titleIcon.image = [poi icon];
                    [cell.descView setText:[OAQuickSearchListItem getTypeName:res]];
                    if (poi.hasOpeningHours)
                    {
                        [cell.openingHoursView setText:poi.openingHours];
                        cell.timeIcon.hidden = NO;
                        [cell updateOpeningTimeInfo];
                    }
                    else
                    {
                        cell.openingHoursView.hidden = YES;
                        cell.timeIcon.hidden = YES;
                    }
                    
                    [self setCellDistanceDirection:cell item:item];
                }
                return cell;
            }
            case RECENT_OBJ:
            {
                OAPointDescCell* cell = [self getPointDescCell];
                if (cell)
                {
                    OAHistoryItem* historyItem = (OAHistoryItem *)res.object;
                    [cell.titleView setText:[item getName]];
                    cell.titleIcon.image = historyItem.icon;
                    [cell.descView setText:[OAQuickSearchListItem getTypeName:res]];
                    cell.openingHoursView.hidden = YES;
                    cell.timeIcon.hidden = YES;
                    
                    [self setCellDistanceDirection:cell item:item];
                }
                return cell;
            }
            case POI_TYPE:
            {
                if ([res.object isKindOfClass:[OACustomSearchPoiFilter class]])
                {
                    OACustomSearchPoiFilter *filter = (OACustomSearchPoiFilter *) res.object;
                    NSString *name = [item getName];
                    UIImage *icon;
                    NSObject *res = [filter getIconResource];
                    if ([res isKindOfClass:[NSString class]])
                    {
                        NSString *iconName = (NSString *)res;
                        icon = [OAUtilities getMxIcon:iconName];
                    }
                    if (!icon)
                        icon = [OAUtilities getMxIcon:@"user_defined"];
                    
                    return [OAQuickSearchTableController getIconTextDescCell:name tableView:self.tableView typeName:@"" icon:icon];
                }
                else if ([res.object isKindOfClass:[OAPOIBaseType class]])
                {
                    NSString *name = [item getName];
                    NSString *typeName = [OAQuickSearchTableController applySynonyms:res];
                    UIImage *icon = [((OAPOIBaseType *)res.object) icon];
                    
                    return [OAQuickSearchTableController getIconTextDescCell:name tableView:self.tableView typeName:typeName icon:icon];
                }
                else if ([res.object isKindOfClass:[OAPOICategory class]])
                {
                    OAIconTextTableViewCell* cell;
                    cell = (OAIconTextTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
                    if (cell == nil)
                    {
                        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
                        cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
                    }
                    if (cell)
                    {
                        cell.contentView.backgroundColor = [UIColor whiteColor];
                        cell.arrowIconView.image = [UIImage imageNamed:@"menu_cell_pointer.png"];
                        cell.arrowIconView.image = [cell.arrowIconView.image imageFlippedForRightToLeftLayoutDirection];
                        [cell.textView setTextColor:[UIColor blackColor]];
                        [cell.textView setText:[item getName]];
                        [cell.iconView setImage:[((OAPOICategory *)res.object) icon]];
                    }
                    return cell;
                }
            }
            default:
                break;
        }
    }
    else
    {
        if ([item getType] == BUTTON)
        {
            OAIconButtonCell* cell;
            cell = (OAIconButtonCell *)[tableView dequeueReusableCellWithIdentifier:[OAIconButtonCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconButtonCell getCellIdentifier] owner:self options:nil];
                cell = (OAIconButtonCell *)[nib objectAtIndex:0];
            }
            
            if (cell)
            {
                OAQuickSearchButtonListItem *buttonItem = (OAQuickSearchButtonListItem *) item;
                cell.contentView.backgroundColor = [UIColor whiteColor];
                cell.arrowIconView.hidden = YES;
                [cell setImage:buttonItem.icon tint:YES];
                if ([buttonItem getName])
                    [cell.textView setText:[item getName]];
                else if ([buttonItem getAttributedName])
                    [cell.textView setAttributedText:[buttonItem getAttributedName]];
                else
                    [cell.textView setText:@""];
            }
            return cell;
        }
        else if ([item getType] == SEARCH_MORE)
        {
            OASearchMoreCell* cell;
            cell = (OASearchMoreCell *)[tableView dequeueReusableCellWithIdentifier:[OASearchMoreCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASearchMoreCell getCellIdentifier] owner:self options:nil];
                cell = (OASearchMoreCell *)[nib objectAtIndex:0];
            }
            cell.textView.text = [item getName];
            return cell;
        }
        else if ([item getType] == EMPTY_SEARCH)
        {
            OAEmptySearchCell* cell;
            cell = (OAEmptySearchCell *)[tableView dequeueReusableCellWithIdentifier:[OAEmptySearchCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAEmptySearchCell getCellIdentifier] owner:self options:nil];
                cell = (OAEmptySearchCell *)[nib objectAtIndex:0];
            }
            if (cell)
            {
                OAQuickSearchEmptyResultListItem *emptyResultItem = (OAQuickSearchEmptyResultListItem *) item;
                cell.titleView.text = emptyResultItem.title;
                cell.messageView.text = emptyResultItem.message;
            }
            return cell;
        }
        else if ([item getType] == HEADER)
        {
            OAMenuSimpleCell *cell;
            cell = (OAMenuSimpleCell *)[tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCell getCellIdentifier] owner:self options:nil];
                cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
            }
            
            if (cell)
            {
                [cell.textView setText:[item getName]];
                cell.descriptionView.hidden = YES;
            }
            return cell;
        }
    }
    return nil;
}

+ (NSString *) applySynonyms:(OASearchResult *)res
{
    NSString *typeName = [OAQuickSearchListItem getTypeName:res];
    OAPOIBaseType *basePoiType = (OAPOIBaseType *)res.object;
    NSArray<NSString *> *synonyms = [basePoiType.nameSynonyms componentsSeparatedByString:@";"];
    OANameStringMatcher *nm = [res.requiredSearchPhrase getMainUnknownNameStringMatcher];
    if (![res.requiredSearchPhrase isEmpty] && ![nm matches:basePoiType.nameLocalized])
    {
        if ([nm matches:basePoiType.nameLocalizedEN])
        {
            typeName = [NSString stringWithFormat:@"%@ (%@)", typeName, basePoiType.nameLocalizedEN];
        }
        else
        {
            for (NSString *syn in synonyms)
            {
                if ([nm matches:syn])
                {
                    typeName = [NSString stringWithFormat:@"%@ (%@)", typeName, syn];
                    break;
                }
            }
        }
    }
    return typeName;
}

#pragma mark - Table view delegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    NSArray<OAQuickSearchListItem *> *dataArray = nil;
    if (indexPath.section < _dataGroups.count)
        dataArray = _dataGroups[indexPath.section];
    
    if (dataArray && row < dataArray.count)
    {
        OAQuickSearchListItem *item = dataArray[row];
        return item && item.getType != HEADER && item.getType != EMPTY_SEARCH;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    NSArray<OAQuickSearchListItem *> *dataArray = nil;
    if (indexPath.section < _dataGroups.count)
        dataArray = _dataGroups[indexPath.section];

    if (dataArray && row < dataArray.count)
    {
        OAQuickSearchListItem *item = dataArray[row];
        if (item)
        {
            if ([item getType] == SEARCH_MORE)
            {
                ((OAQuickSearchMoreListItem *) item).onClickFunction(item);
            }
            else if ([item getType] == BUTTON)
            {
                ((OAQuickSearchButtonListItem *) item).onClickFunction(item);
            }
            else
            {
                OASearchResult *sr = [item getSearchResult];
                
                if (sr.objectType == POI
                    || sr.objectType == LOCATION
                    || sr.objectType == HOUSE
                    || sr.objectType == FAVORITE
                    || sr.objectType == RECENT_OBJ
                    || sr.objectType == WPT
                    || sr.objectType == STREET_INTERSECTION)
                {
                    [self showOnMap:sr searchType:self.searchType delegate:self.delegate];
                }
                else if (sr.objectType == PARTIAL_LOCATION)
                {
                    // nothing
                }
                else
                {
                    if (sr.objectType == CITY || sr.objectType == VILLAGE || sr.objectType == STREET)
                        _showResult = YES;
                    [self.delegate didSelectResult:[item getSearchResult]];
                }
            }
        }
    }    
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _decelerating = YES;
}

// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
        _decelerating = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _decelerating = NO;
}

@end
