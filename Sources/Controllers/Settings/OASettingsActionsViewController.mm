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
@property QLabelElement* elementMapsAndResources;
@property QLabelElement* elementAppMode;
@property QLabelElement* elementMetricSystem;
@property QLabelElement* elementZoomButton;
@property QLabelElement* elementGeoFormat;

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
        QSection* mainSection = [[QSection alloc] initWithTitle:@""];
        [rootElement addSection:mainSection];
        
        self.elementMapsAndResources = [[QLabelElement alloc] initWithTitle:OALocalizedString(@"Maps & Resources") Value:nil ];
        self.elementAppMode = [[QLabelElement alloc] initWithTitle:OALocalizedString(@"Application mode") Value:nil ];
        self.elementMetricSystem = [[QLabelElement alloc] initWithTitle:OALocalizedString(@"Metric system") Value:nil ];
        self.elementZoomButton = [[QLabelElement alloc] initWithTitle:OALocalizedString(@"Zoom button") Value:nil ];
        self.elementGeoFormat = [[QLabelElement alloc] initWithTitle:OALocalizedString(@"Geo format") Value:nil ];
        
        self.elementMapsAndResources.controllerAction = NSStringFromSelector(@selector(onMapsAndResourcesClicked));
        self.elementAppMode.controllerAction = NSStringFromSelector(@selector(onAppMode));
        self.elementMetricSystem.controllerAction = NSStringFromSelector(@selector(onMetricSystem));
        self.elementZoomButton.controllerAction = NSStringFromSelector(@selector(onZoomButton));
        self.elementGeoFormat.controllerAction = NSStringFromSelector(@selector(onGeoFormat));
        
        [mainSection addElement:self.elementMapsAndResources];
        [mainSection addElement:self.elementAppMode];
        [mainSection addElement:self.elementMetricSystem];
        [mainSection addElement:self.elementZoomButton];
        [mainSection addElement:self.elementGeoFormat];
        
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
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];

    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:255.0/255.0 green:143.0/255.0 blue:3.0/255.0 alpha:1]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];

    
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];

    
    [self.navigationController.navigationItem.titleView setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setBackgroundColor:[UIColor colorWithRed:255.0/255.0 green:143.0/255.0 blue:3.0/255.0 alpha:1]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
//    self.showRuletElement.boolValue = [[OAAppSettings sharedManager] settingShowMapRulet];
//    self.mapLanguageSection.selected = [[OAAppSettings sharedManager] settingMapLanguage];
}


#pragma mark - Actions

-(void)onMapsAndResourcesClicked {
    [self.navigationController pushViewController:[[UIStoryboard storyboardWithName:@"Resources" bundle:nil] instantiateInitialViewController] animated:YES];
    
}




- (void)onShowRuletSettingChanged
{
//    [[OAAppSettings sharedManager] setSettingShowMapRulet:self.showRuletElement.boolValue];
}

-(void)onMapLanguageChanged {
    [[OAAppSettings sharedManager] setSettingMapLanguage:self.mapLanguageSection.selected];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSettingsLanguageChange object:nil];
}

@end
