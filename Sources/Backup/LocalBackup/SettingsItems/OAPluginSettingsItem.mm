//
//  OAPluginSettingsItem.mm
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAPluginSettingsItem.h"
#import "OACustomPlugin.h"
#import "OADownloadsItem.h"
#import "OAFileSettingsItem.h"
#import "OASuggestedDownloadsItem.h"
#import "OAPluginsHelper.h"

#define APPROXIMATE_PLUGIN_SIZE_BYTES 1024

@implementation OAPluginSettingsItem
{
    NSArray<OASettingsItem *> *_pluginDependentItems;
}

@dynamic type, name, fileName;

- (EOASettingsItemType) type
{
    return EOASettingsItemTypePlugin;
}

- (NSString *) name
{
    return [self.plugin getId];
}

- (NSString *)getPublicName
{
    return self.plugin.getName;
}

- (BOOL)exists
{
    return [OAPluginsHelper getPluginById:self.pluginId] != nil;
}

- (NSArray<OASettingsItem *> *)pluginDependentItems
{
    if (!_pluginDependentItems)
        _pluginDependentItems = [NSArray new];
    return _pluginDependentItems;
}

- (void)setPluginDependentItems:(NSArray<OASettingsItem *> *)pluginDependentItems
{
    _pluginDependentItems = pluginDependentItems;
}

- (long)getEstimatedSize
{
    return APPROXIMATE_PLUGIN_SIZE_BYTES;
}

- (void)apply
{
    if (self.shouldReplace || ![self exists])
    {
        for (OASettingsItem *item : _pluginDependentItems)
        {
            if ([item isKindOfClass:OAFileSettingsItem.class])
            {
                OAFileSettingsItem *fileItem = (OAFileSettingsItem *) item;
                if (fileItem.subtype == EOASettingsItemFileSubtypeRenderingStyle)
                    [_plugin addRenderer:fileItem.name];
                else if (fileItem.subtype == EOASettingsItemFileSubtypeRoutingConfig)
                    [_plugin addRouter:fileItem.name];
                else if (fileItem.subtype == EOASettingsItemFileSubtypeOther)
                    _plugin.resourceDirName = item.fileName;
            }
            else if ([item isKindOfClass:OASuggestedDownloadsItem.class])
            {
                [_plugin updateSuggestedDownloads:((OASuggestedDownloadsItem *) item).items];
            }
            else if ([item isKindOfClass:OADownloadsItem.class])
            {
                [_plugin updateDownloadItems:((OADownloadsItem *) item).items];
            }
        }
        [OAPluginsHelper addCustomPlugin:_plugin];
    }
}

- (void)remove
{
    [super remove];
    [OAPluginsHelper removeCustomPlugin:_plugin];
    for (OASettingsItem *item in _pluginDependentItems)
         [item remove];
}

- (void) readFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    [super readFromJson:json error:error];
    _plugin = [[OACustomPlugin alloc] initWithJson:json];
}

- (void) writeToJson:(id)json
{
    [super writeToJson:json];
    json[@"version"] = _plugin.getVersion;
    [_plugin writeAdditionalDataToJson:json];
}

@end
