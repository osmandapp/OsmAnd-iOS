//
//  OAStreetNameWidgetParams.m
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 05.06.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAStreetNameWidgetParams.h"
#import "OATurnDrawable.h"
#import "OAAppSettings.h"
#import "OARoutingHelper.h"
#import "OACurrentStreetName.h"
#import "OARouteInfoView.h"
#import "OARoutingHelperUtils.h"
#import "OACurrentPositionHelper.h"
#import "OARouteDirectionInfo.h"
#import "OARouteCalculationResult.h"
#import "OALocationServices.h"
#import "OAMapViewTrackingUtilities.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAStreetNameWidgetParams
{
    OARoutingHelper *_routingHelper;
    OAAppSettings *_settings;
    OALocationServices *_locationProvider;
    OATurnDrawable *_turnDrawable;
    OANextDirectionInfo *_calc1;
    OACurrentPositionHelper *_currentPositionHelper;
}

- (instancetype)initWithTurnDrawable:(OATurnDrawable *)turnDrawable calc1:(OANextDirectionInfo *)calc1
{
    self = [super init];
    if (self)
    {
        _routingHelper = [OARoutingHelper sharedInstance];
        _settings = [OAAppSettings sharedManager];
        _currentPositionHelper = [OACurrentPositionHelper instance];
        _locationProvider = [OsmAndApp instance].locationServices;
        _turnDrawable = turnDrawable;
        _showClosestWaypointFirstInAddress = YES;
        _calc1 = calc1;
        [self computeParams];
    }
    return self;
}

- (void)computeParams
{
    BOOL isMapLinkedToLocation = [[OAMapViewTrackingUtilities instance] isMapLinkedToLocation];
    _showClosestWaypointFirstInAddress = YES;
    
    if ([_routingHelper isRouteCalculated] && ![OARoutingHelper isDeviatedFromRoute])
    {
        if ([_routingHelper isFollowingMode])
        {
            OANextDirectionInfo *nextDirInfo = [_routingHelper getNextRouteDirectionInfo:_calc1 toSpeak:YES];
            _streetName = [_routingHelper getCurrentName:nextDirInfo];
            _turnDrawable.clr = [UIColor colorNamed:ACColorNameNavArrowColor].currentMapThemeColor;
        }
        else
        {
            int di = [OARouteInfoView getDirectionInfo];
            if (di >= 0 && [OARouteInfoView isVisible] && di < [_routingHelper getRouteDirections].count)
            {
                _showClosestWaypointFirstInAddress = NO;
                _streetName = [_routingHelper getCurrentName:[_routingHelper getNextRouteDirectionInfo:_calc1 toSpeak:YES]];
                _turnDrawable.clr = [UIColor colorNamed:ACColorNameNavArrowDistantColor].currentMapThemeColor;
            }
        }
    }
    else if (isMapLinkedToLocation)
    {
        _streetName = [[OACurrentStreetName alloc] init];
        CLLocation *lastKnownLocation = _locationProvider.lastKnownLocation;
        std::shared_ptr<RouteDataObject> road;
        if (lastKnownLocation)
        {
            road = [_currentPositionHelper getLastKnownRouteSegment:lastKnownLocation];
            if (road)
            {
                string lang = _settings.settingPrefMapLanguage.get ? _settings.settingPrefMapLanguage.get.UTF8String : "";
                bool transliterate = _settings.settingMapLanguageTranslit.get;
                
                string rStreetName = road->getName(lang, transliterate);
                string rRefName = road->getRef(lang, transliterate, road->bearingVsRouteDirection(lastKnownLocation.course));
                string rDestinationName = road->getDestinationName(lang, transliterate, true);
                
                NSString *strtName = [NSString stringWithUTF8String:rStreetName.c_str()];
                NSString *refName = [NSString stringWithUTF8String:rRefName.c_str()];
                NSString *destinationName = [NSString stringWithUTF8String:rDestinationName.c_str()];
                
                _streetName.text = [OARoutingHelperUtils formatStreetName:strtName ref:refName destination:destinationName towards:@"»"];
            }
            if (_streetName.text.length > 0 && road)
            {
                double dist = [OACurrentPositionHelper getOrthogonalDistance:road loc:lastKnownLocation];
                if (dist < 50)
                    _streetName.showMarker = YES;
                else
                    _streetName.text = [NSString stringWithFormat:@"%@ %@", OALocalizedString(@"shared_string_near"), _streetName.text];
            }
        }
    }
}

@end
