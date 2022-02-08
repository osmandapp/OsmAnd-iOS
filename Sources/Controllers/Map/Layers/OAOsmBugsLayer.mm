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

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>

#define kMaxZoom 11

static const NSString* BASE_URL = @"https://api.openstreetmap.org/";

@interface OAOsmBugsLayer ()

@end

@implementation OAOsmBugsLayer
{
    std::shared_ptr<OAOsmNotesMapLayerProvider> _notesMapProvider;
    OAOsmEditingPlugin *_plugin;
}

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController baseOrder:(int)baseOrder
{
    self = [super initWithMapViewController:mapViewController baseOrder:baseOrder];
    if (self) {
        _plugin = (OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class];
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
    
    [self.app.data.mapLayersConfiguration setLayer:self.layerId
                                    Visibility:[_plugin isEnabled] && [[OAAppSettings sharedManager].showOSMBugs get]];
    
    _notesMapProvider.reset(new OAOsmNotesMapLayerProvider());
    [self.mapView addTiledSymbolsProvider:_notesMapProvider];
    
    const OAOsmNotesMapLayerProvider::DataReadyCallback callback =
    [self] ()
    {
        [self.mapView invalidateFrame];
    };
    _notesMapProvider->setDataReadyCallback(callback);
}

- (void) onMapFrameRendered
{
    _notesMapProvider->setRequestedBBox31(self.mapView.getVisibleBBox31);
}

- (BOOL) isVisible
{
    return [_plugin isEnabled] && [[OAAppSettings sharedManager].showOSMBugs get];
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
    return nil;
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

- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation
{
    OAOsmNotesMapLayerProvider::NotesSymbolsGroup* notesSymbolGroup = dynamic_cast<OAOsmNotesMapLayerProvider::NotesSymbolsGroup*>(symbolInfo->mapSymbol->groupPtr);
    if (notesSymbolGroup != nullptr)
    {
        std::shared_ptr<const OAOnlineOsmNote> note = notesSymbolGroup->note;
        if (note != nullptr)
        {
            OATargetPoint *targetPoint = [self getTargetPointCpp:note.get()];
            targetPoint.targetObj = [[OAOnlineOsmNoteWrapper alloc] initWithNote:note];
            if (![found containsObject:targetPoint])
                [found addObject:targetPoint];
        }
    }
}

@end
