//
//  OAShowHideCloudAction.mm
//  OsmAnd
//
//  Created by Skalii on 12.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAShowHideCloudAction.h"
#import "OsmAndApp.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OAShowHideCloudAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsShowHideCloudLayerActionId
                                            stringId:@"cloud.layer.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"toggle_cloud")]
              category:QuickActionTypeCategoryConfigureMap]
             iconName:@"ic_custom_clouds"]
            nonEditable];
}

- (void)execute
{
    OsmAndAppInstance app = [OsmAndApp instance];
    app.data.weatherCloud = !app.data.weatherCloud;
}

- (BOOL)isActionWithSlash
{
    return [OsmAndApp instance].data.weatherCloud;
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"cloud_hide") : OALocalizedString(@"cloud_show");
}

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
