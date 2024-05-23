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
#import "OANode.h"
#import "OAEditPOIData.h"
#import "OAOsmEditingViewController.h"
#import "OAButtonTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OATextInputFloatingCellWithIcon.h"
#import "OAPOIUIFilter.h"
#import "OAPOIHelper.h"
#import "OAPluginsHelper.h"
#import "OsmAnd_Maps-Swift.h"

static NSString * const kTag = @"key_tag";
static NSString * const kDialog = @"dialog";
static NSString * const kCategory = @"key_category";

static OAQuickActionType *ACTION_TYPE;

@implementation OAAddPOIAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void) execute
{
    OAOsmEditingPlugin *plugin = (OAOsmEditingPlugin *) [OAPluginsHelper getPlugin:OAOsmEditingPlugin.class];
    
    if (plugin)
    {
        CLLocation *latLon = [self getMapLocation];
        OANode *node = [[OANode alloc] initWithId:-1 latitude:latLon.coordinate.latitude longitude:latLon.coordinate.longitude];
        [node replaceTags:[self getTagsFromParams]];
        
        OAEditPOIData *data = [[OAEditPOIData alloc] initWithEntity:node];
        if ([[self getParams][kDialog] boolValue])
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

- (NSString *) getIconResName
{
    OAPOIType *poiType = [self getPoiType];
    NSString *iconName = [OAPOIUIFilter getPoiTypeIconName:poiType];
    if (iconName.length > 0) {
        return iconName;
    }
    OAPOICategory *poiCategory = [self getCategory];
    NSString *categoryIconName = [OAPOIUIFilter getPoiTypeIconName:poiCategory];
    return categoryIconName.length == 0 ? [super getIconResName] : categoryIconName;
}

- (OAPOIType *) getPoiType
{
    NSString *poiTypeTranslation = [self getPoiTypeTranslation];
    return poiTypeTranslation == nil ? nil : [OAPOIHelper.sharedInstance getAllTranslatedNames:YES][poiTypeTranslation.lowerCase];
}

- (NSString *) getPoiTypeTranslation
{
    return [self getTagsFromParams][POI_TYPE_TAG];
}

- (OAPOICategory *) getCategory
{
    OAPOIType *poiType = [self getPoiType];
    return poiType != nil ? poiType.category : nil;
}

- (OrderedDictionary<NSString *, NSString *> *) getTagsFromParams
{
    OrderedDictionary<NSString *, NSString *> *actions = nil;
    NSString *json = [self getParams][kTag];
    if (json)
        actions = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    
    return actions != nil ? actions : [[OrderedDictionary alloc] init];
}

- (OrderedDictionary *)getUIModel
{
    MutableOrderedDictionary *data = [[MutableOrderedDictionary alloc] init];
    [data setObject:@[@{
                          @"type" : [OASwitchTableViewCell getCellIdentifier],
                          @"key" : kDialog,
                          @"title" : OALocalizedString(@"quick_action_interim_dialog"),
                          @"value" : @([self.getParams[kDialog] boolValue]),
                          },
                      @{
                          @"footer" : OALocalizedString(@"quick_action_dialog_descr")
                          }] forKey:OALocalizedString(@"quick_action_dialog")];
    
    [data setObject:@[@{
                          @"type" : [OAValueTableViewCell getCellIdentifier],
                          @"title" : OALocalizedString(@"poi_dialog_poi_type"),
                          @"key" : kCategory,
                          @"value" : self.getTagsFromParams[POI_TYPE_TAG] ? self.getTagsFromParams[POI_TYPE_TAG] : OALocalizedString(@"shared_string_select"),
                          },
                      @{
                          @"footer" : OALocalizedString(@"quick_action_get_info"),
                          @"url" : kUrlOsm_wikiMapFeatures
                          }
                      ] forKey:OALocalizedString(@"poi_dialog_poi_type")];
    NSMutableArray *arr = [NSMutableArray new];
    [self.getTagsFromParams enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
        if (![key isEqualToString:POI_TYPE_TAG]
            && ![key hasPrefix:REMOVE_TAG_PREFIX]) {
            [arr addObject:@{
                             @"type" : [OATextInputFloatingCellWithIcon getCellIdentifier],
                             @"hint" : OALocalizedString(@"osm_tag"),
                             @"title" : key,
                             @"img" : @"ic_custom_delete"
                             }];
            [arr addObject:@{
                             @"type" : [OATextInputFloatingCellWithIcon getCellIdentifier],
                             @"hint" : OALocalizedString(@"osm_value"),
                             @"title" : value,
                             @"img" : @""
                             }];
        }
    }];
    [arr addObject:@{
                     @"title" : OALocalizedString(@"quick_action_add_tag"),
                     @"type" : [OAButtonTableViewCell getCellIdentifier],
                     @"target" : @"addTagValue:"
                     }];
    [data setObject:arr forKey:OALocalizedString(@"gpx_tags_txt")];
   
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
            if ([item[@"key"] isEqualToString:kDialog])
                [params setValue:item[@"value"] forKey:kDialog];
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
            else if ([item[@"key"] isEqualToString:kCategory])
            {
                [tagValues setObject:item[@"value"] forKey:POI_TYPE_TAG];
            }
        }
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tagValues
                                                       options:0
                                                         error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [params setObject:jsonString forKey:kTag];
    [self setParams:[NSDictionary dictionaryWithDictionary:params]];
    return tagValues.count > 0;
}

+ (OAQuickActionType *) TYPE
{
    if (!ACTION_TYPE)
        ACTION_TYPE = [[[[[OAQuickActionType alloc] initWithId:EOAQuickActionIdsAddPoiActionId stringId:@"osmpoi.add" cl:self.class] name:OALocalizedString(@"quick_action_add_poi")] iconName:@"ic_action_create_poi"] category:EOAQuickActionTypeCategoryCreateCategory];
    return ACTION_TYPE;
}

@end
