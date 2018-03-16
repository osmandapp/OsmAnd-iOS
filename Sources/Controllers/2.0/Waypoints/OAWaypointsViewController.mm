//
//  OAWaypointsViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 14/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAWaypointsViewController.h"
#import "OAWaypointsMainScreen.h"
#import "Localization.h"
#import "OARootViewController.h"

@interface OAWaypointsViewController ()

@end

@implementation OAWaypointsViewController
{
    OsmAndAppInstance _app;
}

@dynamic screenObj;

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
                self.screenObj = [[OAWaypointsMainScreen alloc] initWithTable:self.tableView viewController:self];
            
            break;
        }
        default:
            break;
    }
    
    [super setupView];
}

@end

