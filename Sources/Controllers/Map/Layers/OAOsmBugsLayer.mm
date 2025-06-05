//
//  OAOsmBugsLayer.m
//  OsmAnd
//
//  Created by Paul on 17/01/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmBugsLayer.h"
#import "OADefaultFavorite.h"
#import "OAFavoriteItem.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OATargetPoint.h"
#import "OAUtilities.h"
#import "OAOsmEditingPlugin.h"
#import "OAPlugin.h"
#import "OAOsmBugResult.h"
#import "OAOsmNotesMapLayerProvider.h"
#import "OAOnlineOsmNoteWrapper.h"
#import "OAPluginsHelper.h"
#import "OAAppSettings.h"
#import "OAAppData.h"
#import "OAMapSelectionResult.h"
#import "OAOsmEditsDBHelper.h"
#import "OAOsmNotePoint.h"
#import "OAOsmEditsLayer.h"
#import "Localization.h"
#import "OAPointDescription.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>

#define kMaxZoom 11

static const int START_ZOOM = 8;

static const NSString* BASE_URL = @"https://api.openstreetmap.org/";

@interface OAOsmBugsLayer ()

@end

@implementation OAOsmBugsLayer
{
    std::shared_ptr<OAOsmNotesMapLayerProvider> _notesMapProvider;
    OAOsmEditingPlugin *_plugin;
    double _textSize;
}

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController baseOrder:(int)baseOrder
{
    self = [super initWithMapViewController:mapViewController baseOrder:baseOrder];
    if (self) {
        _plugin = (OAOsmEditingPlugin *) [OAPluginsHelper getPlugin:OAOsmEditingPlugin.class];
    }
    return self;
}

- (NSString *) layerId
{
    return kOsmBugsLayerId;
}

- (void) initLayer
{
    [super initLayer];
    _textSize = [[OAAppSettings sharedManager].textSize get];

    [self.app.data.mapLayersConfiguration setLayer:self.layerId
                                    Visibility:[_plugin isEnabled] && [[OAAppSettings sharedManager].mapSettingShowOnlineNotes get]];

    _notesMapProvider.reset(new OAOsmNotesMapLayerProvider(_textSize));
    [self.mapView addTiledSymbolsProvider:_notesMapProvider];
    
    const OAOsmNotesMapLayerProvider::DataReadyCallback callback =
    [self] ()
    {
        [self.mapView invalidateFrame];
    };
    _notesMapProvider->setDataReadyCallback(callback);
}

- (BOOL) updateLayer
{
    if (![super updateLayer])
        return NO;

    CGFloat textSize = [[OAAppSettings sharedManager].textSize get];
    if (_textSize != textSize)
    {
        _textSize = textSize;
        if ([self isVisible])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hide];
                _notesMapProvider.reset(new OAOsmNotesMapLayerProvider(_textSize));
                const OAOsmNotesMapLayerProvider::DataReadyCallback callback =
                [self] ()
                {
                    [self.mapView invalidateFrame];
                };
                _notesMapProvider->setDataReadyCallback(callback);
                [self show];
            });
        }
    }
    return YES;
}

- (void) onMapFrameRendered
{
    _notesMapProvider->setRequestedBBox31(self.mapView.getVisibleBBox31);
}

- (BOOL) isVisible
{
    return [_plugin isEnabled] && [[OAAppSettings sharedManager].mapSettingShowOnlineNotes get];
}

- (void) show
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addTiledSymbolsProvider:_notesMapProvider];
    }];
}

- (void) hide
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView removeTiledSymbolsProvider:_notesMapProvider];
    }];
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    return [OAOsmEditsLayer getTargetPointFromPoint:obj];
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    if (const auto onlineNote = reinterpret_cast<const OAOnlineOsmNote *>(obj))
    {
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.type = OATargetOsmOnlineNote;
        double lat = onlineNote->getLatitude();
        double lon = onlineNote->getLongitude();
        targetPoint.location = CLLocationCoordinate2DMake(lat, lon);
        
        targetPoint.title = onlineNote->getDescription().toNSString();
        UIImage *icon = [UIImage imageNamed:onlineNote->isOpened() ? @"ic_custom_osm_note_unresolved" : @"ic_custom_osm_note_resolved"];
        targetPoint.icon = icon;
        
        targetPoint.sortIndex = (NSInteger)targetPoint.type;
        return targetPoint;
    }
    return nil;
}

- (void) collectObjectsFromPoint:(OAMapSelectionResult *)result unknownLocation:(BOOL)unknownLocation excludeUntouchableObjects:(BOOL)excludeUntouchableObjects
{
    float zoom = [self.mapViewController getMapZoom];
    NSArray<OAOpenStreetMapPoint *> *objects = [[OAOsmEditsDBHelper sharedDatabase] getOpenstreetmapPoints];
    
    if (zoom >= START_ZOOM && ![NSArray isEmpty:objects])
    {
        CGPoint pixel = [result getPoint];
        int radiusPixels = [self getScaledTouchRadius:[self getDefaultRadiusPoi]] * TOUCH_RADIUS_MULTIPLIER;
        
        CGPoint topLeft = CGPointMake(pixel.x - radiusPixels, pixel.y - (radiusPixels / 3));
        CGPoint bottomRight = CGPointMake(pixel.x + radiusPixels, pixel.y + (radiusPixels * 1.5));
        OsmAnd::AreaI touchPolygon31 = [OANativeUtilities getPolygon31FromScreenArea:topLeft bottomRight:bottomRight];
        
        
        
        for (OAOsmNotePoint *note in objects)
        {
            // Android has extra settings check here. 
            //boolean showClosed = plugin.SHOW_CLOSED_OSM_BUGS.get();
            //if (!note.isOpened() && !showClosed) {
            //    continue;
            //}
            
            double lat = [note getLatitude];
            double lon = [note getLongitude];
            BOOL shouldAdd = [OANativeUtilities isPointInsidePolygon:lat lon:lon polygon31:touchPolygon31];
            
            if (shouldAdd)
                [result collect:note provider:self];
        }
    }
}

- (BOOL)isSecondaryProvider
{
    return NO;
}

- (CLLocation *) getObjectLocation:(id)obj
{
    if ([obj isKindOfClass:OAOnlineOsmNoteWrapper.class])
    {
        OAOnlineOsmNoteWrapper *note = (OAOnlineOsmNoteWrapper *)obj;
        return  [[CLLocation alloc] initWithLatitude:note.latitude longitude:note.longitude];
    }
    return  nil;
}

- (OAPointDescription *) getObjectName:(id)obj
{
    if ([obj isKindOfClass:OAOnlineOsmNoteWrapper.class])
    {
        OAOnlineOsmNoteWrapper *note = (OAOnlineOsmNoteWrapper *)obj;
        NSString *name = note.description ?: @"";
        NSString *typeName = note.typeName ?: OALocalizedString(@"osn_bug_name");
        return [[OAPointDescription alloc] initWithType:POINT_TYPE_OSM_NOTE typeName:typeName name:name];
    }
    return  nil;
}

- (BOOL) showMenuAction:(id)object
{
    return NO;
}

- (BOOL) runExclusiveAction:(id)obj unknownLocation:(BOOL)unknownLocation
{
    return NO;
}

@end
