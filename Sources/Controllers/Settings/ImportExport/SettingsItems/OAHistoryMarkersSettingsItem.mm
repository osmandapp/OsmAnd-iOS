//
//  OAHistoryMarkersSettingsItem.mm
//  OsmAnd
//
// Created by Skalii on 26.05.2021.
// Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAHistoryMarkersSettingsItem.h"
#import "OAGPXMutableDocument.h"
#import "OAHistoryHelper.h"
#import "Localization.h"

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

- (NSString *)publicName
{
    return OALocalizedString(@"history_markers");
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

- (void) apply
{
    NSArray<OAHistoryItem *> *newItems = [self getNewItems];
    if (newItems.count > 0 || self.duplicateItems.count > 0)
    {
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];

        for (OAHistoryItem *duplicate in self.duplicateItems)
        {
            OAHistoryItem *original = [_historyMarkersHelper getPointByName:duplicate.name];
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

- (OAHistoryItem *)renameItem:(OAHistoryItem *)item
{
    return item;
}

- (OASettingsItemReader *) getReader
{
    return [[OAHistoryMarkersSettingsItemReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *)getWriter
{
    OAGPXDocument *gpxFile = [self generateGpx:self.items];
    return [self getGpxWriter:gpxFile];
}

- (OAGPXDocument *) generateGpx:(NSArray<OAHistoryItem *> *)historyItems
{
    OAGPXMutableDocument *doc = [[OAGPXMutableDocument alloc] init];
    [doc setVersion:[NSString stringWithFormat:@"%@ %@", @"OsmAnd", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"]]];
    for (OAHistoryItem *historyItem in historyItems)
    {
        OAGpxWpt *wpt = [[OAGpxWpt alloc] init];
        wpt.position = CLLocationCoordinate2DMake(historyItem.latitude, historyItem.longitude);
        wpt.name = historyItem.name;

        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = @"visited_date";

        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z"];
        e.value = [dateFormatter stringFromDate:historyItem.date];;

        wpt.extensions = @[e];
        [doc addWpt:wpt];
    }
    return doc;
}

@end

#pragma mark - OAHistoryMarkersSettingsItemReader

@implementation OAHistoryMarkersSettingsItemReader

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    OAGPXDocument *gpxFile = [[OAGPXDocument alloc] initWithGpxFile:filePath];
    if (gpxFile)
    {
        for (OAGpxWpt *wpt in gpxFile.locationMarks)
        {
            OAHistoryItem *historyItem = [[OAHistoryItem alloc] init];
            historyItem.name = wpt.name;
            historyItem.latitude = wpt.getLatitude;
            historyItem.longitude = wpt.getLongitude;
            historyItem.hType = OAHistoryTypeDirection;

            for (OAGpxExtension *e in wpt.extensions)
            {
                if ([e.name isEqualToString:@"visited_date"]) {
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z"];
                    historyItem.date = [dateFormatter dateFromString:e.value];
                }
            }
            [[OAHistoryHelper sharedInstance] addPoint:historyItem];

            [self.item.items addObject:historyItem];
        }
    }
    return YES;
}

@end
