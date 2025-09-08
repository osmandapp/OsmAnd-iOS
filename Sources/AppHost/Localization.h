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

NS_ASSUME_NONNULL_BEGIN

#pragma GCC diagnostic ignored "-Wformat-security"

#define OALocalizedString(defaultValue, ...) \
_OALocalizedString(false, nil, defaultValue, ##__VA_ARGS__)

#define OALocalizedStringUp(defaultValue, ...) \
_OALocalizedString(true, nil, defaultValue, ##__VA_ARGS__)

#define OALocalizedStringForLocaleCode(languageCode, defaultValue, ...) \
_OALocalizedString(false, languageCode, defaultValue, ##__VA_ARGS__)

#define OALocalizedStringUpForLocaleCode(languageCode, defaultValue, ...) \
_OALocalizedString(true, languageCode, defaultValue, ##__VA_ARGS__)

static NSBundle * _Nullable enBundle = nil;
static NSMutableDictionary<NSString *, NSBundle *> * _Nullable localeBundleCache = nil;

static inline NSString * _OALocalizedString(BOOL upperCase, NSString * _Nullable languageCode, NSString * _Nullable defaultValue, ...)
{
    if (!enBundle)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"];
        enBundle = [NSBundle bundleWithPath:path];
    }
    
    NSArray *arr = [defaultValue componentsSeparatedByString:@" "];
    NSString *key;
    for (NSString *s in arr)
    {
        if (s.length > 0 && [[NSCharacterSet letterCharacterSet] characterIsMember:[s characterAtIndex:0]])
        {
            key = s;
            break;
        }
    }

    NSString *res;
    if (key)
    {
        NSBundle *bundleToUse = [NSBundle mainBundle];
        if (languageCode.length > 0)
        {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                localeBundleCache = [NSMutableDictionary dictionary];
            });
            
            NSBundle *langBundle;
            @synchronized (localeBundleCache) {
                langBundle = localeBundleCache[languageCode];
            }
            
            if (!langBundle)
            {
                NSString *customPath = [[NSBundle mainBundle] pathForResource:languageCode ofType:@"lproj"];
                if (customPath)
                {
                    langBundle = [NSBundle bundleWithPath:customPath];
                    if (langBundle)
                    {
                        @synchronized (localeBundleCache) {
                            localeBundleCache[languageCode] = langBundle;
                        }
                    }
                }
            }
            
            if (langBundle)
                bundleToUse = langBundle;
        }
        
        NSString *loc = [bundleToUse localizedStringForKey:key value:@"!!!" table:nil];
        if ([loc isEqualToString:@"!!!"] || loc.length == 0)
            loc = [enBundle localizedStringForKey:key value:@"" table:nil];

        NSString *newValue = [defaultValue stringByReplacingOccurrencesOfString:key withString:loc];
        newValue = [newValue stringByReplacingOccurrencesOfString:@"%1$s" withString:@"%@"];
        newValue = [newValue stringByReplacingOccurrencesOfString:@"%1$d" withString:@"%d"];
        newValue = [newValue stringByReplacingOccurrencesOfString:@"%2$s" withString:@"%@"];
        newValue = [newValue stringByReplacingOccurrencesOfString:@"%2$d" withString:@"%d"];
        if ([defaultValue isEqualToString:key])
        {
            if (upperCase)
                res = [newValue uppercaseStringWithLocale:[NSLocale currentLocale]];
            else
                res = newValue;
        }
        else
        {
            va_list args;
            va_start(args, defaultValue);
            if (upperCase)
                res = [[[NSString alloc] initWithFormat:newValue arguments:args] uppercaseStringWithLocale:[NSLocale currentLocale]];
            else
                res = [[NSString alloc] initWithFormat:newValue arguments:args];
            
            va_end(args);
        }
    }
    else
    {
        va_list args;
        va_start(args, defaultValue);
        res = [[NSString alloc] initWithFormat:defaultValue arguments:args];
        va_end(args);
    }
    
    return res;
}

static inline NSString *localizedString(NSString * _Nullable defaultValue)
{
    return _OALocalizedString(false, nil, defaultValue);
}

static inline NSString *localizedStringWithLocale(NSString * _Nullable languageCode, NSString * _Nullable defaultValue)
{
    return _OALocalizedString(false, languageCode, defaultValue);
}

static inline NSString *localizedStringUpWithLocale(NSString * _Nullable languageCode, NSString * _Nullable defaultValue)
{
    return _OALocalizedString(true, languageCode, defaultValue);
}

NS_ASSUME_NONNULL_END

#endif
