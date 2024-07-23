//
//  OAParkingAction.m
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAParkingAction.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAPlugin.h"
#import "OAParkingPositionPlugin.h"
#import "OATargetPoint.h"
#import "OAPluginsHelper.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OAParkingAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsParkingActionId
                                             stringId:@"parking.add"
                                                   cl:self.class]
                name:OALocalizedString(@"quick_action_add_parking")]
               iconName:@"ic_custom_parking"]
              secondaryIconName:@"ic_custom_compound_action_add"]
             category:QuickActionTypeCategoryCreateCategory]
            nonEditable];
}

- (void)execute
{
    OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *)[OAPluginsHelper getEnabledPlugin:OAParkingPositionPlugin.class];
    if (plugin)
    {
        CLLocation *latLon = [self getMapLocation];
        CLLocationCoordinate2D point = CLLocationCoordinate2DMake(latLon.coordinate.latitude, latLon.coordinate.longitude);

        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.type = OATargetParking;
        targetPoint.location = point;

        OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
        [mapPanel showContextMenu:targetPoint];
        [mapPanel targetPointParking];
    }
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_parking_descr");
}

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
