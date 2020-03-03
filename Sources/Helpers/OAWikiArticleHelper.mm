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

+ (RepositoryResourceItem *) findResourceItem:(OAWorldRegion *)worldRegion
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
                    RepositoryResourceItem* item = [[RepositoryResourceItem alloc] init];
                    item.resourceId = resource->id;
                    item.resourceType = resource->type;
                    item.title = [OAResourcesBaseViewController titleOfResource:resource
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
    RepositoryResourceItem *item = [self findResourceItem:worldRegion];
    
    if (item && app.resourcesManager->isResourceInstalled(item.resourceId))
    {
        OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(location.latitude, location.longitude));
        NSArray<OAPOI *> *wiki = [OAPOIHelper findPOIsByTagName:nil name:nil location:locI categoryName:@"osmwiki" poiTypeName:nil radius:250];
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
            OAWikiWebViewController *wikiController = [[OAWikiWebViewController alloc] initWithLocalizedContent:foundPoint.localizedContent localizedNames:foundPoint.localizedNames];
            [OARootViewController.instance.mapPanel.navigationController pushViewController:wikiController animated:YES];
        }
        else
        {
            [OAUtilities callUrl:url];
        }
    }
    else
    {
        OAWikiLinkBottomSheetViewController *bottomSheet = [[OAWikiLinkBottomSheetViewController alloc] initWithUrl:url localItem:item];
        [bottomSheet show];
    }
}


@end
