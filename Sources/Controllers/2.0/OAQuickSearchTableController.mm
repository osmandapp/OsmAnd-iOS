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
#import "OACustomSearchButton.h"
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

#import "OAIconTextTableViewCell.h"
#import "OAIconTextExTableViewCell.h"
#import "OASearchMoreCell.h"
#import "OAPointDescCell.h"
#import "OAIconTextDescCell.h"
#import "OAIconButtonCell.h"

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
    NSMutableArray<OAQuickSearchListItem *> *_dataArray;
    BOOL _decelerating;
}

- (instancetype) initWithTableView:(UITableView *)tableView
{
    self = [super init];
    if (self)
    {
        _dataArray = [NSMutableArray array];
        _tableView = tableView;
        _tableView.delegate = self;
        _tableView.dataSource = self;
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
    for (OAQuickSearchListItem *item in _dataArray)
        [item setMapCenterCoordinate:mapCenterCoordinate];
}

- (void) resetMapCenterSearch
{
    _searchNearMapCenter = NO;
    for (OAQuickSearchListItem *item in _dataArray)
        [item resetMapCenterSearch];
}

- (void) updateData:(NSArray<OAQuickSearchListItem *> *)data  append:(BOOL)append
{
    _dataArray = [NSMutableArray arrayWithArray:data];
    if (self.searchNearMapCenter)
    {
        for (OAQuickSearchListItem *item in _dataArray)
            [item setMapCenterCoordinate:self.mapCenterCoordinate];
    }

    [_tableView reloadData];
    if (!append && _dataArray.count > 0)
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

- (void) addItem:(OAQuickSearchListItem *)item
{
    if (item)
        [_dataArray addObject:item];
}

+ (void) showOnMap:(OASearchResult *)searchResult delegate:(id<OAQuickSearchTableDelegate>)delegate
{
    if (searchResult.location)
    {
        switch (searchResult.objectType)
        {
            case POI:
            {
                [self.class goToPoint:(OAPOI *)searchResult.object];
                break;
            }
            case RECENT_OBJ:
            {
                OAHistoryItem *item = (OAHistoryItem *) searchResult.object;
                NSString *lang = [[searchResult.requiredSearchPhrase getSettings] getLang];
                BOOL transliterate = [[searchResult.requiredSearchPhrase getSettings] isTransliterate];
                [self.class showHistoryItemOnMap:item lang:lang transliterate:transliterate];
                break;
            }
            case FAVORITE:
            {
                OAFavoriteItem *fav = [[OAFavoriteItem alloc] init];
                fav.favorite = std::const_pointer_cast<OsmAnd::IFavoriteLocation>(searchResult.favorite);
                [[OARootViewController instance].mapPanel openTargetViewWithFavorite:fav pushed:NO];
                break;
            }
            case CITY:
            case STREET:
            {
                [[OARootViewController instance].mapPanel openTargetViewWithAddress:(OAAddress *)searchResult.object name:[OAQuickSearchListItem getName:searchResult] typeName:[OAQuickSearchListItem getTypeName:searchResult] pushed:NO];
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
                
                [[OARootViewController instance].mapPanel openTargetViewWithAddress:building name:name typeName:typeNameHouse pushed:NO];
                
                break;
            }
            case STREET_INTERSECTION:
            {
                OAStreetIntersection *streetIntersection = (OAStreetIntersection *)searchResult.object;
                NSString *typeNameIntersection = [OAQuickSearchListItem getTypeName:searchResult];
                if (typeNameIntersection.length == 0)
                    typeNameIntersection = nil;
                
                [[OARootViewController instance].mapPanel openTargetViewWithAddress:streetIntersection name:[OAQuickSearchListItem getName:searchResult] typeName:typeNameIntersection pushed:NO];

                break;
            }
            case LOCATION:
            {
                if (searchResult.location)
                    [self.class goToPoint:searchResult.location.coordinate.latitude longitude:searchResult.location.coordinate.longitude];
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
                    [[OARootViewController instance].mapPanel openTargetViewWithWpt:wptItem pushed:NO showFullMenu:NO];
                }
                break;
            }
            default:
                break;
        }
        
        //dialogFragment.hideToolbar();
        //dialogFragment.hide();
        
        if (delegate)
            [delegate didShowOnMap:searchResult];
        
        //dialogFragment.reloadHistory();
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 16.0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 16.0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    if (row < _dataArray.count)
    {
        OAQuickSearchListItem *item = _dataArray[row];
        CGSize size = [OAUtilities calculateTextBounds:[item getName] width:tableView.bounds.size.width - 59.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:14.0]];
        
        return 30.0 + size.height;
    }
    else
    {
        return 50.0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= _dataArray.count)
        return nil;
    
    OAQuickSearchListItem *item = _dataArray[indexPath.row];
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
                    cell.titleIcon.image = nil;
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
                    OAIconTextDescCell* cell;
                    cell = (OAIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconTextDescCell"];
                    if (cell == nil)
                    {
                        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextDescCell" owner:self options:nil];
                        cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
                    }
                    
                    if (cell)
                    {
                        OACustomSearchPoiFilter *filter = (OACustomSearchPoiFilter *) res.object;
                        UIImage *icon;
                        NSObject *res = [filter getIconResource];
                        if ([res isKindOfClass:[NSString class]])
                        {
                            NSString *iconName = (NSString *)res;
                            icon = [OAUtilities getMxIcon:iconName];
                        }
                        if (!icon)
                            icon = [OAUtilities getMxIcon:@"user_defined"];
                        
                        CGRect f = cell.textView.frame;
                        f.origin.y = 14.0;
                        cell.textView.frame = f;
                        
                        [cell.textView setText:[item getName]];
                        [cell.descView setText:@""];
                        [cell.iconView setImage:icon];
                    }
                    return cell;
                }
                else if ([res.object isKindOfClass:[OAPOIType class]])
                {
                    OAIconTextDescCell* cell;
                    cell = (OAIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconTextDescCell"];
                    if (cell == nil)
                    {
                        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextDescCell" owner:self options:nil];
                        cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
                    }
                    
                    if (cell)
                    {
                        NSString *typeName = [OAQuickSearchListItem getTypeName:res];
                        CGRect f = cell.textView.frame;
                        if (typeName.length == 0)
                            f.origin.y = 14.0;
                        else
                            f.origin.y = 8.0;
                        cell.textView.frame = f;
                        
                        [cell.textView setText:[item getName]];
                        [cell.descView setText:typeName];
                        [cell.iconView setImage:[((OAPOIType *)res.object) icon]];
                    }
                    return cell;
                }
                else if ([res.object isKindOfClass:[OAPOIFilter class]])
                {
                    OAIconTextDescCell* cell;
                    cell = (OAIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconTextDescCell"];
                    if (cell == nil)
                    {
                        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextDescCell" owner:self options:nil];
                        cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
                    }
                    
                    if (cell)
                    {
                        NSString *typeName = [OAQuickSearchListItem getTypeName:res];
                        CGRect f = cell.textView.frame;
                        if (typeName.length == 0)
                            f.origin.y = 14.0;
                        else
                            f.origin.y = 8.0;
                        cell.textView.frame = f;
                        
                        [cell.textView setText:[item getName]];
                        [cell.descView setText:typeName];
                        [cell.iconView setImage: [((OAPOIFilter *)res.object) icon]];
                    }
                    return cell;
                }
                else if ([res.object isKindOfClass:[OAPOICategory class]])
                {
                    OAIconTextTableViewCell* cell;
                    cell = (OAIconTextTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconTextTableViewCell"];
                    if (cell == nil)
                    {
                        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
                        cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
                    }
                    
                    if (cell)
                    {
                        cell.contentView.backgroundColor = [UIColor whiteColor];
                        cell.arrowIconView.image = [UIImage imageNamed:@"menu_cell_pointer.png"];
                        [cell.textView setTextColor:[UIColor blackColor]];
                        
                        CGRect f = cell.textView.frame;
                        f.origin.y = 14.0;
                        cell.textView.frame = f;
                        
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
        if ([item isKindOfClass:[OACustomSearchButton class]])
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
                cell.contentView.backgroundColor = [UIColor whiteColor];
                [cell setImage:[UIImage imageNamed:@"search_icon.png"] tint:YES];
                [cell.textView setText:[item getName]];
                [cell.iconView setImage: nil];
            }
            return cell;
        }
        else if ([item isKindOfClass:[OAQuickSearchMoreListItem class]])
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
    }
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int index = (int)indexPath.row;
    if (index < _dataArray.count)
    {
        OAQuickSearchListItem *item = _dataArray[index];
        if (item)
        {
            if ([item isKindOfClass:[OAQuickSearchMoreListItem class]])
            {
                ((OAQuickSearchMoreListItem *) item).onClickFunction(item);
            }
            else if ([item isKindOfClass:[OACustomSearchButton class]])
            {
                ((OACustomSearchButton *) item).onClickFunction(item);
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
                    [self.class showOnMap:sr delegate:self.delegate];
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
