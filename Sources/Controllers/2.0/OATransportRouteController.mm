//
//  OATransportRouteController.m
//  OsmAnd
//
//  Created by Alexey on 28/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATransportRouteController.h"
#import "OATransportStopRoute.h"
#import "OsmAndApp.h"
#import "OAMapRendererView.h"
#import "OARootViewController.h"
#import "OANativeUtilities.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAAppSettings.h"
#import "OAMapLayers.h"
#import "OATransportStopsLayer.h"
#import "OATransportRouteToolbarViewController.h"
#import "OATransportStop.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Data/TransportRoute.h>
#include <OsmAndCore/Data/TransportStop.h>

static OATransportRouteToolbarViewController *toolbarController;

@interface OATransportRouteController ()<OARowInfoDelegate>

@end

@implementation OATransportRouteController
{
    OsmAndAppInstance _app;
    
    OAMapViewController *_mapViewController;
    NSString *_prefLang;
    QString _lang;
    BOOL _transliterate;
}

- (instancetype) initWithTransportRoute:(OATransportStopRoute *)transportRoute
{
    self = [super init];
    if (self)
    {
        _transportRoute = transportRoute;
        _prefLang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
        _transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit.get;
        _lang = QString::fromNSString(_prefLang);
        
        self.leftControlButton = [[OATargetMenuControlButton alloc] init];
        self.leftControlButton.title = OALocalizedString(@"shared_string_previous");
        self.rightControlButton = [[OATargetMenuControlButton alloc] init];
        self.rightControlButton.title = OALocalizedString(@"intro_next");
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    
    [self applyTopToolbarTargetTitle];
}

- (void) leftControlButtonPressed
{
    int previousStop = [self getPreviousStop];
    if (previousStop != -1)
        [self showTransportStop:_transportRoute.route->forwardStops[previousStop]];
}

- (void) rightControlButtonPressed
{
    int nextStop = [self getNextStop];
    if (nextStop != -1)
        [self showTransportStop:_transportRoute.route->forwardStops[nextStop]];
}

- (void) showTransportStop:(std::shared_ptr<OsmAnd::TransportStop>)stop
{
    _transportRoute.stop = stop;
    _transportRoute.refStop = stop;

    [self refreshContextMenu];
}

- (void) updateControls
{
    BOOL previousStopDisabled = [self getPreviousStop] == -1;
    if (self.leftControlButton.disabled != previousStopDisabled) {
        self.leftControlButton.disabled = previousStopDisabled;
    }
    
    BOOL nextStopDisabled = [self getNextStop] == -1;
    if (self.rightControlButton.disabled != nextStopDisabled) {
        self.rightControlButton.disabled = nextStopDisabled;
    }
}

- (void) refreshContextMenu
{
    [self updateControls];

    [self rebuildRows];
    [self.tableView reloadData];
    
    OATargetPoint *targetPoint = [self.class getTargetPoint:self.transportRoute];
    targetPoint.centerMap = YES;
    [[OARootViewController instance].mapPanel updateContextMenu:targetPoint];
}
                                 
- (UIImage *) getIcon
{
    if (!_transportRoute.type)
        return [OATargetInfoViewController getIcon:@"mx_public_transport.png"];
    else
    {
        NSString *resId = _transportRoute.type.topResId;
        if (resId.length > 0)
            return [OATargetInfoViewController getIcon:[resId stringByAppendingString:@".png"]];
        else
            return [OATargetInfoViewController getIcon:@"mx_public_transport.png"];
    }
}

- (NSString *) getTypeStr;
{
    NSString *description = [_transportRoute getDescription:NO];
    int i = [description indexOf:@":"];
    if (i != -1)
        description = [description substringToIndex:i];

    return description;
}

+ (NSString *) getTitle:(OATransportStopRoute *)transportRoute
{
    NSString *prefLang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit.get;
    const auto& lang = QString::fromNSString(prefLang);

    if (transportRoute.refStop && transportRoute.refStop->getName(lang, transliterate).length() > 0)
        return transportRoute.refStop->getName(lang, transliterate).toNSString();
    else if (transportRoute.stop && transportRoute.stop->getName(lang, transliterate).length() > 0)
        return transportRoute.stop->getName(lang, transliterate).toNSString();
    else if ([transportRoute getDescription:NO].length > 0)
        return [transportRoute getDescription:NO];
    else
        return [self.class getStopType:transportRoute];
}

+ (NSString *) getStopType:(OATransportStopRoute *)transportRoute
{
    return [NSString stringWithFormat:@"%@ %@", [transportRoute getTypeStr], [OALocalizedString(@"transport_stop") lowerCase]];
}

- (void) cancelPressed
{
    [self.class hideToolbar];
    [[OARootViewController instance].mapPanel targetHide];

    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    OAMapViewController *mapController = mapPanel.mapViewController;
    [mapController.mapLayers.transportStopsLayer hideRoute];
}

- (IBAction) buttonClosePressed:(id)sender
{
    [self cancelPressed];
}

- (BOOL) hasTopToolbar
{
    return YES;
}

- (BOOL) shouldShowToolbar
{
    return YES;
}

- (ETopToolbarType) topToolbarType
{
    return ETopToolbarTypeFixed;
}

- (int) getCurrentStop
{
    const auto& stops = _transportRoute.route->forwardStops;
    for (int i = 0; i < stops.size(); i++)
    {
        auto stop = stops[i];
        if (stop->getName(_lang, _transliterate) == _transportRoute.stop->getName(_lang, _transliterate))
            return i;
    }
    return -1;
}

- (int) getNextStop
{
    const auto& stops = _transportRoute.route->forwardStops;
    int currentPos = [self getCurrentStop];
    if (currentPos != -1 && currentPos + 1 < stops.size())
        return currentPos + 1;
    
    return -1;
}

- (int) getPreviousStop
{
    int currentPos = [self getCurrentStop];
    if (currentPos > 0)
        return currentPos - 1;
    
    return -1;
}

- (void) buildRows:(NSMutableArray<OARowInfo *> *)rows
{
    const auto& stops = _transportRoute.route->forwardStops;
    int currentStop = [self getCurrentStop];
    UIImage *defaultIcon = [OATargetInfoViewController getIcon:[NSString stringWithFormat:@"%@.png", !_transportRoute.type ? @"mx_route_bus_ref" : _transportRoute.type.resId]];
    int startPosition = 0;
    if (!_transportRoute.showWholeRoute && currentStop > 1)
    {
        startPosition = (currentStop == -1 ? 0 : currentStop);
        if (currentStop > 0)
        {
            OARowInfo *rowInfo = [[OARowInfo alloc] initWithKey:@"button" icon:defaultIcon textPrefix:[NSString stringWithFormat:OALocalizedString(@"route_stops_before"), currentStop] text:OALocalizedString(@"sett_show") textColor:nil isText:YES needLinks:NO order:-1 typeName:@"" isPhoneNumber:NO isUrl:NO];
            rowInfo.delegate = self;
            [rows addObject:rowInfo];
        }
    }
    for (int i = startPosition; i < stops.size(); i++)
    {
        auto stop = stops[i];
        NSString *name = stop->getName(_lang, _transliterate).toNSString();
        if (name.length == 0)
            name = [self.class getStopType:_transportRoute];
        
        OARowInfo *rowInfo = [[OARowInfo alloc] initWithKey:[NSString stringWithFormat:@"stop_%d", i] icon:(currentStop == i ? [UIImage imageNamed:@"ic_action_marker"] : defaultIcon) textPrefix:@"" text:name textColor:nil isText:YES needLinks:NO order:i typeName:@"" isPhoneNumber:NO isUrl:NO];
        rowInfo.delegate = self;
        [rows addObject:rowInfo];
    }
}

+ (OATargetPoint *) getTargetPoint:(OATransportStopRoute *)r
{
    CLLocationCoordinate2D latLon;
    if (r.refStop)
        latLon = CLLocationCoordinate2DMake(r.refStop->location.latitude, r.refStop->location.longitude);
    else if (r.stop)
        latLon = CLLocationCoordinate2DMake(r.stop->location.latitude, r.stop->location.longitude);
    else
        latLon = [r calculateBounds:0].center;
    
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    targetPoint.type = OATargetTransportRoute;
    targetPoint.location = latLon;
    targetPoint.targetObj = r;
    targetPoint.title = [self.class getTitle:r];
    NSString *description = [r getDescription:NO];
    int i = [description indexOf:@":"];
    if (i != -1 && i < description.length - 1)
        targetPoint.titleAddress = [[description substringFromIndex:i + 1] trim];
    
    targetPoint.sortIndex = (NSInteger)targetPoint.type;
    
    return targetPoint;
}

+ (void) showToolbar:(OATransportStopRoute *)transportRoute
{
    if (!toolbarController)
        toolbarController = [[OATransportRouteToolbarViewController alloc] initWithNibName:@"OATransportRouteToolbarViewController" bundle:nil];

    OATransportStopRoute *r = [transportRoute clone];    
    toolbarController.transportRoute = r;
    if (r.refStop)
    {
        toolbarController.transportStop = [[OATransportStop alloc] init];
        toolbarController.transportStop.stop = r.refStop;
    }
    if (r.stop)
    {
        toolbarController.transportStop = [[OATransportStop alloc] init];
        toolbarController.transportStop.stop = r.stop;
    }
    toolbarController.toolbarTitle = [self.class getTitle:r];

    [[OARootViewController instance].mapPanel showToolbar:toolbarController];
}

+ (void) hideToolbar
{
    [[OARootViewController instance].mapPanel hideToolbar:toolbarController];
    toolbarController = nil;
}

- (void) onMenuSwipedOff
{
    [self.class hideToolbar];
    
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    [mapPanel.mapViewController.mapLayers.transportStopsLayer hideRoute];
}

#pragma mark - OARowInfoDelegate

- (void)onRowClick:(OATargetMenuViewController *)sender rowInfo:(OARowInfo *)rowInfo
{
    if ([rowInfo.key isEqualToString:@"button"])
    {
        _transportRoute.showWholeRoute = YES;
        [self refreshContextMenu];
    }
    else
    {
        const auto& stops = _transportRoute.route->forwardStops;
        int index = [[rowInfo.key substringFromIndex:5] intValue];
        if (index < stops.size())
            [self showTransportStop:stops[index]];
    }
}

@end
