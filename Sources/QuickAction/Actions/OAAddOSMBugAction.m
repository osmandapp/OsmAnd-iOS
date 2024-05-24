//
//  OAAddOSMBugAction.m
//  OsmAnd
//
//  Created by Paul on 8/6/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAAddOSMBugAction.h"
#import "OAPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "OAMultilineTextViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAPluginsHelper.h"
#import "OsmAnd_Maps-Swift.h"

static NSString * const kMessage = @"message";
static NSString * const kDialog = @"dialog";

static OAQuickActionType *TYPE;

@implementation OAAddOSMBugAction

- (instancetype)init
{
    return [super initWithActionType:TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[OAQuickActionType alloc] initWithId:EOAQuickActionIdsAddOsmBugActionId
                                            stringId:@"osmbug.add"
                                                  cl:self.class]
               name:OALocalizedString(@"quick_action_add_osm_bug")]
              iconName:@"ic_action_osm_note"]
             secondaryIconName:@"ic_custom_compound_action_add"]
            category:EOAQuickActionTypeCategoryCreateCategory];
}

- (void)execute
{
    OAOsmEditingPlugin *plugin = (OAOsmEditingPlugin *) [OAPluginsHelper getEnabledPlugin:OAOsmEditingPlugin.class];
    if (plugin)
    {
        CLLocation *latLon = [self getMapLocation];
        if (self.getParams.count == 0)
            [plugin openOsmNote:latLon.coordinate.latitude longitude:latLon.coordinate.longitude message:@"" autoFill:YES];
        else
            [plugin openOsmNote:latLon.coordinate.latitude longitude:latLon.coordinate.longitude message:self.getParams[kMessage] autoFill:![self.getParams[kDialog] boolValue]];
    }
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
                          @"type" : [OAMultilineTextViewCell getCellIdentifier],
                          @"hint" : OALocalizedString(@"quick_action_enter_message"),
                          @"title" : self.getParams[kMessage] ? self.getParams[kMessage] : @"",
                          @"key" : kMessage
                          },
                      @{
                          @"footer" : OALocalizedString(@"quick_action_bug_descr")
                          }] forKey:OALocalizedString(@"osb_comment_dialog_message")];
    
    return data;
}

- (BOOL)fillParams:(NSDictionary *)model
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.getParams];
    for (NSArray *arr in model.allValues)
    {
        for (NSUInteger i = 0; i < arr.count; i++)
        {
            NSDictionary *item = arr[i];
            if ([item[@"key"] isEqualToString:kDialog])
                [params setValue:item[@"value"] forKey:kDialog];
            if ([item[@"key"] isEqualToString:kMessage])
                [params setValue:item[@"title"] forKey:kMessage];
        }
    }
    [self setParams:[NSDictionary dictionaryWithDictionary:params]];
    return params[kMessage] && params;
}

+ (OAQuickActionType *) TYPE
{
    return TYPE;
}

@end
