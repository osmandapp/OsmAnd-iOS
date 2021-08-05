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
        NSArray<NSString *> *ids = [OAManageResourcesViewController getResourcesInRepositoryIdsyRegion:worldRegion];
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


@end
