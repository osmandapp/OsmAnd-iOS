//
//  OAOsmNotesSettingsItem.m
//  OsmAnd
//
//  Created by nnngrach on 01.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAOsmNotesSettingsItem.h"
#import "OAOsmEditsSettingsItem.h"
#import "Localization.h"
#import "OAOsmEditingPlugin.h"
#import "OAOsmBugsDBHelper.h"
#import "OAOsmNotePoint.h"
#import "OAEntity.h"
#import "OsmAndApp.h"
#import "OAObservable.h"

static const NSInteger APPROXIMATE_OSM_NOTE_SIZE_BYTES = 250;

@interface OAOsmNotesSettingsItem()

@property (nonatomic) NSMutableArray<OAOsmNotePoint *> *items;
@property (nonatomic) NSMutableArray<OAOsmNotePoint *> *appliedItems;
@property (nonatomic) NSMutableArray<OAOsmNotePoint *> *duplicateItems;
@property (nonatomic) NSMutableArray<OAOsmNotePoint *> *existingItems;

@end

@implementation OAOsmNotesSettingsItem

@dynamic items, appliedItems, duplicateItems, existingItems;

- (void)initialization
{
    [super initialization];
    self.existingItems = [NSMutableArray arrayWithArray:[[OAOsmBugsDBHelper sharedDatabase] getOsmBugsPoints]];
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeOsmNotes;
}

- (long)localModifiedTime
{
    return [OAOsmBugsDBHelper sharedDatabase].getLastModifiedTime;
}

- (void)setLocalModifiedTime:(long)localModifiedTime
{
    [[OAOsmBugsDBHelper sharedDatabase] setLastModifiedTime:localModifiedTime];
}

- (void) apply
{
    NSArray<OAOsmNotePoint *>*newItems = [self getNewItems];
    if (![newItems isEmpty] || ![[self duplicateItems] isEmpty])
    {
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];
        OAOsmBugsDBHelper *db = [OAOsmBugsDBHelper sharedDatabase];
        for (OAOsmNotePoint *duplicate in [self duplicateItems])
        {
            NSInteger ind = [self.existingItems indexOfObject:duplicate];
            if (ind != NSNotFound && ind < self.existingItems.count)
            {
                OAOsmNotePoint *original = self.existingItems[ind];
                [db deleteAllBugModifications:original];
            }
            [db addOsmbugs:duplicate];
        }
        for (OAOsmNotePoint *point in self.appliedItems)
        {
            [db addOsmbugs:point];
        }
        [OsmAndApp.instance.osmEditsChangeObservable notifyEvent];
    }
}

- (OAOsmNotePoint *) renameItem:(OAOsmNotePoint *)item
{
    return item;
}

- (BOOL) isDuplicate:(OAOsmNotePoint *)item
 {
     return [self.existingItems containsObject:item];
 }

- (void)deleteItem:(OAOsmNotePoint *)item
{
    // android method is empty
    // [[OAOsmBugsDBHelper sharedDatabase] deleteAllBugModifications:item];
}

- (NSString *) name
{
    return @"osm_notes";
}

- (NSString *) getPublicName
{
    return OALocalizedString(@"osm_notes");
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (BOOL)shouldShowDuplicates
{
    return NO;
}

- (long)getEstimatedItemSize:(id)item
{
    return APPROXIMATE_OSM_NOTE_SIZE_BYTES;
}

- (void) readItemsFromJson:(id)json error:(NSError * _Nullable *)error
{
    NSArray* itemsJson = [json mutableArrayValueForKey:@"items"];
    if (itemsJson.count == 0)
        return;
    
    int idOffset = 0;
    long long minId = OAOsmBugsDBHelper.sharedDatabase.getMinID - 1;
    for (id object in itemsJson)
    {
        NSString *text = object[kTEXT_KEY];
        double lat = [object[kLAT_KEY] doubleValue];
        double lon = [object[kLON_KEY] doubleValue];
        NSString *author = object[kAUTHOR_KEY];
        author = author != nil ? author : @"";
        NSString *action = object[kACTION_KEY];
        
        // in android here can be created OamNode or OsmWay. But in ios we don't have OsmWay class at all.
        /*
        if (entityJson.get(TYPE_KEY).equals(Entity.EntityType.NODE.name())) {
            entity = new Node(lat, lon, id);
        } else {
            entity = new Way(id);
            entity.setLatitude(lat);
            entity.setLongitude(lon);
        }
         */
        
        OAOsmNotePoint *point = [[OAOsmNotePoint alloc] init];
        [point setId:MIN(-2, minId - idOffset)];
        [point setText:text];
        [point setLatitude:lat];
        [point setLongitude:lon];
        [point setAuthor:author];
        [point setAction:[OAOsmPoint getActionByName:action]];
        [self.items addObject:point];
        idOffset++;
    }
}

- (OASettingsItemReader *) getReader
 {
     return [self getJsonReader];
 }

  - (OASettingsItemWriter *) getWriter
 {
     return [self getJsonWriter];
 }

- (void)writeItemsToJson:(id)json
{
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (self.items.count > 0)
    {
        for (OAOsmNotePoint *point in self.items)
        {
            NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
            jsonObject[kID_KEY] = @([point getId]);
            jsonObject[kNAME_KEY] = [point getName];
            jsonObject[kLAT_KEY] = @([point getLatitude]);
            jsonObject[kLON_KEY] = @([point getLongitude]);
            
            jsonObject[kTYPE_KEY] = [OAEntity stringType:NODE];
            //jsonEntity.put(TYPE_KEY, Entity.EntityType.valueOf(point.getEntity()));
            
            //JSONObject jsonTags = new JSONObject(point.getEntity().getTags());
            //jsonEntity.put(TAGS_KEY, jsonTags);
            //jsonPoint.put(COMMENT_KEY, point.getComment());
            
            jsonObject[kACTION_KEY] = [OAOsmPoint getStringAction][@([point getAction])];
            
            //jsonPoint.put(ENTITY_KEY, jsonEntity);
            
            //android don't have these wtrings
            jsonObject[kTEXT_KEY] = [point getText];
            jsonObject[kAUTHOR_KEY] = [point getAuthor];
            
            [jsonArray addObject:jsonObject];
        }
        json[@"items"] = jsonArray;
    }
}

@end
