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
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapRendererView.h"

#include <OsmAndCore/Utilities.h>

#define KEY_MESSAGE @"message"
#define KEY_DIALOG @"dialog"

@implementation OAAddOSMBugAction

- (instancetype)init
{
    return [super initWithType:EOAQuickActionTypeAddNote];
}

- (void)execute
{
    OAOsmEditingPlugin *plugin = (OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class];
    
    if (plugin)
    {
        const auto& latLon = OsmAnd::Utilities::convert31ToLatLon([OARootViewController instance].mapPanel.mapViewController.mapView.target31);
        
        if (self.getParams.count == 0)
            [plugin openOsmNote:latLon.latitude longitude:latLon.longitude message:@"" autoFill:YES];
        else
            [plugin openOsmNote:latLon.latitude longitude:latLon.longitude message:self.params[KEY_MESSAGE] autoFill:![self.params[KEY_DIALOG] boolValue]];
    }
}

- (OrderedDictionary *)getUIModel
{
    MutableOrderedDictionary *data = [[MutableOrderedDictionary alloc] init];
    [data setObject:@[@{
                          @"type" : @"OASwitchTableViewCell",
                          @"key" : KEY_DIALOG,
                          @"title" : OALocalizedString(@"quick_actions_show_dialog"),
                          @"value" : @([self.getParams[KEY_DIALOG] boolValue]),
                          },
                      @{
                          @"footer" : OALocalizedString(@"quick_action_dialog_descr")
                          }] forKey:OALocalizedString(@"quick_action_dialog")];
    [data setObject:@[@{
                          @"type" : @"OAMultilineTextViewCell",
                          @"hint" : OALocalizedString(@"quick_action_enter_message"),
                          @"title" : self.getParams[KEY_MESSAGE] ? self.getParams[KEY_MESSAGE] : @"",
                          @"key" : KEY_MESSAGE
                          },
                      @{
                          @"footer" : OALocalizedString(@"osm_note_action_field_descr")
                          }] forKey:OALocalizedString(@"osm_alert_message")];
    
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
            if ([item[@"key"] isEqualToString:KEY_DIALOG])
                [params setValue:item[@"value"] forKey:KEY_DIALOG];
            if ([item[@"key"] isEqualToString:KEY_MESSAGE])
                [params setValue:item[@"title"] forKey:KEY_MESSAGE];
        }
    }
    [self setParams:[NSDictionary dictionaryWithDictionary:params]];
    return params[KEY_MESSAGE] && params;
}

@end
