//
//  OAWikiArticleHelper.m
//  OsmAnd
//
//  Created by Paul on 03.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAWikiArticleHelper.h"
#import "OAWorldRegion.h"
#import "OsmAndApp.h"
#import "OAManageResourcesViewController.h"
#import "OAWikiLinkBottomSheetViewController.h"
#import "OAPOIHelper.h"
#import "OAPOI.h"
#import "OAWikiWebViewController.h"
#import "OARootViewController.h"
#import "Localization.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/ResourcesManager.h>

#define kPOpened @"<p>"
#define kPClosed @"</p>"
#define kPartialContentPhrases 3

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

+ (void) showWikiArticle:(CLLocationCoordinate2D)location url:(NSString *)url
{
    OsmAndAppInstance app = [OsmAndApp instance];
    OAWorldRegion *worldRegion = [app.worldRegion findAtLat:location.latitude lon:location.longitude];
    worldRegion = [self findWikiRegion:worldRegion];
    NSString *articleName = [[url lastPathComponent] stringByRemovingPercentEncoding];
    OARepositoryResourceItem *item = [self findResourceItem:worldRegion];
    
    if (item && app.resourcesManager->isResourceInstalled(item.resourceId))
    {
        OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(location.latitude, location.longitude));
        NSArray<OAPOI *> *wiki = [OAPOIHelper findPOIsByTagName:nil name:nil location:locI categoryName:OSM_WIKI_CATEGORY poiTypeName:nil radius:250];
        OAPOI *foundPoint = nil;
        for (OAPOI *poi in wiki)
        {
            if ([poi.localizedNames.allValues containsObject:articleName])
            {
                foundPoint = poi;
                break;
            }
        }
        if (foundPoint)
        {
            OAWikiWebViewController *wikiController = [[OAWikiWebViewController alloc] initWithPoi:foundPoint];
            [OARootViewController.instance.mapPanel.navigationController pushViewController:wikiController animated:YES];
        }
        else
        {
            [self warnAboutExternalLoad:url];
        }
    }
    else
    {
        OAWikiLinkBottomSheetViewController *bottomSheet = [[OAWikiLinkBottomSheetViewController alloc] initWithUrl:url localItem:item];
        [bottomSheet show];
    }
}

+ (void) warnAboutExternalLoad:(NSString *)url
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:url message:OALocalizedString(@"online_webpage_warning") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [OAUtilities callUrl:url];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
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
    
    NSString *firstParagraphText = [[[firstParagraphHtml regexReplacePattern:@"(<(/)(a|img)>)|(<(a|img).+?>)|(<div.+?/div>)" newString:@""] stringByReplacingOccurrencesOfString:@"<br>" withString:@""] trim];
    firstParagraphText = [firstParagraphHtml regexReplacePattern:@"<[^>]*>" newString:@""];
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

@end
