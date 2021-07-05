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

#define PLUGIN_ID kInAppId_Addon_Wiki

@interface OAWikipediaPlugin ()
@end

@implementation OAWikipediaPlugin {

    OAPOIUIFilter *_topWikiPoiFilter;

}

- (NSString *) getId
{
    return PLUGIN_ID;
}

- (NSString *) getLogoResourceId
{
    return @"ic_plugin_wikipedia";
}

- (NSString *) getName
{
    return OALocalizedString(@"product_title_wiki");
}

- (NSString *) getDescription
{
    return OALocalizedString(@"plugin_wikipedia_description");
}

/*@Override
public void mapActivityResume(MapActivity activity) {
    this.mapActivity = activity;
}*/

/*@Override
public void mapActivityResumeOnTop(MapActivity activity) {
    this.mapActivity = activity;
}*/

/*@Override
public void mapActivityPause(MapActivity activity) {
    this.mapActivity = null;
}*/

/*@Override
public boolean init(@NonNull OsmandApplication app, Activity activity) {
    if (activity instanceof MapActivity) {
        mapActivity = (MapActivity) activity;
    }
    return true;
}*/

/*@Override
protected void registerLayerContextMenuActions(OsmandMapTileView mapView,
        ContextMenuAdapter adapter,
        final MapActivity mapActivity) {
    ContextMenuAdapter.ItemClickListener listener = new ContextMenuAdapter.OnRowItemClick() {

        @Override
        public boolean onRowItemClick(ArrayAdapter<ContextMenuItem> adapter, View view, int itemId, int position) {
            if (itemId == R.string.shared_string_wikipedia) {
                mapActivity.getDashboard().setDashboardVisibility(true,
                        DashboardOnMap.DashboardType.WIKIPEDIA,
                        AndroidUtils.getCenterViewCoordinates(view));
            }
            return false;
        }

        @Override
        public boolean onContextMenuClick(final ArrayAdapter<ContextMenuItem> adapter, int itemId,
                final int pos, boolean isChecked, int[] viewCoordinates) {
            if (itemId == R.string.shared_string_wikipedia) {
                toggleWikipediaPoi(isChecked, new CallbackWithObject<Boolean>() {
                    @Override
                    public boolean processResult(Boolean selected) {
                        ContextMenuItem item = adapter.getItem(pos);
                        if (item != null) {
                            item.setSelected(selected);
                            item.setColor(app, selected ?
                                    R.color.osmand_orange : ContextMenuItem.INVALID_ID);
                            item.setDescription(selected ? getLanguagesSummary() : null);
                            adapter.notifyDataSetChanged();
                        }
                        return true;
                    }
                });
            }
            return false;
        }
    };

    boolean selected = app.getPoiFilters().isTopWikiFilterSelected();
    adapter.addItem(new ContextMenuItem.ItemBuilder()
            .setId(WIKIPEDIA_ID)
            .setTitleId(R.string.shared_string_wikipedia, mapActivity)
            .setDescription(selected ? getLanguagesSummary() : null)
            .setSelected(selected)
            .setColor(app, selected ? R.color.osmand_orange : ContextMenuItem.INVALID_ID)
            .setIcon(R.drawable.ic_plugin_wikipedia)
            .setSecondaryIcon(R.drawable.ic_action_additional_option)
            .setListener(listener).createItem());
}*/

- (NSArray<OAPOIUIFilter *> *)getCustomPoiFilters
{
    NSMutableArray<OAPOIUIFilter *> *poiFilters = [NSMutableArray new];
    if (_topWikiPoiFilter == nil) {
        OAPOICategory *poiType = [OAPOIHelper sharedInstance].getOsmwiki;
        _topWikiPoiFilter = [[OAPOIUIFilter alloc] initWithBasePoiType:poiType idSuffix:@""];
    }
    [poiFilters addObject:_topWikiPoiFilter];

    return poiFilters;
}

- (void)updateWikipediaState
{
    if ([self isShowAllLanguages] || [self hasLanguagesFilter])
        [self refreshWikiOnMap];
    else
        [self toggleWikipediaPoi:NO/* callback:nil*/];
}

- (NSString *)getWikiLanguageTranslation:(NSString *)locale
{
    NSString *translation = [OAUtilities translatedLangName:locale];
    /*if ([translation caseInsensitiveCompare:locale])
        translation = [self getTranslationFromPhrases:locale];*/
    return translation;
}

/*- (NSString *)getTranslationFromPhrases:(NSString *)locale
{
    NSString *keyName = [NSString stringWithFormat:@"wiki_lang%@%@", "_", locale];
    try {
        Field f = R.string.class.getField("poi_" + keyName);
        Integer in = (Integer) f.get(null);
        return app.getString(in);
    } catch (Throwable e) {
        return locale;
    }
}*/

- (BOOL)hasCustomSettings
{
    return ![self isShowAllLanguages] && ![[self getLanguagesToShow] isEqualToArray:@[]];
}

- (BOOL)hasCustomSettings:(OAApplicationMode *)profile
{
    return ![self isShowAllLanguages:profile] && ![[self getLanguagesToShow:profile] isEqualToArray:@[]];
}

- (BOOL)hasLanguagesFilter
{
    return [[OsmAndApp instance].data.wikipediaLanguagesProfile.get isEqualToArray:@[]];
}

- (BOOL)hasLanguagesFilter:(OAApplicationMode *)profile
{
    return ![[[OsmAndApp instance].data.wikipediaLanguagesProfile get:profile] isEqualToArray:@[]];
}

- (BOOL)isShowAllLanguages
{
    return [OsmAndApp instance].data.wikipediaGlobalProfile.get;
}

- (BOOL)isShowAllLanguages:(OAApplicationMode *)mode
{
    return [[OsmAndApp instance].data.wikipediaGlobalProfile get:mode];
}

- (void)setShowAllLanguages:(BOOL)showAllLanguages
{
    [[OsmAndApp instance].data.wikipediaGlobalProfile set:showAllLanguages];
}

- (void)setShowAllLanguages:(OAApplicationMode *)mode showAllLanguages:(BOOL)showAllLanguages
{
    [[OsmAndApp instance].data.wikipediaGlobalProfile set:showAllLanguages mode:mode];
}

- (NSArray<NSString *> *)getLanguagesToShow
{
    return [OsmAndApp instance].data.wikipediaLanguagesProfile.get;
}

- (NSArray<NSString *> *)getLanguagesToShow:(OAApplicationMode *)mode
{
    return [[OsmAndApp instance].data.wikipediaLanguagesProfile get:mode];
}

- (void)setLanguagesToShow:(NSArray<NSString *> *)languagesToShow
{
    [[OsmAndApp instance].data.wikipediaLanguagesProfile set:languagesToShow];
}

- (void)setLanguagesToShow:(OAApplicationMode *)mode languagesToShow:(NSArray<NSString *> *)languagesToShow
{
    [[OsmAndApp instance].data.wikipediaLanguagesProfile set:languagesToShow mode:mode];
}

- (void)toggleWikipediaPoi:(BOOL)enable /*CallbackWithObject<Boolean> callback*/
{
    if (enable)
        [self showWikiOnMap];
    else
        [self hideWikiFromMap];

    /*if (callback != null) {
        callback.processResult(enable);
    } else if (mapActivity != null) {
        mapActivity.getDashboard().refreshContent(true);
    }*/

    [[OARootViewController instance].mapPanel.mapViewController updatePoiLayer];
    [[OARootViewController instance].mapPanel refreshMap];
}

- (void)refreshWikiOnMap
{
    /*if (mapActivity == null) {
        return;
    }*/
    [[OAPOIFiltersHelper sharedInstance] loadSelectedPoiFilters];
//    mapActivity.getDashboard().refreshContent(true);
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
            [translations addObject:[self getWikiLanguageTranslation:locale]];
        }
        return [translations componentsJoinedByString:@", "];
    }
    return OALocalizedString(@"shared_string_all_languages");
}

/*@Override
protected String getMapObjectsLocale(Amenity amenity, String preferredLocale) {
    return getWikiArticleLanguage(amenity.getSupportedContentLocales(), preferredLocale);
}*/

/*@Override
protected String getMapObjectPreferredLang(MapObject object, String defaultLanguage) {
    if (object instanceof Amenity) {
        Amenity amenity = (Amenity) object;
        if (amenity.getType().isWiki()) {
            return getWikiArticleLanguage(amenity.getSupportedContentLocales(), defaultLanguage);
        }
    }
    return null;
}*/

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

/*public void showDownloadWikiMapsScreen() {
    if (mapActivity != null) {
        OsmandMapTileView mv = mapActivity.getMapView();
        DownloadedRegionsLayer dl = mv.getLayerByClass(DownloadedRegionsLayer.class);
        String filter = dl.getFilter(new StringBuilder());
        final Intent intent = new Intent(app, app.getAppCustomization().getDownloadIndexActivity());
        intent.putExtra(DownloadActivity.FILTER_KEY, filter);
        intent.putExtra(DownloadActivity.FILTER_CAT, DownloadActivityType.WIKIPEDIA_FILE.getTag());
        intent.putExtra(DownloadActivity.TAB_TO_OPEN, DownloadActivity.DOWNLOAD_TAB);
        mapActivity.startActivity(intent);
    }
}*/

/*public boolean hasMapsToDownload() {
    try {
        if (mapActivity == null) {
            return false;
        }
        int mapsToDownloadCount = DownloadResources.findIndexItemsAt(
                app, mapActivity.getMapLocation(), DownloadActivityType.WIKIPEDIA_FILE,
                false, 1, false).size();
        return mapsToDownloadCount > 0;
    } catch (IOException e) {
        return false;
    }
}*/

/*@Override
protected boolean searchFinished(final QuickSearchDialogFragment searchFragment, SearchPhrase phrase, boolean isResultEmpty) {
    if (isResultEmpty && isSearchByWiki(phrase)) {
        if (!Version.isPaidVersion(app)) {
            searchFragment.addSearchListItem(new QuickSearchFreeBannerListItem(app));
        } else {
            final DownloadIndexesThread downloadThread = app.getDownloadThread();
            if (!downloadThread.getIndexes().isDownloadedFromInternet) {
                searchFragment.reloadIndexFiles();
            } else {
                addEmptyWikiBanner(searchFragment, phrase);
            }
        }
        return true;
    }
    return false;
}*/

/*@Override
protected void newDownloadIndexes(Fragment fragment) {
    if (fragment instanceof QuickSearchDialogFragment) {
        final QuickSearchDialogFragment f = (QuickSearchDialogFragment) fragment;
        SearchPhrase phrase = app.getSearchUICore().getCore().getPhrase();
        if (f.isResultEmpty() && isSearchByWiki(phrase)) {
            addEmptyWikiBanner(f, phrase);
        }
    }
}*/

/*private void addEmptyWikiBanner(final QuickSearchDialogFragment fragment, SearchPhrase phrase) {
    QuickSearchBannerListItem banner = new QuickSearchBannerListItem(app);
    banner.addButton(QuickSearchListAdapter.getIncreaseSearchButtonTitle(app, phrase),
            null, QuickSearchBannerListItem.INVALID_ID, new View.OnClickListener() {
        @Override
        public void onClick(View v) {
            fragment.increaseSearchRadius();
        }
    });
    if (hasMapsToDownload()) {
        banner.addButton(app.getString(R.string.search_download_wikipedia_maps),
                null, R.drawable.ic_world_globe_dark, new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showDownloadWikiMapsScreen();
            }
        });
    }
    fragment.addSearchListItem(banner);
}*/

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

/*@Override
protected List<ImageCard> getContextMenuImageCards(@NonNull Map<String, String> params, @Nullable Map<String, String> additionalParams, @Nullable GetImageCardsListener listener) {
    List<ImageCard> imageCards = new ArrayList<>();
    if (mapActivity != null) {
        if (additionalParams != null) {
            String wikidataId = additionalParams.get(Amenity.WIKIDATA);
            if (wikidataId != null) {
                additionalParams.remove(Amenity.WIKIDATA);
                WikiImageHelper.addWikidataImageCards(mapActivity, wikidataId, imageCards);
            }
            String wikimediaContent = additionalParams.get(Amenity.WIKIMEDIA_COMMONS);
            if (wikimediaContent != null) {
                additionalParams.remove(Amenity.WIKIMEDIA_COMMONS);
                WikiImageHelper.addWikimediaImageCards(mapActivity, wikimediaContent, imageCards);
            }
            params.putAll(additionalParams);
        }
    }
    return imageCards;
}*/

@end