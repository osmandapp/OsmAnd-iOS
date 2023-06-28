//
//  OAImportExportSettingsConverter.m
//  OsmAnd
//
//  Created by Paul on 13.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAImportExportSettingsConverter.h"

@implementation OAImportExportSettingsConverter

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
