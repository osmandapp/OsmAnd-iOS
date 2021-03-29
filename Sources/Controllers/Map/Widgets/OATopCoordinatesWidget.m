//
//  OATopCoordinatesWidget.m
//  OsmAnd Maps
//
//  Created by nnngrach on 28.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OATopCoordinatesWidget.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "OAAppSettings.h"
#import "OAUtilities.h"
#import "OATextInfoWidget.h"
#import "OALocationConvert.h"
#import "Localization.h"

#define kHorisontalOffset 8
#define kIconWidth 30

@interface OATopCoordinatesWidget ()

@property (weak, nonatomic) IBOutlet UIImageView *latImageView;
@property (weak, nonatomic) IBOutlet UILabel *latTextView;
@property (weak, nonatomic) IBOutlet UIImageView *lonImageView;
@property (weak, nonatomic) IBOutlet UILabel *lonTextView;
@property (weak, nonatomic) IBOutlet UIView *verticalSeparator;
@property (weak, nonatomic) IBOutlet UIView *horisontalSeparator;

@end

@implementation OATopCoordinatesWidget
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    NSTimeInterval _lastUpdatingTime;
    CLLocation* _lastKnownLocation;
    BOOL _isAnimated;
    UIButton *_shadowButton;
}

- (instancetype) init
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATopCoordinatesWidget" owner:self options:nil];
    self = (OATopCoordinatesWidget *)[nib objectAtIndex:0];
    if (self)
        self.frame = CGRectMake(0, 0, 200, 50);
    
    [self commonInit];
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATopCoordinatesWidget" owner:self options:nil];
    self = (OATopCoordinatesWidget *)[nib objectAtIndex:0];
    if (self)
        self.frame = CGRectMake(0, 0, 200, 50);
    
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
    BOOL isLandscape = [OAUtilities isLandscape];
    CGFloat middlePoint = self.frame.size.width / 2;

    _horisontalSeparator.frame = CGRectMake(0, 0, self.frame.size.width, 1);
    _verticalSeparator.frame = CGRectMake(middlePoint - 1, 14, 1, 24);
    CGFloat latIconRightPoint = 2 * kHorisontalOffset + kIconWidth;
    CGFloat lonIconRightPoint = middlePoint + 2 * kHorisontalOffset + kIconWidth;

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
    
    _horisontalSeparator.hidden = isLandscape;
    
    CGFloat cornerRadius = [OAUtilities isLandscape] ? 3 : 0;
    [OAUtilities setMaskTo:self byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight radius:cornerRadius];
}

- (BOOL) updateInfo
{
    if ([self shouldUpdate])
    {
        BOOL visible = [_settings.showCoordinatesWidget get];
        BOOL nightMode = [_settings.appearanceMode get] == 1; //??
        
        [self updateVisibility:visible];
        
        if (visible)
        {
            BOOL isPortrait = ![OAUtilities isLandscape];
            _lastKnownLocation = _app.locationServices.lastKnownLocation;
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
                    [_latImageView setImage:[UIImage imageNamed:nightMode ? @"widget_coordinates_utm_night" : @"widget_coordinates_utm_day"]];
                    _latTextView.text = [OALocationConvert getUTMCoordinateString:lat lon:lon];
                }
                else if (format == MAP_GEO_OLC_FORMAT)
                {
                    _latTextView.hidden = NO;
                    _lonTextView.hidden = YES;
                    _latImageView.hidden = NO;
                    _lonImageView.hidden = YES;
                    _verticalSeparator.hidden = YES;
                    [_latImageView setImage:[UIImage imageNamed:nightMode ? @"widget_coordinates_utm_night" : @"widget_coordinates_utm_day"]];
                    _latTextView.text = [OALocationConvert getLocationOlcName:lat lon:lon];
                }
                else
                {
                    _latTextView.hidden = NO;
                    _lonTextView.hidden = NO;
                    _latImageView.hidden = NO;
                    _lonImageView.hidden = NO;
                    _verticalSeparator.hidden = NO;
                    latText = [OALocationConvert convertLatitude:lat outputType:format addCardinalDirection:YES];
                    lonText = [OALocationConvert convertLongitude:lon outputType:format addCardinalDirection:YES];
                    
                    NSString* latDayImg = lat >= 0 ? @"widget_coordinates_latitude_north_day" : @"widget_coordinates_latitude_south_day";
                    NSString* latNightImg = lat >= 0 ? @"widget_coordinates_latitude_north_night" : @"widget_coordinates_latitude_south_night";
                    NSString* lonDayImg = lon >= 0 ? @"widget_coordinates_longitude_east_day" : @"widget_coordinates_longitude_west_day";
                    NSString* lonNightIm = lon >= 0 ? @"widget_coordinates_longitude_east_night" : @"widget_coordinates_longitude_west_night";
                    
                    [_latImageView setImage:[UIImage imageNamed:nightMode ? latNightImg : latDayImg]];
                    [_lonImageView setImage:[UIImage imageNamed:nightMode ? lonNightIm : lonDayImg]];
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
            
            self.backgroundColor = UIColorFromRGB(nav_bar_night);
            _latTextView.textColor = UIColorFromRGB(text_primary_night);
            _lonTextView.textColor = UIColorFromRGB(text_primary_night);
            _horisontalSeparator.hidden = !isPortrait;
            
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

- (BOOL) shouldUpdate
{
    BOOL isFirstLaunch = _lastUpdatingTime == 0;
    
    CLLocation *currentLocation = _app.locationServices.lastKnownLocation;
    BOOL locationNotChanged = [OAUtilities isCoordEqual:currentLocation.coordinate.latitude srcLon:currentLocation.coordinate.longitude destLat:_lastKnownLocation.coordinate.latitude destLon:_lastKnownLocation.coordinate.latitude];
    
    NSTimeInterval updatingPeriond = 1;
    NSTimeInterval currentTimestamp = [[NSDate new] timeIntervalSince1970];
    NSTimeInterval difference = currentTimestamp - _lastUpdatingTime;
    BOOL notEnoughTimePassed = currentTimestamp - _lastUpdatingTime < updatingPeriond;
    
    return isFirstLaunch || (!_isAnimated && !locationNotChanged && !notEnoughTimePassed);
}

- (BOOL) updateVisibility:(BOOL)visible
{
    if (visible == self.hidden)
    {
        self.hidden = !visible;
        if (_delegate)
            [_delegate widgetVisibilityChanged:nil visible:visible];
        
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
            [_latImageView setImage:[UIImage imageNamed:@"ic_custom_copy"]];
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

@end
