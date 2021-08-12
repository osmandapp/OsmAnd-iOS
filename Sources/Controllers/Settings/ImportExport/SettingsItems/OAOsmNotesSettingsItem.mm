//
//  OAOsmNotesSettingsItem.m
//  OsmAnd
//
//  Created by nnngrach on 01.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAOsmNotesSettingsItem.h"
#import "Localization.h"
#import "OAOsmEditingPlugin.h"
#import "OAOsmBugsDBHelper.h"
#import "OAOsmNotePoint.h"
#import "OsmAndApp.h"

#define kTEXT_KEY @"text"
#define kLAT_KEY @"lat"
#define kLON_KEY @"lon"
#define kAUTHOR_KEY @"author"
#define kACTION_KEY @"action"

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

- (void) apply
{
    NSArray<OAOsmNotePoint *>*newItems = [self getNewItems];
    if (newItems.count > 0 || [self duplicateItems].count > 0)
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

- (NSString *) name
{
    return @"osm_notes";
}

- (NSString *) publicName
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

- (NSDictionary *)getSettingsJson
{
    NSMutableDictionary *json = [NSMutableDictionary new];
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (self.items.count > 0)
    {
        for (OAOsmNotePoint *point in self.items)
        {
            NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
            jsonObject[kTEXT_KEY] = [point getText];
            jsonObject[kLAT_KEY] = @([point getLatitude]);
            jsonObject[kLON_KEY] = @([point getLongitude]);
            jsonObject[kAUTHOR_KEY] = [point getAuthor];
            jsonObject[kACTION_KEY] = [OAOsmPoint getStringAction][@([point getAction])];
            [jsonArray addObject:jsonObject];
        }
        json[@"items"] = jsonArray;
    }
    return json;
}

@end
