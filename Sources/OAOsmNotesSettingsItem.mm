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

#define kID_KEY @"id"
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

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        OAOsmEditingPlugin *osmEditingPlugin = (OAOsmEditingPlugin *)[OAPlugin getPlugin:OAOsmEditingPlugin.class];
        if (osmEditingPlugin)
            [self setExistingItems: [NSMutableArray arrayWithArray:[[OAOsmBugsDBHelper sharedDatabase] getOsmbugsPoints]]];
    }
    return self;
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
        
        for (OAOsmNotePoint *duplicate in [self duplicateItems])
        {
            [self.appliedItems addObject: self.shouldReplace ? duplicate : [self renameItem:duplicate]];
        }
        OAOsmEditingPlugin *osmEditingPlugin = (OAOsmEditingPlugin *)[OAPlugin getPlugin:OAOsmEditingPlugin.class];
        if (osmEditingPlugin)
        {
            OAOsmBugsDBHelper *db = [OAOsmBugsDBHelper sharedDatabase];
            for (OAOsmNotePoint *point in self.appliedItems)
            {
                [db addOsmbugs:point];
            }
        }
    }
}

- (OAOsmNotePoint *) renameItem:(OAOsmNotePoint *)item
{
    return item;
}

- (NSString *) getName
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

- (void) readItemsFromJson:(id)json error:(NSError * _Nullable *)error
{
    NSArray* itemsJson = [json mutableArrayValueForKey:@"items"];
    if (itemsJson.count == 0)
        return;
    
    for (id object in itemsJson)
    {
        long long iD = [object[kID_KEY] longLongValue];
        NSString *text = object[kTEXT_KEY];
        double lat = [object[kLAT_KEY] doubleValue];
        double lon = [object[kLON_KEY] doubleValue];
        NSString *author = object[kAUTHOR_KEY];
        author = author.length > 0 ? author : nil;
        NSString *action = object[kACTION_KEY];
        OAOsmNotePoint *point = [[OAOsmNotePoint alloc] init];
        [point setId:iD];
        [point setText:text];
        [point setLatitude:lat];
        [point setLongitude:lon];
        [point setAuthor:author];
        [point setAction:[OAOsmPoint getActionByName:action]];
        [self.items addObject:point];
    }
}

- (void) writeItemsToJson:(id)json
{
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (self.items.count > 0)
    {
        for (OAOsmNotePoint *point in self.items)
        {
            NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
            jsonObject[kID_KEY] = [NSNumber numberWithLongLong: [point getId]];
            jsonObject[kTEXT_KEY] = [point getText];
            jsonObject[kLAT_KEY] = [NSString stringWithFormat:@"%0.5f", [point getLatitude]];
            jsonObject[kLON_KEY] = [NSString stringWithFormat:@"%0.5f", [point getLongitude]];
            jsonObject[kAUTHOR_KEY] = [point getAuthor];
            jsonObject[kACTION_KEY] = [OAOsmPoint getStringAction][[NSNumber numberWithInteger:[point getAction]]];
            [jsonArray addObject:jsonObject];
        }
        json[@"items"] = jsonArray;
    }
}

- (OASettingsItemReader *) getReader
 {
     return [[OASettingsItemReader alloc] initWithItem:self];
 }

  - (OASettingsItemWriter *) getWriter
 {
     return [[OASettingsItemJsonWriter alloc] initWithItem:self];
 }

@end
