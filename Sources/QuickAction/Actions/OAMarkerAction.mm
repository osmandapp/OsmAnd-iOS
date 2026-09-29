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
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

static QuickActionType *TYPE;

@implementation OAMarkerAction

- (instancetype)init
{
    return [super initWithActionType:self.class.getQuickActionType];
}

+ (void)initialize
{
    TYPE = [[[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsMarkerActionId
                                            stringId:@"marker.add"
                                                  cl:self.class]
                 name:OALocalizedString(@"map_marker")]
                nameAction:OALocalizedString(@"shared_string_add")]
               iconName:ACImageNameIcCustomFavorites]
              secondaryIconName:ACImageNameIcCustomCompoundActionAdd]
             category:QuickActionTypeCategoryMyPlaces]
            forceUseExtendedName];
}

- (void)execute
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    CLLocation *latLon = [self getMapLocation];
    [OAReverseGeocoder.instance lookupAddressAtLat:latLon.coordinate.latitude
                                               lon:latLon.coordinate.longitude
                                          objectId:0
                                        completion:^(NSString *address) {
        [mapPanel addMapMarker:latLon.coordinate.latitude lon:latLon.coordinate.longitude description:address];
    }];
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_add_marker_descr");
}

+ (QuickActionType *)getQuickActionType
{
    return TYPE;
}

@end
