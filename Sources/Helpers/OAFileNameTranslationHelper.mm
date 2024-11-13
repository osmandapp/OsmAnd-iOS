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
#import "OASQLiteTileSource.h"
#import "OsmAndApp.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

static NSString *WIKI_NAME = @"_wiki";
static NSString *WIKIVOYAGE_NAME = @"_wikivoyage";
static NSString *HILL_SHADE = @"Hillshade";
static NSString *HEIGHTMAP = @"Heightmap";
static NSString *SLOPE = @"Slope";
static NSString *SEA_DEPTH = @"Depth_";
static NSString *TRAVEL_TOPICS = @"travel_topics";

@implementation OAFileNameTranslationHelper

+ (NSString *) getFileNameWithRegion:(NSString *)fileName
{
    return [self getFileName:fileName divider:@" " includingParent:YES reversed:NO];
}

+ (NSString *) getFileName:(NSString *)fileName divider:(NSString *)divider includingParent:(BOOL)includingParent reversed:(BOOL)reversed
{
    NSString *basename = [self getBasename:fileName];
    if ([basename hasSuffix:WIKI_NAME])
    {
        return [self getWikiName:basename];
    }
    else if ([basename hasSuffix:WIKIVOYAGE_NAME])
    {
        return [self getWikivoyageName:basename];
    }
    else if ([fileName hasSuffix:WEATHER_MAP_INDEX_EXT])
    {
        basename = [basename stringByReplacingOccurrencesOfString:@"Weather_" withString:@""];
        return [self getWeatherName:basename];
    }
    else if ([fileName hasSuffix:@"tts"])
    {
        return [self getVoiceName:fileName];
    }
//    else if ([fileName hasSuffix:FONT_INDEX_EXT])
//    {
//        return getFontName(basename);
//    }
    else if ([fileName hasPrefix:HILL_SHADE])
    {
        basename = [basename stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@ ", HILL_SHADE] withString:@""];
        return [self getTerrainName:basename terrainName:OALocalizedString(@"download_hillshade_maps")];
    }
    else if ([fileName hasPrefix:HEIGHTMAP])
    {
        basename = [basename stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@ ", HEIGHTMAP] withString:@""];
        return [self getTerrainName:basename terrainName:OALocalizedString(@"terrain_map")];
    }
    else if ([fileName hasPrefix:SLOPE])
    {
        basename = [basename stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@ ", SLOPE] withString:@""];
        return [self getTerrainName:basename terrainName:OALocalizedString(@"download_slope_maps")];
    }
    else if ([SrtmDownloadItem isSrtmFile:fileName])
    {
        return [self getTerrainName:basename terrainName:OALocalizedString(@"download_srtm_maps")];
    }
//    else if (fileName.length == 2)  //voice recorded files
//    {
//    }
    
    //if nothing else
    NSString *lc = [basename lowercaseString];
    NSString *std = [self getStandardMapName:lc];
    if (std)
        return std;
    
    return [OsmAndApp.instance.worldRegion getLocaleName:basename divider:divider includingParent:includingParent reversed:reversed];
}

+ (NSString *) getTerrainName:(NSString *)basename terrainName:(NSString *)terrainName
{
    basename = [basename stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    NSString *locName = [OsmAndApp.instance.worldRegion getLocaleName:basename includingParent:YES];
    NSString *formatName = [NSString stringWithFormat:@"(%@)", terrainName];
    return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_space"), locName, formatName];

}

+ (NSString *) getWikiName:(NSString *)basename
{
    NSString *cutted = [basename substringToIndex:[basename indexOf:@"_wiki"]];
    NSString *wikiName = [self getStandardLangName:cutted];
    if (!wikiName)
        wikiName = cutted;
    NSString *wikiWord = OALocalizedString(@"amenity_type_osmwiki");
    int index = [wikiWord indexOf:@"("];
    if (index >= 0)
    {
        //removing word in "()" from recourse file
        return [NSString stringWithFormat:@"%@ %@", wikiName, [wikiWord substringToIndex:index].trim];
    }
    return [NSString stringWithFormat:@"%@ %@", wikiName, OALocalizedString(@"amenity_type_osmwiki")];
}

+ (NSString *) getWikivoyageName:(NSString *)basename
{
    NSString *formattedName = [basename substringToIndex:[basename indexOf:WIKIVOYAGE_NAME]];
    formattedName = [formattedName stringByReplacingOccurrencesOfString:@"-" withString:@""];
    formattedName = [formattedName stringByReplacingOccurrencesOfString:@"all" withString:@""];
    
    if ([formattedName isEqualToString:@"Default"])
    {
        return OALocalizedString(@"sample_wikivoyage");
    }
    else
    {
        NSString *wikiVoyageName = [self getSuggestedWikivoyageMaps:formattedName];
        if (!wikiVoyageName)
            wikiVoyageName = formattedName;
        NSString *wikiVoyageWord = OALocalizedString(@"shared_string_wikivoyage");
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_space"), wikiVoyageName, wikiVoyageWord];
    }
}

+ (NSString *) getWeatherName:(NSString *)basename
{
    basename = [basename stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    if ([self equalsIgnoreCase:basename stringB:kWorldRegionId])
        return OALocalizedString(@"shared_string_all_world");
    else
        return [OsmAndApp.instance.worldRegion getLocaleName:basename.trim includingParent:NO];
}

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

+ (NSString *) getBasename:(NSString *)fileName
{
    if ([fileName hasSuffix:EXTRA_ZIP_EXT])
    {
        return [fileName substringToIndex:fileName.length - EXTRA_ZIP_EXT.length];
    }
    if ([fileName hasSuffix:SQLITE_EXT])
    {
        // in android
        // return settings.getTileSourceTitle(fileName);
        
        NSString *title = fileName.lastPathComponent;
        NSInteger dotLoc = [title lastIndexOf:@"."];
        if (dotLoc > 0)
            title = [title substringToIndex:dotLoc];
        return title.lastPathComponent;
    }
    if ([fileName hasSuffix:WEATHER_EXT])
    {
        return [fileName substringToIndex:fileName.length - WEATHER_EXT.length];
    }
    
    int ls = [fileName indexOf:@"-roads"];
    if (ls >= 0)
    {
        return [fileName substringToIndex:ls];
    }
    else
    {
        ls = [fileName indexOf:@"."];
        if (ls >= 0)
            return [fileName substringToIndex:ls];
    }
    return fileName;
}

+ (NSString *) getStandardLangName:(NSString *)filename
{
    if ([self equalsIgnoreCase:filename stringB:@"Afrikaans"] || [self equalsIgnoreCase:filename stringB:@"Africaans"])
        return OALocalizedString(@"lang_af");
    else if ([self equalsIgnoreCase:filename stringB:@"Belarusian"])
        return OALocalizedString(@"lang_be");
    else if ([self equalsIgnoreCase:filename stringB:@"Bulgarian"])
        return OALocalizedString(@"lang_bg");
    else if ([self equalsIgnoreCase:filename stringB:@"Bosnian"])
        return OALocalizedString(@"lang_bs");
    else if ([self equalsIgnoreCase:filename stringB:@"Catalan"])
        return OALocalizedString(@"lang_ca");
    else if ([self equalsIgnoreCase:filename stringB:@"Czech"])
        return OALocalizedString(@"lang_cs");
    else if ([self equalsIgnoreCase:filename stringB:@"Welsh"])
        return OALocalizedString(@"lang_cy");
    else if ([self equalsIgnoreCase:filename stringB:@"Danish"])
        return OALocalizedString(@"lang_da");
    else if ([self equalsIgnoreCase:filename stringB:@"German"])
        return OALocalizedString(@"lang_de");
    else if ([self equalsIgnoreCase:filename stringB:@"Greek"])
        return OALocalizedString(@"lang_el");
    else if ([self equalsIgnoreCase:filename stringB:@"English"])
        return OALocalizedString(@"lang_en");
    else if ([self equalsIgnoreCase:filename stringB:@"Spanish"])
        return OALocalizedString(@"lang_es");
    else if ([self equalsIgnoreCase:filename stringB:@"Basque"])
        return OALocalizedString(@"lang_eu");
    else if ([self equalsIgnoreCase:filename stringB:@"Finnish"])
        return OALocalizedString(@"lang_fi");
    else if ([self equalsIgnoreCase:filename stringB:@"French"])
        return OALocalizedString(@"lang_fr");
    else if ([self equalsIgnoreCase:filename stringB:@"Hindi"])
        return OALocalizedString(@"lang_hi");
    else if ([self equalsIgnoreCase:filename stringB:@"Croatian"])
        return OALocalizedString(@"lang_hr");
    else if ([self equalsIgnoreCase:filename stringB:@"Hungarian"])
        return OALocalizedString(@"lang_hu");
    else if ([self equalsIgnoreCase:filename stringB:@"Armenian"])
        return OALocalizedString(@"lang_hy");
    else if ([self equalsIgnoreCase:filename stringB:@"Indonesian"])
        return OALocalizedString(@"lang_id");
    else if ([self equalsIgnoreCase:filename stringB:@"Italian"])
        return OALocalizedString(@"lang_it");
    else if ([self equalsIgnoreCase:filename stringB:@"Hebrew"])
        return OALocalizedString(@"lang_iw");
    else if ([self equalsIgnoreCase:filename stringB:@"Japanese"])
        return OALocalizedString(@"lang_ja");
    else if ([self equalsIgnoreCase:filename stringB:@"Georgian"])
        return OALocalizedString(@"lang_ka");
    else if ([self equalsIgnoreCase:filename stringB:@"Korean"])
        return OALocalizedString(@"lang_ko");
    else if ([self equalsIgnoreCase:filename stringB:@"Lithuanian"])
        return OALocalizedString(@"lang_lt");
    else if ([self equalsIgnoreCase:filename stringB:@"Latvian"])
        return OALocalizedString(@"lang_lv");
    else if ([self equalsIgnoreCase:filename stringB:@"Marathi"])
        return OALocalizedString(@"lang_mr");
    else if ([self equalsIgnoreCase:filename stringB:@"Dutch"])
        return OALocalizedString(@"lang_nl");
    else if ([self equalsIgnoreCase:filename stringB:@"Norwegian"])
        return OALocalizedString(@"lang_no");
    else if ([self equalsIgnoreCase:filename stringB:@"Polish"])
        return OALocalizedString(@"lang_pl");
    else if ([self equalsIgnoreCase:filename stringB:@"Portuguese"])
        return OALocalizedString(@"lang_pt");
    else if ([self equalsIgnoreCase:filename stringB:@"Romanian"])
        return OALocalizedString(@"lang_ro");
    else if ([self equalsIgnoreCase:filename stringB:@"Russian"])
        return OALocalizedString(@"lang_ru");
    else if ([self equalsIgnoreCase:filename stringB:@"Slovak"])
        return OALocalizedString(@"lang_sk");
    else if ([self equalsIgnoreCase:filename stringB:@"Slovenian"])
        return OALocalizedString(@"lang_sl");
    else if ([self equalsIgnoreCase:filename stringB:@"Swedish"])
        return OALocalizedString(@"lang_sv");
    else if ([self equalsIgnoreCase:filename stringB:@"Turkish"])
        return OALocalizedString(@"lang_tr");
    else if ([self equalsIgnoreCase:filename stringB:@"Ukrainian"])
        return OALocalizedString(@"lang_uk");
    else if ([self equalsIgnoreCase:filename stringB:@"Vietnamese"])
        return OALocalizedString(@"lang_vi");
    else if ([self equalsIgnoreCase:filename stringB:@"Chinese"])
        return OALocalizedString(@"lang_zh");
    return nil;
}

+ (NSString *) getStandardMapName:(NSString *)basename
{
    if ([basename isEqualToString:@"world-ski"])
        return OALocalizedString(@"index_item_world_ski");
    else if ([basename isEqualToString:@"world_altitude_correction_ww15mgh"])
        return OALocalizedString(@"index_item_world_altitude_correction");
    else if ([basename isEqualToString:@"world_basemap"])
        return OALocalizedString(@"index_item_world_basemap");
    else if ([basename isEqualToString:@"world_basemap_detailed"])
        return OALocalizedString(@"index_item_world_basemap_detailed");
    else if ([basename isEqualToString:@"world_basemap_mini"])
    {
        NSString *basemap = OALocalizedString(@"index_item_world_basemap");
        NSString *mini = [NSString stringWithFormat:@"(%@)", OALocalizedString(@"shared_string_mini")];
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_space", basemap, mini)];
    }
    else if ([basename isEqualToString:@"world_bitcoin_payments"])
        return OALocalizedString(@"index_item_world_bitcoin_payments");
    else if ([basename isEqualToString:WORLD_SEAMARKS_KEY] ||
             [basename isEqualToString:WORLD_SEAMARKS_OLD_KEY])
        return OALocalizedString(@"index_item_world_seamarks");
    else if ([basename isEqualToString:@"world_wikivoyage"])
        return OALocalizedString(@"index_item_world_wikivoyage");
    else if ([basename isEqualToString:@"depth_contours_osmand_ext"])
        return OALocalizedString(@"index_item_depth_contours_osmand_ext");
    else if ([basename isEqualToString:@"depth_points_southern_hemisphere_osmand_ext"])
        return OALocalizedString(@"index_item_depth_points_southern_hemisphere");
    else if ([basename isEqualToString:@"depth_points_northern_hemisphere_osmand_ext"])
        return OALocalizedString(@"index_item_depth_points_northern_hemisphere");
    return nil;
}

+ (NSString *) getSuggestedWikivoyageMaps:(NSString *)filename
{
    if ([self equalsIgnoreCase:filename stringB:kAfricaRegionId])
        return OALocalizedString(@"index_name_africa");
    else if ([self equalsIgnoreCase:filename stringB:[kAustraliaAndOceaniaRegionId stringByReplacingOccurrencesOfString:@"-" withString:@""]])
        return OALocalizedString(@"index_name_oceania");
    else if ([self equalsIgnoreCase:filename stringB:kAsiaRegionId])
        return OALocalizedString(@"index_name_asia");
    else if ([self equalsIgnoreCase:filename stringB:kCentralAmericaRegionId])
        return OALocalizedString(@"index_name_central_america");
    else if ([self equalsIgnoreCase:filename stringB:kEuropeRegionId])
        return OALocalizedString(@"index_name_europe");
    else if ([self equalsIgnoreCase:filename stringB:kRussiaRegionId])
        return OALocalizedString(@"index_name_russia");
    else if ([self equalsIgnoreCase:filename stringB:kNorthAmericaRegionId])
        return OALocalizedString(@"index_name_north_america");
    else if ([self equalsIgnoreCase:filename stringB:kSouthAmericaRegionId])
        return OALocalizedString(@"index_name_south_america");
    else if ([self equalsIgnoreCase:filename stringB:kAntarcticaRegionId])
        return OALocalizedString(@"index_name_antarctica");
    else if ([self equalsIgnoreCase:filename stringB:TRAVEL_TOPICS])
        return OALocalizedString(@"travel_topics");
    return nil;
}

+ (BOOL) equalsIgnoreCase:(NSString *)stringA stringB:(NSString *)stringB
{
    return [[stringA lowercaseString] isEqualToString:[stringB lowercaseString]];
}

@end
