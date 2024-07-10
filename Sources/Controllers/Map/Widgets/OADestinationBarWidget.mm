//
//  OADestinationTopWidget.m
//  OsmAnd Maps
//
//  Created by Alexey K on 27.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OADestinationBarWidget.h"
#import "OADestination.h"
#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OALocationServices.h"
#import "OAMultiDestinationCell.h"
#import "OAObservable.h"
#import "OAAppSettings.h"
#import "OALog.h"
#import "OAUtilities.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OADestinationsHelper.h"
#import "OAHistoryHelper.h"
#import "OAHistoryItem.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAValueTableViewCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OAAppData.h"
#import "OsmAnd_Maps-Swift.h"

@interface OADestinationBarWidget ()

@property (nonatomic) NSMutableArray *destinationCells;
@property (nonatomic) OAMultiDestinationCell *multiCell;

@end

@implementation OADestinationBarWidget
{
    BOOL _singleLineMode;
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OADestinationsHelper *_helper;

    CLLocationCoordinate2D _location;
    CLLocationDirection _direction;

    OAAutoObserverProxy* _locationUpdateObserver;
    OAAutoObserverProxy* _headingUpdateObserver;

    OAAutoObserverProxy* _destinationsChangeObserver;
    OAAutoObserverProxy* _mapLocationObserver;

    NSTimeInterval _lastUpdate;
}

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil];
    for (UIView *v in bundle)
        if ([v isKindOfClass:[OADestinationBarWidget class]])
        {
            self = (OADestinationBarWidget *)v;
            break;
        }

    if (self)
        self.frame = CGRectMake(0, 0, 414, 50);

    [self commonInit];
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
        if ([v isKindOfClass:[OADestinationBarWidget class]])
        {
            self = (OADestinationBarWidget *)v;
            break;
        }

    if (self)
        self.frame = frame;

    [self commonInit];
    return self;
}

- (void) commonInit
{
    self.widgetType = OAWidgetType.markersTopBar;
    
    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];
    _helper = [OADestinationsHelper instance];

    self.destinationCells = [NSMutableArray array];
}

- (BOOL) updateInfo
{
    BOOL visible = _helper.sortedDestinations.count > 0
    	&& [OAWidgetsVisibilityHelper.sharedInstance shouldShowTopMapMarkersWidget];
    [self updateVisibility:visible];

    return YES;
}

- (BOOL) updateVisibility:(BOOL)visible
{
    if (visible == self.hidden)
    {
        self.hidden = !visible;
        if (self.delegate)
            [self.delegate widgetVisibilityChanged:self visible:visible];

        return YES;
    }
    return NO;
}

- (void) attachView:(UIView *_Nonnull)container specialContainer:(UIView *_Nullable)specialContainer order:(NSInteger)order followingWidgets:(NSArray<OABaseWidgetView *> *)followingWidgets
{
    [super attachView:container specialContainer:specialContainer order:order followingWidgets:followingWidgets];

    if (_helper.sortedDestinations.count > 0)
        [self refreshCells];

    _destinationsChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onDestinationsChanged)
                                                          andObserve:_app.data.destinationsChangeObservable];
    _mapLocationObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                     withHandler:@selector(onMapChanged:withKey:)
                                                      andObserve:OARootViewController.instance.mapPanel.mapViewController.mapObservable];
    [self startLocationUpdate];
}

- (void) detachView:(OAWidgetsPanel *)widgetsPanel
{
    [self stopLocationUpdate];

    if (_mapLocationObserver)
    {
        [_mapLocationObserver detach];
        _mapLocationObserver = nil;
    }
    if (_destinationsChangeObserver)
    {
        [_destinationsChangeObserver detach];
        _destinationsChangeObserver = nil;
    }

    [super detachView:widgetsPanel];
}

- (void) onDestinationsChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshCells];
        [self widgetChanged];
    });
}

- (void) onMapChanged:(id)observable withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([OAAppSettings sharedManager].settingMapArrows == MAP_ARROWS_MAP_CENTER)
            [self updateDestinationsUsingMapCenter];
        else
            [self doLocationUpdate];
    });
}

- (void) refreshView
{
    [self refreshCells];
    [self widgetChanged];
}

- (void) refreshCells
{
    [self clean];

    if (_helper.sortedDestinations.count == 0)
        return;

    CLLocationCoordinate2D location;
    CLLocationDirection direction;
    [self obtainCurrentLocationDirection:&location direction:&direction];

    NSArray *destinations = _helper.sortedDestinations;

    OADestination *firstCellDestination = (destinations.count >= 1 ? destinations[0] : nil);
    OADestination *secondCellDestination;
    if (_helper.dynamic2ndRowDestination)
        secondCellDestination = _helper.dynamic2ndRowDestination;
    else
        secondCellDestination = (destinations.count >= 2 ? destinations[1] : nil);

    if (firstCellDestination)
    {
        OADestination *destination = firstCellDestination;

        OADestinationCell *cell;
        if (_destinationCells.count == 0)
        {
            cell = [[OADestinationCell alloc] initWithDestination:destination destinationIndex:0];
            cell.delegate = self;
            [_destinationCells addObject:cell];
            [self insertSubview:cell.contentView atIndex:0];
        }
        else
        {
            cell = _destinationCells[0];
            cell.destinations = @[destination];
        }

        [cell updateDirections:location direction:direction];
    }

    if (secondCellDestination && [_settings.activeMarkers get] == TWO_ACTIVE_MARKERS)
    {
        OADestination *destination = secondCellDestination;

        OADestinationCell *cell;
        if (_destinationCells.count == 1)
        {
            cell = [[OADestinationCell alloc] initWithDestination:destination destinationIndex:1];
            cell.delegate = self;
            [_destinationCells addObject:cell];
            [self insertSubview:cell.contentView atIndex:0];
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
        [self addSubview:_multiCell.contentView];
    }
    else
    {
        _multiCell.destinations = [NSArray arrayWithArray:destinations];
    }

    [_multiCell updateDirections:location direction:direction];
}

- (void) clean
{
    NSInteger destinationsCount = [_settings.activeMarkers get] == TWO_ACTIVE_MARKERS ? _helper.sortedDestinations.count : 1;
    while (_destinationCells.count > destinationsCount)
    {
        OADestinationCell *cell = [_destinationCells lastObject];
        [cell.contentView removeFromSuperview];
        [_destinationCells removeLastObject];
    }
}

- (OATableDataModel *)getSettingsData:(OAApplicationMode *)appMode
{
    OACommonActiveMarkerConstant *pref = _settings.activeMarkers;
    OATableDataModel *data = [OATableDataModel model];
    OATableSectionData *section = [data createNewSection];
    section.headerText = OALocalizedString(@"shared_string_settings");
    section.footerText = OALocalizedString(@"specify_number_of_dir_indicators_desc");

    OATableRowData *settingRow = [section createNewRow];
    settingRow.cellType = [OAValueTableViewCell getCellIdentifier];
    settingRow.key = @"value_pref";
    settingRow.title = OALocalizedString(@"active_markers");
    [settingRow setObj:pref forKey:@"pref"];
    [settingRow setObj:[self getTitle:[pref get:appMode]] forKey: @"value"];
    [settingRow setObj:[self getPossibleValues] forKey: @"possible_values"];

    return data;
}

- (NSString *)getTitle:(EOAActiveMarkerConstant)amc
{
    switch (amc)
    {
        case ONE_ACTIVE_MARKER:
            return OALocalizedString(@"shared_string_one");
        case TWO_ACTIVE_MARKERS:
            return OALocalizedString(@"shared_string_two");
        default:
            return @"";
    }
}

- (NSArray<OATableRowData *> *)getPossibleValues
{
    NSMutableArray<OATableRowData *> *res = [NSMutableArray array];
    for (NSInteger i = ONE_ACTIVE_MARKER; i <= TWO_ACTIVE_MARKERS; i++)
    {
        OATableRowData *row = [[OATableRowData alloc] init];
        row.cellType = OASimpleTableViewCell.getCellIdentifier;
        [row setObj:@(i) forKey:@"value"];
        row.title = [self getTitle:(EOAActiveMarkerConstant) i];
        [res addObject:row];
    }
    return res;
}

- (void) obtainCurrentLocationDirection:(CLLocationCoordinate2D*)location direction:(CLLocationDirection*)direction
{
    if (_settings.settingMapArrows == MAP_ARROWS_MAP_CENTER)
    {
        CLLocation *mapLocation = OARootViewController.instance.mapPanel.mapViewController.getMapLocation;
        float mapDirection = _app.data.mapLastViewedState.azimuth;
        *location = mapLocation.coordinate;
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

- (void) widgetChanged
{
    if (self.delegate)
        [self.delegate widgetChanged:self];
}

- (void) adjustViewSize
{
    [super adjustViewSize];
    
    CGRect frame;
    CGFloat left = self.frame.origin.x;
    CGFloat top = self.frame.origin.y;
    CGFloat w = OAUtilities.calculateScreenWidth;
    if (!OAUtilities.isLandscape)
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            w = kInfoViewLandscapeWidthPad;
            _singleLineMode = YES;
            CGFloat h = 50.0;
            frame = CGRectMake(left, top, w, h);

            if (_multiCell)
                _multiCell.contentView.hidden = NO;

            for (OADestinationCell *cell in _destinationCells)
                cell.contentView.hidden = YES;
        }
        else
        {
            _singleLineMode = NO;
            CGFloat h = 0.0;

            if (_destinationCells.count > 0)
                h = 50.0 + 35.0 * (_destinationCells.count - 1.0);

            if (h < 0.0)
                h = 0.0;

            frame = CGRectMake(left, top, w, h);

            if (_multiCell)
                _multiCell.contentView.hidden = YES;

            for (OADestinationCell *cell in _destinationCells)
                cell.contentView.hidden = NO;
        }
    }
    else
    {
        w = kInfoViewLandscapeWidthPad;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            _singleLineMode = YES;
            CGFloat h = 50.0;
            frame = CGRectMake(left, top, w, h);

            if (_multiCell)
                _multiCell.contentView.hidden = NO;

            for (OADestinationCell *cell in _destinationCells)
                cell.contentView.hidden = YES;
        }
        else
        {
            _singleLineMode = YES;
            CGFloat h = 50.0;
            frame = CGRectMake(left, top, w, h);

            if (_multiCell)
                _multiCell.contentView.hidden = NO;

            for (OADestinationCell *cell in _destinationCells)
                cell.contentView.hidden = YES;
        }
    }

    self.frame = frame;

    [self updateLayout];
}

- (void) updateLayout
{
    CGFloat width = self.bounds.size.width;

    if (_singleLineMode)
    {
        if (_multiCell)
        {
            CGRect frame = CGRectMake(0.0, 0.0, width, 50.0);
            [_multiCell updateLayout:frame];
            CGFloat cornerRadius = [OAUtilities isLandscape] ? 3 : 0;
            [OAUtilities setMaskTo:_multiCell.contentView byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight radius:cornerRadius];

            self.layer.shadowColor = [UIColor.blackColor colorWithAlphaComponent:0.7].CGColor;
            self.layer.shadowOpacity = 1.0;
            self.layer.shadowRadius = 1.0;
            self.layer.shadowOffset = CGSizeMake(0.0, 1.0);
            self.layer.masksToBounds = NO;
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

- (void) updateDestinations
{
    CLLocationCoordinate2D location;
    CLLocationDirection direction;
    [self obtainCurrentLocationDirection:&location direction:&direction];
    [_multiCell updateDirections:location direction:direction];
    [self setNeedsLayout];
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
            [_helper apply2ndRowAutoSelection];
        else
            _lastUpdate = [[NSDate date] timeIntervalSince1970];
    });
}

- (void) startLocationUpdate
{
    if (_helper.sortedDestinations.count == 0 || _locationUpdateObserver)
        return;

    OsmAndAppInstance app = [OsmAndApp instance];

    _locationUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(doLocationUpdate)
                                                         andObserve:app.locationServices.updateLocationObserver];
    _headingUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(doLocationUpdate)
                                                        andObserve:app.locationServices.updateHeadingObserver];
}

- (void) stopLocationUpdate
{
    if (_locationUpdateObserver)
    {
        [_locationUpdateObserver detach];
        _locationUpdateObserver = nil;
    }
    if (_headingUpdateObserver)
    {
        [_headingUpdateObserver detach];
        _headingUpdateObserver = nil;
    }
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];

    UITouch *touch = [[event allTouches] anyObject];
    if (!_singleLineMode)
    {
        for (OADestinationCell *c in _destinationCells)
        {
            CGPoint touchPoint = [touch locationInView:c.contentView];
            OADestination *destination = [c destinationByPoint:touchPoint];
            if (destination)
                [[OARootViewController instance].mapPanel openTargetViewWithDestination:destination];
        }
    }
    else
    {
        CGPoint touchPoint = [touch locationInView:_multiCell.contentView];
        OADestination *destination = [_multiCell destinationByPoint:touchPoint];
        if (destination)
            [[OARootViewController instance].mapPanel openTargetViewWithDestination:destination];
    }
}

#pragma mark - OADestinatioCellProtocol

- (void) openDestinationViewController
{
    [OARootViewController.instance.mapPanel openDestinationViewController];
}

@end
