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
#import "OADestinationCardsViewController.h"

#import <EventKit/EventKit.h>

#import <OsmAndCore.h>
#import <OsmAndCore/Utilities.h>

@interface OADestinationViewController ()

@property (nonatomic) NSMutableArray *destinationCells;
@property (nonatomic) OAMultiDestinationCell *multiCell;

@property (nonatomic) UIColor *parkingColor;
@property (nonatomic) NSArray *colors;
@property (nonatomic) NSArray *markerNames;

@property (nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;
@property (nonatomic) OAAutoObserverProxy* destinationsChangeObserver;

@end

@implementation OADestinationViewController
{
    BOOL _singleLineMode;
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    CLLocationCoordinate2D _location;
    CLLocationDirection _direction;

    OAAutoObserverProxy* _gpxRouteDefinedObserver;
    OAAutoObserverProxy* _gpxRouteChangedObserver;
    OAAutoObserverProxy* _gpxRouteCanceledObserver;
}

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];

    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.destinationCells = [NSMutableArray array];
        
        self.parkingColor = UIColorFromRGB(0x4A69EC);

        self.colors = @[UIColorFromRGB(0xff9207),
                        UIColorFromRGB(0x00bcd4),
                        UIColorFromRGB(0x7fbd4d),
                        UIColorFromRGB(0xff444a),
                        UIColorFromRGB(0xcddc39)];
        
        self.markerNames = @[@"ic_destination_pin_1", @"ic_destination_pin_2", @"ic_destination_pin_3", @"ic_destination_pin_4", @"ic_destination_pin_5"];
        
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
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([OADestinationsHelper instance].sortedDestinations.count > 0)
    {
        [self refreshCells];
    }
}

- (void)onRouteDefined
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self refreshCells];

        if (self.delegate)
            [self.delegate destinationsAdded];
    });
}

- (void)onRouteCanceled
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self refreshCells];
        [self updateFrame:YES];
    });
}

- (void)onDestinationsChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshCells];
    });
}

- (void)refreshCells
{
    [self clean];

    if ([OADestinationsHelper instance].sortedDestinations.count == 0)
        return;

    CLLocationCoordinate2D location;
    CLLocationDirection direction;
    [self obtainCurrentLocationDirection:&location direction:&direction];

    NSArray *destinations = [OADestinationsHelper instance].sortedDestinations;
    
    OADestination *firstCellDestination = (destinations.count >= 1 ? destinations[0] : nil);
    OADestination *secondCellDestination = (destinations.count >= 2 ? destinations[1] : nil);
    
    if (firstCellDestination)
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
    
    if (secondCellDestination)
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
}

- (void)clean
{
    NSInteger destinationsCount = [OADestinationsHelper instance].sortedDestinations.count;
    
    while (_destinationCells.count > destinationsCount)
    {
        OADestinationCell *cell = [_destinationCells lastObject];
        [cell.contentView removeFromSuperview];
        [_destinationCells removeLastObject];
    }
    
    if (destinationsCount == 0)
    {
        [self stopLocationUpdate];
        [self.view removeFromSuperview];
    }
}

-(void)obtainCurrentLocationDirection:(CLLocationCoordinate2D*)location direction:(CLLocationDirection*)direction
{
    if (_app.appMode == OAAppModeBrowseMap && _settings.settingMapArrows == MAP_ARROWS_MAP_CENTER)
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
        CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
        CLLocationDirection newDirection =
        (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
        ? newLocation.course
        : newHeading;
        
        *location = newLocation.coordinate;
        *direction = newDirection;
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

- (void)updateFrame:(BOOL)animated
{
    CGRect frame;
    
    NSInteger destinationsCount = MIN(2, [OADestinationsHelper instance].sortedDestinations.count);
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            _singleLineMode = YES;
            CGFloat h = 50.0;
            if (destinationsCount == 0)
                h = 0.0;
            
            frame = CGRectMake(0.0, _top, DeviceScreenWidth, h);
            
            if (_multiCell)
                _multiCell.contentView.hidden = NO;
            for (OADestinationCell *cell in _destinationCells)
                cell.contentView.hidden = YES;
        }
        else
        {
            _singleLineMode = NO;
            CGFloat h = 0.0;

            if (destinationsCount > 0)
                h = 50.0 + 35.0 * (destinationsCount - 1.0);

            if (h < 0.0)
                h = 0.0;
            
            frame = CGRectMake(0.0, _top, DeviceScreenWidth, h);

            if (_multiCell)
                _multiCell.contentView.hidden = YES;

            for (OADestinationCell *cell in _destinationCells)
                cell.contentView.hidden = NO;
        }
    }
    else
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            _singleLineMode = YES;
            CGFloat h = 50.0;
            if (destinationsCount == 0)
                h = 0.0;
            
            frame = CGRectMake(0.0, _top, DeviceScreenWidth, h);
            
            if (_multiCell)
                _multiCell.contentView.hidden = NO;
            for (OADestinationCell *cell in _destinationCells)
                cell.contentView.hidden = YES;
        }
        else
        {
            _singleLineMode = YES;
            CGFloat h = 50.0;
            if (destinationsCount == 0)
                h = 0.0;
            
            frame = CGRectMake(0.0, _top, DeviceScreenWidth, h);
            
            if (_multiCell)
                _multiCell.contentView.hidden = NO;
            for (OADestinationCell *cell in _destinationCells)
                cell.contentView.hidden = YES;
        }
    }
    
    self.view.frame = frame;
    
    if (_delegate)
        [_delegate destinationViewLayoutDidChange:animated];
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

- (void)openHideDestinationCardsView:(id)sender
{
    if (self.delegate)
        [_delegate openHideDestinationCardsView];
}

- (void)removeParkingReminderFromCalendar:(OADestination *)destination
{
    if (destination.eventIdentifier)
    {
        EKEventStore *eventStore = [[EKEventStore alloc] init];
        EKEvent *event = [eventStore eventWithIdentifier:destination.eventIdentifier];
        NSError *error;
        if (![eventStore removeEvent:event span:EKSpanFutureEvents error:&error])
            OALog(@"%@", [error localizedDescription]);
        else
            destination.eventIdentifier = nil;
    }
}

-(void)markAsVisited:(OADestination *)destination
{
    if (!destination.routePoint)
    {
        [self removeDestination:destination];
    }
    else
    {
        
    }
}

- (void)removeDestination:(OADestination *)destination
{
    if (destination.parking)
        [self removeParkingReminderFromCalendar:destination];
    
    if ([_app.data.destinations containsObject:destination])
    {
        [[OADestinationsHelper instance] removeDestination:destination];

        if (_delegate)
            [_delegate destinationRemoved:destination];
        
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
            [self updateFrame:YES];
            [_multiCell.contentView removeFromSuperview];
            _multiCell = nil;

            [self.view removeFromSuperview];
            [self stopLocationUpdate];
        }
    }
}

- (UIColor *) addDestination:(OADestination *)destination
{
    if (destination.parking)
    {
        for (OADestination *dest in _app.data.destinations)
            if (dest.parking)
            {
                [self removeDestination:dest];
                break;
            }
    }
    
    CLLocationCoordinate2D location;
    CLLocationDirection direction;
    [self obtainCurrentLocationDirection:&location direction:&direction];

    [[OADestinationsHelper instance] addDestination:destination];
    
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
    
    if (self.delegate)
        [self.delegate destinationsAdded];
    
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
    for (int i = _app.data.destinations.count - 1; i >= 0; i--)
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

- (void)updateDestinationsUsingMapCenter
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

- (void)doLocationUpdate
{
    if (_app.appMode == OAAppModeBrowseMap && _settings.settingMapArrows == MAP_ARROWS_MAP_CENTER)
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Obtain fresh location and heading
        CLLocation* newLocation = _app.locationServices.lastKnownLocation;
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
    });
}

- (void)startLocationUpdate
{
    if ([OADestinationsHelper instance].sortedDestinations.count == 0 || self.locationServicesUpdateObserver)
        return;
    
    OsmAndAppInstance app = [OsmAndApp instance];
    self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(doLocationUpdate)
                                                                     andObserve:app.locationServices.updateObserver];
}

- (void)stopLocationUpdate
{
    if (self.locationServicesUpdateObserver) {
        [self.locationServicesUpdateObserver detach];
        self.locationServicesUpdateObserver = nil;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];

    if (!_delegate || [OADestinationCardsViewController sharedInstance].view.superview)
        return;
    
    UITouch *touch = [[event allTouches] anyObject];
    
    if (!_singleLineMode) {
        for (OADestinationCell *c in _destinationCells) {
            CGPoint touchPoint = [touch locationInView:c.contentView];
            OADestination *destination = [c destinationByPoint:touchPoint];
            if (destination)
                [_delegate destinationViewMoveTo:destination];
        }
    } else {
        
        CGPoint touchPoint = [touch locationInView:_multiCell.contentView];
        OADestination *destination = [_multiCell destinationByPoint:touchPoint];
        if (destination)
            [_delegate destinationViewMoveTo:destination];
    }
}


- (void)updateCloseButton
{
    for (OADestinationCell *c in _destinationCells)
        [c updateCloseButton];
    
    if (_multiCell)
        [_multiCell updateCloseButton];
}

@end
