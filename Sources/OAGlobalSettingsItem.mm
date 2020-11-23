//
//  OAGlobalSettingsItem.m
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAGlobalSettingsItem.h"
#import "Localization.h"

@implementation OAGlobalSettingsItem

@dynamic type, name, fileName;

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeGlobal;
}

- (NSString *) name
{
    return @"general_settings";
}

- (NSString *) publicName
{
    return OALocalizedString(@"general_settings_2");
}

- (BOOL)exists
{
    return YES;
}

- (OASettingsItemReader *)getReader
{
    return [[OASettingsItemReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *)getWriter
{
    return [[OASettingsItemWriter alloc] initWithItem:self];
}

@end
