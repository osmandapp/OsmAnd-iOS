//
//  OAOsmEditingPlugin.m
//  OsmAnd
//
//  Created by Paul on 1/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmEditingPlugin.h"

#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OATextInfoWidget.h"
#import "OAApplicationMode.h"
#import "OAIAPHelper.h"
#import "OAMapPanelViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapInfoController.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OADestinationsHelper.h"
#import "OADestination.h"
#import "OARoutingHelper.h"
#import "OAMapViewController.h"
#import "OANativeUtilities.h"
#import "OAOsmEditsLayer.h"
#import "OAOsmEditsDBHelper.h"
#import "OAOpenStreetMapPoint.h"
#import "OANode.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OAMapLayers.h"
#import "OAOpenStreetMapLocalUtil.h"
#import "OAOpenStreetMapRemoteUtil.h"
#import "OAOsmBugsRemoteUtil.h"
#import "OAOsmBugsLocalUtil.h"
#import "Reachability.h"
#import "OAEditPOIData.h"
#import "OAOsmNotePoint.h"
#import "OAOsmNoteBottomSheetViewController.h"
#import "OAAddPOIAction.h"
#import "OAAddOSMBugAction.h"
#import "OAShowHideLocalOSMChanges.h"
#import "OAShowHideOSMBugAction.h"
#import "OAOsmBugsDBHelper.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

#define PLUGIN_ID kInAppId_Addon_OsmEditing

@interface OAOsmEditingPlugin ()

@property (nonatomic) OsmAndAppInstance app;
@property (nonatomic) OAAppSettings *settings;
@property (nonatomic) OADestinationsHelper *helper;
@property (nonatomic) OAMapViewController *mapViewController;

@end

@implementation OAOsmEditingPlugin
{
    OAOsmEditsDBHelper *_dbpoi;
    OAOsmBugsDBHelper *_dbbug;
    OAOpenStreetMapLocalUtil *_localUtil;
    OAOpenStreetMapRemoteUtil *_remoteUtil;
    OAOsmBugsRemoteUtil *_remoteNotesUtil;
    OAOsmBugsLocalUtil *_localNotesUtil;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _helper = [OADestinationsHelper instance];
        _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        _dbbug = [OAOsmBugsDBHelper sharedDatabase];
        _dbpoi = [OAOsmEditsDBHelper sharedDatabase];
        _localUtil = [[OAOpenStreetMapLocalUtil alloc] init];
        _localNotesUtil = [[OAOsmBugsLocalUtil alloc] init];
        _remoteUtil = [[OAOpenStreetMapRemoteUtil alloc] init];
        _remoteNotesUtil = [[OAOsmBugsRemoteUtil alloc] init];
    }
    return self;
}

- (NSString *) getId
{
    return PLUGIN_ID;
}

- (void) registerLayers
{
    
}

- (void) updateLayers
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_mapViewController)
            _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        OAMapLayer *editsLayer = _mapViewController.mapLayers.osmEditsLayer;
        OAMapLayer *bugsLayer = _mapViewController.mapLayers.osmBugsLayer;
        [_app.data.mapLayersConfiguration setLayer:kOsmEditsLayerId Visibility:editsLayer.isVisible];
        [_app.data.mapLayersConfiguration setLayer:kOsmBugsLayerId Visibility:bugsLayer.isVisible];
    });
}

- (id<OAOpenStreetMapUtilsProtocol>)getPoiModificationUtil
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable && !_settings.offlineEditing.get)
        return _remoteUtil;
    else
        return _localUtil;
}

- (id<OAOpenStreetMapUtilsProtocol>)getPoiModificationLocalUtil
{
    return _localUtil;
}

- (id<OAOpenStreetMapUtilsProtocol>)getPoiModificationRemoteUtil
{
    return _remoteUtil;
}

-(id<OAOsmBugsUtilsProtocol>)getOsmNotesRemoteUtil
{
    return _remoteNotesUtil;
}

-(id<OAOsmBugsUtilsProtocol>)getLocalOsmNotesUtil
{
    return _localNotesUtil;
}

-(void) openOsmNote:(double)latitude longitude:(double)longitude message:(NSString *)message autoFill:(BOOL)autofill
{
    OAOsmNotePoint *p = [[OAOsmNotePoint alloc] init];
    [p setLatitude:latitude];
    [p setLongitude:longitude];
    [p setAuthor:@""];
    if (autofill)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [_localNotesUtil commit:p text:message action:CREATE]; /*OAOsmBugResult *res = */
        });
    }
    else
    {
        [p setText:message];
        OAOsmNoteBottomSheetViewController *noteScreen = [[OAOsmNoteBottomSheetViewController alloc] initWithEditingPlugin:self points:[NSArray arrayWithObject:p] type:TYPE_CREATE];
        [noteScreen show];
    }
}

+ (NSString *) getTitle:(OAOsmPoint *)osmPoint
{
    NSString *title = [self getName:osmPoint];
    if (!title || title.length == 0)
        title = [self getCategory:osmPoint];
    return title;
}

+ (NSString *) getName:(OAOsmPoint *)point
{
    if ([point getGroup] == POI)
    {
        return [((OAOpenStreetMapPoint *)point) getName];
    }
    else if ([point getGroup] == BUG)
    {
        return [((OAOsmNotePoint *)point) getText];
    }
    else
    {
        return @"";
    }
}

+ (NSString *) getCategory:(OAOsmPoint *)point
{
    NSString *category = @"";
    if (point.getGroup == POI)
    {
        OAEditPOIData *data = [[OAEditPOIData alloc] initWithEntity:((OAOpenStreetMapPoint *) point).getEntity];
        category = data.getLocalizedTypeString;
    }
    else if (point.getGroup == BUG)
        category = OALocalizedString(@"osm_note");
    
    return category;
}

- (NSArray *)getQuickActionTypes
{
    return @[OAAddPOIAction.TYPE, OAAddOSMBugAction.TYPE, OAShowHideOSMBugAction.TYPE, OAShowHideLocalOSMChanges.TYPE];
}

@end
