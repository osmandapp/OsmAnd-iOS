//
//  OANavDirectionsFromAction.m
//  OsmAnd
//
//  Created by Paul on 30.05.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OANavDirectionsFromAction.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OANavDirectionsFromAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsNavDirectionsFromActionId
                                            stringId:@"nav.directions"
                                                  cl:self.class]
               name:OALocalizedString(@"quick_action_directions_from")]
               nameAction:OALocalizedString(@"shared_string_set")]
              iconName:@"ic_action_directions_from"]
             category:QuickActionTypeCategoryNavigation]
            nonEditable];
}

- (void)execute
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    CLLocation *latLon = [self getMapLocation];
    OATargetPoint *p = [[OATargetPoint alloc] init];
    p.location = CLLocationCoordinate2DMake(latLon.coordinate.latitude, latLon.coordinate.longitude);
    [mapPanel navigateFrom:p];
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_dir_from_descr");
}

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
