//
//  OAMarkersSettingsItem.mm
//  OsmAnd
//
//  Created by Anna Bibyk on 28.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMarkersSettingsItem.h"
#import "OADestination.h"
#import "OADestinationsHelper.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "Localization.h"
#import "OsmAndSharedWrapper.h"


#define APPROXIMATE_MARKER_SIZE_BYTES 240

@interface OAMarkersSettingsItem()

@property (nonatomic) NSMutableArray *items;
@property (nonatomic) NSMutableArray *appliedItems;
@property (nonatomic) NSMutableArray *existingItems;

@end

@implementation OAMarkersSettingsItem
{
    OADestinationsHelper *_destinationsHelper;
}

@dynamic items, appliedItems, existingItems;

- (instancetype _Nullable) initWithJson:(NSDictionary *)json error:(NSError * _Nullable *)error
{
    NSError *initError;
    self = [super initWithJson:json error:&initError];
    if (initError)
    {
        if (error)
            *error = initError;
        return nil;
    }
    return self;
}

- (void) initialization
{
    [super initialization];

    _destinationsHelper = [OADestinationsHelper instance];
    self.existingItems = [NSMutableArray arrayWithArray:[_destinationsHelper sortedDestinationsWithoutParking]];
}
 
- (EOASettingsItemType) type
{
    return EOASettingsItemTypeActiveMarkers;
}

- (NSString *) name
{
    return @"markers";
}

- (NSString *) defaultFileExtension
{
    return @".gpx";
}

- (NSString *)getPublicName
{
    return OALocalizedString(@"map_markers");
}

- (long)localModifiedTime
{
    return [_destinationsHelper getMarkersLastModifiedTime];
}

- (void)setLocalModifiedTime:(long)localModifiedTime
{
    [_destinationsHelper setMarkersLastModifiedTime:localModifiedTime];
}

- (void) apply
{
   NSArray<OADestination *> *newItems = [self getNewItems];
    if (newItems.count > 0 || self.duplicateItems.count > 0)
    {
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];
        
        for (OADestination *duplicate in self.duplicateItems)
        {
            if ([self shouldReplace])
            {
                [_destinationsHelper removeDestination:duplicate];
            }
            [self.appliedItems addObject:[self shouldReplace] ? duplicate : [self renameItem:duplicate]];
        }
        
        for (OADestination *marker in self.appliedItems)
            [_destinationsHelper addDestination:marker];
    }
    
}

- (BOOL) applyFileName:(NSString *)fileName
{
    return self.fileName ? ((![fileName isEqualToString:@"history_markers.gpx"] && [fileName hasSuffix:self.fileName]) || [fileName hasPrefix:[self.fileName stringByAppendingString:@"/"]] || [fileName isEqualToString:self.fileName]) : NO;
}

- (BOOL) isDuplicate:(OADestination *)mapMarker
{
    for (OADestination *marker in self.existingItems)
    {
        if ([OAUtilities isCoordEqual:marker.latitude srcLon:marker.longitude destLat:mapMarker.latitude destLon:mapMarker.longitude] && [marker.desc isEqualToString:mapMarker.desc])
            return YES;
    }
    return NO;
}

- (void)deleteItem:(OADestination *)item
{
    [_destinationsHelper removeDestination:item];
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (OADestination *) renameItem:(OADestination *)item
{
    int number = 0;
    while (true)
    {
        number++;
        NSString *name = [NSString stringWithFormat:@"%@ %d", item.desc, number];
        OADestination *renamedMarker = [[OADestination alloc] initWithDesc:name latitude:item.latitude longitude:item.longitude];
        renamedMarker.color = item.color;
        renamedMarker.markerResourceName = item.markerResourceName;
        renamedMarker.creationDate = item.creationDate;
        if (![self isDuplicate:renamedMarker])
            return renamedMarker;
    }
    return nil;
}

- (long)getEstimatedItemSize:(id)item
{
    return APPROXIMATE_MARKER_SIZE_BYTES;
}

- (OASettingsItemReader *) getReader
{
    return [[OAMarkersSettingsItemReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *)getWriter
{
    OASGpxFile *gpxFile = [_destinationsHelper generateGpx:self.items completeBackup:YES];
    return [self getGpxWriter:gpxFile];
}

@end

#pragma mark - OAMarkersSettingsItemReader

@implementation OAMarkersSettingsItemReader

- (NSString *) getResourceName:(NSString *)color
{
    if ([color isEqualToString:[UIColorFromRGB(marker_pin_color_teal) toHexString]] || [color isEqualToString:@"#26A69A"])
        return @"ic_destination_pin_2";
    else if ([color isEqualToString:[UIColorFromRGB(marker_pin_color_green) toHexString]] || [color isEqualToString:@"#73B825"])
        return @"ic_destination_pin_3";
    else if ([color isEqualToString:[UIColorFromRGB(marker_pin_color_red) toHexString]] || [color isEqualToString:@"#E53935"])
        return @"ic_destination_pin_4";
    else if ([color isEqualToString:[UIColorFromRGB(marker_pin_color_light_green) toHexString]] || [color isEqualToString:@"#FDD835"])
        return @"ic_destination_pin_5";
    else if ([color isEqualToString:[UIColorFromRGB(marker_pin_color_purple) toHexString]])
        return @"ic_destination_pin_6";
    else if ([color isEqualToString:[UIColorFromRGB(marker_pin_color_blue) toHexString]])
        return @"ic_destination_pin_7";
    return @"ic_destination_pin_1";
}

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

    if (gpxFile)
    {
        for (OASWptPt *wpt in gpxFile.getPointsList)
        {
            OADestination *dest = [[OADestination alloc] initWithDesc:wpt.name latitude:wpt.getLatitude longitude:wpt.getLongitude];
            int color = [wpt getColor];
            dest.color = color != 0 ? UIColorFromRGBA(color) : UIColorFromRGB(marker_pin_color_blue);
            dest.markerResourceName = [self getResourceName:[dest.color.toHexString upperCase]];
            NSDictionary<NSString *, NSString *> *extensions = [wpt getExtensionsToRead];
            for (NSString *key in extensions.allKeys)
            {
                if ([key isEqualToString:@"creation_date"])
                {
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z"];
                    dest.creationDate = [dateFormatter dateFromString:extensions[key]];
                }
            }
            [self.item.items addObject:dest];
        }
    }
    self.item.read = YES;
    return YES;
}

@end
