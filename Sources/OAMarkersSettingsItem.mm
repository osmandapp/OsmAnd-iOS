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
    std::shared_ptr<OsmAnd::MapMarkersCollection> _destinationsMarkersCollection;
    OAAppSettings *_settings;
    //private MapMarkersHelper markersHelper;
}

@dynamic items, appliedItems, existingItems;

- (instancetype) initWithMarkers:(NSArray *)items // type is needed
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

 /*
@Override
protected void init() {
    super.init();
    markersHelper = app.getMapMarkersHelper();
    existingItems = new ArrayList<>(markersHelper.getMapMarkersFromDefaultGroups(false));
}
*/

- (void) initialization
{
    [super initialization];

    _settings = [OAAppSettings sharedManager];
    
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

/*
public void apply() {
    List<MapMarker> newItems = getNewItems();
    if (!newItems.isEmpty() || !duplicateItems.isEmpty()) {
        appliedItems = new ArrayList<>(newItems);
        
        for (MapMarker duplicate : duplicateItems) {
            if (shouldReplace) {
                MapMarker existingMarker = markersHelper.getMapMarker(duplicate.point);
                markersHelper.removeMarker(existingMarker);
            }
            appliedItems.add(shouldReplace ? duplicate : renameItem(duplicate));
        }
        
        for (MapMarker marker : appliedItems) {
            markersHelper.addMarker(marker);
        }
    }
}
*/

- (void) apply
{

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

- (BOOL) isDuplicate:(OASettingsItem *)item // type is needed
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

- (OASettingsItem *) renameItem:(OASettingsItem *)item // type is needed
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

/*
public void readFromStream(@NonNull InputStream inputStream, String entryName) throws IllegalArgumentException {
    GPXFile gpxFile = GPXUtilities.loadGPXFile(inputStream);
    if (gpxFile.error != null) {
        warnings.add(app.getString(R.string.settings_item_read_error, String.valueOf(getType())));
        SettingsHelper.LOG.error("Failed read gpx file", gpxFile.error);
    } else {
        List<MapMarker> mapMarkers = markersHelper.readMarkersFromGpx(gpxFile, false);
        items.addAll(mapMarkers);
    }
}
 */

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    NSLog(@"Import markers");
    
    return YES;
}

@end
