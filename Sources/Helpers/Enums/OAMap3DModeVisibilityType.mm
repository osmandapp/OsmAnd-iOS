//
//  OAMap3DModeVisibilityType.m
//  OsmAnd
//
//  Created by nnngrach on 08.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAMap3DModeVisibilityType.h"
#import "Localization.h"
#include <CommonCollections.h>


static OAMap3DModeVisibilityType *HIDDEN;
static OAMap3DModeVisibilityType *VISIBLE;
static OAMap3DModeVisibilityType *VISIBLE_IN_3D_MODE;

static NSArray<OAMap3DModeVisibilityType *> *VALUES = @[OAMap3DModeVisibilityType.HIDDEN, OAMap3DModeVisibilityType.VISIBLE, OAMap3DModeVisibilityType.VISIBLE_IN_3D_MODE];


@implementation OAMap3DModeVisibilityType

- (instancetype) initWithName:(NSString *)name title:(NSString *)title iconName:(NSString *)iconName
{
    self = [super init];
    if (self) {
        _title = title;
        _name = name;
        _iconName = iconName;
    }
    return self;
}

+ (OAMap3DModeVisibilityType *) HIDDEN
{
    if (!HIDDEN)
    {
        HIDDEN = [[OAMap3DModeVisibilityType alloc] initWithName:@"hidden" title:OALocalizedString(@"shared_string_hidden") iconName:@"ic_custom_map_style"];
    }
    return HIDDEN;
}

+ (OAMap3DModeVisibilityType *) VISIBLE
{
    if (!VISIBLE)
    {
        VISIBLE = [[OAMap3DModeVisibilityType alloc] initWithName:@"visible" title:OALocalizedString(@"shared_string_visible") iconName:@"ic_custom_map_style"];
    }
    return VISIBLE;
}

+ (OAMap3DModeVisibilityType *) VISIBLE_IN_3D_MODE
{
    if (!VISIBLE_IN_3D_MODE)
    {
        VISIBLE_IN_3D_MODE = [[OAMap3DModeVisibilityType alloc] initWithName:@"visible_in_3d_mode" title:OALocalizedString(@"visible_in_3d_mode") iconName:@"ic_custom_map_style"];
    }
    return VISIBLE_IN_3D_MODE;
}

+ (NSArray<OAMap3DModeVisibilityType *> *) getTypes
{
    return VALUES;
}

@end
