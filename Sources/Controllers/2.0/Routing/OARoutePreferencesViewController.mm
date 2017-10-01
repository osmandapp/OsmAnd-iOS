//
//  OARoutePreferencesViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 02/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARoutePreferencesViewController.h"
#import "OARoutePreferencesMainScreen.h"
#import "Localization.h"
#import "OARootViewController.h"

@interface OARoutePreferencesViewController ()

@end

@implementation OARoutePreferencesViewController
{
    OsmAndAppInstance _app;
}

@dynamic screenObj;

- (instancetype) init
{
    return [super initWithScreenType:ERoutePreferencesScreenMain];
}

- (instancetype) initWithPreferencesScreen:(ERoutePreferencesScreen)preferencesScreen
{
    return [super initWithScreenType:preferencesScreen];
}

- (instancetype) initWithPreferencesScreen:(ERoutePreferencesScreen)preferencesScreen param:(id)param
{
    return [super initWithScreenType:preferencesScreen param:param];
}

- (void) commonInit
{
    _app = [OsmAndApp instance];
    _preferencesScreen = (ERoutePreferencesScreen) self.screenType;
    
    [super commonInit];
}

- (BOOL) isMainScreen
{
    return _preferencesScreen == ERoutePreferencesScreenMain;
}

- (void) applyLocalization
{
    [super applyLocalization];
    
    self.titleView.text = OALocalizedString(@"sett_settings");
}

- (void) setupView
{
    switch (_preferencesScreen)
    {
        case ERoutePreferencesScreenMain:
            if (!self.screenObj)
                self.screenObj = [[OARoutePreferencesMainScreen alloc] initWithTable:self.tableView viewController:self];
            break;
            
        default:
            break;
    }
    
    [super setupView];
}

@end
