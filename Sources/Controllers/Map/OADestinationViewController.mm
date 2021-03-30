//
//  OADestinationViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OADestinationViewController.h"
#import "OADestination.h"
#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OAMultiDestinationCell.h"
#import "OAAppSettings.h"
#import "OALog.h"
#import "OAUtilities.h"
#import "OADestinationsHelper.h"
#import "OAGPXRouter.h"
#import "OAGPXRouteDocument.h"
#import "OADestinationCardsViewController.h"
#import "OAHistoryHelper.h"
#import "OAHistoryItem.h"
#import "Localization.h"
#import "OAColors.h"

#import <OsmAndCore.h>
#import <OsmAndCore/Utilities.h>

@interface OADestinationViewController ()

@property (nonatomic) NSMutableArray *destinationCells;
@property (nonatomic) OAMultiDestinationCell *multiCell;

@property (nonatomic) UIColor *parkingColor;
@property (nonatomic) NSArray *colors;
@property (nonatomic) NSArray *markerNames;


@end

@implementation OADestinationViewController
{
    BOOL _singleLineMode;
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    CLLocationCoordinate2D _location;
    CLLocationDirection _direction;

    OAAutoObserverProxy* _locationServicesUpdateObserver;

    OAAutoObserverProxy* _gpxRouteDefinedObserver;
    OAAutoObserverProxy* _gpxRouteChangedObserver;
    OAAutoObserverProxy* _gpxRouteCanceledObserver;

    OAAutoObserverProxy* _destinationsChangeObserver;
    OAAutoObserverProxy* _destinationRemoveObserver;
    
    NSTimeInterval _lastUpdate;
}

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];

    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {        
        self.destinationCells = [NSMutableArray array];
        
        self.parkingColor = UIColorFromRGB(parking_pin_color_blue);

        self.colors = @[UIColorFromRGB(marker_pin_color_orange),
                        UIColorFromRGB(marker_pin_color_teal),
                        UIColorFromRGB(marker_pin_color_green),
                        UIColorFromRGB(marker_pin_color_red),
                        UIColorFromRGB(marker_pin_color_light_green),
                        UIColorFromRGB(marker_pin_color_purple),
                        UIColorFromRGB(marker_pin_color_blue)];
        
        self.markerNames = @[@"ic_destination_pin_1", @"ic_destination_pin_2", @"ic_destination_pin_3", @"ic_destination_pin_4", @"ic_destination_pin_5", @"ic_destination_pin_6", @"ic_destination_pin_7"];
        
        _gpxRouteDefinedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onRouteDefined)
                                                              andObserve:[OAGPXRouter sharedInstance].routeDefinedObservable];
        _gpxRouteChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onDestinationsChanged)
                                                              andObserve:[OAGPXRouter sharedInstance].routeChangedObservable];
        _gpxRouteCanceledObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onRouteCanceled)
                                                              andObserve:[OAGPXRouter sharedInstance].routeCanceledObservable];

        _destinationsChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onDestinationsChanged)
                                                              andObserve:_app.data.destinationsChangeObservable];

        _destinationRemoveObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onDestinationRemove:withKey:)
                                                                 andObserve:_app.data.destinationRemoveObservable];
        
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.titleLabel.text = OALocalizedString(@"map_markers");
    
    if ([OADestinationsHelper instance].sortedDestinations.count > 0)
    {
        [self refreshCells];
    }
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateFrame:NO];
    } completion:nil];
}

- (int) getPriority
{
    return DESTINATIONS_TOOLBAR_PRIORITY;
}

- (IBAction) backButtonPress:(id)sender
{
    [self openHideDestinationCardsView:sender];
}

- (void) onRouteDefined
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self refreshCells];

        if (self.destinationDelegate)
            [self.destinationDelegate destinationsAdded];
    });
}

- (void) onRouteCanceled
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self refreshCells];
        if ([OADestinationsHelper instance].sortedDestinations.count == 0 && self.destinationDelegate)
            [self.destinationDelegate hideDestinations];
        else
            [self updateFrame:YES];
    });
}

- (void) onDestinationsChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshCells];
        [self updateFrame:YES];
    });
}

- (void) onDestinationRemove:(id)observable withKey:(id)key
{
    OADestination *destination = key;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self doRemoveDestination:destination];
    });
}

- (void) refreshView
{
    [self refreshCells];
    [self updateFrame:YES];
}

- (void) refreshCells
{
    [self clean];
    
    if ([_settings.distanceIndication get] == WIDGET_DISPLAY)
        return;

    if ([OADestinationsHelper instance].sortedDestinations.count == 0)
        return;

    CLLocationCoordinate2D location;
    CLLocationDirection direction;
    [self obtainCurrentLocationDirection:&location direction:&direction];

    NSArray *destinations = [OADestinationsHelper instance].sortedDestinations;
    
    OADestination *firstCellDestination = (destinations.count >= 1 ? destinations[0] : nil);
    OADestination *secondCellDestination;
    if ([OADestinationsHelper instance].dynamic2ndRowDestination)
        secondCellDestination = [OADestinationsHelper instance].dynamic2ndRowDestination;
    else
        secondCellDestination = (destinations.count >= 2 ? destinations[1] : nil);
    
    if (firstCellDestination && [_settings.distanceIndicationVisibility get])
    {
        OADestination *destination = firstCellDestination;

        OADestinationCell *cell;
        if (_destinationCells.count == 0)
        {
            cell = [[OADestinationCell alloc] initWithDestination:destination destinationIndex:0];
            cell.delegate = self;
            [_destinationCells addObject:cell];
            [self.view insertSubview:cell.contentView atIndex:0];
        }
        else
        {
            cell = _destinationCells[0];
            cell.destinations = @[destination];
        }
        
        [cell updateDirections:location direction:direction];
    }
    
    if (secondCellDestination && [_settings.distanceIndication get] == TOP_BAR_DISPLAY && [_settings.activeMarkers get] == TWO_ACTIVE_MARKERS && [_settings.distanceIndicationVisibility get])
    {
        OADestination *destination = secondCellDestination;
        
        OADestinationCell *cell;
        if (_destinationCells.count == 1)
        {
            cell = [[OADestinationCell alloc] initWithDestination:destination destinationIndex:1];
            cell.delegate = self;
            [_destinationCells addObject:cell];
            [self.view insertSubview:cell.contentView atIndex:0];
        }
        else
        {
            cell = _destinationCells[1];
            cell.destinations = @[destination];
        }
        
        [cell updateDirections:location direction:direction];
    }
    
    if (!_multiCell)
    {
        self.multiCell = [[OAMultiDestinationCell alloc] initWithDestinations:[NSArray arrayWithArray:destinations]];
        _multiCell.delegate = self;
        [self.view addSubview:_multiCell.contentView];
    }
    else
    {
        _multiCell.destinations = [NSArray arrayWithArray:destinations];
    }
    
    [_multiCell updateDirections:location direction:direction];
    
    [self startLocationUpdate];
}

- (void)clean
{
    NSInteger destinationsCount = [_settings.activeMarkers get] == TWO_ACTIVE_MARKERS ? [OADestinationsHelper instance].sortedDestinations.count : 1;

    while (_destinationCells.count > destinationsCount)
    {
        OADestinationCell *cell = [_destinationCells lastObject];
        [cell.contentView removeFromSuperview];
        [_destinationCells removeLastObject];
    }

    if ([_settings.distanceIndication get] == WIDGET_DISPLAY || ![_settings.distanceIndicationVisibility get])
    {
        while (_destinationCells.count > 0)
        {
            OADestinationCell *cell = [_destinationCells lastObject];
            [cell.contentView removeFromSuperview];
            [_destinationCells removeLastObject];
        }
    }

    if (destinationsCount == 0)
        [self stopLocationUpdate];
}

-(void)obtainCurrentLocationDirection:(CLLocationCoordinate2D*)location direction:(CLLocationDirection*)direction
{
    if (_settings.settingMapArrows == MAP_ARROWS_MAP_CENTER)
    {
        Point31 mapCenter = _app.data.mapLastViewedState.target31;
        float mapDirection = _app.data.mapLastViewedState.azimuth;
        
        OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(OsmAnd::PointI(mapCenter.x, mapCenter.y));
        *location = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
        *direction = mapDirection;
    }
    else
    {
        // Obtain fresh location and heading
        CLLocation* newLocation = _app.locationServices.lastKnownLocation;
        if (!newLocation)
        {
            CLLocationCoordinate2D emptyCoords;
            emptyCoords.latitude = NAN;
            emptyCoords.longitude = NAN;
            *location = emptyCoords;
            *direction = NAN;
        }
        else
        {
            CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
            CLLocationDirection newDirection =
            (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
            ? newLocation.course
            : newHeading;
            
            *location = newLocation.coordinate;
            *direction = newDirection;
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillLayoutSubviews
{
    [self updateLayout];
}

-(void)onViewWillAppear:(EOAMapHudType)mapHudType
{
    self.singleLineOnly = mapHudType == EOAMapHudDrive;
}

-(void)onViewDidAppear:(EOAMapHudType)mapHudType
{
    [self startLocationUpdate];
}

-(void)onViewWillDisappear:(EOAMapHudType)mapHudType
{
    [self stopLocationUpdate];
}

-(void)onMapAzimuthChanged:(id)observable withKey:(id)key andValue:(id)value
{
    if ([OAAppSettings sharedManager].settingMapArrows == MAP_ARROWS_MAP_CENTER)
        [self updateDestinationsUsingMapCenter];
}

-(void)onMapChanged:(id)observable withKey:(id)key
{
    if ([OAAppSettings sharedManager].settingMapArrows == MAP_ARROWS_MAP_CENTER)
        [self updateDestinationsUsingMapCenter];
    else
        [self doLocationUpdate];
}

-(UIStatusBarStyle)getPreferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(UIColor *)getStatusBarColor
{
    return UIColorFromRGB(0x021e33);
}

- (void)updateFrame:(BOOL)animated
{
    CGRect frame;

    BOOL _navBarHidden = _destinationCells.count > 0;
    self.navBarView.hidden = _navBarHidden;
    CGFloat navBarHeight = !_navBarHidden ? self.navBarView.bounds.size.height : 0.0;
    
    CGFloat top = [OAUtilities getStatusBarHeight];
    CGFloat w = DeviceScreenWidth;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            _singleLineMode = YES;
            CGFloat h = 50.0;
            if (_destinationCells.count == 0)
                h = navBarHeight;
            
            frame = CGRectMake(0.0, top, w, h);
            
            if (_multiCell)
            {
                if ([_settings.distanceIndication get] == TOP_BAR_DISPLAY)
                    _multiCell.contentView.hidden = NO;
                else
                    _multiCell.contentView.hidden = YES;
            }
            for (OADestinationCell *cell in _destinationCells)
                cell.contentView.hidden = YES;
        }
        else
        {
            _singleLineMode = NO;
            CGFloat h = 0.0;

            if (_destinationCells.count > 0 && [_settings.distanceIndication get] == TOP_BAR_DISPLAY)
                h = 50.0 + 35.0 * (_destinationCells.count - 1.0);
            else
                h = navBarHeight;

            if (h < 0.0)
                h = 0.0;
            
            frame = CGRectMake(0.0, top, w, h);

            if (_multiCell)
                _multiCell.contentView.hidden = YES;

            for (OADestinationCell *cell in _destinationCells)
            {
                cell.contentView.hidden = NO;
//                cell.contentView.backgroundColor = [cell isDirectionRTL];
                
//                if ([cell isDirectionRTL])
//                {
//                    cell.contentView.backgroundColor = UIColor.redColor;
//                }
//                else
//                {
//                    cell.contentView.backgroundColor = UIColor.greenColor;
//                }
            }
            
            
        }
    }
    else
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            _singleLineMode = YES;
            CGFloat h = 50.0;
            if (_destinationCells.count == 0)
                h = navBarHeight;
            
            frame = CGRectMake(0.0, top, w, h);
            
            if (_multiCell)
            {
                if ([_settings.distanceIndication get] == TOP_BAR_DISPLAY)
                    _multiCell.contentView.hidden = NO;
                else
                    _multiCell.contentView.hidden = YES;
            }
            for (OADestinationCell *cell in _destinationCells)
                cell.contentView.hidden = YES;
        }
        else
        {
            _singleLineMode = YES;
            CGFloat h = 50.0;
            if (_destinationCells.count == 0)
                h = navBarHeight;
            
            frame = CGRectMake(0.0 - OAUtilities.getLeftMargin, top, w, h);
            
            if (_multiCell)
            {
                if ([_settings.distanceIndication get] == TOP_BAR_DISPLAY)
                    _multiCell.contentView.hidden = NO;
                else
                    _multiCell.contentView.hidden = YES;
            }
            for (OADestinationCell *cell in _destinationCells)
                cell.contentView.hidden = YES;
        }
    }
    
    self.view.frame = frame;
    
    [self.delegate toolbarLayoutDidChange:self animated:animated];
}

- (void)updateLayout
{
    CGFloat width = self.view.bounds.size.width;
    
    if (_singleLineMode)
    {
        if (_multiCell)
        {
            CGRect frame = CGRectMake(0.0, 0.0, width, 50.0);
            [_multiCell updateLayout:frame];
            CGFloat cornerRadius = [OAUtilities isLandscape] ? 3 : 0;
            [OAUtilities setMaskTo:_multiCell.contentView byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight radius:cornerRadius];
        }
    }
    else
    {
        int i = 0;
        CGFloat y = 0.0;
        
        for (OADestinationCell *cell in _destinationCells)
        {
            CGFloat h = (i == 0 ? 50.0 : 35.0);
            
            CGRect frame = CGRectMake(0.0, y, width, h);
            [cell updateLayout:frame];

            y += h;
            
            i++;
        }
    }
}

- (void) openHideDestinationCardsView:(id)sender
{
    if (self.destinationDelegate)
        [self.destinationDelegate openHideDestinationCardsView];
}

-(void) markAsVisited:(OADestination *)destination
{
    [[OADestinationsHelper instance] addHistoryItem:destination];
    
    if (!destination.routePoint)
    {
        [[OADestinationsHelper instance] removeDestination:destination];
    }
    else
    {
        [[OAGPXRouter sharedInstance].routeDoc moveToInactiveByIndex:destination.routePointIndex];
        [[OAGPXRouter sharedInstance].routeDoc updatePointsArray];
    }
}

- (void) doRemoveDestination:(OADestination *)destination
{
    // process single cells
    OADestinationCell *cell;
    for (OADestinationCell *c in _destinationCells)
        if ([c.destinations containsObject:destination])
        {
            cell = c;
            break;
        }
    
    if (cell)
    {
        [self onDestinationsChanged];
        [self updateFrame:YES];
    }
    
    // process multi cell
    BOOL isCellEmpty = NO;
    
    if ([OADestinationsHelper instance].sortedDestinations.count > 0)
    {
        _multiCell.destinations = [NSArray arrayWithArray:[OADestinationsHelper instance].sortedDestinations];
    }
    else
    {
        isCellEmpty = YES;
        _multiCell.destinations = nil;
    }
    
    if (isCellEmpty)
    {
        [self.delegate toolbarHide:self];

        [_multiCell.contentView removeFromSuperview];
        _multiCell = nil;
        [self stopLocationUpdate];
    }
}

- (UIColor *) addDestination:(OADestination *)destination
{
    if (destination.parking)
    {
        for (OADestination *dest in _app.data.destinations)
            if (dest.parking)
            {
                [[OADestinationsHelper instance] removeDestination:dest];
                break;
            }
    }
    
    CLLocationCoordinate2D location;
    CLLocationDirection direction;
    [self obtainCurrentLocationDirection:&location direction:&direction];
    
    if (destination.parking)
    {
        destination.color = _parkingColor;
        destination.markerResourceName = @"map_parking_pin";
    }
    else
    {
        int colorIndex = [self getFreeColorIndex];
        destination.color = _colors[colorIndex];
        destination.markerResourceName = _markerNames[colorIndex];
    }

    [[OADestinationsHelper instance] addDestination:destination];

    NSArray *destinations = [OADestinationsHelper instance].sortedDestinations;

    if (!_multiCell)
    {
        self.multiCell = [[OAMultiDestinationCell alloc] initWithDestinations:[NSArray arrayWithArray:destinations]];
        _multiCell.delegate = self;

        [self.view addSubview:_multiCell.contentView];
    }
    else
    {
        _multiCell.destinations = [NSArray arrayWithArray:destinations];
    }
    [_multiCell updateDirections:location direction:direction];
    
    [self onDestinationsChanged];
    
    if (self.destinationDelegate)
        [self.destinationDelegate destinationsAdded];
    
    [self startLocationUpdate];
    
    return [destination.color copy];
}

- (void) updateDestinations
{
    CLLocationCoordinate2D location;
    CLLocationDirection direction;
    [self obtainCurrentLocationDirection:&location direction:&direction];
    [_multiCell updateDirections:location direction:direction];
    [self.view setNeedsLayout];
}

- (int) getFreeColorIndex
{
    for (int i = 0; i < _colors.count; i++)
    {
        UIColor *c = _colors[i];
        BOOL colorExists = NO;
        for (OADestination *destination in _app.data.destinations)
            if (!destination.parking && !destination.routePoint && [OAUtilities areColorsEqual:destination.color color2:c])
            {
                colorExists = YES;
                break;
            }

        if (!colorExists)
            return i;
    }

    UIColor *lastUsedColor;
    for (long i = (long) _app.data.destinations.count - 1; i >= 0; i--)
    {
        OADestination *destination = _app.data.destinations[i];
        if (destination.color && !destination.parking && !destination.routePoint)
        {
            lastUsedColor = destination.color;
            break;
        }
    }
    
    if (lastUsedColor)
    {
        for (int i = 0; i < _colors.count; i++)
        {
            UIColor *c = _colors[i];
            if ([OAUtilities areColorsEqual:lastUsedColor color2:c])
            {
                int res = i + 1;
                if (res >= _colors.count)
                    res = 0;
                return res;
            }
        }
    }

    return 0;
}

- (void) updateDestinationsUsingMapCenter
{
    float mapDirection = _app.data.mapLastViewedState.azimuth;
    CLLocationCoordinate2D location = [OAAppSettings sharedManager].mapCenter;
    CLLocationDirection direction = mapDirection;

    _location = location;
    _direction = direction;
        
    if (_multiCell)
    {
        _multiCell.mapCenterArrow = YES;
        [_multiCell updateDirections:location direction:direction];
    }
    for (OADestinationCell *cell in _destinationCells)
    {
        cell.mapCenterArrow = YES;
        [cell updateDirections:location direction:direction];
    }
}

- (void) doLocationUpdate
{
    if (_settings.settingMapArrows == MAP_ARROWS_MAP_CENTER)
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Obtain fresh location and heading
        CLLocation* newLocation = _app.locationServices.lastKnownLocation;
        if (!newLocation)
            return;
        CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
        CLLocationDirection newDirection =
        (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
        ? newLocation.course
        : newHeading;
        
        if (_location.latitude != newLocation.coordinate.latitude ||
            _location.longitude != newLocation.coordinate.longitude ||
            _direction != newDirection)
        {
            _location = newLocation.coordinate;
            _direction = newDirection;
            
            CLLocationCoordinate2D location = _location;
            CLLocationDirection direction = _direction;

            if (_multiCell)
            {
                _multiCell.mapCenterArrow = NO;
                [_multiCell updateDirections:location direction:direction];
            }
            for (OADestinationCell *cell in _destinationCells)
            {
                cell.mapCenterArrow = NO;
                [cell updateDirections:location direction:direction];
            }
        }
        
        if ([[NSDate date] timeIntervalSince1970] - _lastUpdate > 1.0)
            [[OADestinationsHelper instance] apply2ndRowAutoSelection];
        else
            _lastUpdate = [[NSDate date] timeIntervalSince1970];
    });
}

- (void)startLocationUpdate
{
    if ([OADestinationsHelper instance].sortedDestinations.count == 0 || _locationServicesUpdateObserver)
        return;
    
    OsmAndAppInstance app = [OsmAndApp instance];
    
    _locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(doLocationUpdate)
                                                                     andObserve:app.locationServices.updateObserver];
}

- (void)stopLocationUpdate
{
    if (_locationServicesUpdateObserver)
    {
        [_locationServicesUpdateObserver detach];
        _locationServicesUpdateObserver = nil;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];

    if (!self.destinationDelegate || [OADestinationCardsViewController sharedInstance].view.superview)
        return;
    
    UITouch *touch = [[event allTouches] anyObject];
    
    if (!_singleLineMode) {
        for (OADestinationCell *c in _destinationCells) {
            CGPoint touchPoint = [touch locationInView:c.contentView];
            OADestination *destination = [c destinationByPoint:touchPoint];
            if (destination)
                [self.destinationDelegate destinationViewMoveTo:destination];
        }
    } else {
        
        CGPoint touchPoint = [touch locationInView:_multiCell.contentView];
        OADestination *destination = [_multiCell destinationByPoint:touchPoint];
        if (destination)
            [self.destinationDelegate destinationViewMoveTo:destination];
    }
}

- (void)updateCloseButton
{
    for (OADestinationCell *c in _destinationCells)
        [c updateCloseButton];
    
    if (_multiCell)
        [_multiCell updateCloseButton];
}

- (CGFloat) getHeight
{
    NSUInteger extraCellsCount = _destinationCells.count > 0 ? _destinationCells.count - 1 : 0;
    return [OAUtilities isLandscape] ? 50.0 : 50.0 + 35.0 * extraCellsCount;
}

@end
