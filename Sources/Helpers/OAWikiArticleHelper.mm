//
//  OAWikiArticleHelper.m
//  OsmAnd
//
//  Created by Paul on 03.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAWikiArticleHelper.h"
#import "OAWikiArticleHelper+cpp.h"
#import "OAWorldRegion.h"
#import "OsmAndApp.h"
#import "OAManageResourcesViewController.h"
#import "OAPOIHelper.h"
#import "OAPOI.h"
#import "OAWikiWebViewController.h"
#import "OARootViewController.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAWikiLanguagesWebViewContoller.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/ResourcesManager.h>

#define kPOpened @"<p>"
#define kPClosed @"</p>"
#define kPartialContentPhrases 3

@implementation OAWikiArticleSearchTask
{
    NSArray<CLLocation *> *_articleLocations;
    NSString *_regionName;
    NSString *_url;
    NSString *_lang;
    NSString *_name;
    UIView *_sourceView;
    BOOL _isCanceled;
    OAWikiArticleSearchTaskBlockType _onStart;
    OAWikiArticleSearchTaskBlockType _onComplete;
}

- (instancetype) initWithLocations:(NSArray<CLLocation *> *)locations url:(NSString *)url onStart:(void (^)())onStart sourceView:(UIView *)sourceView onComplete:(void (^)())onComplete
{
    self = [super init];
    if (self)
    {
        _articleLocations = locations;
        _url = url;
        _onStart = onStart;
        _onComplete = onComplete;
        _isCanceled = NO;
        _sourceView = sourceView;
    }
    return self;
}

- (void) execute
{
    [self onPreExecute];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<OAPOI *> *items = [self doInBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onPostExecute:items];
        });
    });
}

- (void) onPreExecute
{
    _lang = [OAWikiArticleHelper getLang:_url];
    _name = [OAWikiArticleHelper getArticleNameFromUrl:_url lang:_lang];
    if (_onStart)
        _onStart();
}

- (NSArray<OAPOI *> *) doInBackground
{
    NSMutableArray<OAPOI *> *results = [NSMutableArray array];
    if (!_isCanceled)
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        NSDictionary<CLLocation *, NSArray<OAWorldRegion *> *> *regionsByLatLon = [self collectUniqueRegions:_articleLocations];
        OARepositoryResourceItem __block *foundRepository;
        [regionsByLatLon enumerateKeysAndObjectsUsingBlock:^(CLLocation * _Nonnull location, NSArray<OAWorldRegion *> * _Nonnull regions, BOOL * _Nonnull stop) {
            for (OAWorldRegion *region in regions)
            {
                OAWorldRegion *worldRegion = [OAWikiArticleHelper findWikiRegion:region];
                OARepositoryResourceItem *repository = [OAWikiArticleHelper findResourceItem:worldRegion];

                if (repository)
                {
                    if (app.resourcesManager->isResourceInstalled(repository.resourceId))
                    {
                        OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(location.coordinate.latitude, location.coordinate.longitude));
                        NSArray<OAPOI *> *wikiPoints = [OAPOIHelper findPOIsByTagName:nil name:_name location:locI categoryName:OSM_WIKI_CATEGORY poiTypeName:nil bboxTopLeft:worldRegion.bboxTopLeft bboxBottomRight:worldRegion.bboxBottomRight];
                        
                        [results addObjectsFromArray:wikiPoints];
                        if (results.count > 0)
                            break;
                    }
                    else
                    {
                        foundRepository = repository;
                    }
                }
                if (results.count > 0)
                    break;
            }
        }];
        if (foundRepository && results.count == 0)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [OAWikiArticleHelper showHowToOpenWikiAlert:foundRepository url:_url sourceView:_sourceView];
            });
        }
    }
    return results;
}

- (void) onPostExecute:(NSArray<OAPOI *> *)found
{
    if (_onComplete)
        _onComplete();
    
    if (found && found.count > 0)
    {
        OAWikiWebViewController *wikiController = [[OAWikiWebViewController alloc] initWithPoi:found[0] locale:_lang];
        [OARootViewController.instance.mapPanel.navigationController pushViewController:wikiController animated:YES];
    }
    else
    {
        [OAWikiArticleHelper warnAboutExternalLoad:_url sourceView:_sourceView];
    }
}

- (void) cancel
{
    _isCanceled = YES;
    if (_onComplete)
        _onComplete();
}

- (BOOL)isRegionAdded:(OAWorldRegion *)region
      regionsByLatLon:(NSDictionary<CLLocation *, NSArray<OAWorldRegion *> *> *)regionsByLatLon
{
    for (NSArray<OAWorldRegion *> *regionsInMap in regionsByLatLon.allValues)
    {
        if ([regionsInMap containsObject:region])
            return YES;
    }
    return NO;
}

- (BOOL)isUniqueLocation:(CLLocation *)location regionsByLatLon:(NSDictionary<CLLocation *, NSArray<OAWorldRegion *> *> *)regionsByLatLon
{
    for (NSArray<OAWorldRegion *> *regions in regionsByLatLon.allValues)
    {
        BOOL containsInAll = YES;
        for (OAWorldRegion *region in regions)
        {
            if (![region containsPoint:location])
            {
                containsInAll = NO;
                break;
            }
        }
        if (containsInAll)
            return NO;
    }
    return YES;
}

- (NSDictionary<CLLocation *, NSArray<OAWorldRegion *> *> *)collectUniqueRegions:(NSArray<CLLocation *> *)locations
{
    OsmAndAppInstance app = [OsmAndApp instance];
    NSMutableDictionary<CLLocation *, NSArray<OAWorldRegion *> *> *regionsByLocation = [NSMutableDictionary dictionary];
    for (CLLocation *location in locations)
    {
        if (![self isUniqueLocation:location regionsByLatLon:regionsByLocation])
            continue;
        @try {
            NSArray<OAWorldRegion *> *regionsAtLocation = [app.worldRegion getWorldRegionsAt:location.coordinate.latitude longitude:location.coordinate.longitude];
            NSMutableArray<OAWorldRegion *> *uniqueRegions = [NSMutableArray array];
            for (OAWorldRegion *region in regionsAtLocation)
            {
                if (![self isRegionAdded:region regionsByLatLon:regionsByLocation])
                    [uniqueRegions addObject:region];
            }
            if (uniqueRegions.count > 0)
                regionsByLocation[location] = uniqueRegions;
        }
        @catch (NSException *exception)
        {
            NSLog(@"%@", [exception reason]);
        }
    }
    return regionsByLocation;
}
@end


@implementation OAWikiArticleHelper

+ (OAWorldRegion *) findWikiRegion:(OAWorldRegion *)mapRegion
{
    if (mapRegion)
    {
        if ([mapRegion.resourceTypes containsObject:@((int)OsmAnd::ResourcesManager::ResourceType::WikiMapRegion)])
            return mapRegion;
        else if (mapRegion.superregion)
            return [self findWikiRegion:mapRegion.superregion];
    }
    return nil;
}

+ (OARepositoryResourceItem *) findResourceItem:(OAWorldRegion *)worldRegion
{
    if (worldRegion)
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        NSArray<NSString *> *ids = [OAManageResourcesViewController getResourcesInRepositoryIdsByRegion:worldRegion];
        if (ids.count > 0)
        {
            for (NSString *resourceId in ids)
            {
                const auto resource = app.resourcesManager->getResourceInRepository(QString::fromNSString(resourceId));
                if (resource->type == OsmAnd::ResourcesManager::ResourceType::WikiMapRegion)
                {
                    OARepositoryResourceItem* item = [[OARepositoryResourceItem alloc] init];
                    item.resourceId = resource->id;
                    item.resourceType = resource->type;
                    item.title = [OAResourcesUIHelper titleOfResource:resource
                                                             inRegion:worldRegion
                                                       withRegionName:YES
                                                     withResourceType:NO];
                    item.resource = resource;
                    item.downloadTask = [[app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]] firstObject];
                    item.size = resource->size;
                    item.sizePkg = resource->packageSize;
                    item.worldRegion = worldRegion;
                    item.date = [NSDate dateWithTimeIntervalSince1970:(resource->timestamp / 1000)];
                    return item;
                }
            }
        }
    }
    return nil;
}

+ (void) showWikiArticle:(CLLocation *)location url:(NSString *)url sourceView:(UIView *)sourceView
{
    [self showWikiArticle:@[location] url:url onStart:nil sourceView:sourceView onComplete:nil];
}

+ (void) showWikiArticle:(NSArray<CLLocation *> *)locations url:(NSString *)url onStart:(void (^)())onStart sourceView:(UIView *)sourceView onComplete:(void (^)())onComplete
{
    OAWikiArticleSearchTask *task = [[OAWikiArticleSearchTask alloc] initWithLocations:locations url:url onStart:onStart sourceView:sourceView onComplete:onComplete];
    [task execute];
}

+ (void) showHowToOpenWikiAlert:(OARepositoryResourceItem *)item url:(NSString *)url sourceView:(UIView *)sourceView
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"how_to_open_wiki_title")
                                                                   message:OALocalizedString(url)
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *downloadAction = [UIAlertAction actionWithTitle:OALocalizedString(@"download_wikipedia_data")
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
        OsmAndAppInstance app = [OsmAndApp instance];
        if ([app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:item.resourceId.toNSString()]].count == 0)
        {
            NSString *resourceName = [OAResourcesUIHelper titleOfResource:item.resource
                                                                 inRegion:item.worldRegion
                                                           withRegionName:YES
                                                         withResourceType:YES];
            [OAResourcesUIHelper startBackgroundDownloadOf:item.resource resourceName:resourceName];
        }
        else
        {
            OASuperViewController* resourcesViewController = [[UIStoryboard storyboardWithName:@"Resources" bundle:nil] instantiateInitialViewController];
            [[OARootViewController instance].navigationController pushViewController:resourcesViewController animated:YES];
        }
    }];
    UIAlertAction *openOnlineAction = [UIAlertAction actionWithTitle:OALocalizedString(@"open_in_browser_wiki")
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
        [OAUtilities callUrl:url];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil
    ];
    
    [alert addAction:downloadAction];
    [alert addAction:openOnlineAction];
    [alert addAction:cancelAction];
    alert.preferredAction = cancelAction;
    
    UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
    popPresenter.sourceView = sourceView;
    popPresenter.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [[OARootViewController instance] presentViewController:alert animated:YES completion:nil];
}

+ (void) warnAboutExternalLoad:(NSString *)url sourceView:(UIView *)sourceView
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:url message:OALocalizedString(@"online_webpage_warning") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [OAUtilities callUrl:url];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];

    UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
    popPresenter.sourceView = sourceView;
    popPresenter.permittedArrowDirections = UIPopoverArrowDirectionAny;

    [[OARootViewController instance] presentViewController:alert animated:YES completion:nil];
}

+ (NSString *) getFirstParagraph:(NSString *)descriptionHtml
{
   if (descriptionHtml)
   {
       NSString *firstParagraph = [self.class getPartialContent:descriptionHtml];
       if (firstParagraph && firstParagraph.length > 0)
           return firstParagraph;
   }
   return descriptionHtml;
}

+ (NSString *) getPartialContent:(NSString *)source
{
    if (!source || source.length == 0)
        return nil;
    
    NSString *content = [source regexReplacePattern:@"\\n" newString:@""];
    int firstParagraphStart = [content indexOf:kPOpened];
    int firstParagraphEnd = [content indexOf:kPClosed];
    firstParagraphEnd = firstParagraphEnd < firstParagraphStart ? [content indexOf:kPClosed start:firstParagraphStart] : firstParagraphEnd;
    NSString *firstParagraphHtml = nil;
    if (firstParagraphStart != -1 && firstParagraphEnd != -1 && firstParagraphEnd >= firstParagraphStart)
    {
        firstParagraphHtml = [content substringWithRange:NSMakeRange(firstParagraphStart, firstParagraphEnd - firstParagraphStart + kPClosed.length)];
        while (([[firstParagraphHtml substringWithRange:NSMakeRange(kPOpened.length, firstParagraphHtml.length - kPOpened.length - kPClosed.length)] trim].length == 0
               && (firstParagraphEnd + kPClosed.length < content.length))
               || [[firstParagraphHtml regexReplacePattern:@"(<a.+?/a>)|(<div.+?/div>)" newString:@""] trim].length == 0)
        {
            firstParagraphStart = [content indexOf:kPOpened start:firstParagraphEnd];
            firstParagraphEnd = firstParagraphStart == -1 ? -1 : [content indexOf:kPClosed start:firstParagraphStart];
            if (firstParagraphStart != -1 && firstParagraphEnd != -1)
                firstParagraphHtml = [content substringWithRange:NSMakeRange(firstParagraphStart, firstParagraphEnd - firstParagraphStart + kPClosed.length)];
            else
                break;
        }
    }
    
    if (!firstParagraphHtml || firstParagraphHtml.length == 0)
        firstParagraphHtml = source;
    if (!firstParagraphHtml || firstParagraphHtml.length == 0)
        return nil;
    
    NSString *firstParagraphText = [[self fromHtml:[firstParagraphHtml regexReplacePattern:@"(<(/)(a|img)>)|(<(a|img).+?>)|(<div.+?/div>)" newString:@""]] trim];
    
    NSArray<NSString *> *phrases = [firstParagraphText regexSplitInStringByPattern:@"\\. "];
    NSMutableString *res = [NSMutableString string];
    NSInteger limit = MIN(phrases.count, kPartialContentPhrases);
    for (NSInteger i = 0; i < limit; i++)
    {
        [res appendString:phrases[i]];
        if (i < limit - 1)
            [res appendString:@". "];
    }
    return [NSString stringWithString:res];
}

+ (NSString *) fromHtml:(NSString *)htmlText
{
    //method to replace Java Html.fromHtml()
    NSString *result;
    NSAttributedString *attrString = [OAUtilities attributedStringFromHtmlString:htmlText fontSize:17 textColor:nil];
    if (attrString)
        result = attrString.string;
    return result;
}

+ (NSString *) normalizeFileUrl:(NSString *)url
{
    if ([url hasPrefix:kPagePrefixFile])
        return [url stringByReplacingOccurrencesOfString:kPagePrefixFile withString:kPagePrefixHttps];
    else
        return url;
}

+ (NSString *) getLang:(NSString *)url
{
    if ([url hasPrefix:kPagePrefixHttp])
    {
        int index = [url indexOf:@"."];
        return [url substringWithRange:NSMakeRange(kPagePrefixHttp.length, index - kPagePrefixHttp.length)];
    }
    else if ([url hasPrefix:kPagePrefixHttps])
    {
        int index = [url indexOf:@"."];
        return [url substringWithRange:NSMakeRange(kPagePrefixHttps.length, index - kPagePrefixHttps.length)];
    }
    return @"";
}

+ (NSString *) getArticleNameFromUrl:(NSString *)url lang:(NSString *)lang
{
    NSString *domain = [url containsString:kWikivoyageDomain] ? kWikivoyageDomain : [url containsString:kWikiDomain] ? kWikiDomain : kWikiDomainCom;
    NSString *articleName = @"";
    
    if ([url hasPrefix:kPagePrefixHttp])
        articleName = [[url stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@%@%@", kPagePrefixHttp, lang, domain] withString:@""] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    else if ([url hasPrefix:kPagePrefixHttps])
        articleName = [[url stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@%@%@", kPagePrefixHttps, lang, domain] withString:@""] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    
    articleName = [articleName stringByRemovingPercentEncoding];
    return articleName;
}

+ (UIMenu *)createLanguagesMenu:(NSArray<NSString *> *)availableLocales selectedLocale:(NSString *)selectedLocale delegate:(id<OAWikiLanguagesWebDelegate>)delegate
{
    UIMenu *languageMenu;
    NSMutableArray<UIMenuElement *> *languageOptions = [NSMutableArray array];
    if (availableLocales.count > 1)
    {
        NSMutableSet<NSString *> *preferredLocales = [NSMutableSet set];
        NSArray<NSString *> *preferredLanguages = [NSLocale preferredLanguages];
        for (NSInteger i = 0; i < preferredLanguages.count; i ++)
        {
            NSString *preferredLocale = preferredLanguages[i];
            if ([preferredLocale containsString:@"-"])
                preferredLocale = [preferredLocale substringToIndex:[preferredLocale indexOf:@"-"]];
            if ([preferredLocale isEqualToString:@"en"])
                preferredLocale = @"";
            [preferredLocales addObject:preferredLocale];
        }

        NSMutableArray<NSString *> *possibleAvailableLocale = [NSMutableArray array];
        NSMutableArray<NSString *> *possiblePreferredLocale = [NSMutableArray array];
        __weak id<OAWikiLanguagesWebDelegate> weakDelegate = delegate;
        
        for (NSString *contentLocale in availableLocales)
        {
            NSString *processedLocale = [contentLocale isEqualToString:@"en"] ? @"" : contentLocale;
            if ([preferredLocales containsObject:processedLocale])
            {
                UIAction *languageAction = [UIAction actionWithTitle:[OAUtilities translatedLangName:processedLocale.length > 0 ? processedLocale : @"en"].capitalizedString
                                                       image:nil
                                                  identifier:nil
                                                     handler:^(__kindof UIAction * _Nonnull action) {
                    
                    
                    [weakDelegate onLocaleSelected:contentLocale];
                    
                }];
                if ([contentLocale isEqualToString:selectedLocale])
                    languageAction.state = UIMenuElementStateOn;
                [languageOptions addObject:languageAction];
                [possiblePreferredLocale addObject:processedLocale];
            }
            else
            {
                [possibleAvailableLocale addObject:contentLocale];
            }
        }
        if (possibleAvailableLocale.count > 0)
        {
            UIAction *availableLanguagesAction = [UIAction actionWithTitle:OALocalizedString(@"available_languages")
                                                                     image:[UIImage systemImageNamed:@"globe"]
                                                                identifier:nil
                                                                   handler:^(__kindof UIAction * _Nonnull action) {
                OAWikiLanguagesWebViewContoller *wikiLanguagesViewController =
                            [[OAWikiLanguagesWebViewContoller alloc] initWithSelectedLocale:selectedLocale
                                                                           availableLocales:possibleAvailableLocale
                                                                           preferredLocales:possiblePreferredLocale];

                wikiLanguagesViewController.delegate = weakDelegate;
                [weakDelegate showLocalesVC:wikiLanguagesViewController];
            }];
            if (![preferredLocales containsObject:selectedLocale])
                availableLanguagesAction.state = UIMenuElementStateOn;
            UIMenu *availableLanguagesMenu = [UIMenu menuWithTitle:@""
                                                             image:nil
                                                        identifier:nil
                                                           options:UIMenuOptionsDisplayInline
                                                          children:@[availableLanguagesAction]];
            [languageOptions addObject:availableLanguagesMenu];
        }
        languageMenu = [UIMenu menuWithChildren:languageOptions];
    }
    
    return languageMenu;
}

@end
