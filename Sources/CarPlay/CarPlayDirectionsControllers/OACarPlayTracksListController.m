//
//  OACarPlayTracksListController.m
//  OsmAnd Maps
//
//  Created by Paul on 20.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACarPlayTracksListController.h"
#import "OACarPlayTrackResultListController.h"
#import "OAColors.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OsmAndSharedWrapper.h"

#import <CarPlay/CarPlay.h>

@interface OACarPlayTracksListController()<OASTrackFolderLoaderTaskLoadTracksListener>

@end

@implementation OACarPlayTracksListController
{
    OACarPlayTrackResultListController *_trackResultController;
    OASTrackFolderLoaderTask *_folderLoaderTask;
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
    if (_folderLoaderTask)
        [_folderLoaderTask cancel];

    OASKFile *file = [[OASKFile alloc] initWithFilePath:OsmAndApp.instance.gpxPath];
    OASTrackFolder *rootFolder = [[OASTrackFolder alloc] initWithDirFile:file parentFolder:nil];
    _folderLoaderTask = [[OASTrackFolderLoaderTask alloc] initWithFolder:rootFolder listener:self forceLoad:NO];
    OASKotlinArray<OASKotlinUnit *> *emptyArray = [OASKotlinArray<OASKotlinUnit *> arrayWithSize:0 init:^OASKotlinUnit *(OASInt *index) {
        return nil;
    }];
    [_folderLoaderTask executeParams:emptyArray];
}

- (void) updateList:(OASTrackFolder *)rootFolder
{
    if (!rootFolder.isEmpty)
    {
        NSMutableArray<CPListItem *> *listItems = [NSMutableArray new];
        NSMutableArray<OASTrackItem *> *lastModifiedList = [NSMutableArray new];
        NSArray<OASTrackFolder *> *trackFolders = [rootFolder.getFlattenedSubFolders arrayByAddingObject:rootFolder];
        for (OASTrackFolder *folder in trackFolders)
        {
            NSMutableArray<OASTrackItem *> *trackItems = [NSMutableArray arrayWithArray:folder.getTrackItems];
            [self sortGpxItems:trackItems];
            if (trackItems.count > CPListTemplate.maximumItemCount)
                [trackItems removeObjectsInRange:NSMakeRange(CPListTemplate.maximumItemCount, trackItems.count - CPListTemplate.maximumItemCount)];
            NSString *folderName = folder == rootFolder ? OALocalizedString(@"shared_string_gpx_tracks") : folder.getName;
            CPListItem *listItem = [[CPListItem alloc] initWithText:folderName
                                                         detailText:@(trackItems.count).stringValue
                                                              image:[UIImage imageNamed:@"ic_custom_folder"]
                                                     accessoryImage:nil
                                                      accessoryType:CPListItemAccessoryTypeDisclosureIndicator];
            listItem.userInfo = trackItems;
            listItem.handler = ^(id <CPSelectableListItem> item, dispatch_block_t completionBlock) {
                [self onItemSelected:item completionHandler:completionBlock];
            };
            [listItems addObject:listItem];
            [lastModifiedList addObjectsFromArray:trackItems];
        }
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

- (void)sortGpxItems:(NSMutableArray<OASTrackItem *> *)trackItems
{
    [trackItems sortUsingComparator:^NSComparisonResult(OASTrackItem *i1, OASTrackItem *i2) {
        int64_t lastTime1 = i1.lastModified;
        int64_t lastTime2 = i2.lastModified;
        return (lastTime1 < lastTime2) ? NSOrderedDescending : ((lastTime1 == lastTime2) ? NSOrderedSame : NSOrderedAscending);
    }];
}

- (void)onItemSelected:(CPListItem * _Nonnull)item completionHandler:(dispatch_block_t)completionBlock
{
    NSString *folderName = item.text;
    NSArray<OASTrackItem *> *trackItems = item.userInfo;
    if (!trackItems)
    {
        if (completionBlock)
            completionBlock();
        return;
    }
    _trackResultController = [[OACarPlayTrackResultListController alloc] initWithInterfaceController:self.interfaceController
                                                                                          folderName:folderName
                                                                                          trackItems:trackItems];
    [_trackResultController present];

    if (completionBlock)
        completionBlock();
}

#pragma mark - OASTrackFolderLoaderTaskLoadTracksListener

- (void)deferredLoadTracksFinishedFolder:(OASTrackFolder *)folder __attribute__((swift_name("deferredLoadTracksFinished(folder:)")))
{
}

- (void)loadTracksFinishedFolder:(OASTrackFolder *)folder __attribute__((swift_name("loadTracksFinished(folder:)")))
{
    [self updateList:folder];
}

- (void)loadTracksProgressItems:(OASKotlinArray<OASTrackItem *> *)items __attribute__((swift_name("loadTracksProgress(items:)")))
{
}

- (void)loadTracksStarted __attribute__((swift_name("loadTracksStarted()")))
{
}

- (void)tracksLoadedFolder:(OASTrackFolder *)folder __attribute__((swift_name("tracksLoaded(folder:)")))
{
}

@end
