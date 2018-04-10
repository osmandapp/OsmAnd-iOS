//
//  OAWaypointsViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 14/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAWaypointsViewController.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OALocationPointWrapper.h"
#import "OAPointDescription.h"

#import "OAWaypointsMainScreen.h"
#import "OAWaypointsRadiusScreen.h"
#import "OAWaypointsPOIScreen.h"

@implementation OAWaypointsViewControllerRequest

- (instancetype) initWithType:(int)type action:(EWaypointsViewControllerRequestAction)action param:(NSNumber *)param
{
    self = [super init];
    if (self)
    {
        _type = type;
        _action = action;
        _param = param;
    }
    return self;
}

@end

@interface OAWaypointsViewController ()

@end

@implementation OAWaypointsViewController
{
    OsmAndAppInstance _app;
}

@dynamic screenObj;

static OAWaypointsViewControllerRequest *request = nil;

+ (OAWaypointsViewControllerRequest *) getRequest
{
    return request;
}

+ (void) setRequest:(EWaypointsViewControllerRequestAction)action type:(int)type param:(NSNumber *)param
{
    OAWaypointsViewControllerRequest *newRequest = [[OAWaypointsViewControllerRequest alloc] initWithType:type action:action param:param];
    request = newRequest;
}

+ (void) resetRequest
{
    request = nil;
}

- (instancetype) init
{
    return [super initWithScreenType:EWaypointsScreenMain];
}

- (instancetype) initWithWaypointsScreen:(EWaypointsScreen)waypointsScreen
{
    return [super initWithScreenType:waypointsScreen];
}

- (instancetype) initWithWaypointsScreen:(EWaypointsScreen)waypointsScreen param:(id)param
{
    return [super initWithScreenType:waypointsScreen param:param];
}

- (void) commonInit
{
    _app = [OsmAndApp instance];
    _waypointsScreen = (EWaypointsScreen) self.screenType;
    
    [super commonInit];
}

- (BOOL) isMainScreen
{
    return _waypointsScreen == EWaypointsScreenMain;
}

- (void) applyLocalization
{
    [super applyLocalization];
    
    self.titleView.text = OALocalizedString(@"gpx_waypoints");
}

- (void) setupView
{
    switch (_waypointsScreen)
    {
        case EWaypointsScreenMain:
        {
            if (!self.screenObj)
                self.screenObj = [[OAWaypointsMainScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];
            
            break;
        }
        case EWaypointsScreenRadius:
        {
            if (!self.screenObj)
                self.screenObj = [[OAWaypointsRadiusScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];
            
            break;
        }
        case EWaypointsScreenPOI:
        {
            if (!self.screenObj)
                self.screenObj = [[OAWaypointsPOIScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];
            
            break;
        }
        default:
            break;
    }
    
    [super setupView];
}

@end

