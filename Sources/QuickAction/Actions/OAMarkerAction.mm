//
//  OAMarkerAction.m
//  OsmAnd
//
//  Created by Paul on 8/13/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMarkerAction.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAReverseGeocoder.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OAMarkerAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsMarkerActionId
                                            stringId:@"marker.add"
                                                  cl:self.class]
               name:OALocalizedString(@"map_marker")]
              nameAction:OALocalizedString(@"shared_string_add")]
              iconName:@"ic_custom_favorites"]
             secondaryIconName:@"ic_custom_compound_action_add"]
            category:QuickActionTypeCategoryMyPlaces];
}

- (void)execute
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    CLLocation *latLon = [self getMapLocation];
    [mapPanel addMapMarker:latLon.coordinate.latitude lon:latLon.coordinate.longitude description:[[OAReverseGeocoder instance] lookupAddressAtLat:latLon.coordinate.latitude lon:latLon.coordinate.longitude]];
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_add_marker_descr");
}

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
