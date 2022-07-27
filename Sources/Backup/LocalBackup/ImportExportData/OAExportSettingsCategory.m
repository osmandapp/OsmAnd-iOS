//
//  OAExportSettingsCategory.m
//  OsmAnd
//
//  Created by Paul on 27.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAExportSettingsCategory.h"
#import "Localization.h"

@interface OAExportSettingsCategory ()

- (instancetype) initWithTitle:(NSString *)title;

@end

static OAExportSettingsCategory *SETTINGS;
static OAExportSettingsCategory *MY_PLACES;
static OAExportSettingsCategory *RESOURCES;

@implementation OAExportSettingsCategory

- (instancetype) initWithTitle:(NSString *)title
{
    self = [super init];
    if (self) {
        _title = title;
    }
    return self;
}

+ (OAExportSettingsCategory *) SETTINGS
{
    if (!SETTINGS)
        SETTINGS = [[OAExportSettingsCategory alloc] initWithTitle:OALocalizedString(@"sett_settings")];
    return SETTINGS;
}

+ (OAExportSettingsCategory *) MY_PLACES
{
    if (!MY_PLACES)
        MY_PLACES = [[OAExportSettingsCategory alloc] initWithTitle:OALocalizedString(@"menu_my_places")];
    return MY_PLACES;
}

+ (OAExportSettingsCategory *) RESOURCES
{
    if (!RESOURCES)
        RESOURCES = [[OAExportSettingsCategory alloc] initWithTitle:OALocalizedString(@"shared_string_resources")];
    return RESOURCES;
}

@end
