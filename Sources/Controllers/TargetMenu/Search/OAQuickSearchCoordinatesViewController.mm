//
//  OAQuickSearchCoordinatesViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 25.08.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAQuickSearchCoordinatesViewController.h"
#import "Localization.h"
#import "OAValueTableViewCell.h"
#import "OAInputTableViewCell.h"
#import "OAQuickSearchCoordinateFormatsViewController.h"
#import "OAAppSettings.h"
#import "OAObservable.h"
#import "OsmAndApp.h"
#import "OALocationServices.h"
#import "OAWorldRegion.h"
#import "OAPointDescription.h"
#import "OALocationConvert.h"
#import "OALocationParser.h"
#import "OAMapUtils.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OANameStringMatcher.h"
#import "OAPOIHelper.h"
#import "OAPOI.h"
#import "OAQuickSearchResultTableViewCell.h"
#import "OAAutoObserverProxy.h"
#import "OAQuickSearchHelper.h"
#import "OASearchResult.h"
#import "OASearchUICore.h"
#import "OASearchSettings.h"
#import "OAMapLayers.h"
#import "OAOsmAndFormatter.h"
#import "OAUtilities.h"
#import "OANativeUtilities.h"
#import "OAHistoryItem.h"
#import "OAHistoryHelper.h"
#import "OAQuickSearchListItem.h"
#import "OASearchResult.h"
#import "OASearchCoreFactory.h"
#import "QuadRect.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAnd_Maps-Swift.h"
#import <OsmAndCore/Utilities.h>

#include <GeographicLib/GeoCoords.hpp>
#include <GeographicLib/MGRS.hpp>

#define kSearchCityLimit 500
#define kHintBarHeight 44
#define kMaxEastingValue 833360
#define kMaxNorthingValue 9300000
#define kUtmZoneMaxNumber 60
#define kMaxTexFieldSymbolsCount 30
#define kEstimatedCellHeight 48.0


typedef NS_ENUM(NSInteger, EOAQuickSearchCoordinatesSection)
{
    EOAQuickSearchCoordinatesSectionControls = 0,
    EOAQuickSearchCoordinatesSectionSearchResult
};

typedef NS_ENUM(NSInteger, EOAQuickSearchCoordinatesTextField)
{
    EOAQuickSearchCoordinatesTextFieldLat = 0,
    EOAQuickSearchCoordinatesTextFieldLon,
    EOAQuickSearchCoordinatesTextFieldNorthing,
    EOAQuickSearchCoordinatesTextFieldEasting,
    EOAQuickSearchCoordinatesTextFieldZone,
    EOAQuickSearchCoordinatesTextFieldOlc,
    EOAQuickSearchCoordinatesTextFieldMgrs
};


@interface OAQuickSearchCoordinatesViewController() <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, OAQuickSearchCoordinateFormatsDelegate, OAPOISearchDelegate>

@property (strong, nonatomic) IBOutlet UIView *toolbarView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak) UITextView *tagTextView;

@end

@implementation OAQuickSearchCoordinatesViewController
{
    OsmAndAppInstance _app;
    double _quickSearchCoordsLattitude;
    double _quickSearchCoordsLongitude;
    CLLocation *_currentLatLon;
    CLLocation *_additionalUtmLatLon;
    NSInteger _currentFormat;
    NSArray *_controlsSectionData;
    NSArray *_searchResultSectionData;
    NSString *_latStr;
    NSString *_lonStr;
    NSString *_northingStr;
    NSString *_eastingStr;
    NSString *_zoneStr;
    NSString *_olcStr;
    NSString *_mgrsStr;
    NSString *_formatStr;
    
    CLLocation *_searchLocation;
    NSString *_region;
    NSTimeInterval _lastUpdate;
    NSString *_distanceString;
    NSNumber *_direction;
    BOOL _isOlcCitySearchRunning;
    
    UITextField *_currentEditingTextField;
    BOOL _shouldHideHintBar;
    
    NSMutableArray<OAPOI *> *_olcCities;
    NSString *_olcSearchingCity;
    NSString *_olcSearchingCode;
}

- (instancetype) initWithLat:(double)lat lon:(double)lon
{
    self = [super initWithNibName:@"OAQuickSearchCoordinatesViewController" bundle:nil];
    if (self)
    {
        _quickSearchCoordsLattitude = lat;
        _quickSearchCoordsLongitude = lon;
        _currentFormat = 0;
        _app = [OsmAndApp instance];
    }
    return self;
}

- (void)registerObservers
{
    OsmAndAppInstance app = [OsmAndApp instance];
    [self addObserver:[[OAAutoObserverProxy alloc] initWith:self
                                                withHandler:@selector(updateDistanceAndDirection)
                                                 andObserve:app.locationServices.updateLocationObserver]];
    [self addObserver:[[OAAutoObserverProxy alloc] initWith:self
                                                withHandler:@selector(updateDistanceAndDirection)
                                                 andObserve:app.locationServices.updateHeadingObserver]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self configureNavigationBar];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = [UIColor colorNamed:ACColorNameCustomSeparator];

    self.navigationItem.title = OALocalizedString(@"coords_search");
    
    _toolbarView.frame = CGRectMake(0, DeviceScreenHeight, self.view.frame.size.width, kHintBarHeight);
    
    _currentFormat = [OAAppSettings.sharedManager.settingGeoFormat get];
    if (!isnan(_quickSearchCoordsLattitude) && !isnan(_quickSearchCoordsLongitude))
    {
        _currentLatLon = [[CLLocation alloc] initWithLatitude:_quickSearchCoordsLattitude longitude:_quickSearchCoordsLongitude];
        [self applyFormat:_currentFormat forceApply:YES];
    }
    
    [self generateData];
}

- (void) configureNavigationBar
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = self.tableView.backgroundColor;
    appearance.shadowColor = [UIColor colorNamed:ACColorNameCustomSeparator];
    appearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorPrimary]
    };
    UINavigationBarAppearance *blurAppearance = [[UINavigationBarAppearance alloc] init];
    
    self.navigationController.navigationBar.standardAppearance = blurAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationController.navigationBar.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"shared_string_back") style:UIBarButtonItemStylePlain target:self action:@selector(onLeftNavbarButtonPressed)];
    [self.navigationController.navigationBar.topItem setLeftBarButtonItem:backButton animated:YES];
}

- (void) generateData
{
    [self updateControllsSectionCells];
    [self parseLocation];
}

- (void) updateControllsSectionCells
{
    NSMutableArray *result = [NSMutableArray array];
    
    [result addObject:@{
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"coords_format"),
        @"value" : _formatStr,
    }];
    
    if (_currentFormat == MAP_GEO_OLC_FORMAT)
    {
        [result addObject:@{
            @"type" : [OAInputTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"navigate_point_olc_short"),
            @"value" : _olcStr,
            @"tag" : @(EOAQuickSearchCoordinatesTextFieldOlc),
        }];
    }
    else if (_currentFormat == MAP_GEO_UTM_FORMAT)
    {
        [result addObject:@{
            @"type" : [OAInputTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"navigate_point_zone"),
            @"value" : _zoneStr,
            @"tag" : @(EOAQuickSearchCoordinatesTextFieldZone),
        }];
        [result addObject:@{
            @"type" : [OAInputTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"navigate_point_easting"),
            @"value" : _eastingStr,
            @"tag" : @(EOAQuickSearchCoordinatesTextFieldEasting),
        }];
        [result addObject:@{
            @"type" : [OAInputTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"navigate_point_northing"),
            @"value" : _northingStr,
            @"tag" : @(EOAQuickSearchCoordinatesTextFieldNorthing),
        }];
    }
    else if (_currentFormat == MAP_GEO_MGRS_FORMAT)
    {
        [result addObject:@{
            @"type" : [OAInputTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"navigate_point_mgrs"),
            @"value" : _mgrsStr,
            @"tag" : @(EOAQuickSearchCoordinatesTextFieldMgrs),
        }];
    }
    else
    {
        [result addObject:@{
            @"type" : [OAInputTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"navigate_point_latitude"),
            @"value" : _latStr,
            @"tag" : @(EOAQuickSearchCoordinatesTextFieldLat),
        }];
        
        [result addObject:@{
            @"type" : [OAInputTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"navigate_point_longitude"),
            @"value" : _lonStr,
            @"tag" : @(EOAQuickSearchCoordinatesTextFieldLon),
        }];
    }
    
    _controlsSectionData = [NSArray arrayWithArray:result];
    
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:EOAQuickSearchCoordinatesSectionControls] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) updateLocationCell:(CLLocation *)latLon
{
    if (_isOlcCitySearchRunning)
    {
        _searchResultSectionData = @[];
    }
    else if (!latLon)
    {
        _searchResultSectionData = @[ @{
            @"type" : [OAQuickSearchResultTableViewCell getCellIdentifier],
            @"isErrorCell" : @YES
        }];
    }
    else
    {
        NSMutableArray *result = [NSMutableArray new];
        [result addObject:[self getLocationData:latLon]];
        if (_additionalUtmLatLon)
            [result addObject:[self getLocationData:_additionalUtmLatLon]];
        
        _searchResultSectionData = [NSArray arrayWithArray:result];
    }
    
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:EOAQuickSearchCoordinatesSectionSearchResult] withRowAnimation:UITableViewRowAnimationNone];
}

- (NSDictionary *) getLocationData:(CLLocation *)location
{
    NSString *title = [OAPointDescription getLocationNamePlain:location.coordinate.latitude lon:location.coordinate.longitude];
    NSString *countryName = [_app.worldRegion getCountryNameAtLat:location.coordinate.latitude lon:location.coordinate.longitude];
    NSString *subTitle = countryName ?: OALocalizedString(@"shared_string_location");
    
    return @{
        @"type" : [OAQuickSearchResultTableViewCell getCellIdentifier],
        @"isErrorCell" : @NO,
        @"title" : subTitle,
        @"direction" : _direction,
        @"distance" : _distanceString,
        @"coordinates" : title,
        @"location" : location
    };
}

#pragma mark - OAPOISearchDelegate

- (void) poiFound:(OAPOI *)poi
{
    if (!_olcCities)
        _olcCities = [NSMutableArray array];
    [_olcCities addObject:poi];
}

#pragma mark - Coordinates processing

- (CLLocation *) getDisplayingCoordinate
{
    return _searchLocation ? _searchLocation : [[OARootViewController instance].mapPanel.mapViewController getMapLocation];
}

- (BOOL) applyFormat:(NSInteger)format forceApply:(BOOL)forceApply
{
   if (_currentFormat != format || forceApply)
   {
       NSInteger prevFormat = _currentFormat;
       _currentFormat = format;
       _formatStr = [OAPointDescription formatToHumanString:_currentFormat];
       
       CLLocation *latLon = [self getDisplayingCoordinate];
       
       if (_currentFormat == MAP_GEO_UTM_FORMAT)
       {
           if (latLon)
           {
               GeographicLib::GeoCoords pnt(latLon.coordinate.latitude, latLon.coordinate.longitude);
               _zoneStr = [NSString stringWithFormat:@"%i%@", pnt.Zone(), [OALocationConvert getUTMLetterDesignator:latLon.coordinate.latitude]];
               _northingStr = [NSString stringWithFormat:@"%i", int(round(pnt.Northing()))];
               _eastingStr = [NSString stringWithFormat:@"%i", int(round(pnt.Easting()))];
           }
           else if (prevFormat == MAP_GEO_OLC_FORMAT)
           {
               _zoneStr = _olcStr;
               _northingStr = @"";
               _eastingStr = @"";
           }
           else if (prevFormat == MAP_GEO_MGRS_FORMAT)
           {
               _zoneStr = _mgrsStr;
               _northingStr = @"";
               _eastingStr = @"";
           }
           else
           {
               _zoneStr = _latStr;
               _northingStr = @"";
               _eastingStr = @"";
           }
       }
       else if (_currentFormat == MAP_GEO_OLC_FORMAT)
       {
           if (latLon)
           {
               _olcStr = [OALocationConvert getLocationOlcName:latLon.coordinate.latitude lon:latLon.coordinate.longitude];
           }
           else if (prevFormat == MAP_GEO_UTM_FORMAT)
           {
               _olcStr = _zoneStr;
           }
           else if (prevFormat == MAP_GEO_MGRS_FORMAT)
           {
               _olcStr = _mgrsStr;
           }
           else
           {
               _olcStr = _latStr;
           }
       }
       else if (_currentFormat == MAP_GEO_MGRS_FORMAT)
       {
           if (latLon)
           {
               _mgrsStr = [OALocationConvert getMgrsCoordinateString:latLon.coordinate.latitude lon:latLon.coordinate.longitude];
           }
           else if (prevFormat == MAP_GEO_UTM_FORMAT)
           {
               _mgrsStr = _zoneStr;
           }
           else if (prevFormat == MAP_GEO_OLC_FORMAT)
           {
               _mgrsStr = _olcStr;
           }
           else
           {
               _mgrsStr = _latStr;
           }
       }
       else
       {
           if (latLon)
           {
               _latStr = [OALocationConvert convert:[OAMapUtils checkLatitude:latLon.coordinate.latitude] outputType:_currentFormat];
               _lonStr = [OALocationConvert convert:[OAMapUtils checkLongitude:latLon.coordinate.longitude] outputType:_currentFormat];
           }
           else if (prevFormat == MAP_GEO_UTM_FORMAT)
           {
               _latStr = _zoneStr;
               _lonStr = @"";
           }
           else if (prevFormat == MAP_GEO_OLC_FORMAT)
           {
               _latStr = _olcStr;
               _lonStr = @"";
           }
           else if (prevFormat == MAP_GEO_MGRS_FORMAT)
           {
               _latStr = _mgrsStr;
               _lonStr = @"";
           }
       }
       return latLon;
   }
   else
   {
       return NO;
   }
}

- (void)updateResults:(CLLocation *)additionalLoc loc:(CLLocation *)loc {
    dispatch_async(dispatch_get_main_queue(), ^{
        _searchLocation = loc;
        _additionalUtmLatLon = additionalLoc;
        [self updateDistanceAndDirection:YES];
    });
}

- (void) parseLocation
{
    if (_isOlcCitySearchRunning)
    {
        _isOlcCitySearchRunning = NO;
        [self updateDistanceAndDirection:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view removeSpinner];
        });
    }
    CLLocation *loc = nil;
    CLLocation *additionalLoc = nil;
    try
    {
        if (_currentFormat == MAP_GEO_UTM_FORMAT)
        {
            if ([self isValidValueInField:EOAQuickSearchCoordinatesTextFieldNorthing] && [self isValidValueInField:EOAQuickSearchCoordinatesTextFieldEasting] && [self isValidValueInField:EOAQuickSearchCoordinatesTextFieldZone])
            {
                double northing = [self parseDoubleFromString:_northingStr];
                double easting = [self parseDoubleFromString:_eastingStr];
                NSString *zone = [_zoneStr trim];
                int zoneNumber = [self parseIntFromString:[zone substringToIndex:zone.length - 1]];
                NSString *zoneLetter = [zone substringFromIndex:zone.length - 1];
                
                NSArray<CLLocation *> *locations = [self parseUtmLocations:northing easting:easting zoneNumber:zoneNumber zoneLetter:zoneLetter];
                loc = locations[0];
                
                CLLocation *secondLocation;
                if (locations.count > 1)
                    secondLocation = locations[1];
                
                if (!loc || (secondLocation && ![OAUtilities isCoordEqual:loc.coordinate.latitude srcLon:loc.coordinate.longitude destLat:secondLocation.coordinate.latitude destLon:secondLocation.coordinate.longitude upToDigits:6]))
                    additionalLoc = locations[1];
            }
        }
        else if (_currentFormat == MAP_GEO_OLC_FORMAT)
        {
            if ([self isValidValueInField:EOAQuickSearchCoordinatesTextFieldOlc])
                loc = [self parseOlcCode:_olcStr];
        }
        else if (_currentFormat == MAP_GEO_MGRS_FORMAT)
        {
            if ([self isValidValueInField:EOAQuickSearchCoordinatesTextFieldMgrs])
                loc = [self parseMgrsString:_mgrsStr];
        }
        else
        {
            if ([self isValidValueInField:EOAQuickSearchCoordinatesTextFieldLat] && [self isValidValueInField:EOAQuickSearchCoordinatesTextFieldLon])
            {
                double lat = [OALocationConvert convert:_latStr];
                double lon = [OALocationConvert convert:_lonStr];
                if (!isnan(lat) && !isnan(lon))
                    loc = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
            }
        }
    }
    catch(GeographicLib::GeographicErr err)
    {
        [self updateResults:additionalLoc loc:loc];
    }
    [self updateResults:additionalLoc loc:loc];
}

- (BOOL) isValidValueInField:(NSInteger)field
{
    if (field == EOAQuickSearchCoordinatesTextFieldLat || field == EOAQuickSearchCoordinatesTextFieldLon)
    {
        NSString *value = field == EOAQuickSearchCoordinatesTextFieldLat ? _latStr : _lonStr;
        value = [value trim];
        
        if (value.length == 0)
            return NO;
        
        if ([value rangeOfCharacterFromSet: [[NSCharacterSet characterSetWithCharactersInString:@"0123456789:.-"] invertedSet] ].location != NSNotFound)
            return NO;
        
        NSUInteger minusesCount = [[value componentsSeparatedByString:@"-"] count] - 1;
        if (minusesCount > 1)
            return NO;
        NSUInteger dotsCount = [[value componentsSeparatedByString:@"."] count] - 1;
        if (dotsCount > 1)
            return NO;
        NSUInteger colonsCount = [[value componentsSeparatedByString:@":"] count] - 1;
        if (_currentFormat == FORMAT_DEGREES && colonsCount > 0)
            return NO;
        else if (_currentFormat == FORMAT_MINUTES && colonsCount != 1)
            return NO;
        else if (_currentFormat == FORMAT_SECONDS && colonsCount != 2)
            return NO;
        
        if (_currentFormat == FORMAT_DEGREES)
        {
            double number = [value doubleValue];
            if (isnan(number) || abs(number) > 180)
                return NO;
        }
        else
        {
            NSString *firstPart = [value componentsSeparatedByString:@":"].firstObject;
            if (firstPart)
            {
                NSInteger number = [value integerValue];
                if (isnan(number) || abs(number) > 180)
                    return NO;
            }
        }
    }
    else if (field == EOAQuickSearchCoordinatesTextFieldEasting || field == EOAQuickSearchCoordinatesTextFieldNorthing)
    {
        NSString *value = field == EOAQuickSearchCoordinatesTextFieldEasting ? _eastingStr : _northingStr;
        if ([value trim].length == 0)
            return NO;
        if ([value rangeOfCharacterFromSet: [[NSCharacterSet characterSetWithCharactersInString:@".0123456789"] invertedSet] ].location != NSNotFound)
            return NO;
        NSUInteger dotsCount = [[value componentsSeparatedByString:@"."] count] - 1;
        if (dotsCount > 1)
            return NO;
        if (field == EOAQuickSearchCoordinatesTextFieldEasting && value.intValue >= kMaxEastingValue)
            return NO;
        if (field == EOAQuickSearchCoordinatesTextFieldNorthing && value.intValue >= kMaxNorthingValue)
            return NO;
    }
    else if (field == EOAQuickSearchCoordinatesTextFieldZone)
    {
        NSString *value = _zoneStr.lowerCase;
        if (value.length == 0 || value.length > 3)
            return NO;
        NSString *numberPart = [value substringToIndex:value.length - 1];
        if ([numberPart trim].length == 0)
            return NO;
        if ([numberPart rangeOfCharacterFromSet: [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet] ].location != NSNotFound)
            return NO;
        if ([numberPart intValue] == 0 || [numberPart intValue] > kUtmZoneMaxNumber)
            return NO;
        
        NSString *textPart = [value substringFromIndex:value.length - 1];
        if ([textPart trim].length == 0)
            return NO;
        if ([textPart rangeOfCharacterFromSet: [[NSCharacterSet characterSetWithCharactersInString:@"cdefghjklmnpqrstuvwx"] invertedSet] ].location != NSNotFound)
            return NO;
    }
    else if (field == EOAQuickSearchCoordinatesTextFieldOlc)
    {
        NSString *value = _olcStr.lowerCase;
        if (value.length == 0)
            return NO;
    }
    else if (field == EOAQuickSearchCoordinatesTextFieldMgrs)
    {
        NSString *value = _mgrsStr.lowerCase;
        if (value.length == 0)
            return NO;
    }
    
    return YES;
}

- (NSArray<CLLocation *> *)parseUtmLocations:(double)northing easting:(double)easting zoneNumber:(int)zoneNumber zoneLetter:(NSString *)zoneLetter
{
    CLLocation *first = [self parseZonedUtmPoint:northing easting:easting zoneNumber:zoneNumber zoneLetter:zoneLetter];
    CLLocation *second = [self parseUtmPoint:northing easting:easting zoneNumber:zoneNumber zoneLetter:zoneLetter];
    
    NSMutableArray*result = [NSMutableArray new];
    if (first)
        [result addObject:first];
    if (second)
        [result addObject:second];
    return [NSArray arrayWithArray:result];
}

- (CLLocation *) parseZonedUtmPoint:(double)northing easting:(double)easting zoneNumber:(int)zoneNumber zoneLetter:(NSString *)zoneLetter
{
    NSString *checkedZoneLetter = [self mgrsZoneToUTMZone:zoneLetter];
    if (!checkedZoneLetter)
        return nil;
    BOOL isNorthernHemisphere = [[checkedZoneLetter upperCase] isEqualToString:@"N"];
    GeographicLib::GeoCoords upoint(zoneNumber, isNorthernHemisphere, easting, northing);
    return [[CLLocation alloc] initWithLatitude:upoint.Latitude() longitude:upoint.Longitude()];
}

- (CLLocation *) parseUtmPoint:(double)northing easting:(double)easting zoneNumber:(int)zoneNumber zoneLetter:(NSString *)zoneLetter
{
    NSString *checkedZoneLetter = [self checkZone:zoneLetter];
    if (!checkedZoneLetter)
        return nil;
    BOOL isNorthernHemisphere = [[checkedZoneLetter upperCase] isEqualToString:@"N"];
    GeographicLib::GeoCoords upoint(zoneNumber, isNorthernHemisphere, easting, northing);
    return [[CLLocation alloc] initWithLatitude:upoint.Latitude() longitude:upoint.Longitude()];
}

- (NSString *) checkZone:(NSString *)zone
{
    if (![[zone upperCase] isEqualToString:@"N"] && ![[zone upperCase] isEqualToString:@"S"])
        return nil;
    return zone;
}

- (NSString *) mgrsZoneToUTMZone:(NSString *)mgrsZone
{
    char zone = [mgrsZone.upperCase characterAtIndex:0];
    if (zone <= 'A' || zone == 'B' || zone == 'Y' || zone >= 'Z' || zone == 'I' || zone == 'O')
        return nil;
    return zone >= 'N' ? @"N" : @"S";
}

- (CLLocation *) parseMgrsString:(NSString *)mgrsString
{
    CLLocation *loc = nil;
    //get rid of all the whitespaces
    NSArray<NSString *> *mgrsSplit = [mgrsString componentsSeparatedByString:@" "];
    NSMutableString *mgrsStr = [NSMutableString stringWithString:@""];
    for (NSString *i in mgrsSplit)
        [mgrsStr appendString:i];
    
    if (mgrsStr.length > 2
           && ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[mgrsStr characterAtIndex:0]]
                || [mgrsStr characterAtIndex:0] == 'A' || [mgrsStr characterAtIndex:0] == 'a'
                || [mgrsStr characterAtIndex:0] == 'B' || [mgrsStr characterAtIndex:0] == 'b'
                || [mgrsStr characterAtIndex:0] == 'Y' || [mgrsStr characterAtIndex:0] == 'y'
                || [mgrsStr characterAtIndex:0] == 'Z' || [mgrsStr characterAtIndex:0] == 'z'
                )
           )
    {
        try
        {
            int zone;
            bool northp;
            double x;
            double y;
            int prec;
            GeographicLib::MGRS::Reverse([mgrsStr UTF8String], zone, northp, x, y, prec, false);
            
            GeographicLib::GeoCoords mgrsPoint(zone, northp, x, y);
            loc = [[CLLocation alloc] initWithLatitude:mgrsPoint.Latitude() longitude:mgrsPoint.Longitude()];
        }
        catch(GeographicLib::GeographicErr err)
        {
            //input was not a valid MGRS string
            //loc stays nil
        }
    }
    else
    {
        //mgrsString is already known invalid
        //loc stays nil
    }
    return loc;
    
    
}

+ (BOOL) isValidMgrsString:(NSString *)s
{
    if (s.length < 3
        || !([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[s characterAtIndex:0]]
             || [s characterAtIndex:0] == 'A' || [s characterAtIndex:0] == 'a'
             || [s characterAtIndex:0] == 'B' || [s characterAtIndex:0] == 'b'
             || [s characterAtIndex:0] == 'Y' || [s characterAtIndex:0] == 'y'
             || [s characterAtIndex:0] == 'Z' || [s characterAtIndex:0] == 'z'
             )
        )
    {
        return NO;
    }
    return YES;
}

- (CLLocation *) parseOlcCode:(NSString *)olcText
{
    CLLocation *loc = nil;
    _olcSearchingCity = @"";
    NSArray<NSString *> *olcTextParts = [olcText componentsSeparatedByString:@" "];
    if (olcTextParts.count > 1)
    {
        _olcSearchingCode = olcTextParts[0];
        _olcSearchingCity = [olcText substringFromIndex:_olcSearchingCode.length + 1];
    }
    else
    {
        _olcSearchingCode = olcText;
    }
    OLCArea *codeArea = nil;
    if ([OLCConverter isFullCode:_olcSearchingCode])
    {
        codeArea = [OLCConverter decode:_olcSearchingCode];
    }
    else if ([OLCConverter isShortCode:_olcSearchingCode])
    {
        CLLocation *mapLocation = [[OARootViewController instance].mapPanel.mapViewController getMapLocation];
        if (!_olcSearchingCity || _olcSearchingCity.length == 0)
        {
            if (mapLocation)
            {
                NSString *newCode = [OLCConverter recoverNearestWithShortcode:_olcSearchingCode referenceLatitude:mapLocation.coordinate.latitude referenceLongitude:mapLocation.coordinate.longitude];
                codeArea = [OLCConverter decode:newCode];
            }
        }
        else
        {
            _searchLocation = mapLocation;
            _region = olcText;
            [self startAsyncCitySearching];
        }
    }
    if (codeArea)
        loc = [[CLLocation alloc] initWithLatitude:codeArea.latitudeCenter longitude:codeArea.longitudeCenter];
    return loc;
}

- (void) startAsyncCitySearching
{
    [self.view addSpinner];
    _isOlcCitySearchRunning = YES;
    [OAQuickSearchHelper.instance searchCityLocations:_region
                                   searchLocation:_searchLocation
                                     searchBBox31:[[QuadRect alloc] initWithLeft:0 top:0 right:INT_MAX bottom:INT_MAX]
                                     allowedTypes:@[@"city", @"town", @"village"]
                                            limit:kSearchCityLimit
                                       onComplete:^(NSArray<OASearchResult *> *searchResults)
    {
        _isOlcCitySearchRunning = NO;
        [self onCitiesSearchDone:searchResults];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view removeSpinner];
        });
    }];
}

- (void) onCitiesSearchDone:(NSArray<OASearchResult *> *)searchResults
{
    if (searchResults && searchResults.count > 0 && searchResults[0].location)
    {
        _searchLocation = searchResults[0].location;
        [self updateDistanceAndDirection:YES];
    }
}

- (double) parseDoubleFromString:(NSString *)stringValue
{
    if (stringValue)
    {
        if ([[stringValue trim] rangeOfCharacterFromSet: [[NSCharacterSet characterSetWithCharactersInString:@"0123456789.-"] invertedSet] ].location == NSNotFound)
            return [[stringValue trim] doubleValue];
    }
    return NAN;
}

- (int) parseIntFromString:(NSString *)stringValue
{
    if (stringValue)
    {
        if ([[stringValue trim] rangeOfCharacterFromSet: [[NSCharacterSet characterSetWithCharactersInString:@"0123456789-"] invertedSet] ].location == NSNotFound)
            return [[stringValue trim] intValue];
    }
    return NAN;
}

- (OASearchResult *)searchResultByLocation:(CLLocation *)location
{
    OASearchUICore *searchUICore = [[OAQuickSearchHelper instance] getCore];
    OASearchPhrase *phrase = [searchUICore getPhrase];
    OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
    sr.objectType = EOAObjectTypeLocation;
    sr.location = location;
    sr.preferredZoom = PREFERRED_DEFAULT_ZOOM;
    sr.object = _searchLocation;
    return sr;
}

- (void) addHistoryItem:(OASearchResult *)searchResult
{
    if (searchResult.location && [[OAAppSettings sharedManager].searchHistory get])
    {
        OAHistoryItem *h = [[OAHistoryItem alloc] init];
        h.name = [OAQuickSearchListItem getName:searchResult];
        h.latitude = searchResult.location.coordinate.latitude;
        h.longitude = searchResult.location.coordinate.longitude;
        h.date = [NSDate date];
        h.iconName = [OAQuickSearchListItem getIconName:searchResult];
        h.typeName = [OAQuickSearchListItem getTypeName:searchResult];
        h.hType = OAHistoryTypeLocation;
        [[OAHistoryHelper sharedInstance] addPoint:h];
    }
}

- (void) showMapMenuForLocationPoint:(CLLocation *)location
{
    OAMapPanelViewController* mapPanel = [OARootViewController instance].mapPanel;
    OAMapViewController* mapVC = mapPanel.mapViewController;
    OATargetPoint *targetPoint = [mapVC.mapLayers.contextMenuLayer getUnknownTargetPoint:_searchLocation.coordinate.latitude longitude:_searchLocation.coordinate.longitude];
    targetPoint.centerMap = YES;
    [mapPanel showContextMenu:targetPoint];
    [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Current location updating

- (void) updateDistanceAndDirection
{
    [self updateDistanceAndDirection:NO];
}

- (void) updateDistanceAndDirection:(BOOL)forceUpdate
{
    @synchronized (self)
    {
        if ([[NSDate date] timeIntervalSince1970] - _lastUpdate < 0.3 && !forceUpdate)
            return;
        _lastUpdate = [[NSDate date] timeIntervalSince1970];

        if (!_searchLocation)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateLocationCell:nil];
            });
            return;
        }

        // Obtain fresh location and heading
        CLLocation* newLocation = _app.locationServices.lastKnownLocation ? _app.locationServices.lastKnownLocation : [[OARootViewController instance].mapPanel.mapViewController getMapLocation];
        double distance = NAN;
        CLLocationDirection newDirection = 0;
        if (newLocation)
        {
            CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
            newDirection = (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
            ? newLocation.course
            : newHeading;

            distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                   newLocation.coordinate.latitude,
                                                   _searchLocation.coordinate.longitude, _searchLocation.coordinate.latitude);
        }

        _distanceString = isnan(distance) ? @"" : [OAOsmAndFormatter getFormattedDistance:distance];
        CGFloat itemDirection = [_app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:_searchLocation.coordinate.latitude longitude:_searchLocation.coordinate.longitude]];
        double direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
        _direction = [NSNumber numberWithDouble:direction];
        _currentLatLon = newLocation;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateLocationCell:_searchLocation];
        });
    }
}

#pragma mark - UITableViewDelegate

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == EOAQuickSearchCoordinatesSectionControls)
        return _controlsSectionData.count;
    else
        return _searchResultSectionData.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == EOAQuickSearchCoordinatesSectionSearchResult)
        return OALocalizedString(@"search_results");
    return nil;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = indexPath.section == 0 ? _controlsSectionData[indexPath.row] : _searchResultSectionData[indexPath.row];
    NSString *cellType = item[@"type"];
    
    if ([cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = item[@"value"];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAInputTableViewCell getCellIdentifier]])
    {
        OAInputTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAInputTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAInputTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAInputTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
        }
        if (cell)
        {
            NSInteger tag = [item[@"tag"] integerValue];
            if (tag == EOAQuickSearchCoordinatesTextFieldOlc || tag == EOAQuickSearchCoordinatesTextFieldMgrs)
                cell.inputField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
            else
                cell.inputField.keyboardType = UIKeyboardTypeASCIICapableNumberPad;

            cell.inputField.tag = tag;
            cell.inputField.text = item[@"value"];
            cell.inputField.delegate = self;
            cell.inputField.autocorrectionType = UITextAutocorrectionTypeNo;
            cell.inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            cell.inputField.returnKeyType = UIReturnKeyDone;
            cell.inputField.enablesReturnKeyAutomatically = YES;
            [cell.inputField removeTarget:self action:NULL forControlEvents:UIControlEventEditingChanged];
            [cell.inputField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];

            cell.titleLabel.text = item[@"title"];

            cell.clearButton.tag = tag;
            [cell.clearButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
            [cell.clearButton addTarget:self action:@selector(onClearButtonClick:) forControlEvents:UIControlEventTouchUpInside];
            cell.clearButtonArea.tag = tag;
            [cell.clearButtonArea removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
            [cell.clearButtonArea addTarget:self action:@selector(onClearButtonClick:) forControlEvents:UIControlEventTouchUpInside];

            UITextInputAssistantItem *inputAssistantItem = cell.inputField.inputAssistantItem;
            inputAssistantItem.leadingBarButtonGroups = @[];
            inputAssistantItem.trailingBarButtonGroups = @[];
            if (tag == EOAQuickSearchCoordinatesTextFieldEasting || tag == EOAQuickSearchCoordinatesTextFieldNorthing)
                cell.inputField.inputAccessoryView = nil;
            else
                cell.inputField.inputAccessoryView = self.toolbarView;

            [cell.inputField reloadInputViews];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAQuickSearchResultTableViewCell getCellIdentifier]])
    {
        OAQuickSearchResultTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAQuickSearchResultTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAQuickSearchResultTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAQuickSearchResultTableViewCell *)[nib objectAtIndex:0];
            cell.directionIcon.image = [UIImage templateImageNamed:@"ic_small_direction"];
            cell.directionIcon.tintColor = UIColorFromRGB(color_active_light);
            cell.distanceLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            cell.coordinateLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            if ([item[@"isErrorCell"] boolValue])
            {
                cell.titleLabel.text = OALocalizedString(@"invalid_format");
                cell.distanceLabel.text = @"";
                cell.coordinateLabel.text = @"";
                [cell setDesriptionLablesVisible:NO];
                cell.icon.image = [UIImage templateImageNamed:@"ic_custom_alert"];
                cell.icon.tintColor = [UIColor colorNamed:ACColorNameIconColorSelected];
            }
            else
            {
                cell.titleLabel.text = item[@"title"];
                cell.distanceLabel.text = item[@"distance"];
                cell.coordinateLabel.text = [NSString stringWithFormat:@"  •  %@", item[@"coordinates"]];
                [cell setDesriptionLablesVisible:YES];
                cell.icon.image = [UIImage templateImageNamed:@"ic_custom_map_pin"];
                cell.icon.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
                cell.directionIcon.transform = CGAffineTransformMakeRotation([item[@"direction"] doubleValue]);
            }
        }
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *item = indexPath.section == 0 ? _controlsSectionData[indexPath.row] : _searchResultSectionData[indexPath.row];
    NSString *cellType = item[@"type"];

    if ([cellType isEqualToString:[OAInputTableViewCell getCellIdentifier]])
    {
        OAInputTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (cell)
            [cell.inputField becomeFirstResponder];
    }
    else
    {
        if (_currentEditingTextField)
            [_currentEditingTextField resignFirstResponder];

        if ([cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
        {
            OAQuickSearchCoordinateFormatsViewController *vc = [[OAQuickSearchCoordinateFormatsViewController alloc] initWithCurrentFormat:_currentFormat location:[self getDisplayingCoordinate]];
            vc.delegate = self;
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:navigationController animated:YES completion:nil];
        }
        else if ([cellType isEqualToString:[OAQuickSearchResultTableViewCell getCellIdentifier]] && ![item[@"isErrorCell"] boolValue])
        {
            CLLocation *location = item[@"location"];
            if (location)
            {
                OASearchResult *sr = [self searchResultByLocation:location];
                [self addHistoryItem:sr];
                [self showMapMenuForLocationPoint:location];
            }
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // handle only touches on tableView background
    if([touch.view isKindOfClass:[UITableViewCell class]] || [touch.view.superview isKindOfClass:[UITableViewCell class]] || [touch.view.superview.superview isKindOfClass:[UITableViewCell class]])
        return NO;
    return YES;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    _currentEditingTextField = textField;
    [self updateHintbar];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.text.length >= kMaxTexFieldSymbolsCount && string.length > 0)
        return NO;
    return YES;
}

-(void)textViewDidChange:(UITextView *)textView
{
    [self setText:textView.text forTextFieldByTag:textView.tag];
    [self parseLocation];
}

- (void) setText:(NSString *)text forTextFieldByTag:(NSInteger)tag
{
    if (tag == EOAQuickSearchCoordinatesTextFieldLat)
        _latStr = text;
    else if (tag == EOAQuickSearchCoordinatesTextFieldLon)
        _lonStr = text;
    else if (tag == EOAQuickSearchCoordinatesTextFieldOlc)
        _olcStr = text;
    else if (tag == EOAQuickSearchCoordinatesTextFieldMgrs)
        _mgrsStr = text;
    else if (tag == EOAQuickSearchCoordinatesTextFieldNorthing)
        _northingStr = text;
    else if (tag == EOAQuickSearchCoordinatesTextFieldEasting)
        _eastingStr = text;
    else if (tag == EOAQuickSearchCoordinatesTextFieldZone)
        _zoneStr = text;
}

- (IBAction) onClearButtonClick:(UIButton *)sender
{
    CGPoint rootViewPoint = [sender.superview convertPoint:sender.center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rootViewPoint];
    
    [self.tableView beginUpdates];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section]];
    if ([cell isKindOfClass:OAInputTableViewCell.class])
        ((OAInputTableViewCell *) cell).inputField.text = @"";
    [self.tableView endUpdates];
    
    [self setText:@"" forTextFieldByTag:sender.tag];
    [self parseLocation];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    _currentEditingTextField = nil;
    return YES;
}

#pragma mark - Keyboard notifications


- (void) keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = [keyboardBoundsValue CGRectValue].size.height;
    CGFloat aboveKeyboardScreenPart = self.view.frame.size.height - keyboardHeight;
    CGFloat inputFieldsHeight = 35 + _controlsSectionData.count * kEstimatedCellHeight;
    if (aboveKeyboardScreenPart < inputFieldsHeight)
    {
        [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
            UIEdgeInsets insets = [[self tableView] contentInset];
            [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, kHintBarHeight + (DeviceScreenHeight - keyboardHeight), insets.right)];
        } completion:nil];
    }
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        UIEdgeInsets insets = [[self tableView] contentInset];
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0, insets.right)];
        _currentEditingTextField = nil;
    } completion:nil];
}

#pragma mark - Hintbar

- (void) updateHintbar
{
    NSArray<NSString *> *hintList = @[];
    if (_currentEditingTextField)
    {
        NSInteger tag = _currentEditingTextField.tag;
        if (tag == EOAQuickSearchCoordinatesTextFieldLat)
            hintList = @[@"-", @".", @":"];
        else if (tag == EOAQuickSearchCoordinatesTextFieldLon)
            hintList = @[@"-", @".", @":"];
        else if (tag == EOAQuickSearchCoordinatesTextFieldOlc)
            hintList = @[@"+", @"C", @"F", @"G", @"H", @"J", @"M", @"P", @"Q", @"R", @"V", @"W", @"X"];
        else if (tag == EOAQuickSearchCoordinatesTextFieldMgrs)
            hintList = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"J", @"K", @"L", @"M", @"N", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"];
        else if (tag == EOAQuickSearchCoordinatesTextFieldNorthing)
            hintList = @[];
        else if (tag == EOAQuickSearchCoordinatesTextFieldEasting)
            hintList = @[];
        else if (tag == EOAQuickSearchCoordinatesTextFieldZone)
            hintList = @[@"N", @"S", @"C", @"D", @"E", @"F", @"G", @"H", @"J", @"K", @"L", @"M", @"P", @"Q", @"R", @"T", @"U", @"V", @"W", @"X"];
    }
    _shouldHideHintBar = hintList.count == 0;
    [self updateHints:hintList];
}
 
- (void) updateHints:(NSArray *)hints
{
    NSInteger xPosition = 0;
    NSInteger margin = 8;
    
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scrollView.contentSize = CGSizeMake(margin, self.toolbarView.frame.size.height);
    self.scrollView.backgroundColor = [UIColor colorNamed:ACColorNameViewBg];
    _toolbarView.backgroundColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
    
    if (!_shouldHideHintBar)
    {
        for (NSString *hint in hints)
        {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            btn.frame = CGRectMake(xPosition + margin, 6, 0, 0);
            btn.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorTertiary];
            btn.layer.masksToBounds = YES;
            btn.layer.cornerRadius = 6.0;
            btn.titleLabel.numberOfLines = 1;
            btn.titleLabel.font = [UIFont scaledMonospacedSystemFontOfSize:17 weight:UIFontWeightSemibold];

            [btn setTitle:hint forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor colorNamed:ACColorNameTextColorActive] forState:UIControlStateNormal];
            [btn sizeToFit];
            [btn addTarget:self action:@selector(tagHintTapped:) forControlEvents:UIControlEventTouchUpInside];
            
            CGRect btnFrame = [btn frame];
            btnFrame.size.width = btn.frame.size.width + 15;
            btnFrame.size.height = 32;
            [btn setFrame:btnFrame];
            
            xPosition += btn.frame.size.width + margin;
            [self.scrollView addSubview:btn];
        }
    }
    self.scrollView.contentSize = CGSizeMake(xPosition, self.toolbarView.frame.size.height);
}

- (void) tagHintTapped:(id)sender
{
    NSString *buttonText = ((UIButton *)sender).titleLabel.text;
    if (_currentEditingTextField)
        [_currentEditingTextField insertText:buttonText];
}

#pragma mark - OAQuickSearchCoordinateFormatsDelegate

- (void)onCoordinateFormatChanged:(NSInteger)currentFormat
{
    [self applyFormat:currentFormat forceApply:NO];
    [self parseLocation];
    [self updateControllsSectionCells];
}

@end
