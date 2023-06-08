//
//  OACoordinatesBaseWidget.m
//  OsmAnd Maps
//
//  Created by nnngrach on 13.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OACoordinatesWidget.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "OALocationConvert.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAMapHudViewController.h"
#import "OAToolbarViewController.h"
#import "OADownloadMapWidget.h"
#import "OAOsmAndFormatter.h"
#import "OASearchToolbarViewController.h"
#import "OADestinationCardsViewController.h"

#import "OsmAnd_Maps-Swift.h"

#import <OsmAndCore/Utilities.h>

#define kHorisontalOffset 8
#define kIconWidth 30

@interface OACoordinatesWidget ()

@property (weak, nonatomic) IBOutlet UIImageView *latImageView;
@property (weak, nonatomic) IBOutlet UILabel *latTextView;
@property (weak, nonatomic) IBOutlet UIImageView *lonImageView;
@property (weak, nonatomic) IBOutlet UILabel *lonTextView;
@property (weak, nonatomic) IBOutlet UIView *verticalSeparator;
@property (weak, nonatomic) IBOutlet UIView *horisontalSeparator;

@end

@implementation OACoordinatesWidget
{
    EOACoordinatesWidgetType _type;
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    NSTimeInterval _lastUpdatingTime;
    CLLocation* _lastKnownLocation;
    BOOL _cachedVisibiliy;
    BOOL _isAnimated;
    UIButton *_shadowButton;
}

- (instancetype) initWithType:(EOACoordinatesWidgetType)type;
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OACoordinatesWidget" owner:self options:nil];
    self = (OACoordinatesWidget *)[nib objectAtIndex:0];

    if (self)
    {
        // TODO: Refactor as in Android
        self.widgetType = type == EOACoordinatesWidgetTypeMapCenter ? OAWidgetType.coordinatesMapCenter : OAWidgetType.coordinatesCurrentLocation;
        _type = type;
        self.frame = CGRectMake(0, 0, 200, 50);
    }
    
    [self commonInit];
    return self;
}

- (void) commonInit
{
    _settings = [OAAppSettings sharedManager];
    _app = [OsmAndApp instance];

    self.hidden = YES;
    _shadowButton = [[UIButton alloc] initWithFrame:self.frame];
    _shadowButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_shadowButton addTarget:self action:@selector(onWidgetClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_shadowButton];

    [self updateInfo];
}

- (void) layoutSubviews
{
    if (self.delegate)
        [self.delegate widgetChanged:nil];

    CGFloat middlePoint = self.frame.size.width / 2;
    CGFloat lineWidth = 0.5;
    _horisontalSeparator.frame = CGRectMake(0, 0, self.frame.size.width, lineWidth);
    _verticalSeparator.frame = CGRectMake(middlePoint - lineWidth, 14, lineWidth, 24);

    if (![self isDirectionRTL])
    {
        CGFloat latIconRightPoint = 2 * kHorisontalOffset + kIconWidth;
        CGFloat lonIconRightPoint = middlePoint + 2 * kHorisontalOffset + kIconWidth;
        _latImageView.frame = CGRectMake(kHorisontalOffset, 10, kIconWidth, kIconWidth);
        if (_lonTextView.hidden)
        {
            _latTextView.frame = CGRectMake(latIconRightPoint, 15, self.frame.size.width - latIconRightPoint - 2 * kHorisontalOffset, 22);
        }
        else
        {
            _latTextView.frame = CGRectMake(latIconRightPoint, 15, middlePoint - latIconRightPoint - kHorisontalOffset, 22);
            _lonImageView.frame = CGRectMake(middlePoint + kHorisontalOffset, 10, kIconWidth, kIconWidth);
            _lonTextView.frame = CGRectMake(lonIconRightPoint, 15, self.frame.size.width - lonIconRightPoint - kHorisontalOffset, 22);
        }
    }
    else
    {
        if (_lonTextView.hidden)
        {
            _latTextView.frame = CGRectMake(kHorisontalOffset, 15, self.frame.size.width - kIconWidth - 3 * kHorisontalOffset, 22);
            _latImageView.frame = CGRectMake(self.frame.size.width - kIconWidth - kHorisontalOffset, 10, kIconWidth, kIconWidth);
        }
        else
        {
            _latTextView.frame = CGRectMake(kHorisontalOffset, 15, middlePoint - 3 * kHorisontalOffset - kIconWidth, 22);
            _latImageView.frame = CGRectMake(middlePoint - kIconWidth - kHorisontalOffset , 10, kIconWidth, kIconWidth);
            _lonTextView.frame = CGRectMake(middlePoint + kHorisontalOffset, 15, _latTextView.frame.size.width, 22);
            _lonImageView.frame = CGRectMake(self.frame.size.width - kIconWidth - kHorisontalOffset, 10, kIconWidth, kIconWidth);
        }
    }

    OAMapHudViewController *mapHud = [OARootViewController instance].mapPanel.hudViewController;
    BOOL topVisible = [mapHud.topCoordinatesWidget isVisible];
    BOOL bottomVisible = [mapHud.coordinatesMapCenterWidget isVisible];
    BOOL bothVisible = topVisible && bottomVisible;
    _horisontalSeparator.hidden = !(bothVisible && _type == EOACoordinatesWidgetTypeMapCenter);

    CGRect rect = self.bounds;
    rect.origin.y = 5.;
    rect.size.height -= 5.;
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:rect];
    self.layer.shadowPath = shadowPath.CGPath;
    self.layer.shadowOpacity = 0.35;
    self.layer.shadowRadius = 5;
    self.layer.shadowOffset = CGSizeMake(0, 2);
    self.layer.masksToBounds = NO;

    self.layer.cornerRadius = [OAUtilities isLandscape] ? 3 : 0;
    self.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
}

- (BOOL) isVisible
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    OAToolbarViewController *topToolbar = [mapPanel.hudViewController toolbarViewController];
    return [self isEnabled]
            && [topToolbar getAttentionLevel] != EOAToolbarAttentionLevelHigh
            && !mapPanel.hudViewController.downloadMapWidget.isVisible
            && ![mapPanel isTopToolbarSearchVisible]
            && ![OADestinationCardsViewController sharedInstance].view.superview;
}

- (BOOL) updateInfo
{
    BOOL visible = [self isVisible];
    self.hidden = !visible;

    if ([self shouldUpdate])
    {
        BOOL nightMode = [OAAppSettings sharedManager].nightMode;
        [self updateVisibility:visible];
        _cachedVisibiliy = [self isEnabled];

        if (visible)
        {
            BOOL isPortrait = ![OAUtilities isLandscape];
            _lastKnownLocation = [self getLocation];
            if (_lastKnownLocation)
            {
                int format = [_settings.settingGeoFormat get];
                double lat = _lastKnownLocation.coordinate.latitude;
                double lon = _lastKnownLocation.coordinate.longitude;

                NSString *latText;
                NSString *lonText;

                if (format == MAP_GEO_UTM_FORMAT)
                {
                    _latTextView.hidden = NO;
                    _lonTextView.hidden = YES;
                    _latImageView.hidden = NO;
                    _lonImageView.hidden = YES;
                    _verticalSeparator.hidden = YES;
                    [_latImageView setImage:[UIImage imageNamed:[self getUtmIcon]]];
                    _latTextView.text = [OALocationConvert getUTMCoordinateString:lat lon:lon];
                }
                else if (format == MAP_GEO_OLC_FORMAT)
                {
                    _latTextView.hidden = NO;
                    _lonTextView.hidden = YES;
                    _latImageView.hidden = NO;
                    _lonImageView.hidden = YES;
                    _verticalSeparator.hidden = YES;
                    [_latImageView setImage:[UIImage imageNamed:[self getUtmIcon]]];
                    _latTextView.text = [OALocationConvert getLocationOlcName:lat lon:lon];
                }
                else if (format == MAP_GEO_MGRS_FORMAT)
                {
                    _latTextView.hidden = NO;
                    _lonTextView.hidden = YES;
                    _latImageView.hidden = NO;
                    _lonImageView.hidden = YES;
                    _verticalSeparator.hidden = YES;
                    [_latImageView setImage:[UIImage imageNamed:[self getUtmIcon]]];
                    _latTextView.text = [OALocationConvert getMgrsCoordinateString:lat lon:lon];
                }
                else
                {
                    _latTextView.hidden = NO;
                    _lonTextView.hidden = NO;
                    _latImageView.hidden = NO;
                    _lonImageView.hidden = NO;
                    _verticalSeparator.hidden = NO;

                    NSString *coordinatesString = [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:format];
                    NSArray<NSString *> *coordinates = [coordinatesString componentsSeparatedByString:@","];
                    latText = coordinates[0];
                    lonText = [coordinates[1] trim];
                    [_latImageView setImage:[UIImage imageNamed:[self getLatitudeIcon:lat]]];
                    [_lonImageView setImage:[UIImage imageNamed:[self getLongitudeIcon:lon]]];
                    _latTextView.text = latText;
                    _lonTextView.text = lonText;
                }
            }
            else
            {
                _latTextView.hidden = NO;
                _lonTextView.hidden = YES;
                _latImageView.hidden = YES;
                _lonImageView.hidden = YES;
                _verticalSeparator.hidden = YES;
                _latTextView.text = OALocalizedString(@"searching_gps");
            }

            self.backgroundColor = nightMode ? UIColorFromRGB(nav_bar_night) : UIColor.whiteColor;
            _latTextView.textColor = nightMode ? UIColorFromRGB(text_primary_night) : UIColor.blackColor;
            _lonTextView.textColor = nightMode ? UIColorFromRGB(text_primary_night) : UIColor.blackColor;
            _horisontalSeparator.hidden = !isPortrait;
            _horisontalSeparator.backgroundColor = UIColorFromRGB(color_tint_gray);

            _lastUpdatingTime = [[NSDate new] timeIntervalSince1970];
        }

        [self layoutSubviews];
        return NO;
    }
    else
    {
        return NO;
    }
}

- (int) getConverterFormat:(int)format
{
    return format + 101;
}

- (BOOL) shouldUpdate
{
    BOOL isFirstLaunch = _lastUpdatingTime == 0;
    if (isFirstLaunch)
    {
        return YES;
    }
    else
    {
        BOOL isVisibilityChanged = _cachedVisibiliy != [self isEnabled];

        CLLocation *currentLocation = _app.locationServices.lastKnownLocation;
        BOOL isLocationChanged = ![OAUtilities isCoordEqual:currentLocation.coordinate.latitude srcLon:currentLocation.coordinate.longitude destLat:_lastKnownLocation.coordinate.latitude destLon:_lastKnownLocation.coordinate.latitude];

        NSTimeInterval updatingPeriond = 0.5;
        NSTimeInterval currentTimestamp = [[NSDate new] timeIntervalSince1970];
        BOOL hasUpdatingTimeLimitPassed = currentTimestamp - _lastUpdatingTime > updatingPeriond;

        return isVisibilityChanged || (!_isAnimated && isLocationChanged && hasUpdatingTimeLimitPassed);
    }
}

- (BOOL) updateVisibility:(BOOL)visible
{
    if (visible == self.hidden)
    {
        self.hidden = !visible;
        if (self.delegate)
            [self.delegate widgetVisibilityChanged:nil visible:visible];

        return YES;
    }
    return NO;
}

- (void) onWidgetClicked:(id)sender
{
    if (_lastKnownLocation)
    {
        NSString *coordinates = _latTextView.text;
        if (!_lonTextView.hidden)
            coordinates = [NSString stringWithFormat:@"%@, %@", coordinates, _lonTextView.text];

        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = coordinates;

        [UIView animateWithDuration:.2 animations:^{
            _isAnimated = YES;
            _latTextView.hidden = NO;
            _lonTextView.hidden = YES;
            _latImageView.hidden = NO;
            _lonImageView.hidden = YES;
            _verticalSeparator.hidden = YES;
            [_latImageView setImage:[UIImage imageNamed:@"ic_custom_clipboard"]];
            _latTextView.text = OALocalizedString(@"copied_to_clipboard");

            CGFloat latIconRightPoint = 2 * kHorisontalOffset + kIconWidth;
            _latTextView.frame = CGRectMake(latIconRightPoint, 14, self.frame.size.width - latIconRightPoint - 2 * kHorisontalOffset, 22);
        }];

        NSTimeInterval delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

            [UIView animateWithDuration:.3 animations:^{
                _isAnimated = NO;
                [self updateInfo];
            }];
        });
    }
}

- (BOOL) isEnabled
{
    return [OARootViewController.instance.mapPanel.mapWidgetRegistry isWidgetVisible:self.widgetType.id];
}

- (CLLocation *) getLocation
{
    if (_type == EOACoordinatesWidgetTypeCurrentLocation)
    {
        return _app.locationServices.lastKnownLocation;
    }
    else
    {
        Point31 mapCenter = _app.data.mapLastViewedState.target31;
        OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(OsmAnd::PointI(mapCenter.x, mapCenter.y));
        return [[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
    }
}

- (NSString *) getUtmIcon
{
    BOOL nightMode = [OAAppSettings sharedManager].nightMode;
    if (_type == EOACoordinatesWidgetTypeCurrentLocation)
        return nightMode ? @"widget_coordinates_utm_night" : @"widget_coordinates_utm_day";
    else
        return nightMode ? @"widget_coordinates_map_center_utm_night" : @"widget_coordinates_map_center_utm_day";
}

- (NSString *) getLatitudeIcon:(double)lat
{
    //not a bug: in android in Night mode in this case shows Day icons too.
    BOOL nightMode = [OAAppSettings sharedManager].nightMode;
    if (_type == EOACoordinatesWidgetTypeCurrentLocation)
    {
        if (nightMode)
            return lat >= 0 ? @"widget_coordinates_latitude_north_day" : @"widget_coordinates_latitude_south_day";
        else
            return lat >= 0 ? @"widget_coordinates_latitude_north_night" : @"widget_coordinates_latitude_south_night";
    }
    else
    {
        if (nightMode)
            return lat >= 0 ? @"widget_coordinates_map_center_latitude_north_day" : @"widget_coordinates_map_center_latitude_south_day";
        else
            return lat >= 0 ? @"widget_coordinates_map_center_latitude_north_night" : @"widget_coordinates_map_center_latitude_south_night";
    }
}

- (NSString *) getLongitudeIcon:(double)lon
{
    BOOL nightMode = [OAAppSettings sharedManager].nightMode;
    if (_type == EOACoordinatesWidgetTypeCurrentLocation)
    {
        if (nightMode)
            return lon >= 0 ? @"widget_coordinates_longitude_east_day" : @"widget_coordinates_longitude_west_day";
        else
            return lon >= 0 ? @"widget_coordinates_longitude_east_night" : @"widget_coordinates_longitude_west_night";
    }
    else
    {
        if (nightMode)
            return lon >= 0 ? @"widget_coordinates_map_center_longitude_east_day" : @"widget_coordinates_map_center_longitude_west_day";
        else
            return lon >= 0 ? @"widget_coordinates_map_center_longitude_east_night" : @"widget_coordinates_map_center_longitude_west_night";
    }
}

@end
