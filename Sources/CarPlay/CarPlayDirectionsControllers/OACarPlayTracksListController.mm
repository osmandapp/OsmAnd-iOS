//
//  OACarPlayTracksListController.m
//  OsmAnd Maps
//
//  Created by Paul on 20.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACarPlayTracksListController.h"
#import "OALoadGpxTask.h"
#import "OAGpxInfo.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapActions.h"
#import "OARoutingHelper.h"
#import "OAGPXDocumentPrimitives.h"
#import "OATargetPointsHelper.h"
#import "OASelectedGPXHelper.h"
#import "OAAppSettings.h"
#import "OAOsmAndFormatter.h"

#import <CarPlay/CarPlay.h>

@implementation OACarPlayTracksListController

- (NSString *)screenTitle
{
    return OALocalizedString(@"tracks");
}

- (NSArray<CPListSection *> *)generateSections
{
    return [self generateSingleItemSectionWithTitle:OALocalizedString(@"shared_string_loading")];
}

- (void) present
{
    [super present];
    [self populateListWithTracks];
}

- (void) populateListWithTracks
{
    OALoadGpxTask *task = [[OALoadGpxTask alloc] init];
    [task execute:^(NSDictionary<NSString *, NSArray<OAGpxInfo *> *>* gpxFolders) {
        [self updateList:gpxFolders];
    }];
}

- (void) updateList:(NSDictionary<NSString *, NSArray<OAGpxInfo *> *> *)gpxByFolder
{
    NSMutableArray<CPListSection *> *sections = [NSMutableArray new];
    if (gpxByFolder.count > 0)
    {
        [gpxByFolder enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<OAGpxInfo *> * _Nonnull obj, BOOL * _Nonnull stop) {
            NSMutableArray<CPListItem *> *items = [NSMutableArray new];
            for (OAGpxInfo *info in obj)
            {
                CPListItem *item = [[CPListItem alloc] initWithText:info.getName detailText:[self getTrackDescription:info.gpx] image:[UIImage imageNamed:@"ic_custom_trip"]];
                item.userInfo = info;
                [items addObject:item];
            }
            [sections addObject:[[CPListSection alloc] initWithItems:items header:key sectionIndexTitle:[key substringToIndex:1]]];
        }];
    }
    else
    {
        [self generateSingleItemSectionWithTitle:OALocalizedString(@"tracks_empty")];
    }
    [self updateSections:sections];
}

- (NSString *) getTrackDescription:(OAGPX *)gpx
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
        [res appendFormat:@"%@: %d", OALocalizedString(@"gpx_waypoints"), gpx.wptPoints];
    }
    return res;
}

// MARK: - CPListTemplateDelegate

- (void)listTemplate:(CPListTemplate *)listTemplate didSelectListItem:(CPListItem *)item completionHandler:(void (^)())completionHandler
{
    OAGpxInfo *info = item.userInfo;
    if (!info)
    {
        completionHandler();
        return;
    }
    const auto& activeGpx = OASelectedGPXHelper.instance.activeGpx;
    if (activeGpx.find(QString::fromNSString(info.gpx.gpxFilePath)) == activeGpx.end())
    {
        [OAAppSettings.sharedManager showGpx:@[info.gpx.gpxFilePath]];
    }
    [OARoutingHelper.sharedInstance setAppMode:OAApplicationMode.CAR];
    [OARootViewController.instance.mapPanel.mapActions setGPXRouteParams:info.gpx];
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:info.gpx.locationEnd.getLatitude longitude:info.gpx.locationEnd.getLongitude];
    [OATargetPointsHelper.sharedInstance navigateToPoint:loc updateRoute:YES intermediate:-1];
    [OARootViewController.instance.mapPanel.mapActions enterRoutePlanningModeGivenGpx:info.gpx from:nil fromName:nil useIntermediatePointsByDefault:NO showDialog:NO];
    
    [self.interfaceController popToRootTemplateAnimated:YES];
    completionHandler();
}

@end
