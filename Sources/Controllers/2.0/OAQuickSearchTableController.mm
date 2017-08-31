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

#import "OAIconTextTableViewCell.h"
#import "OAIconTextExTableViewCell.h"
#import "OASearchMoreCell.h"
#import "OAPointDescCell.h"
#import "OAIconTextDescCell.h"
#import "OAIconButtonCell.h"
#import "OAHeaderCell.h"
#import "OAEmptySearchCell.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Search/AmenitiesByNameSearch.h>
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
        _tableView.separatorInset = UIEdgeInsetsMake(0, 51, 0, 0);
    }
    return self;
}

- (void) updateDistanceAndDirection
{
    if (!_decelerating)
        [self.tableView reloadData];
}

+ (CGPoint) showPinAtLatitude:(double)latitude longitude:(double)longitude
{
    const OsmAnd::LatLon latLon(latitude, longitude);
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    OAMapRendererView* mapRendererView = (OAMapRendererView*)mapVC.view;
    Point31 pos = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];
    [mapVC goToPosition:pos andZoom:kDefaultZoomOnShow animated:YES];
    [mapVC showContextPinMarker:latLon.latitude longitude:latLon.longitude animated:NO];
    
    CGPoint touchPoint = CGPointMake(mapRendererView.bounds.size.width / 2.0, mapRendererView.bounds.size.height / 2.0);
    touchPoint.x *= mapRendererView.contentScaleFactor;
    touchPoint.y *= mapRendererView.contentScaleFactor;
    return touchPoint;
}

+ (void) goToPoint:(double)latitude longitude:(double)longitude
{
    CGPoint touchPoint = [self.class showPinAtLatitude:latitude longitude:longitude];
    
    OAMapSymbol *symbol = [[OAMapSymbol alloc] init];
    symbol.type = OAMapSymbolLocation;
    symbol.touchPoint = CGPointMake(touchPoint.x, touchPoint.y);
    symbol.location = CLLocationCoordinate2DMake(latitude, longitude);
    symbol.poiType = [[OAPOILocationType alloc] init];
    symbol.centerMap = YES;
    [OAMapViewController postTargetNotification:symbol];
}

+ (void) goToPoint:(OAPOI *)poi
{
    CGPoint touchPoint = [self.class showPinAtLatitude:poi.latitude longitude:poi.longitude];
    
    OAMapSymbol *symbol = [OAMapViewController getMapSymbol:poi];
    symbol.touchPoint = CGPointMake(touchPoint.x, touchPoint.y);
    symbol.centerMap = YES;
    [OAMapViewController postTargetNotification:symbol];
}

+ (OAPOI *) findAmenity:(NSString *)name lat:(double)lat lon:(double)lon lang:(NSString *)lang transliterate:(BOOL)transliterate
{
    OsmAndAppInstance app = [OsmAndApp instance];

    OsmAnd::PointI pointI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    
    const std::shared_ptr<OsmAnd::AmenitiesByNameSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::AmenitiesByNameSearch::Criteria>(new OsmAnd::AmenitiesByNameSearch::Criteria);
    
    searchCriteria->name = QString::fromNSString(name);
    searchCriteria->bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(15, pointI);
    searchCriteria->xy31 = pointI;
    
    const auto& obfsCollection = app.resourcesManager->obfsCollection;
    const auto search = std::shared_ptr<const OsmAnd::AmenitiesByNameSearch>(new OsmAnd::AmenitiesByNameSearch(obfsCollection));

    std::shared_ptr<const OsmAnd::Amenity> amenity;

    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([self, &amenity]
                                                  (const OsmAnd::IQueryController* const controller)
                                                  {
                                                      return amenity != nullptr;
                                                  }));

    search->performSearch(*searchCriteria,
                          [self, &amenity]
                          (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                              amenity = ((OsmAnd::AmenitiesByNameSearch::ResultEntry&)resultEntry).amenity;
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
            if ([OAUtilities doublesEqualUpToDigits:5 source:latLon.latitude destination:item.latitude] &&
                [OAUtilities doublesEqualUpToDigits:5 source:latLon.longitude destination:item.longitude] && [item.name isEqualToString:point->getTitle().toNSString()])
            {
                OAFavoriteItem *fav = [[OAFavoriteItem alloc] init];
                fav.favorite = point;
                [[OARootViewController instance].mapPanel openTargetViewWithFavorite:fav pushed:NO];
                originFound = YES;
                break;
            }
        }
    }
    if (!originFound)
        [[OARootViewController instance].mapPanel openTargetViewWithHistoryItem:item pushed:NO showFullMenu:NO];
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

    _tableView.separatorInset = UIEdgeInsetsMake(0, 51, 0, 0);
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

+ (void) showOnMap:(OASearchResult *)searchResult searchType:(OAQuickSearchType)searchType delegate:(id<OAQuickSearchTableDelegate>)delegate
{
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
                else if (searchType == OAQuickSearchType::START_POINT || searchType == OAQuickSearchType::DESTINATION)
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
                else if (searchType == OAQuickSearchType::START_POINT || searchType == OAQuickSearchType::DESTINATION)
                {
                    latitude = item.latitude;
                    longitude = item.longitude;
                    pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION typeName:item.typeName name:item.name];
                }
                break;
            }
            case FAVORITE:
            {
                OAFavoriteItem *fav = [[OAFavoriteItem alloc] init];
                fav.favorite = std::const_pointer_cast<OsmAnd::IFavoriteLocation>(searchResult.favorite);
                if (searchType == OAQuickSearchType::REGULAR)
                {
                    [[OARootViewController instance].mapPanel openTargetViewWithFavorite:fav pushed:NO];
                }
                else if (searchType == OAQuickSearchType::START_POINT || searchType == OAQuickSearchType::DESTINATION)
                {
                    latitude = fav.favorite->getLatLon().latitude;
                    longitude = fav.favorite->getLatLon().longitude;
                    pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE name:fav.favorite->getTitle().toNSString()];
                }
                break;
            }
            case CITY:
            case STREET:
            {
                OAAddress *address = (OAAddress *)searchResult.object;
                if (searchType == OAQuickSearchType::REGULAR)
                {
                    [[OARootViewController instance].mapPanel openTargetViewWithAddress:address name:[OAQuickSearchListItem getName:searchResult] typeName:[OAQuickSearchListItem getTypeName:searchResult] pushed:NO];
                }
                else if (searchType == OAQuickSearchType::START_POINT || searchType == OAQuickSearchType::DESTINATION)
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
                    [[OARootViewController instance].mapPanel openTargetViewWithAddress:building name:name typeName:typeNameHouse pushed:NO];
                }
                else if (searchType == OAQuickSearchType::START_POINT || searchType == OAQuickSearchType::DESTINATION)
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
                    [[OARootViewController instance].mapPanel openTargetViewWithAddress:streetIntersection name:[OAQuickSearchListItem getName:searchResult] typeName:typeNameIntersection pushed:NO];
                }
                else if (searchType == OAQuickSearchType::START_POINT || searchType == OAQuickSearchType::DESTINATION)
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
                    else if (searchType == OAQuickSearchType::START_POINT || searchType == OAQuickSearchType::DESTINATION)
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
                        [[OARootViewController instance].mapPanel openTargetViewWithWpt:wptItem pushed:NO showFullMenu:NO];
                    }
                    else if (searchType == OAQuickSearchType::START_POINT || searchType == OAQuickSearchType::DESTINATION)
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
        
        if ((searchType == OAQuickSearchType::START_POINT || searchType == OAQuickSearchType::DESTINATION) && latitude != DBL_MAX)
        {
            [[OARootViewController instance].mapPanel setRouteTargetPoint:searchType == OAQuickSearchType::DESTINATION latitude:latitude longitude:longitude pointDescription:pointDescription];
        }
    }
}

- (OAPointDescCell *) getPointDescCell
{
    static NSString* const reusableIdentifierPoint = @"OAPointDescCell";
    
    OAPointDescCell* cell;
    cell = (OAPointDescCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPointDescCell" owner:self options:nil];
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
        CGRect frame = cell.distanceView.frame;
        frame.origin.x = 51.0;
        cell.distanceView.frame = frame;
    }
    else
    {
        cell.directionImageView.hidden = NO;
        CGRect frame = cell.distanceView.frame;
        frame.origin.x = 69.0;
        cell.distanceView.frame = frame;
        cell.directionImageView.transform = CGAffineTransformMakeRotation(distDir.direction);
    }
}

- (OAIconTextDescCell *) getIconTextDescCell:(NSString *)name typeName:(NSString *)typeName icon:(UIImage *)icon
{
    OAIconTextDescCell* cell;
    cell = (OAIconTextDescCell *)[self.tableView dequeueReusableCellWithIdentifier:@"OAIconTextDescCell"];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextDescCell" owner:self options:nil];
        cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
        cell.textView.numberOfLines = 0;
        cell.textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    
    if (cell)
    {
        CGRect f = cell.textView.frame;
        if (typeName.length == 0)
        {
            f.origin.y = 0.0;
            f.size.height = cell.frame.size.height;
        }
        else
        {
            f.origin.y = 8.0;
            f.size.height = cell.frame.size.height - 30.0;
        }
        cell.textView.frame = f;
        
        [cell.textView setText:name];
        [cell.descView setText:typeName];
        [cell.iconView setImage:icon];
    }
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

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    NSArray<OAQuickSearchListItem *> *dataArray = nil;
    if (indexPath.section < _dataGroups.count)
        dataArray = _dataGroups[indexPath.section];

    if (dataArray && row < dataArray.count)
    {
        OAQuickSearchListItem *item = dataArray[row];
        switch ([item getType])
        {
            case HEADER:
            {
                CGSize size = [OAUtilities calculateTextBounds:[item getName] width:tableView.bounds.size.width - 59.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:14.0]];
                return 24.0 + size.height;
            }
            case BUTTON:
            {
                OAQuickSearchButtonListItem *btnItem = (OAQuickSearchButtonListItem *) item;
                NSString *text = [btnItem getAttributedName] ? [btnItem getAttributedName].string : [btnItem getName];
                CGSize size = [OAUtilities calculateTextBounds:text width:tableView.bounds.size.width - 59.0 font:[UIFont fontWithName:@"AvenirNext-Medium" size:14.0]];
                return 30.0 + size.height;
            }
            case EMPTY_SEARCH:
            {
                OAQuickSearchEmptyResultListItem *emptyResultItem = (OAQuickSearchEmptyResultListItem *) item;
                return [OAEmptySearchCell getHeightWithTitle:emptyResultItem.title message:emptyResultItem.message cellWidth:tableView.bounds.size.width];
            }
            default:
            {
                CGSize size;
                OASearchResult *sr = [item getSearchResult];
                if (sr && sr.objectType == POI_TYPE)
                {
                    if ([sr.object isKindOfClass:[OAPOICategory class]])
                    {
                        size = [OAUtilities calculateTextBounds:[item getName] width:tableView.bounds.size.width - 87.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:16.0]];
                    }
                    else
                    {
                        size = [OAUtilities calculateTextBounds:[item getName] width:tableView.bounds.size.width - 87.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:15.0]];
                    }
                }
                else
                {
                    size = [OAUtilities calculateTextBounds:[item getName] width:tableView.bounds.size.width - 59.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:14.0]];
                }
                return 30.0 + size.height;
            }
        }
    }
    else
    {
        return 50.0;
    }
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
                    [cell updateDescVisibility];
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
                    [cell updateDescVisibility];
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
                    [cell updateDescVisibility];
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
                    [cell updateDescVisibility];
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
                    [cell updateDescVisibility];
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
                    [cell updateDescVisibility];
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
                    
                    return [self getIconTextDescCell:name typeName:@"" icon:icon];
                }
                else if ([res.object isKindOfClass:[OAPOIType class]])
                {
                    NSString *name = [item getName];
                    NSString *typeName = [OAQuickSearchListItem getTypeName:res];
                    UIImage *icon = [((OAPOIType *)res.object) icon];
                    
                    return [self getIconTextDescCell:name typeName:typeName icon:icon];
                }
                else if ([res.object isKindOfClass:[OAPOIFilter class]])
                {
                    NSString *name = [item getName];
                    NSString *typeName = [OAQuickSearchListItem getTypeName:res];
                    UIImage *icon = [((OAPOIFilter *)res.object) icon];
                    
                    return [self getIconTextDescCell:name typeName:typeName icon:icon];
                }
                else if ([res.object isKindOfClass:[OAPOICategory class]])
                {
                    OAIconTextTableViewCell* cell;
                    cell = (OAIconTextTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconTextTableViewCell"];
                    if (cell == nil)
                    {
                        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
                        cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
                        cell.textView.numberOfLines = 0;
                        CGRect f = cell.textView.frame;
                        f.origin.y = 0.0;
                        f.size.height = cell.frame.size.height;
                        cell.textView.frame = f;
                        cell.textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
                    }
                    
                    if (cell)
                    {
                        cell.contentView.backgroundColor = [UIColor whiteColor];
                        cell.arrowIconView.image = [UIImage imageNamed:@"menu_cell_pointer.png"];
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
            cell = (OAIconButtonCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconButtonCell"];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconButtonCell" owner:self options:nil];
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
            cell = (OASearchMoreCell *)[tableView dequeueReusableCellWithIdentifier:@"OASearchMoreCell"];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASearchMoreCell" owner:self options:nil];
                cell = (OASearchMoreCell *)[nib objectAtIndex:0];
            }
            cell.textView.text = [item getName];
            return cell;
        }
        else if ([item getType] == EMPTY_SEARCH)
        {
            OAEmptySearchCell* cell;
            cell = (OAEmptySearchCell *)[tableView dequeueReusableCellWithIdentifier:@"OAEmptySearchCell"];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAEmptySearchCell" owner:self options:nil];
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
            OAHeaderCell *cell;
            cell = (OAHeaderCell *)[tableView dequeueReusableCellWithIdentifier:@"OAHeaderCell"];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAHeaderCell" owner:self options:nil];
                cell = (OAHeaderCell *)[nib objectAtIndex:0];
            }
            
            if (cell)
            {
                cell.contentView.backgroundColor = [UIColor whiteColor];
                [cell.textView setText:[item getName]];
                [cell setImage:nil tint:NO];
            }
            return cell;
        }
    }
    return nil;
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
                    [self.class showOnMap:sr searchType:self.searchType delegate:self.delegate];
                }
                else if (sr.objectType == PARTIAL_LOCATION)
                {
                    // nothing
                }
                else
                {
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
