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

@property OsmAndAppInstance app;
@property QBooleanElement* showRuletElement;
@property QRadioSection* mapLanguageSection;

@end

@implementation OASettingsActionsViewController
{
}

- (instancetype)init
{
    QRootElement* rootElement = [[QRootElement alloc] init];
    rootElement.title = OALocalizedString(@"Settings");
    rootElement.grouped = YES;
    rootElement.appearance.entryAlignment = NSTextAlignmentRight;

    self = [super initWithRoot:rootElement];
    if (self) {

        self.app = [OsmAndApp instance];
        
        // Map section
        QSection* mapSection = [[QSection alloc] initWithTitle:OALocalizedString(@"Map")];
        [rootElement addSection:mapSection];
        
        self.showRuletElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"Show map ruler")
                                                         BoolValue:NO];
        self.showRuletElement.controllerAction = NSStringFromSelector(@selector(onShowRuletSettingChanged));
        [mapSection addElement:self.showRuletElement];
        
        // Language section
        self.mapLanguageSection = [[QRadioSection alloc] initWithItems:@[OALocalizedString(@"Local Only"),
                                                                         OALocalizedString(@"Local And System"),
                                                                         OALocalizedString(@"System And Local"),
                                                                         ]
                                                              selected:0
                                                                 title:OALocalizedString(@"Map language")];
        self.mapLanguageSection.onSelected = ^(){
            [self onMapLanguageChanged];
        };
        [rootElement addSection: self.mapLanguageSection];
        
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
    self.showRuletElement.boolValue = [[OAAppSettings sharedManager] settingShowMapRulet];
    self.mapLanguageSection.selected = [[OAAppSettings sharedManager] settingMapLanguage];
}

- (void)onShowRuletSettingChanged
{
    [[OAAppSettings sharedManager] setSettingShowMapRulet:self.showRuletElement.boolValue];
}

-(void)onMapLanguageChanged {
    [[OAAppSettings sharedManager] setSettingMapLanguage:self.mapLanguageSection.selected];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSettingsLanguageChange object:nil];
}

@end
