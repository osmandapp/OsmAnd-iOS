#import "OADownloadMapLayerHelper.h"
#import "OAAppData.h"
#import "OAMapSource.h"
#import "OAResourcesUIHelper.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "GeneratedAssetSymbols.h"

@implementation OADownloadMapLayerHelper

+ (NSArray<NSNumber *> *)downloadableLayers
{
    NSDictionary<OAMapSource *, OAResourceItem *> *resources = [OAResourcesUIHelper getOnlineRasterMapSourcesBySource];
    NSMutableArray<NSNumber *> *layers = [NSMutableArray array];
    for (NSNumber *value in @[@(EOADownloadMapLayerMapSource), @(EOADownloadMapLayerOverlay), @(EOADownloadMapLayerUnderlay)])
    {
        OAMapSource *source = [self mapSourceForLayer:(EOADownloadMapLayer)value.integerValue];
        if (source && resources[source])
            [layers addObject:value];
    }
    return layers;
}

+ (OAMapSource *)mapSourceForLayer:(EOADownloadMapLayer)layer
{
    OAAppData *data = OsmAndApp.instance.data;
    switch (layer)
    {
        case EOADownloadMapLayerMapSource:
            return data.lastMapSource;
        case EOADownloadMapLayerOverlay:
            return data.overlayMapSource;
        case EOADownloadMapLayerUnderlay:
            return data.underlayMapSource;
    }
    return nil;
}

+ (void)setMapSource:(OAMapSource *)source forLayer:(EOADownloadMapLayer)layer
{
    OAAppData *data = OsmAndApp.instance.data;
    switch (layer)
    {
        case EOADownloadMapLayerMapSource:
            data.lastMapSource = source;
            break;
        case EOADownloadMapLayerOverlay:
            data.lastOverlayMapSource = source;
            data.overlayMapSource = source;
            break;
        case EOADownloadMapLayerUnderlay:
            data.lastUnderlayMapSource = source;
            data.underlayMapSource = source;
            break;
    }
}

+ (OAResourceItem *)resourceItemForLayer:(EOADownloadMapLayer)layer
{
    OAMapSource *source = [self mapSourceForLayer:layer];
    return source ? [OAResourcesUIHelper getOnlineRasterMapSourcesBySource][source] : nil;
}

+ (NSString *)titleForLayer:(EOADownloadMapLayer)layer
{
    switch (layer)
    {
        case EOADownloadMapLayerMapSource:
            return OALocalizedString(@"map_settings_type");
        case EOADownloadMapLayerOverlay:
            return OALocalizedString(@"map_settings_over");
        case EOADownloadMapLayerUnderlay:
            return OALocalizedString(@"map_settings_under");
    }
    return @"";
}

+ (NSString *)iconNameForLayer:(EOADownloadMapLayer)layer
{
    switch (layer)
    {
        case EOADownloadMapLayerMapSource:
            return ACImageNameIcCustomMapOnline;
        case EOADownloadMapLayerOverlay:
            return ACImageNameIcCustomOverlayMap;
        case EOADownloadMapLayerUnderlay:
            return ACImageNameIcCustomUnderlayMap;
    }
    return @"";
}

@end
