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
    
    NSString *name = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:nm];
    if (name)
        return [name capitalizedStringWithLocale:[NSLocale currentLocale]];
    else
        return fileName;
}

+ (NSArray<NSString *> *) getVoiceNames:(NSArray *) languageCodes
{
    NSMutableArray<NSString *> *fullNames = [NSMutableArray new];
    for (NSString *code in languageCodes) {
        [fullNames addObject:[OAFileNameTranslationHelper getVoiceName:code]];
    }
    return fullNames;
}

//+ (NSString *) getFileNameWithRegion:(NSString *)fileName
//{
//    return [self getFileName(app, app.getResourceManager().getOsmandRegions(), fileName);
//}

//+ (NSString *) getFileName:(NSString *)fileName
//{
//    NSString *basename = [self.class getBasename:fileName];
//    if ([basename hasSuffix:WIKI_NAME])
//    { //wiki files
//        return [self.class getWikiName:basename];
//    }
//    else if (fileName.endsWith("tts"))
//    { //tts files
//        return getVoiceName(ctx, fileName);
//    } else if (fileName.endsWith(IndexConstants.FONT_INDEX_EXT)) { //otf files
//        return getFontName(ctx, basename);
//    }
//    else if ([fileName hasSuffix:HILL_SHADE])
//    {
//        basename = [basename stringByReplacingOccurrencesOfString:[HILL_SHADE stringByAppendingString:@" "] withString:@""];
//        return [self.class getTerrainName:basename localizedType:OALocalizedString(@"res_hillshade")];
//    }
//    else if ([fileName hasSuffix:SLOPE])
//    {
//        basename = [basename stringByReplacingOccurrencesOfString:[SLOPE stringByAppendingString:@" "] withString:@""];
//        return [self.class getTerrainName:basename localizedType:OALocalizedString(@"res_slope")];
//    }
//    else if (fileName.length() == 2) { //voice recorded files
//        try {
//            Field f = R.string.class.getField("lang_" + fileName);
//            if (f != null) {
//                Integer in = (Integer) f.get(null);
//                return ctx.getString(in);
//            }
//        } catch (Exception e) {
//            System.err.println(e.getMessage());
//        }
//    }
    
    //if nothing else
//    NSString *lc = basename.lowerCase;
//    NSString *std = [self getStandardMapName:lc];
//    if (std)
//        return std;
    
//    OAWorldRegion *regions = OsmAndApp.instance.worldRegion;
//
//    if (regions)
//        return [regions getLocaleName:basename, true);
    
//    return nil;
//}

//+ (NSString *) getTerrainName:(NSString *)basename localizedType:(NSString *)localizedType
//{
//        basename = [basename stringByReplacingOccurrencesOfString:@" " withString:@"_"];
//        NSString *locName = regions.getLocaleName(basename.trim(), true);
//        return ctx.getString(R.string.ltr_or_rtl_combine_via_space, locName, "(" + terrain + ")");
//}
//
//    public static String getWikiName(Context ctx, String basename){
//        String cutted = basename.substring(0, basename.indexOf("_wiki"));
//        String wikiName = getStandardLangName(ctx, cutted);
//        if (wikiName == null){
//            wikiName = cutted;
//        }
//        String wikiWord = ctx.getString(R.string.amenity_type_osmwiki);
//        int index = wikiWord.indexOf("(");
//        if (index >= 0) {
//            //removing word in "()" from recourse file
//            return wikiName + " " + wikiWord.substring(0, index).trim();
//        }
//        return  wikiName + " " + ctx.getString(R.string.amenity_type_osmwiki);
//    }

//public static String getVoiceName(Context ctx, String fileName) {
//        try {
//            String nm = fileName.replace('-', '_').replace(' ', '_');
//            if (nm.endsWith("_tts") || nm.endsWith(IndexConstants.VOICE_PROVIDER_SUFFIX)) {
//                nm = nm.substring(0, nm.length() - 4);
//            }
//            Field f = R.string.class.getField("lang_" + nm);
//            if (f != null) {
//                Integer in = (Integer) f.get(null);
//                return ctx.getString(in);
//            }
//        } catch (Exception e) {
//            System.err.println(e.getMessage());
//        }
//        return fileName;
//    }
//
//    public static String getFontName(Context ctx, String basename) {
//        return basename.replace('-', ' ').replace('_', ' ');
//    }

//+ (NSString *) getBasename:(NSString *)fileName
//{
//    if ([fileName hasSuffix:EXTRA_ZIP_EXT])
//        return [fileName substringToIndex:fileName.lenght - EXTRA_ZIP_EXT.lenght];
//
//    if ([fileName hasSuffix:SQLITE_EXT])
//        return [[fileName substringToIndex:fileName.length - SQLITE_EXT.length] stringByReplacingOccurencesOfString:@"_" withString:@" "];
//
//    NSInteger ls = [fileName lastIndexOf:@"-roads"];
//    if (ls >= 0)
//    {
//        return [fileName substringToIndex:ls];
//    }
//    else
//    {
//        ls = [fileName indexOf:@"."];
//        if (ls >= 0)
//        {
//            return [fileName substringToIndex:ls];
//        }
//    }
//    return fileName;
//}

@end
