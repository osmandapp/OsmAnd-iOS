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
#import "PXAlertView.h"
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
    OAOsmEditsDBHelper *_editsDb;
    OAOpenStreetMapLocalUtil *_localOsmUtil;
    OAOsmBugsLocalUtil *_localBugsUtil;
    OAOpenStreetMapRemoteUtil *_remoteOsmUtil;
    OAOsmBugsRemoteUtil *_remoteBugsUtil;
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
        _editsDb = [OAOsmEditsDBHelper sharedDatabase];
        _localOsmUtil = [[OAOpenStreetMapLocalUtil alloc] init];
        _localBugsUtil = [[OAOsmBugsLocalUtil alloc] init];
        _remoteOsmUtil = [[OAOpenStreetMapRemoteUtil alloc] init];
        _remoteBugsUtil = [[OAOsmBugsRemoteUtil alloc] init];
    }
    return self;
}

+ (NSString *) getId
{
    return PLUGIN_ID;
}

- (void) registerLayers
{
    
}

- (void) updateLayers
{
    if (!_mapViewController)
        _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    if ([self isActive])
    {
        if (_settings.mapSettingShowOfflineEdits && ![_app.data.mapLayersConfiguration isLayerVisible:kOsmEditsLayerId])
            [_mapViewController.mapLayers showLayer:kOsmEditsLayerId];
        if (_settings.mapSettingShowOnlineNotes && ![_app.data.mapLayersConfiguration isLayerVisible:kOsmBugsLayerId])
            [_mapViewController.mapLayers showLayer:kOsmBugsLayerId];
    }
    else
    {
        if (_settings.mapSettingShowOfflineEdits && [_app.data.mapLayersConfiguration isLayerVisible:kOsmEditsLayerId])
            [_mapViewController.mapLayers hideLayer:kOsmEditsLayerId];
        if (_settings.mapSettingShowOnlineNotes && [_app.data.mapLayersConfiguration isLayerVisible:kOsmBugsLayerId])
            [_mapViewController.mapLayers hideLayer:kOsmBugsLayerId];
    }
}

- (id<OAOpenStreetMapUtilsProtocol>)getPoiModificationUtil
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable && !_settings.offlineEditing)
        return _remoteOsmUtil;
    else
        return _localOsmUtil;
}

- (id<OAOpenStreetMapUtilsProtocol>)getOfflineModificationUtil
{
    return _localOsmUtil;
}

- (id<OAOpenStreetMapUtilsProtocol>)getOnlineModificationUtil
{
    return _remoteOsmUtil;
}

-(id<OAOsmBugsUtilsProtocol>)getLocalOsmNotesUtil
{
    return _localBugsUtil;
}

-(id<OAOsmBugsUtilsProtocol>)getRemoteOsmNotesUtil
{
    return _remoteBugsUtil;
}

+ (NSString *) getCategory:(OAOsmPoint *)point
{
    NSString *category = @"";
    if (point.getGroup == POI)
    {
        category = [((OAOpenStreetMapPoint *) point).getEntity getTagFromString:POI_TYPE_TAG];
        if (!category || category.length == 0)
            category = OALocalizedString(@"osm_edit_without_name");
    }
    else if (point.getGroup == BUG)
        category = OALocalizedString(@"osm_note");
    
    return category;
}

@end
