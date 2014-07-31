//
//  OADebugActionsViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADebugActionsViewController.h"

#import <QuickDialog.h>

#import "OsmAndApp.h"
#import "OAMapRendererView.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#include "Localization.h"

#define _(name) OADebugActionsViewController__##name

@interface OADebugActionsViewController ()
@end

@implementation OADebugActionsViewController
{
    OsmAndAppInstance _app;

    QBooleanElement* _forcedRenderingElement;
    QBooleanElement* _hideStaticSymbolsElement;

    QRadioSection* _forcedGpsAccuracySection;

    QRadioSection* _visualMetricsSection;

    QBooleanElement* _useRawSpeedAndAltitudeOnHUDElement;

    OAMapViewController* __weak _mapViewController;
    OAMapRendererView* __weak _mapRendererView;
}

- (instancetype)init
{
    OsmAndAppInstance app = [OsmAndApp instance];

    QRootElement* rootElement = [[QRootElement alloc] init];

    rootElement.title = OALocalizedString(@"Debug");
    rootElement.grouped = YES;
    rootElement.appearance.entryAlignment = NSTextAlignmentRight;

    // Renderer section
    QSection* rendererSection = [[QSection alloc] initWithTitle:OALocalizedString(@"Renderer")];
    [rootElement addSection:rendererSection];

    QBooleanElement* forcedRenderingElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"Forced rendering")
                                                                           BoolValue:NO];
    forcedRenderingElement.controllerAction = NSStringFromSelector(@selector(onForcedRenderingSettingChanged));
    [rendererSection addElement:forcedRenderingElement];

    QBooleanElement* hideStaticSymbolsElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"Hide static symbols")
                                                                           BoolValue:NO];
    hideStaticSymbolsElement.controllerAction = NSStringFromSelector(@selector(onHideStaticSymbolsSettingChanged));
    [rendererSection addElement:hideStaticSymbolsElement];

    // Forced GPS accuracy section
    QRadioSection* forcedGpsAccuracySection = [[QRadioSection alloc] initWithItems:@[OALocalizedString(@"None"),
                                                                                     OALocalizedString(@"Best"),
                                                                                     OALocalizedString(@"Best for Navigation")]
                                                                          selected:0
                                                                             title:OALocalizedString(@"Forced GPS accuracy")];
    forcedGpsAccuracySection.onSelected = ^(){
        [self onForcedGpsAccuracyChanged];
    };
    [rootElement addSection: forcedGpsAccuracySection];

    // Visual metrics section
    QRadioSection* visualMetricsSection = [[QRadioSection alloc] initWithItems:@[OALocalizedString(@"Off"),
                                                                                 OALocalizedString(@"Binary Map Data"),
                                                                                 OALocalizedString(@"Binary Map Primitives"),
                                                                                 OALocalizedString(@"Binary Map Rasterize")]
                                                                      selected:0
                                                                         title:OALocalizedString(@"Visual metrics")];
    visualMetricsSection.onSelected = ^(){
        [self onVisualMetricsSettingChanged];
    };
    [rootElement addSection: visualMetricsSection];

    // HUD section
    QSection* hudSection = [[QSection alloc] initWithTitle:OALocalizedString(@"HUD")];
    [rootElement addSection:hudSection];

    QBooleanElement* useRawSpeedAndAltitudeOnHUDElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"Show raw speed/altritude")
                                                                                       BoolValue:NO];
    useRawSpeedAndAltitudeOnHUDElement.controllerAction = NSStringFromSelector(@selector(onUseRawSpeedAndAltitudeOnHUDSettingChanged));
    [hudSection addElement:useRawSpeedAndAltitudeOnHUDElement];

    self = [super initWithRoot:rootElement];
    if (self) {
        _app = app;

        _forcedRenderingElement = forcedRenderingElement;
        _hideStaticSymbolsElement = hideStaticSymbolsElement;

        _forcedGpsAccuracySection = forcedGpsAccuracySection;

        _visualMetricsSection = visualMetricsSection;

        _useRawSpeedAndAltitudeOnHUDElement = useRawSpeedAndAltitudeOnHUDElement;
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

    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    _mapViewController = mapVC;
    if ([mapVC isViewLoaded])
        _mapRendererView = (OAMapRendererView*)mapVC.view;

    _forcedRenderingElement.boolValue = _mapRendererView.forcedRenderingOnEachFrame;
    _hideStaticSymbolsElement.boolValue = _mapViewController.hideStaticSymbols;

    _forcedGpsAccuracySection.selected = _app.locationServices.forceAccuracy;

    _visualMetricsSection.selected = _mapViewController.visualMetricsMode;

    _useRawSpeedAndAltitudeOnHUDElement.boolValue = _app.debugSettings.useRawSpeedAndAltitudeOnHUD;
}

- (void)onForcedRenderingSettingChanged
{
    _mapRendererView.forcedRenderingOnEachFrame = _forcedRenderingElement.boolValue;
}

- (void)onHideStaticSymbolsSettingChanged
{
    _mapViewController.hideStaticSymbols = _hideStaticSymbolsElement.boolValue;
}

- (void)onForcedGpsAccuracyChanged
{
    _app.locationServices.forceAccuracy = (OALocationServicesForcedAccuracy)_forcedGpsAccuracySection.selected;
}

- (void)onVisualMetricsSettingChanged
{
    _mapViewController.visualMetricsMode = (OAVisualMetricsMode)_visualMetricsSection.selected;
}

- (void)onUseRawSpeedAndAltitudeOnHUDSettingChanged
{
    _app.debugSettings.useRawSpeedAndAltitudeOnHUD = _useRawSpeedAndAltitudeOnHUDElement.boolValue;
}

@end
