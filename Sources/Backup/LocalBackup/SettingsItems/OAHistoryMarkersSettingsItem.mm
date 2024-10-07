//
//  OAHistoryMarkersSettingsItem.mm
//  OsmAnd
//
// Created by Skalii on 26.05.2021.
// Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAHistoryMarkersSettingsItem.h"
#import "OAHistoryHelper.h"
#import "Localization.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"

#define APPROXIMATE_HISTORY_MARKER_SIZE_BYTES 380

@interface OAHistoryMarkersSettingsItem()

@property (nonatomic) NSMutableArray *items;
@property (nonatomic) NSMutableArray *appliedItems;
@property (nonatomic) NSMutableArray *existingItems;

@end

@implementation OAHistoryMarkersSettingsItem
{
    OAHistoryHelper *_historyMarkersHelper;
}

@dynamic items, appliedItems, existingItems;

- (void)initialization
{
    [super initialization];
    _historyMarkersHelper = [OAHistoryHelper sharedInstance];
    self.existingItems = [NSMutableArray arrayWithArray:[_historyMarkersHelper getPointsHavingTypes:_historyMarkersHelper.destinationTypes limit:0]];
}

- (EOASettingsItemType)type
{
    return EOASettingsItemTypeHistoryMarkers;
}

- (NSString *)name
{
    return @"history_markers";
}

- (NSString *)getPublicName
{
    return OALocalizedString(@"markers_history");
}

- (NSString *)defaultFileExtension
{
    return @".gpx";
}

- (BOOL)shouldReadOnCollecting
{
    return YES;
}

- (BOOL)shouldShowDuplicates
{
    return NO;
}

- (long)localModifiedTime
{
    return _historyMarkersHelper.getMarkersHistoryLastModifiedTime;
}

- (void)setLocalModifiedTime:(long)lastModifiedTime
{
    [_historyMarkersHelper setMarkersHistoryLastModifiedTime:lastModifiedTime];
}

- (void) apply
{
    NSArray<OAHistoryItem *> *newItems = [self getNewItems];
    if (newItems.count > 0 || self.duplicateItems.count > 0)
    {
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];

        for (OAHistoryItem *duplicate in self.duplicateItems)
        {
            OAHistoryItem *original = [_historyMarkersHelper getPointByName:duplicate.name fromNavigation:NO];
            if (original)
            {
                [self.appliedItems removeObject:original];
                [self.appliedItems addObject:duplicate];
            }
        }

        for (OAHistoryItem *historyItem in self.appliedItems)
            [_historyMarkersHelper addPoint:historyItem];
    }
}

- (BOOL) isDuplicate:(OAHistoryItem *)item
{
    OAHistoryItem *historyEntry = item;
    NSString *name = historyEntry.name;
    for (OAHistoryItem *entry in self.existingItems)
    {
        if ([entry.name isEqualToString:name]) {
            return YES;
        }
    }
    return NO;
}

- (long)getEstimatedItemSize:(OAHistoryItem *)item
{
    return APPROXIMATE_HISTORY_MARKER_SIZE_BYTES;
}

- (OAHistoryItem *)renameItem:(OAHistoryItem *)item
{
    return item;
}

- (void)deleteItem:(OAHistoryItem *)item
{
    [_historyMarkersHelper removePoint:item];
}

- (OASettingsItemReader *) getReader
{
    return [[OAHistoryMarkersSettingsItemReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *)getWriter
{
    OASGpxFile *gpxFile = [self generateGpx:self.items];
    return [self getGpxWriter:gpxFile];
}

- (OASGpxFile *) generateGpx:(NSArray<OAHistoryItem *> *)historyItems
{
    
    // FIXME:
//    OAGPXMutableDocument *doc = [[OAGPXMutableDocument alloc] init];
//    for (OAHistoryItem *historyItem in historyItems)
//    {
//        OASWptPt *wpt = [[OASWptPt alloc] init];
//        wpt.position = CLLocationCoordinate2DMake(historyItem.latitude, historyItem.longitude);
//        wpt.name = historyItem.name;
//
//        OAGpxExtension *e = [[OAGpxExtension alloc] init];
//        e.name = VISITED_TIME_EXTENSION;
//
//        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z"];
//        e.value = [dateFormatter stringFromDate:historyItem.date];
//
//        wpt.extensions = @[e];
//        [doc addWpt:wpt];
//    }
//    return doc;
}

@end

#pragma mark - OAHistoryMarkersSettingsItemReader

@implementation OAHistoryMarkersSettingsItemReader

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    if (self.item.read)
    {
        if (error)
            *error = [NSError errorWithDomain:kSettingsItemErrorDomain code:kSettingsItemErrorCodeAlreadyRead userInfo:nil];

        return NO;
    }
    
    OASKFile *file = [[OASKFile alloc] initWithFilePath:filePath];
    OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileFile:file];

 //   OAGPXDocument *gpxFile = [[OAGPXDocument alloc] initWithGpxFile:filePath];
    if (gpxFile)
    {
        for (OASWptPt *wpt in gpxFile.getAllPoints)
        {
            OAHistoryItem *historyItem = [[OAHistoryItem alloc] init];
            historyItem.name = wpt.name;
            historyItem.latitude = wpt.getLatitude;
            historyItem.longitude = wpt.getLongitude;
            historyItem.hType = OAHistoryTypeDirection;
// FIXME:
//            for (OAGpxExtension *e in wpt.extensions)
//            {
//                if ([e.name isEqualToString:VISITED_TIME_EXTENSION]) {
//                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//                    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z"];
//                    historyItem.date = [dateFormatter dateFromString:e.value];
//                }
//            }
            [[OAHistoryHelper sharedInstance] addPoint:historyItem];

            [self.item.items addObject:historyItem];
        }
    }
    self.item.read = YES;
    return YES;
}

@end
