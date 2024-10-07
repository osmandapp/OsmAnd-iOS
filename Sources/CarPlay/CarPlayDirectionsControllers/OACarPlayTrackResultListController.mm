//
//  OACarPlayTrackResultListController.mm
//  OsmAnd
//
//  Created by Skalii on 01.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OACarPlayTrackResultListController.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OARoutingHelper.h"
#import "OASelectedGPXHelper.h"
#import "OATargetPointsHelper.h"
#import "OAOsmAndFormatter.h"
#import "OAApplicationMode.h"
#import "OAMapActions.h"
#import "OAGpxInfo.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDatabase.h"
#import "Localization.h"
#import <CarPlay/CarPlay.h>
#import "OsmAnd_Maps-Swift.h"
#import "OsmAndSharedWrapper.h"


#include <OsmAndCore/GpxDocument.h>

@implementation OACarPlayTrackResultListController
{
    NSString *_folderName;
    NSArray<OAGpxInfo *> *_gpxList;
}

- (instancetype)initWithInterfaceController:(CPInterfaceController *)interfaceController
                                 folderName:(NSString *)folderName
                                    gpxList:(NSArray<OAGpxInfo *> *)gpxList
{
    self = [super initWithInterfaceController:interfaceController];
    if (self)
    {
        _folderName = folderName;
        _gpxList = gpxList;
    }
    return self;
}

- (NSString *)screenTitle
{
    return _folderName;
}

- (NSArray<CPListSection *> *)generateSections
{
    if (_gpxList.count > 0)
    {
        NSInteger maximumItemCount = CPListTemplate.maximumItemCount;
        NSMutableArray<CPListItem *> *listItems = [NSMutableArray new];
        for (OAGpxInfo *gpxInfo in _gpxList)
        {
            if (listItems.count >= maximumItemCount)
                break;

            CPListItem *listItem = [[CPListItem alloc] initWithText:[gpxInfo.gpx getNiceTitle]
                                                         detailText:[self getTrackDescription:gpxInfo.gpx]
                                                              image:[UIImage imageNamed:@"ic_custom_trip"]
                                                     accessoryImage:nil
                                                      accessoryType:CPListItemAccessoryTypeDisclosureIndicator];
            listItem.userInfo = gpxInfo;
            listItem.handler = ^(id <CPSelectableListItem> item, dispatch_block_t completionBlock) {
                [self onItemSelected:item completionHandler:completionBlock];
            };
            [listItems addObject:listItem];
        }
        return @[[[CPListSection alloc] initWithItems:listItems header:nil sectionIndexTitle:nil]];
    }
    else
    {
        return [self generateSingleItemSectionWithTitle:OALocalizedString(@"tracks_empty")];
    }
}

- (NSString *)getTrackDescription:(OASGpxDataItem *)gpx
{
    NSMutableString *res = [NSMutableString new];
    BOOL needsSeparator = NO;
    if (!isnan(gpx.totalDistance) && gpx.totalDistance > 0)
    {
        [res appendString:[OAOsmAndFormatter getFormattedDistance:gpx.totalDistance]];
        needsSeparator = YES;
    }
    if (!isnan(gpx.timeSpan) && gpx.timeSpan > 0)
    {
        if (needsSeparator)
            [res appendString:@" • "];
        [res appendString:[OAOsmAndFormatter getFormattedTimeInterval:gpx.timeSpan shortFormat:YES]];
        needsSeparator = YES;
    }
    if (gpx.wptPoints > 0)
    {
        if (needsSeparator)
            [res appendString:@" • "];
        [res appendFormat:@"%@: %d", OALocalizedString(@"shared_string_waypoints"), gpx.wptPoints];
    }
    return res;
}

- (void)onItemSelected:(CPListItem * _Nonnull)item completionHandler:(dispatch_block_t)completionBlock
{
    OAGpxInfo *info = item.userInfo;
    if (!info)
    {
        if (completionBlock)
            completionBlock();
        return;
    }
    NSDictionary<NSString *, OASGpxFile *> *activeGpx = [OASelectedGPXHelper instance].activeGpx;
    
    NSString *gpxFilePath = info.gpx.gpxFilePath;

    if (![activeGpx objectForKey:gpxFilePath]) {
        [OAAppSettings.sharedManager showGpx:@[gpxFilePath]];
    }
    
    [[OARoutingHelper sharedInstance] setAppMode:OAApplicationMode.CAR];
    [[OARootViewController instance].mapPanel.mapActions setGPXRouteParams:info.gpx];
    OASGpxTrackAnalysis *analysis = info.gpx.getAnalysis;
   
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:analysis.locationEnd.getLatitude
                                                 longitude:analysis.locationEnd.getLongitude];
    [[OATargetPointsHelper sharedInstance] navigateToPoint:loc updateRoute:YES intermediate:-1];
    [OARootViewController.instance.mapPanel.mapActions enterRoutePlanningModeGivenGpx:info.gpx
                                                                                 from:nil
                                                                             fromName:nil
                                                       useIntermediatePointsByDefault:NO
                                                                           showDialog:NO];

    [self.interfaceController popToRootTemplateAnimated:YES completion:nil];
    if (completionBlock)
        completionBlock();
}

@end
