//
//  OAOsmEditsSettingsItem.m
//  OsmAnd
//
//  Created by nnngrach on 01.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAOsmEditsSettingsItem.h"
#import "Localization.h"
#import "OAOsmEditingPlugin.h"
#import "OAOsmEditsDBHelper.h"
#import "OAOsmNotePoint.h"
#import "OAEntity.h"
#import "OANode.h"
#import "OAObservable.h"
#import "OAWay.h"
#import "OAOpenStreetMapPoint.h"
#import "OsmAndApp.h"

static const NSInteger APPROXIMATE_OSM_EDIT_SIZE_BYTES = 500;

@interface OAOsmEditsSettingsItem()

@property (nonatomic) NSMutableArray<OAOpenStreetMapPoint *> *items;
@property (nonatomic) NSMutableArray<OAOpenStreetMapPoint *> *appliedItems;
@property (nonatomic) NSMutableArray<OAOpenStreetMapPoint *> *duplicateItems;
@property (nonatomic) NSMutableArray<OAOpenStreetMapPoint *> *existingItems;

@end

@implementation OAOsmEditsSettingsItem

@dynamic items, appliedItems, duplicateItems, existingItems;


- (void)initialization
{
    [super initialization];
    [self setExistingItems: [NSMutableArray arrayWithArray:[[OAOsmEditsDBHelper sharedDatabase] getOpenstreetmapPoints]]];
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeOsmEdits;
}

- (long)localModifiedTime
{
    return [OAOsmEditsDBHelper sharedDatabase].getLastModifiedTime;
}

- (void)setLocalModifiedTime:(long)localModifiedTime
{
    [[OAOsmEditsDBHelper sharedDatabase] setLastModifiedTime:localModifiedTime];
}

- (void) apply
{
    NSArray<OAOpenStreetMapPoint *>*newItems = [self getNewItems];
    if (newItems.count > 0 || [self duplicateItems].count > 0)
    {
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];
        OAOsmEditsDBHelper *db = [OAOsmEditsDBHelper sharedDatabase];
        for (OAOpenStreetMapPoint *duplicate in [self duplicateItems])
        {
            [db deletePOI:duplicate];
            [db addOpenstreetmap:duplicate];
        }
        for (OAOpenStreetMapPoint *point in self.appliedItems)
        {
            [db addOpenstreetmap:point];
        }
        [OsmAndApp.instance.osmEditsChangeObservable notifyEvent];
    }
}

- (OAOpenStreetMapPoint *) renameItem:(OAOpenStreetMapPoint *)item
{
    return item;
}

- (BOOL) isDuplicate:(OAOpenStreetMapPoint *)item
 {
     return [self.existingItems containsObject:item];
 }

- (void)deleteItem:(OAOpenStreetMapPoint *)item
{
    // android method is empty
    // [[OAOsmEditsDBHelper sharedDatabase] deletePOI:item];
}

- (BOOL)shouldShowDuplicates
{
    return NO;
}

- (NSString *) name
{
    return @"osm_edits";
}

- (NSString *)getPublicName
{
    return OALocalizedString(@"osm_edits_title");
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (long)getEstimatedItemSize:(id)item
{
    return APPROXIMATE_OSM_EDIT_SIZE_BYTES;
}

- (void) readItemsFromJson:(id)json error:(NSError * _Nullable *)error
{
    NSArray* itemsJson = [json mutableArrayValueForKey:@"items"];
    if (itemsJson.count == 0)
        return;
    
    for (id jsonPoint in itemsJson)
    {
        NSString *comment = jsonPoint[kCOMMENT_KEY];
        comment = comment.length > 0 ? comment : nil;
        NSDictionary *entityJson = jsonPoint[kENTITY_KEY];
        long long iD = [entityJson[kID_KEY] longLongValue];
        double lat = [entityJson[kLAT_KEY] doubleValue];
        double lon = [entityJson[kLON_KEY] doubleValue];
        NSDictionary *tagMap = entityJson[kTAGS_KEY];
        NSString *action = entityJson[kACTION_KEY];
        OAEntity *entity;
        if ([entityJson[kTYPE_KEY] isEqualToString: [OAEntity stringType:NODE]])
        {
            entity = [[OANode alloc] initWithId:iD latitude:lat longitude:lon];
        }
        else
        {
            entity = [[OAWay alloc] initWithId:iD latitude:lat longitude:lon];
        }
        [entity replaceTags:tagMap];
        OAOpenStreetMapPoint *point = [[OAOpenStreetMapPoint alloc] init];
        [point setComment:comment];
        [point setEntity:entity];
        [point setAction:[OAOsmPoint getActionByName:action]];
        [self.items addObject:point];
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
        for (OAOpenStreetMapPoint *point in self.items)
        {
            NSMutableDictionary *jsonPoint = [NSMutableDictionary dictionary];
            NSMutableDictionary *jsonEntity = [NSMutableDictionary dictionary];
            jsonEntity[kID_KEY] = @([point getId]);
            jsonEntity[kTEXT_KEY] = [point getTagsString];
            jsonEntity[kLAT_KEY] = @([point getLatitude]);
            jsonEntity[kLON_KEY] = @([point getLongitude]);
            jsonEntity[kTYPE_KEY] = [OAEntity stringTypeOf:[point getEntity]];
            NSDictionary *jsonTags = [NSDictionary dictionaryWithDictionary:[[point getEntity] getTags]];
            jsonEntity[kTAGS_KEY] = jsonTags;
            jsonPoint[kCOMMENT_KEY] = [point getComment];
            jsonEntity[kACTION_KEY] = [OAOsmPoint getStringAction][@([point getAction])];
            jsonPoint[kENTITY_KEY] = jsonEntity;
            [jsonArray addObject:jsonPoint];
        }
        json[@"items"] = jsonArray;
    }
}

@end
