//
//  OAActionsPanelViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAActionsPanelViewController.h"

#import <QuickDialog.h>
#import <QEmptyListElement.h>

#import "OsmAndApp.h"
#import "UIViewController+OARootViewController.h"
#import "OAAutoObserverProxy.h"
#include "Localization.h"

#define _(name) OAActionsPanelViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

@interface OAActionsPanelViewController ()

@end

@implementation OAActionsPanelViewController
{
    OsmAndAppInstance _app;

    BOOL _actionsListInvalidated;

    OAAutoObserverProxy* _appModeObserver;

    QSection* _appDriveModeActionsSection;
}

- (instancetype)init
{
    self = [super initWithRoot:[self createActionsList]];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc
{
    [self deinit];
}

- (void)commonInit
{
    _app = [OsmAndApp instance];

    _actionsListInvalidated = YES;

    _appModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onAppModeChanged)
                                                  andObserve:_app.appModeObservable];

    [self inflateDriveModeActions];
}

- (void)deinit
{
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (_actionsListInvalidated)
    {
        [self updateActionsList];

        _actionsListInvalidated = NO;
    }
}

- (QRootElement*)createActionsList
{
    QRootElement* rootElement = [[QRootElement alloc] init];
    rootElement.title = OALocalizedString(@"Actions");
    rootElement.grouped = YES;

    if (_app.appMode == OAAppModeDrive)
        [rootElement addSection:_appDriveModeActionsSection];

    // Check if there are any actions
    if ([rootElement.sections count] == 0)
    {
        QSection* emptySection = [[QSection alloc] init];
        [rootElement addSection:emptySection];

        QEmptyListElement* noActionsElement = [[QEmptyListElement alloc] initWithTitle:OALocalizedString(@"No actions")
                                                                                 Value:nil];
        [emptySection addElement:noActionsElement];
    }

    return rootElement;
}

- (void)inflateDriveModeActions
{
    _appDriveModeActionsSection = [[QSection alloc] initWithTitle:OALocalizedString(@"Drive Mode")];

    QLabelElement* exitDriveModeElement = [[QLabelElement alloc] initWithTitle:OALocalizedString(@"Exit")
                                                                         Value:nil];
    exitDriveModeElement.controllerAction = NSStringFromSelector(@selector(onExitDriveMode));
    [_appDriveModeActionsSection addElement:exitDriveModeElement];
}

- (void)invalidateActionsList
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _actionsListInvalidated = YES;
            return;
        }

        [self updateActionsList];
    });
}

- (void)updateActionsList
{
    self.root = [self createActionsList];
}

- (void)onExitDriveMode
{
    _app.appMode = OAAppModeBrowseMap;

    [self.rootViewController closeMenuAndPanelsAnimated:YES];
}

- (void)onAppModeChanged
{
    [self invalidateActionsList];
}

@end
