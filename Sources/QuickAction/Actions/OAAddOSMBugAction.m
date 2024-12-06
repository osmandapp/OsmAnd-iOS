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
#import "OrderedDictionary.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

#import "OALog.h"
#include <OsmAndCore/Utilities.h>

static NSString * const kMessage = @"message";

static QuickActionType *TYPE;

@implementation OAAddOSMBugAction

- (instancetype)init
{
    return [super initWithActionType:TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsAddOsmBugActionId
                                            stringId:@"osmbug.add"
                                                  cl:self.class]
               name:OALocalizedString(@"osn_bug_name")]
               nameAction:OALocalizedString(@"shared_string_add")]
              iconName:@"ic_action_osm_note"]
             secondaryIconName:@"ic_custom_compound_action_add"]
            category:QuickActionTypeCategoryMyPlaces];
}

- (void)execute
{
    //TODO: do not commit!
    
    OALog(@"!!! Debug action");
    
    OAMapViewController *mapVc = OARootViewController.instance.mapPanel.mapViewController;
    [mapVc foo];

    
//    QVector<OsmAnd::PointI> points;
//    points.push_back( OsmAnd::PointI(1255718528, 724253184) );
//    points.push_back( OsmAnd::PointI(1255717888, 724255968) );
//    points.push_back( OsmAnd::PointI(1255719520, 724256352) );
//    points.push_back( OsmAnd::PointI(1255719776, 724255232) );
//    points.push_back( OsmAnd::PointI(1255719296, 724255136) );
//    points.push_back( OsmAnd::PointI(1255719680, 724253472) );
//    points.push_back( OsmAnd::PointI(1255718528, 724253184) );
//    points.push_back( OsmAnd::PointI(0, 0) );
    
    
    
    
//    [0]    OsmAnd::Point<int>
//    x    int    1255718528
//    y    int    724253184
//    [1]    OsmAnd::Point<int>
//    x    int    1255717888
//    y    int    724255968
//    [2]    OsmAnd::Point<int>
//    x    int    1255719520
//    y    int    724256352
//    [3]    OsmAnd::Point<int>
//    x    int    1255719776
//    y    int    724255232
//    [4]    OsmAnd::Point<int>
//    x    int    1255719296
//    y    int    724255136
//    [5]    OsmAnd::Point<int>
//    x    int    1255719680
//    y    int    724253472
//    [6]    OsmAnd::Point<int>
//    x    int    1255718528
//    y    int    724253184

    
    
    //    OsmAnd::PointI a = OsmAnd::PointI(0, 0);
    
    
//    QVector<OsmAnd::PointI> points;
//    points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(destination.latitude, destination.longitude)));
//    points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(currLoc.coordinate.latitude, currLoc.coordinate.longitude)));
    
    /*
    OAOsmEditingPlugin *plugin = (OAOsmEditingPlugin *) [OAPluginsHelper getEnabledPlugin:OAOsmEditingPlugin.class];
    if (plugin)
    {
        CLLocation *latLon = [self getMapLocation];
        if (self.getParams.count == 0)
            [plugin openOsmNote:latLon.coordinate.latitude longitude:latLon.coordinate.longitude message:@"" autoFill:YES];
        else
            [plugin openOsmNote:latLon.coordinate.latitude longitude:latLon.coordinate.longitude message:self.getParams[kMessage] autoFill:![self.getParams[kDialog] boolValue]];
    }
     */
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

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
