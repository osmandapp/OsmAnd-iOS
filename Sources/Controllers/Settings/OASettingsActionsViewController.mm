//
//  OASettingsActionsViewController.mm
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 10/16/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASettingsActionsViewController.h"

#import <QuickDialog.h>

#import "OsmAndApp.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OAAppSettings.h"
#include "Localization.h"

#define _(name) OASettingsActionsViewController__##name

@interface OASettingsActionsViewController ()
@end

@implementation OASettingsActionsViewController
{
    OsmAndAppInstance _app;
    QBooleanElement* _showRuletElement;
}

- (instancetype)init
{
    OsmAndAppInstance app = [OsmAndApp instance];

    QRootElement* rootElement = [[QRootElement alloc] init];

    rootElement.title = OALocalizedString(@"Settings");
    rootElement.grouped = YES;
    rootElement.appearance.entryAlignment = NSTextAlignmentRight;

    // Map section
    QSection* mapSection = [[QSection alloc] initWithTitle:OALocalizedString(@"Map")];
    [rootElement addSection:mapSection];

    QBooleanElement* showRuletElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"Show map ruler")
                                                                           BoolValue:NO];
    showRuletElement.controllerAction = NSStringFromSelector(@selector(onShowRuletSettingChanged));
    [mapSection addElement:showRuletElement];

    self = [super initWithRoot:rootElement];
    if (self) {
        _app = app;

        _showRuletElement = showRuletElement;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    _showRuletElement.boolValue = [[OAAppSettings sharedManager] settingShowMapRulet];
}

- (void)onShowRuletSettingChanged
{
    [[OAAppSettings sharedManager] setSettingShowMapRulet:_showRuletElement.boolValue];
}

@end
