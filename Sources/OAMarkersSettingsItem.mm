//
//  OAMarkersSettingsItem.mm
//  OsmAnd
//
//  Created by Anna Bibyk on 28.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMarkersSettingsItem.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OADestination.h"
#import "OADestinationsHelper.h"
#import "OAGPXDocument.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAUtilities.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>

@interface OAMarkersSettingsItem()

@property (nonatomic) NSMutableArray *items;
@property (nonatomic) NSMutableArray *appliedItems;
@property (nonatomic) NSMutableArray *existingItems;

@end

@implementation OAMarkersSettingsItem
{
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
    OADestinationsHelper *_destinationsHelper;
}

@dynamic items, appliedItems, existingItems;

- (instancetype) initWithMarkers:(NSArray<OADestination *> *)items
{
    return [super initWithItems:items];
}

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

    _app = OsmAndApp.instance;
    _settings = [OAAppSettings sharedManager];
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
        {
            [_destinationsHelper addDestination:marker];
        }
    }
    
}

/*
public boolean isDuplicate(@NonNull MapMarker mapMarker) {
    for (MapMarker marker : existingItems) {
        if (marker.equals(mapMarker)
            && Algorithms.objectEquals(marker.getOnlyName(), mapMarker.getOnlyName())) {
            return true;
        }
    }
    return false;
}
 */

- (BOOL) isDuplicate:(OADestination *)mapMarker
{
    return NO;
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

/*
 public MapMarker renameItem(@NonNull MapMarker item) {
         int number = 0;
         while (true) {
             number++;
             String name = item.getOnlyName() + " " + number;
             PointDescription description = new PointDescription(PointDescription.POINT_TYPE_LOCATION, name);
             MapMarker renamedMarker = new MapMarker(item.point, description, item.colorIndex, item.selected, item.index);
             if (!isDuplicate(renamedMarker)) {
                 renamedMarker.history = false;
                 renamedMarker.visitedDate = item.visitedDate;
                 renamedMarker.creationDate = item.creationDate;
                 renamedMarker.nextKey = MapMarkersDbHelper.TAIL_NEXT_VALUE;
                 return renamedMarker;
             }
         }
     }
 */

- (OADestination *) renameItem:(OADestination *)item
{
    int number = 0;
    while (true)
    {
        number++;
        
    }
    return nil;
}

/*
public MapMarkersGroup getMarkersGroup() {
    String name = app.getString(R.string.map_markers);
    String groupId = ExportSettingsType.ACTIVE_MARKERS.name();
    MapMarkersGroup markersGroup = new MapMarkersGroup(groupId, name, MapMarkersGroup.ANY_TYPE);
    markersGroup.setMarkers(items);
    return markersGroup;
}
 */

- () getMarkersGroup
{
    return nil;
}

- (OASettingsItemReader *) getReader
{
    return [[OAMarkersSettingsItemReader alloc] initWithItem:self];
}

@end

#pragma mark - OAMarkersSettingsItemReader

@implementation OAMarkersSettingsItemReader

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
   OAGPXDocument *gpxFile = [[OAGPXDocument alloc] initWithGpxFile:filePath];
    if (gpxFile)
    {
        for (OAGpxWpt *wpt in gpxFile.locationMarks)
        {
            OADestination *dest = [[OADestination alloc] initWithDesc:wpt.name latitude:wpt.getLatitude longitude:wpt.getLongitude];
            dest.color = [OAUtilities colorFromString:wpt.color];
            [self.item.items addObject:dest];
        }
    }
    return YES;
}

@end
