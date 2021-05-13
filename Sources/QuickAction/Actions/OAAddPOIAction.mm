//
//  OAAddPOIAction.m
//  OsmAnd
//
//  Created by Paul on 8/7/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAAddPOIAction.h"
#import "OAPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapRendererView.h"
#import "OANode.h"
#import "OAEntity.h"
#import "OAEditPOIData.h"
#import "OrderedDictionary.h"
#import "OAOsmEditingViewController.h"
#import "OAOpenStreetMapLocalUtil.h"
#import "OAPOIType.h"
#import "OAOsmEditingViewController.h"
#import "OAOsmEditsDBHelper.h"
#import "OAQuickActionType.h"
#import "OAButtonCell.h"
#import "OAIconTitleValueCell.h"
#import "OASwitchTableViewCell.h"

#include <OsmAndCore/Utilities.h>

#define KEY_TAG @"key_tag"
#define KEY_DIALOG @"dialog"
#define KEY_CATEGORY @"key_category"

static OAQuickActionType *ACTION_TYPE;

@implementation OAAddPOIAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void) execute
{
    OAOsmEditingPlugin *plugin = (OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class];
    
    if (plugin)
    {
        const auto latLon = OsmAnd::Utilities::convert31ToLatLon([OARootViewController instance].mapPanel.mapViewController.mapView.target31);
        OANode *node = [[OANode alloc] initWithId:-1 latitude:latLon.latitude longitude:latLon.longitude];
        [node replaceTags:[self getTagsFromParams]];
        
        OAEditPOIData *data = [[OAEditPOIData alloc] initWithEntity:node];
        if ([[self getParams][KEY_DIALOG] boolValue])
        {
            OAEntity *entity = data.getEntity;
            OAOsmEditingViewController *editingScreen = [[OAOsmEditingViewController alloc] initWithEntity:entity];
            [[OARootViewController instance].navigationController pushViewController:editingScreen animated:YES];
        }
        else
        {
            [OAOsmEditingViewController savePoi:@"" poiData:data editingUtil:plugin.getPoiModificationLocalUtil closeChangeSet:NO];
        }
    }
}

- (OrderedDictionary<NSString *, NSString *> *) getTagsFromParams
{
    OrderedDictionary<NSString *, NSString *> *actions = nil;
    NSString *json = [self getParams][KEY_TAG];
    if (json)
        actions = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    
    return actions != nil ? actions : [[OrderedDictionary alloc] init];
}

- (OrderedDictionary *)getUIModel
{
    MutableOrderedDictionary *data = [[MutableOrderedDictionary alloc] init];
    [data setObject:@[@{
                          @"type" : [OASwitchTableViewCell getCellIdentifier],
                          @"key" : KEY_DIALOG,
                          @"title" : OALocalizedString(@"quick_actions_show_dialog"),
                          @"value" : @([self.getParams[KEY_DIALOG] boolValue]),
                          },
                      @{
                          @"footer" : OALocalizedString(@"quick_action_dialog_descr")
                          }] forKey:OALocalizedString(@"quick_action_dialog")];
    
    [data setObject:@[@{
                          @"type" : [OAIconTitleValueCell getCellIdentifier],
                          @"title" : OALocalizedString(@"poi_type"),
                          @"key" : KEY_CATEGORY,
                          @"value" : self.getTagsFromParams[POI_TYPE_TAG] ? self.getTagsFromParams[POI_TYPE_TAG] : OALocalizedString(@"key_hint_select"),
                          },
                      @{
                          @"footer" : OALocalizedString(@"quick_action_get_info"),
                          @"url" : @"https://wiki.openstreetmap.org/wiki/Map_Features"
                          }
                      ] forKey:OALocalizedString(@"poi_type")];
    NSMutableArray *arr = [NSMutableArray new];
    [self.getTagsFromParams enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
        if (![key isEqualToString:POI_TYPE_TAG]
            && ![key hasPrefix:REMOVE_TAG_PREFIX]) {
            [arr addObject:@{
                             @"type" : @"OATextInputFloatingCellWithIcon",
                             @"hint" : OALocalizedString(@"osm_tag"),
                             @"title" : key,
                             @"img" : @"ic_custom_delete"
                             }];
            [arr addObject:@{
                             @"type" : @"OATextInputFloatingCellWithIcon",
                             @"hint" : OALocalizedString(@"osm_value"),
                             @"title" : value,
                             @"img" : @""
                             }];
        }
    }];
    [arr addObject:@{
                     @"title" : OALocalizedString(@"quick_action_add_tag"),
                     @"type" : [OAButtonCell getCellIdentifier],
                     @"target" : @"addTagValue:"
                     }];
    [data setObject:arr forKey:OALocalizedString(@"quick_action_tags")];
   
    return data;
}

- (BOOL)fillParams:(NSDictionary *)model
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.getParams];
    NSMutableDictionary *tagValues = [NSMutableDictionary new];
    for (NSArray *arr in model.allValues)
    {
        for (NSUInteger i = 0; i < arr.count; i++)
        {
            NSDictionary *item = arr[i];
            if ([item[@"key"] isEqualToString:KEY_DIALOG])
                [params setValue:item[@"value"] forKey:KEY_DIALOG];
            else if ([item[@"type"] isEqualToString:@"OATextInputFloatingCellWithIcon"] && item[@"img"])
            {
                if (i + 1 < arr.count - 1)
                {
                    i++;
                    NSDictionary *value = arr[i];
                    NSString *tag = item[@"title"];
                    NSString *val = value[@"title"];
                    if (tag && tag.length > 0 && val && val.length > 0)
                        [tagValues setObject:val forKey:tag];
                }
            }
            else if ([item[@"key"] isEqualToString:KEY_CATEGORY])
            {
                [tagValues setObject:item[@"value"] forKey:POI_TYPE_TAG];
            }
        }
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tagValues
                                                       options:0
                                                         error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [params setObject:jsonString forKey:KEY_TAG];
    [self setParams:[NSDictionary dictionaryWithDictionary:params]];
    return tagValues.count > 0;
}

+ (OAQuickActionType *) TYPE
{
    if (!ACTION_TYPE)
        ACTION_TYPE = [[OAQuickActionType alloc] initWithIdentifier:13 stringId:@"osmpoi.add" class:self.class name:OALocalizedString(@"add_poi") category:CREATE_CATEGORY iconName:@"ic_action_create_poi" secondaryIconName:nil];
       
    return ACTION_TYPE;
}

@end
