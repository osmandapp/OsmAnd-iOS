//
//  OAPluginSettingsItem.mm
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAPluginSettingsItem.h"
#import "OAPlugin.h"

@implementation OAPluginSettingsItem
{
    OAPlugin *_plugin;
}

@dynamic type, name, fileName;

- (EOASettingsItemType) type
{
    return EOASettingsItemTypePlugin;
}

- (NSString *) name
{
    return [_plugin.class getId];
}

- (NSString *) publicName
{
    return _plugin.getName;
}

- (BOOL)exists
{
    return [OAPlugin getPlugin:_plugin.class] != nil;
}

- (NSArray<OASettingsItem *> *)pluginDependentItems
{
    if (!_pluginDependentItems)
        _pluginDependentItems = [NSArray new];
    return _pluginDependentItems;
}

- (void)apply
{
    if (self.shouldReplace || ![self exists])
    {
        // TODO: implement custom plugins
//        for (OASettingsItem *item : _pluginDependentItems)
//        {
//            if ([item isKindOfClass:OAFileSettingsItem.class])
//            {
//                OAFileSettingsItem *fileItem = (OAFileSettingsItem *) item;
//                if (fileItem.subtype == EOASettingsItemFileSubtypeRenderingStyle)
//                {
//                    [_plugin addRenderer:fileItem.name];
//                }
//                else if (fileItem.subtype == EOASettingsItemFileSubtypeRoutingConfig)
//                {
//                    [plugin addRouter:fileItem.name];
//                }
//                else if (fileItem.subtype == EOASettingsItemFileSubtypeOther)
//                {
//                    [plugin setResourceDirName:item.fileName];
//                }
//            }
//            else if ([item isKindOfClass:OASuggestedDownloadsItem.class])
//            {
//                [plugin updateSuggestedDownloads:((OASuggestedDownloadsItem *) item).items];
//            }
//            else if ([item isKindOfClass:OADownloadsItem.class])
//            {
//                [plugin updateDownloadItems:((OADownloadsItem *) item).items];
//            }
//        }
//        [OAPlugin addCusomPlugin:_plugin];
    }
}

- (void) readFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    [super readFromJson:json error:error];
//    _plugin = [[OAPlugin alloc] initWithJson:json];
//    new CustomOsmandPlugin(app, json);
}

- (void) writeToJson:(id)json
{
    // TODO: Finish later
    [super writeToJson:json];
//    _plugin.writeAdditionalDataToJson(json);
}

@end
