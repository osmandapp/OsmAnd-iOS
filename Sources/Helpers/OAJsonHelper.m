//
//  OAJsonHelper.m
//  OsmAnd
//
//  Created by Paul on 15.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAJsonHelper.h"

@implementation OAJsonHelper

+ (NSString *) getLocalizedResFromMap:(NSDictionary<NSString *, NSString *> *)localizedMap defValue:(NSString *)defValule
{
    if (localizedMap.count > 0)
    {
        NSString *currLang = NSLocale.currentLocale.languageCode;
        NSString *name = localizedMap[currLang];
        if (!name || name.length == 0)
            name = localizedMap[@""];
        
        if (name && name.length > 0)
            return name;
    }
    return defValule;
}

@end
