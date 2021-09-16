//
//  OAMapDownloadController.m
//  OsmAnd
//
//  Created by Paul on 07.08.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAMapDownloadController.h"
#import "OADownloadedRegionsLayer.h"
#import "OAWorldRegion.h"
#import "OAResourcesUIHelper.h"
#import "OAManageResourcesViewController.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapLayers.h"
#import "OADownloadedRegionsLayer.h"
#import "Localization.h"

@interface OAMapDownloadController ()

@end

@implementation OAMapDownloadController
{
    OADownloadMapObject *_mapObject;
    
    NSArray<OAResourceItem *> *_otherResources;
}

- (instancetype)initWithMapObject:(OADownloadMapObject *)downloadMapObject
{
    self = [super init];
    if (self)
    {
        _mapObject = downloadMapObject;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self applyTopToolbarTargetTitle];
    [self populateOtherResources];
    [self setupOtherMapsButton];
}

- (void) applyTopToolbarTargetTitle
{
    if (self.delegate)
        self.titleView.text = [self.delegate getTargetTitle];
}

- (OAResourceItem *) resourceItemByResource:(const std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> &)resource region:(OAWorldRegion *)region
{
    OARepositoryResourceItem* item = [[OARepositoryResourceItem alloc] init];
    item.resourceId = resource->id;
    item.resourceType = resource->type;
    item.title = [OAResourcesUIHelper titleOfResource:resource
                                             inRegion:region
                                       withRegionName:YES
                                     withResourceType:NO];
    item.resource = resource;
    item.downloadTask = [[OsmAndApp.instance.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]] firstObject];
    item.size = resource->size;
    item.sizePkg = resource->packageSize;
    item.worldRegion = region;
    item.date = [NSDate dateWithTimeIntervalSince1970:(resource->timestamp / 1000)];
    return item;
}

- (void) populateOtherResources
{
    OsmAndAppInstance app = OsmAndApp.instance;
    NSMutableArray<OAResourceItem *> *res = [NSMutableArray array];
    NSArray<NSString *> *ids = [OAManageResourcesViewController getResourcesInRepositoryIdsByRegion:_mapObject.worldRegion];
    if (ids.count > 0)
    {
        for (NSString *resourceId in ids)
        {
            const auto resId = QString::fromNSString(resourceId);
            const auto& resource = app.resourcesManager->getResourceInRepository(resId);
            if (!app.resourcesManager->isResourceInstalled(resId) && resource->type != _mapObject.indexItem.resourceType)
            {
                OAResourceItem *item = [self resourceItemByResource:resource region:_mapObject.worldRegion];
                [res addObject:item];
            }
        }
    }
    _otherResources = res;
}

- (void) setupOtherMapsButton
{
    if (_otherResources.count > 0)
    {
        self.rightControlButton = [[OATargetMenuControlButton alloc] init];
        self.rightControlButton.title = OALocalizedString(@"region_others");
    }
}

- (NSString *) getTypeStr
{
    return [OAResourceType resourceTypeLocalized:_mapObject.indexItem.resourceType];
}

- (UIColor *) getAdditionalInfoColor
{
    return nil;
}

- (NSAttributedString *) getAdditionalInfoStr
{
    return nil;
}

- (UIImage *) getAdditionalInfoImage
{
    return nil;
}

- (BOOL)showNearestPoi
{
    return NO;
}

- (BOOL)showNearestWiki
{
    return NO;
}

- (BOOL) hasTopToolbar
{
    return YES;
}

- (BOOL) shouldShowToolbar
{
    return YES;
}

- (BOOL)hideButtons
{
    return YES;
}

- (BOOL)offerMapDownload
{
    return NO;
}

- (ETopToolbarType) topToolbarType
{
    return ETopToolbarTypeFloating;
}

- (id) getTargetObj
{
    return _mapObject;
}

- (void) buildRows:(NSMutableArray<OARowInfo *> *)rows
{
    OAWorldRegion *region = _mapObject.worldRegion;
    OAResourceItem *item = _mapObject.indexItem;
    NSString *resTypeLocalized = [OAResourceType resourceTypeLocalized:item.resourceType];
    NSString *iconInfo = @"ic_description.png";
    if (resTypeLocalized && resTypeLocalized.length > 0)
    {
        NSString *rowText = [NSString stringWithFormat:@"%@ - %@", resTypeLocalized, [NSByteCountFormatter stringFromByteCount:item.sizePkg countStyle:NSByteCountFormatterCountStyleFile]];
        [rows addObject:[[OARowInfo alloc] initWithKey:region.name icon:[OATargetInfoViewController getIcon:iconInfo] textPrefix:nil text:rowText textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO]];
    }
    if (region.wikiLink && region.wikiLink.length > 0)
    {
        NSArray<NSString *> *items = [region.wikiLink componentsSeparatedByString:@":"];
        NSString *url;
        if (items.count > 1)
            url = [NSString stringWithFormat:@"https://%@.wikipedia.org/wiki/%@", items[0], [items[1] stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
        else
            url = [NSString stringWithFormat:@"https://wikipedia.org/wiki/%@", [items[0] stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
        [rows addObject:[[OARowInfo alloc] initWithKey:region.name icon:[OATargetInfoViewController getIcon:iconInfo] textPrefix:nil text:url textColor:UIColorFromRGB(kHyperlinkColor) isText:NO needLinks:YES order:0 typeName:@"" isPhoneNumber:NO isUrl:YES]];
    }
    if (region.population && region.population.length > 0)
    {
        [rows addObject:[[OARowInfo alloc] initWithKey:region.name icon:[OATargetInfoViewController getIcon:iconInfo] textPrefix:nil text:[NSString stringWithFormat:OALocalizedString(@"population_num"), region.population] textColor:nil isText:YES needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:YES]];
    }
}

- (void)rightControlButtonPressed
{
    OADownloadedRegionsLayer *layer = OARootViewController.instance.mapPanel.mapViewController.mapLayers.downloadedRegionsLayer;
    NSMutableArray<OATargetPoint *> *targetPoints = [NSMutableArray array];
    for (OAResourceItem *item in _otherResources)
    {
        [targetPoints addObject:[layer getTargetPoint:[[OADownloadMapObject alloc] initWithWorldRegion:_mapObject.worldRegion indexItem:item]]];
    }
    [OARootViewController.instance.mapPanel showContextMenuWithPoints:targetPoints];
}

@end
