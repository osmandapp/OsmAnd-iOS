//
//  Localization.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/18/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#ifndef OsmAnd_Localization_h
#define OsmAnd_Localization_h

#import <Foundation/Foundation.h>

#define OALocalizedString(defaultValue) \
    defaultValue
/*
#define OALocalizedString(defaultValue) \
    _OALocalizedString(defaultValue, __FILE__, __LINE__, __PRETTY_FUNCTION__)
inline NSString* _OALocalizedString(NSString* defaultValue, const char* file, unsigned int line, const char* prettyFunction)
{
    NSString* key = [NSString stringWithFormat:@"%s(%d):'%@'", prettyFunction, line, defaultValue];
    NSString* comment = [NSString stringWithFormat:@"%s:%d:%s:'%@'", file, line, prettyFunction, defaultValue];
    return NSLocalizedStringWithDefaultValue(key, nil, [NSBundle mainBundle], defaultValue, comment);
}
*/
#endif
