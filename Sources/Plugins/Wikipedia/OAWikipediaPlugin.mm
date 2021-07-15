//
//  OAWikipediaPlugin.mm
//  OsmAnd
//
//  Created by Skalii on 02.07.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "Localization.h"
#import "OsmAndApp.h"
#import "OAProducts.h"
#import "OARootViewController.h"
#import "OAWikipediaPlugin.h"
#import "OAPOIUIFilter.h"
#import "OAPOIHelper.h"
#import "OAPOIFiltersHelper.h"
#import "OASearchPhrase.h"
#import "OASearchWord.h"
#import "OAPOI.h"

#define PLUGIN_ID kInAppId_Addon_Wiki

@implementation OAWikipediaPlugin {

    OsmAndAppInstance _app;
    OAPOIUIFilter *_topWikiPoiFilter;

}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
    }
    return self;
}

- (NSString *)getId
{
    return PLUGIN_ID;
}

- (NSString *)getLogoResourceId
{
    return @"ic_plugin_wikipedia";
}

- (NSString *)getName
{
    return OALocalizedString(@"product_title_wiki");
}

- (NSString *)getDescription
{
    return OALocalizedString(@"plugin_wikipedia_description");
}

- (void)updateLayers
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self toggleWikipediaPoi:!self.isActive ? NO : _app.data.wikipedia];
    });
}

- (NSArray<OAPOIUIFilter *> *)getCustomPoiFilters
{
    NSMutableArray<OAPOIUIFilter *> *poiFilters = [NSMutableArray new];
    if (_topWikiPoiFilter == nil)
    {
        OAPOICategory *poiType = [OAPOIHelper sharedInstance].getOsmwiki;
        _topWikiPoiFilter = [[OAPOIUIFilter alloc] initWithBasePoiType:poiType idSuffix:@""];
    }
    [poiFilters addObject:_topWikiPoiFilter];

    return poiFilters;
}

- (void)updateWikipediaState
{
    [self toggleWikipediaPoi:[self isShowAllLanguages] || [self hasLanguagesFilter]];
    [self refreshWikiOnMap];
}


- (BOOL)hasCustomSettings
{
    return ![self isShowAllLanguages] && [self getLanguagesToShow].count > 0;
}

- (BOOL)hasCustomSettings:(OAApplicationMode *)profile
{
    return ![self isShowAllLanguages:profile] && [self getLanguagesToShow:profile].count > 0;
}

- (BOOL)hasLanguagesFilter
{
    return [_app.data getWikipediaLanguages].count > 0;
}

- (BOOL)hasLanguagesFilter:(OAApplicationMode *)profile
{
    return [_app.data getWikipediaLanguages:profile].count > 0;
}

- (BOOL)isShowAllLanguages
{
    return [_app.data getWikipediaAllLanguages];
}

- (BOOL)isShowAllLanguages:(OAApplicationMode *)mode
{
    return [_app.data getWikipediaAllLanguages:mode];
}

- (void)setShowAllLanguages:(BOOL)showAllLanguages
{
    [_app.data setWikipediaAllLanguages:showAllLanguages];
}

- (void)setShowAllLanguages:(OAApplicationMode *)mode showAllLanguages:(BOOL)showAllLanguages
{
    [_app.data setWikipediaAllLanguages:showAllLanguages mode:mode];
}

- (NSArray<NSString *> *)getLanguagesToShow
{
    return [_app.data getWikipediaLanguages];
}

- (NSArray<NSString *> *)getLanguagesToShow:(OAApplicationMode *)mode
{
    return [_app.data getWikipediaLanguages:mode];
}

- (void)setLanguagesToShow:(NSArray<NSString *> *)languagesToShow
{
    [_app.data setWikipediaLanguages:languagesToShow];
}

- (void)setLanguagesToShow:(OAApplicationMode *)mode languagesToShow:(NSArray<NSString *> *)languagesToShow
{
    [_app.data setWikipediaLanguages:languagesToShow mode:mode];
}

- (void)toggleWikipediaPoi:(BOOL)enable
{
    if (enable)
        [self showWikiOnMap];
    else
        [self hideWikiFromMap];

    [[OARootViewController instance].mapPanel.mapViewController updatePoiLayer];
    [[OARootViewController instance].mapPanel refreshMap];
}

- (void)refreshWikiOnMap
{
    [[OAPOIFiltersHelper sharedInstance] loadSelectedPoiFilters];
//    [[OARootViewController instance].mapPanel.mapViewController updatePoiLayer];
    [[OARootViewController instance].mapPanel refreshMap];
}

- (void)showWikiOnMap
{
    OAPOIUIFilter *wiki = [[OAPOIFiltersHelper sharedInstance] getTopWikiPoiFilter];
    [[OAPOIFiltersHelper sharedInstance] loadSelectedPoiFilters];
    [[OAPOIFiltersHelper sharedInstance] addSelectedPoiFilter:wiki];
}

- (void)hideWikiFromMap
{
    OAPOIUIFilter *wiki = [[OAPOIFiltersHelper sharedInstance] getTopWikiPoiFilter];
    [[OAPOIFiltersHelper sharedInstance] removePoiFilter:wiki];
    [[OAPOIFiltersHelper sharedInstance] removeSelectedPoiFilter:wiki];
}

- (NSString *)getLanguagesSummary
{
    if ([self hasCustomSettings])
    {
        NSMutableArray<NSString *> *translations = [NSMutableArray new];
        for (NSString *locale in [self getLanguagesToShow])
        {
            [translations addObject:[OAUtilities capitalizeFirstLetterAndLowercase:[OAUtilities translatedLangName:locale]]];
        }
        return [translations componentsJoinedByString:@", "];
    }
    return OALocalizedString(@"shared_string_all_languages");
}

- (NSString *)getMapObjectsLocale:(NSObject *)object preferredLocale:(NSString *)preferredLocale
{
    if ([object isKindOfClass:OAPOI.class])
        return [self getWikiArticleLanguage:[((OAPOI *)object) getSupportedContentLocales] preferredLanguage:preferredLocale];
    return nil;
}

- (NSString *)getWikiArticleLanguage:(NSSet<NSString *> *)availableArticleLangs preferredLanguage:(NSString *)preferredLanguage
{
    if (![self hasCustomSettings])
        // Wikipedia with default settings
        return preferredLanguage;

    if (!preferredLanguage || preferredLanguage.length == 0)
        preferredLanguage = [OAAppSettings sharedManager].settingPrefMapLanguage.get;

    NSArray<NSString *> *wikiLangs = [self getLanguagesToShow];
    if (![wikiLangs containsObject:preferredLanguage])
    {
        // return first matched language from enabled Wikipedia languages
        for (NSString *language in wikiLangs)
        {
            if ([availableArticleLangs containsObject:language])
                return language;
        }
    }
    return preferredLanguage;
}

- (void)prepareExtraTopPoiFilters:(NSSet<OAPOIUIFilter *> *)poiUIFilters
{
    for (OAPOIUIFilter *filter in poiUIFilters)
    {
        if ([filter isTopWikiFilter])
        {
            BOOL prepareByDefault = YES;
            if ([self hasCustomSettings])
            {
                prepareByDefault = NO;
                NSString *wikiLang = @"wiki:lang:";
                NSMutableString *sb = [NSMutableString new];
                for (NSString *lang in [self getLanguagesToShow])
                {
                    if (sb.length > 1)
                        [sb appendString:@" "];
                    [sb appendString:wikiLang];
                    [sb appendString:lang];
                }
                [filter setFilterByName:sb];
            }
            if (prepareByDefault)
                [filter setFilterByName:nil];
            return;
        }
    }
}

- (BOOL)isSearchByWiki:(OASearchPhrase *)phrase
{
    if ([phrase isLastWord:POI_TYPE])
    {
        NSObject *obj = [phrase getLastSelectedWord].result.object;
        if ([obj isKindOfClass:OAPOIUIFilter.class])
        {
            OAPOIUIFilter *pf = (OAPOIUIFilter *) obj;
            return [pf isWikiFilter];
        }
        else if ([obj isKindOfClass:OAPOIBaseType.class])
        {
            OAPOIBaseType *pt = (OAPOIBaseType *) obj;
            return [pt.name hasPrefix:@"wiki_lang"];
        }
    }
    return NO;
}

@end
