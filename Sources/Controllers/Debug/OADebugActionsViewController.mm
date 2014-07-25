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
    QRadioSection* _visualMetricsSection;

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

    // Visual metrics section
    QRadioSection* visualMetricsSection = [[QRadioSection alloc] initWithItems:@[OALocalizedString(@"Off"),
                                                                                 OALocalizedString(@"Binary Map Data"),
                                                                                 OALocalizedString(@"Binary Map Primitives")]
                                                                      selected:0
                                                                         title:OALocalizedString(@"Visual metrics")];
    visualMetricsSection.onSelected = ^(){
        [self onVisualMetricsSettingChanged];
    };
    [rootElement addSection: visualMetricsSection];

    self = [super initWithRoot:rootElement];
    if (self) {
        _app = app;

        _forcedRenderingElement = forcedRenderingElement;
        _visualMetricsSection = visualMetricsSection;
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

    [_forcedRenderingElement setBoolValue:_mapRendererView.forcedRenderingOnEachFrame];
    [_visualMetricsSection setSelected:_mapViewController.visualMetricsMode];
}

- (void)onForcedRenderingSettingChanged
{
    _mapRendererView.forcedRenderingOnEachFrame = _forcedRenderingElement.boolValue;
}

- (void)onVisualMetricsSettingChanged
{
    _mapViewController.visualMetricsMode = (OAVisualMetricsMode)_visualMetricsSection.selected;
}

@end
