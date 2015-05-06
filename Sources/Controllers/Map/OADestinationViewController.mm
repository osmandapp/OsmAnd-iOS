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

#import <OsmAndCore.h>
#import <OsmAndCore/Utilities.h>

@interface OADestinationViewController ()

@property (nonatomic) NSMutableArray *destinationCells;
@property (nonatomic) OAMultiDestinationCell *multiCell;

@property (nonatomic) UIColor *parkingColor;
@property (nonatomic) NSArray *colors;
@property (nonatomic) NSArray *markerNames;
@property (nonatomic) NSMutableArray *usedColors;

@property (nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;

@end

@implementation OADestinationViewController {
    
    BOOL _singleLineMode;
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    CLLocationCoordinate2D _location;
    CLLocationDirection _direction;

}

- (NSArray *)allDestinations
{
    return [NSArray arrayWithArray:_app.data.destinations];
}

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];

    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.destinationCells = [NSMutableArray array];
        self.usedColors = [NSMutableArray array];
        
        self.parkingColor = [UIColor colorWithRed:0.290f green:0.412f blue:0.925f alpha:1.00f];
        
        self.colors = @[[UIColor colorWithRed:0.369f green:0.510f blue:0.914f alpha:1.00f],
                        [UIColor colorWithRed:0.992f green:0.627f blue:0.200f alpha:1.00f],
                        [UIColor colorWithRed:0.541f green:0.741f blue:0.373f alpha:1.00f]];
        self.markerNames = @[@"ic_destination_pin_2", @"ic_destination_pin_1", @"ic_destination_pin_3"];        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_app.data.destinations.count > 0)
    {
        CLLocationCoordinate2D location;
        CLLocationDirection direction;
        [self obtainCurrentLocationDirection:&location direction:&direction];

        if (!_multiCell)
        {
            self.multiCell = [[OAMultiDestinationCell alloc] initWithDestinations:_app.data.destinations];
            [_multiCell updateDirections:location direction:direction];
            _multiCell.delegate = self;
            [self.view addSubview:_multiCell.contentView];
        }
        
        for (OADestination *destination in _app.data.destinations)
        {
            OADestinationCell *cell = [[OADestinationCell alloc] initWithDestination:destination];
            [cell updateDirections:location direction:direction];
            cell.delegate = self;
            [_destinationCells addObject:cell];
            [self.view addSubview:cell.contentView];
            
            [_usedColors addObject:destination.color];
        }
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
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) && !_singleLineOnly)
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            _singleLineMode = YES;
            CGFloat h = 50.0 + (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) && (_app.data.destinations.count == 3) ? 20.0 : 0.0);
            if (_app.data.destinations.count == 0)
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
            CGFloat h = 50.0 * _app.data.destinations.count + _app.data.destinations.count - 1.0;
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
            CGFloat h = 50.0 + (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) && (_app.data.destinations.count == 3) ? 20.0 : 0.0);
            if (_app.data.destinations.count == 0)
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
            CGFloat h = 50.0 + (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) && (_app.data.destinations.count == 3) ? 20.0 : 0.0);
            if (_app.data.destinations.count == 0)
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


- (void)btnCloseClicked:(id)sender destination:(OADestination *)destination
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([_app.data.destinations containsObject:destination]) {
            
            [_usedColors removeObject:destination.color];
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
            
            if (cell) {
                
                [_destinationCells removeObject:cell];
                [UIView animateWithDuration:.2 animations:^{
                    cell.contentView.alpha = 0.0;
                    
                } completion:^(BOOL finished) {
                    [self updateFrame:YES];
                    [cell.contentView removeFromSuperview];
                    if (_app.data.destinations.count == 0) {
                        [self.view removeFromSuperview];
                        [self stopLocationUpdate];
                    }
                }];
                
            }
            
            // process multi cell
            BOOL isCellEmpty = NO;
            
            if (_multiCell.destinations.count > 1) {
                NSMutableArray *arr = [NSMutableArray arrayWithArray:_multiCell.destinations];
                [arr removeObject:destination];
                [UIView animateWithDuration:.2 animations:^{
                    _multiCell.destinations = [NSArray arrayWithArray:arr];
                }];
            } else {
                isCellEmpty = YES;
                _multiCell.destinations = nil;
            }
            
            if (isCellEmpty) {
                [UIView animateWithDuration:.2 animations:^{
                    _multiCell.contentView.alpha = 0.0;
                    
                } completion:^(BOOL finished) {
                    
                    if (_multiCell.editModeActive)
                        [_multiCell exitEditMode];

                    [self updateFrame:YES];
                    [_multiCell.contentView removeFromSuperview];
                    _multiCell = nil;
                    if (_app.data.destinations.count == 0) {
                        [self.view removeFromSuperview];
                        [self stopLocationUpdate];
                    }
                }];
            }
        }
    });
}

- (UIColor *) addDestination:(OADestination *)destination
{
    if (_app.data.destinations.count >= 3)
        return nil;
    
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

    if (!_multiCell) {
        self.multiCell = [[OAMultiDestinationCell alloc] initWithDestinations:@[destination]];
        _multiCell.delegate = self;
        if (_singleLineMode)
            _multiCell.contentView.alpha = 0.0;
        [self.view addSubview:_multiCell.contentView];
    } else {
        [UIView animateWithDuration:.2 animations:^{
            _multiCell.destinations = [NSArray arrayWithArray:_app.data.destinations];
        }];
    }
    [_multiCell updateDirections:location direction:direction];
    
    OADestinationCell *cell = [[OADestinationCell alloc] initWithDestination:destination];
    [cell updateDirections:location direction:direction];
    cell.delegate = self;
    if (!_singleLineMode)
        cell.contentView.alpha = 0.0;
    else
        cell.contentView.hidden = YES;
    
    [_destinationCells addObject:cell];
    [self.view addSubview:cell.contentView];
    
    if (!_singleLineMode)
        [UIView animateWithDuration:.2 animations:^{
            cell.contentView.alpha = 1.0;
        }];
    else  if (_multiCell.contentView.alpha == 0.0)
        [UIView animateWithDuration:.2 animations:^{
            _multiCell.contentView.alpha = 1.0;
        }];

    [self startLocationUpdate];
    
    return [destination.color copy];
}

- (int)getFreeColorIndex
{
    for (int i = 0; i < _colors.count; i++) {
        UIColor *c = _colors[i];
        if (![_usedColors containsObject:c]) {
            [_usedColors addObject:c];
            return i;
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
    if (_app.data.destinations.count == 0 || self.locationServicesUpdateObserver)
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

/*
-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
}
*/

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];

    if (!_delegate)
        return;
    
    UITouch *touch = [[event allTouches] anyObject];
    
    if (!_singleLineMode) {
        for (OADestinationCell *c in _destinationCells) {
            CGPoint touchPoint = [touch locationInView:c.contentView];
            OADestination *destination = [c destinationByPoint:touchPoint];
            if (destination)
                [_delegate destinationViewMoveToLatitude:destination.latitude lon:destination.longitude];
        }
    } else {
        
        CGPoint touchPoint = [touch locationInView:_multiCell.contentView];
        OADestination *destination = [_multiCell destinationByPoint:touchPoint];
        if (destination)
            [_delegate destinationViewMoveToLatitude:destination.latitude lon:destination.longitude];
        
    }
}

@end
