//
//  OAImportExportSettingsConverter.m
//  OsmAnd
//
//  Created by Paul on 13.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAImportExportSettingsConverter.h"

@implementation OAImportExportSettingsConverter

+ (NSString *) rulerWidgetModeToString:(EOARulerWidgetMode)rulerMode
{
    switch (rulerMode) {
        case RULER_MODE_DARK:
            return @"FIRST";
        case RULER_MODE_LIGHT:
            return @"SECOND";
        case RULER_MODE_NO_CIRCLES:
            return @"EMPTY";
        default:
            return @"FIRST";
    }
}

+ (NSString *) booleanPreferenceToString:(BOOL)pref
{
    return pref ? @"true" : @"false";
}

+ (NSString *) arrayPreferenceToString:(NSArray *)pref
{
    NSMutableString *res = [NSMutableString new];
    for (NSInteger i = 0; i < pref.count; i++)
    {
        [res appendString:pref[i]];
        if (i != pref.count - 1)
            [res appendString:@","];
    }
    return res;
}

@end
