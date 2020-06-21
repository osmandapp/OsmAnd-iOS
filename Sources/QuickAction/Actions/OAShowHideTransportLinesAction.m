//
//  OAShowHideTransportLinesAction.m
//  OsmAnd Maps
//
//  Created by nnngrach on 21.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAQuickActionType.h"
#import "OAShowHideTransportLinesAction.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"

static OAQuickActionType *TYPE;

@implementation OAShowHideTransportLinesAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [[OAAppSettings sharedManager] setMapSettingShowPublicTransport:!settings.mapSettingShowPublicTransport];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}

- (BOOL)isActionWithSlash
{
    return [OAAppSettings sharedManager].mapSettingShowPublicTransport;
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"m_style_pulic_transport") : OALocalizedString(@"m_style_pulic_transport");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:4 stringId:@"favorites.showhide" class:self.class name:OALocalizedString(@"m_style_pulic_transport") category:CONFIGURE_MAP iconName:@"ic_profile_bus" secondaryIconName:nil editable:NO];
       
    return TYPE;
}

@end
