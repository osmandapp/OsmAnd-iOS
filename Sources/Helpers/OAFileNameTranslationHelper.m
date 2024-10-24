//
//  OAFileNameTranslationHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 02/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAFileNameTranslationHelper.h"
#import "OAIndexConstants.h"
#import "Localization.h"
#import "OAWorldRegion.h"
#import "OsmAndApp.h"
#import "OsmAnd_Maps-Swift.h"

#define WIKI_NAME @"_wiki"
#define HILL_SHADE @"Hillshade"
#define SLOPE @"Slope"
#define SEA_DEPTH @"Depth_"

@implementation OAFileNameTranslationHelper

+ (NSString *) getVoiceName:(NSString *)fileName
{
    NSString *nm = [[fileName stringByReplacingOccurrencesOfString:@"-" withString:@"_"] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    if ([nm hasSuffix:@"_tts"] || [nm hasSuffix:@"-tts"])
        nm = [nm substringToIndex:nm.length - 4];
    
    NSString *name = [OAUtilities displayNameForLang:nm];
    if (name)
        return [name capitalizedStringWithLocale:[NSLocale currentLocale]];
    else
        return fileName;
}

+ (NSArray<NSString *> *) getVoiceNames:(NSArray *)languageCodes
{
    NSMutableArray<NSString *> *fullNames = [NSMutableArray new];
    for (NSString *code in languageCodes) {
        [fullNames addObject:[OAFileNameTranslationHelper getVoiceName:code]];
    }
    return fullNames;
}

+ (NSString *) getMapName:(NSString *)fileName
{
    NSString *title = [[fileName stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "].capitalizedString;
    NSInteger dotLoc = [title lastIndexOf:@"."];
    if (dotLoc > 0)
        title = [title substringToIndex:dotLoc];
    return title;
}

@end
