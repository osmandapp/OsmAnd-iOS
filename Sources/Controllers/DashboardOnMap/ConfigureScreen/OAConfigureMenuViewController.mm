//
//  OAConfigureMenuViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAConfigureMenuViewController.h"
#import "OAConfigureMenuMainScreen.h"
#import "OAConfigureMenuVisibilityScreen.h"
#import "Localization.h"
#import "OARootViewController.h"

@interface OAConfigureMenuViewController ()

@end

@implementation OAConfigureMenuViewController
{
    OsmAndAppInstance _app;
}

@dynamic screenObj;

- (instancetype) init
{
    return [super initWithScreenType:EConfigureMenuScreenMain];
}

- (instancetype) initWithConfigureMenuScreen:(EConfigureMenuScreen)configureMenuScreen
{
    return [super initWithScreenType:configureMenuScreen];
}

- (instancetype) initWithConfigureMenuScreen:(EConfigureMenuScreen)configureMenuScreen param:(id)param
{
    return [super initWithScreenType:configureMenuScreen param:param];
}

- (void) commonInit
{
    _app = [OsmAndApp instance];
    _configureMenuScreen = (EConfigureMenuScreen) self.screenType;
    
    [super commonInit];
}

- (BOOL) isMainScreen
{
    return _configureMenuScreen == EConfigureMenuScreenMain;
}

- (void) applyLocalization
{
    [super applyLocalization];
    
    self.titleView.text = OALocalizedString(@"layer_map_appearance");
}

- (void) setupView
{
    switch (_configureMenuScreen)
    {
        case EConfigureMenuScreenMain:
        {
            if (!self.screenObj)
                self.screenObj = [[OAConfigureMenuMainScreen alloc] initWithTable:self.tableView viewController:self];
            
            break;
        }
        case EConfigureMenuScreenVisibility:
        {
            if (!self.screenObj)
                self.screenObj = [[OAConfigureMenuVisibilityScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];
            
            break;
        }
        default:
            break;
    }
    
    [super setupView];
}

@end
