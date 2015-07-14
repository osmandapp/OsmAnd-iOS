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

        self.colors = @[UIColorFromRGB(0x008596),
                        UIColorFromRGB(0xEBA033),
                        UIColorFromRGB(0x8ABD5F)];
        self.markerNames = @[@"ic_destination_pin_2", @"ic_destination_pin_1", @"ic_destination_pin_3"];
        
        _gpxRouteDefinedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onDestinationsChanged)
                                                              andObserve:[OAGPXRouter sharedInstance].routeDefinedObservable];
        _gpxRouteChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onDestinationsChanged)
                                                              andObserve:[OAGPXRouter sharedInstance].routeChangedObservable];
        _gpxRouteCanceledObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onDestinationsChanged)
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
    
    if ([OADestinationsHelper instance].topDestinations.count > 0)
    {
        [self refreshCells];
    }
}

- (void)onDestinationsChanged
{
    [[OADestinationsHelper instance] refreshTopDestinations];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshCells];
    });
}

- (void)refreshCells
{
    [self clean];

    if ([OADestinationsHelper instance].topDestinations.count == 0)
        return;

    CLLocationCoordinate2D location;
    CLLocationDirection direction;
    [self obtainCurrentLocationDirection:&location direction:&direction];

    NSArray *destinations = [OADestinationsHelper instance].topDestinations;
    
    NSInteger firstCellDestinationIndex = (destinations.count >= 1 ? [destinations[0] integerValue] : -1);
    NSInteger secondCellDestinationIndex = (destinations.count >= 2 ? [destinations[1] integerValue] : -1);
    
    if (firstCellDestinationIndex >= 0)
    {
        OADestination *destination = _app.data.destinations[firstCellDestinationIndex];

        OADestinationCell *cell;
        if (_destinationCells.count == 0)
        {
            cell = [[OADestinationCell alloc] initWithDestination:destination destinationIndex:firstCellDestinationIndex];
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
    
    if (secondCellDestinationIndex >= 0)
    {
        OADestination *destination = _app.data.destinations[secondCellDestinationIndex];
        
        OADestinationCell *cell;
        if (_destinationCells.count == 1)
        {
            cell = [[OADestinationCell alloc] initWithDestination:destination destinationIndex:secondCellDestinationIndex];
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
        self.multiCell = [[OAMultiDestinationCell alloc] initWithDestinations:_app.data.destinations];
        _multiCell.delegate = self;
        [self.view addSubview:_multiCell.contentView];
    }
    
    [_multiCell updateDirections:location direction:direction];
    //[_multiCell refreshViews];
}

- (void)clean
{
    NSInteger destinationsCount = [OADestinationsHelper instance].topDestinations.count;
    
    while (_destinationCells.count > destinationsCount)
    {
        OADestinationCell *cell = [_destinationCells lastObject];
        [cell.contentView removeFromSuperview];
        [_destinationCells removeLastObject];
    }
    
    if (destinationsCount == 0 && self.view.superview)
    {
        [self.view removeFromSuperview];
        [self stopLocationUpdate];
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
    CGFloat big;
    CGFloat small;
    
    CGRect rect = [UIScreen mainScreen].bounds;
    if (rect.size.width > rect.size.height) {
        big = rect.size.width;
        small = rect.size.height;
    } else {
        big = rect.size.height;
        small = rect.size.width;
    }
    
    CGRect frame;
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) && _singleLineOnly)
        big = small;
    
    NSInteger destinationsCount = [OADestinationsHelper instance].topDestinations.count;
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) && !_singleLineOnly)
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad || kOADestinationsSingleLineOnly)
        {
            _singleLineMode = YES;
            CGFloat h = 50.0;
            if (destinationsCount == 0)
                h = 0.0;
            
            frame = CGRectMake(0.0, _top, small, h);
            
            if (_multiCell)
                _multiCell.contentView.hidden = NO;
            for (OADestinationCell *cell in _destinationCells)
                cell.contentView.hidden = YES;
        }
        else
        {
           
            _singleLineMode = NO;
            CGFloat h = 50.0 * destinationsCount + destinationsCount - 1.0;
            if (h < 0.0)
                h = 0.0;
            frame = CGRectMake(0.0, _top, small, h);

            if (_multiCell) {
                _multiCell.contentView.hidden = YES;
                if (_multiCell.editModeActive)
                    [_multiCell exitEditMode];
            }
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
            
            frame = CGRectMake(0.0, _top, big, h);
            
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
            
            frame = CGRectMake(0.0, _top, big, h);
            
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
    
    if (_singleLineMode) {
        if (_multiCell) {
            CGRect frame = CGRectMake(0.0, 0.0, width, 50.0);
            [_multiCell updateLayout:frame];
            //_multiCell.contentView.hidden = NO;
        }
    } else {
        int i = 0;
        for (OADestinationCell *cell in _destinationCells) {
            cell.drawSplitLine = i > 0;
            CGRect frame = CGRectMake(0.0, 50.0 * i + i - (cell.drawSplitLine ? 1 : 0), width, 50.0 + (cell.drawSplitLine ? 1 : 0));
            [cell updateLayout:frame];
            //cell.contentView.hidden = NO;
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

- (void)removeDestination:(OADestination *)destination
{
    if (destination.parking)
        [self removeParkingReminderFromCalendar:destination];
    
    if ([_app.data.destinations containsObject:destination])
    {
        [_app.data.destinations removeObject:destination];
        
        if (_delegate)
            [_delegate destinationRemoved:destination];
        
        // process single cells
        OADestinationCell *cell;
        for (OADestinationCell *c in _destinationCells)
            if ([c.destinations containsObject:destination]) {
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
        
        if (_multiCell.destinations.count > 1)
        {
            NSMutableArray *arr = [NSMutableArray arrayWithArray:_multiCell.destinations];
            [arr removeObject:destination];
            _multiCell.destinations = [NSArray arrayWithArray:arr];
        }
        else
        {
            isCellEmpty = YES;
            _multiCell.destinations = nil;
        }
        
        if (isCellEmpty)
        {
            if (_multiCell.editModeActive)
                [_multiCell exitEditMode];
            
            [self updateFrame:YES];
            [_multiCell.contentView removeFromSuperview];
            _multiCell = nil;
            if ([OADestinationsHelper instance].topDestinations.count == 0)
            {
                [self.view removeFromSuperview];
                [self stopLocationUpdate];
            }
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

    [_app.data.destinations addObject:destination];
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

    if (!_multiCell)
    {
        self.multiCell = [[OAMultiDestinationCell alloc] initWithDestinations:@[destination]];
        _multiCell.delegate = self;

        [self.view addSubview:_multiCell.contentView];
    }
    else
    {
        _multiCell.destinations = [NSArray arrayWithArray:_app.data.destinations];
    }
    [_multiCell updateDirections:location direction:direction];
    
    [self onDestinationsChanged];
    
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
    if ([OADestinationsHelper instance].topDestinations.count == 0 || self.locationServicesUpdateObserver)
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

@end
