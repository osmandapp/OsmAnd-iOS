//
//  OACarPlayTracksListController.m
//  OsmAnd Maps
//
//  Created by Paul on 20.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACarPlayTracksListController.h"
#import "OACarPlayTrackResultListController.h"
#import "OALoadGpxTask.h"
#import "OAGpxInfo.h"
#import "OAColors.h"
#import "Localization.h"
#import <CarPlay/CarPlay.h>

@implementation OACarPlayTracksListController
{
    OACarPlayTrackResultListController *_trackResultController;
}

- (NSString *)screenTitle
{
    return OALocalizedString(@"shared_string_gpx_tracks");
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
    if (gpxByFolder.count > 0)
    {
        NSMutableArray<CPListItem *> *listItems = [NSMutableArray new];
        NSMutableArray<OAGpxInfo *> *lastModifiedList = [NSMutableArray new];
        [gpxByFolder enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<OAGpxInfo *> * _Nonnull obj, BOOL * _Nonnull stop) {
            NSMutableArray<OAGpxInfo *> *gpxList = [NSMutableArray arrayWithArray:obj];
            [self sortGpxItems:gpxList];
            if (gpxList.count > CPListTemplate.maximumItemCount)
                [gpxList removeObjectsInRange:NSMakeRange(CPListTemplate.maximumItemCount, gpxList.count - CPListTemplate.maximumItemCount)];
            CPListItem *listItem = [[CPListItem alloc] initWithText:key.capitalizedString
                                                         detailText:@(gpxList.count).stringValue
                                                              image:[UIImage imageNamed:@"ic_custom_folder"]
                                                     accessoryImage:nil
                                                      accessoryType:CPListItemAccessoryTypeDisclosureIndicator];
            listItem.userInfo = gpxList;
            listItem.handler = ^(id <CPSelectableListItem> item, dispatch_block_t completionBlock) {
                [self onItemSelected:item completionHandler:completionBlock];
            };
            [listItems addObject:listItem];
            [lastModifiedList addObjectsFromArray:obj];
        }];
        [listItems sortUsingComparator:^NSComparisonResult(CPListItem *i1, CPListItem *i2) {
            return [i1.text compare:i2.text];
        }];
        NSInteger maximumItemCount = CPListTemplate.maximumItemCount;
        if (listItems.count > maximumItemCount - 1)
            [listItems removeObjectsInRange:NSMakeRange(maximumItemCount - 1, listItems.count - maximumItemCount - 1)];

        [self sortGpxItems:lastModifiedList];
        if (lastModifiedList.count > maximumItemCount)
            [lastModifiedList removeObjectsInRange:NSMakeRange(maximumItemCount, lastModifiedList.count - maximumItemCount)];
        CPListItem *lastModifiedItem = [[CPListItem alloc] initWithText:OALocalizedString(@"sort_last_modified")
                                                             detailText:@(lastModifiedList.count).stringValue
                                                                  image:[OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_custom_history"]
                                                                                                  color:UIColorFromRGB(color_primary_purple)]
                                                         accessoryImage:nil
                                                          accessoryType:CPListItemAccessoryTypeDisclosureIndicator];
        lastModifiedItem.userInfo = lastModifiedList;
        lastModifiedItem.handler = ^(id <CPSelectableListItem> item, dispatch_block_t completionBlock) {
            [self onItemSelected:item completionHandler:completionBlock];
        };
        [listItems insertObject:lastModifiedItem atIndex:0];

        [self updateSections:@[[[CPListSection alloc] initWithItems:listItems header:nil sectionIndexTitle:nil]]];
    }
    else
    {
        [self updateSections:[self generateSingleItemSectionWithTitle:OALocalizedString(@"tracks_empty")]];
    }
}

- (void)sortGpxItems:(NSMutableArray<OAGpxInfo *> *)gpxItems
{
    [gpxItems sortUsingComparator:^NSComparisonResult(OAGpxInfo *i1, OAGpxInfo *i2) {
        NSTimeInterval lastTime1 = [i1 getFileDate].timeIntervalSince1970;
        NSTimeInterval lastTime2 = [i2 getFileDate].timeIntervalSince1970;
        return (lastTime1 < lastTime2) ? NSOrderedDescending : ((lastTime1 == lastTime2) ? NSOrderedSame : NSOrderedAscending);
    }];
}

- (void)onItemSelected:(CPListItem * _Nonnull)item completionHandler:(dispatch_block_t)completionBlock
{
    NSString *folderName = item.text;
    NSArray<OAGpxInfo *> *gpxList = item.userInfo;
    if (!gpxList)
    {
        if (completionBlock)
            completionBlock();
        return;
    }
    _trackResultController = [[OACarPlayTrackResultListController alloc] initWithInterfaceController:self.interfaceController
                                                                                          folderName:folderName
                                                                                             gpxList:gpxList];
    [_trackResultController present];

    if (completionBlock)
        completionBlock();
}

@end
