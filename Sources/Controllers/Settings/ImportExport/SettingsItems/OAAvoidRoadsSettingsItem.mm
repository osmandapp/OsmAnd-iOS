//
//  OAAvoidRoadsSettingsItem.mm
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAAvoidRoadsSettingsItem.h"
#import "OASettingsImporter.h"
#import "OASettingsExporter.h"
#import "OAAppSettings.h"
#import "OAAvoidSpecificRoads.h"
#import "OARoutingHelper.h"
#import "OASettingsItemReader.h"

@interface OAAvoidRoadsSettingsItem()

@property (nonatomic) NSMutableArray<OAAvoidRoadInfo *> *items;
@property (nonatomic) NSMutableArray<OAAvoidRoadInfo *> *appliedItems;
@property (nonatomic) NSMutableArray<OAAvoidRoadInfo *> *existingItems;

@end

@implementation OAAvoidRoadsSettingsItem
{
    OAAvoidSpecificRoads *_specificRoads;
    OAAppSettings *_settings;
}

@dynamic items, appliedItems, existingItems;

- (void) initialization
{
    [super initialization];
    
    _specificRoads = [OAAvoidSpecificRoads instance];
    _settings = [OAAppSettings sharedManager];
    self.existingItems = [[_specificRoads getImpassableRoads] mutableCopy];
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeAvoidRoads;
}

- (NSString *) name
{
    return @"avoid_roads";
}

- (BOOL) isDuplicate:(OAAvoidRoadInfo *)item
{
    for (OAAvoidRoadInfo *info in self.existingItems)
    {
        if (info.roadId == item.roadId)
            return YES;
    }
    return NO;
}

- (BOOL)shouldShowDuplicates
{
    return NO;
}

- (void) apply
{
    NSArray<OAAvoidRoadInfo *> *newItems = [self getNewItems];
    if (newItems.count > 0 || self.duplicateItems.count > 0)
    {
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];
        for (OAAvoidRoadInfo *duplicate in self.duplicateItems)
        {
            if ([_settings removeImpassableRoad:duplicate.location])
                [_settings addImpassableRoad:duplicate];
        }
        for (OAAvoidRoadInfo *roadInfo in self.appliedItems)
            [_settings addImpassableRoad:roadInfo];

        [_specificRoads loadImpassableRoads];
        [_specificRoads initRouteObjects:YES];
    }
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (OASettingsItemReader *) getReader
{
    return [self getJsonReader];
}

- (void) readItemsFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSArray* itemsJson = [json mutableArrayValueForKey:@"items"];
    if (itemsJson.count == 0)
        return;
    
    for (id object in itemsJson)
    {
        double latitude = [object[@"latitude"] doubleValue];
        double longitude = [object[@"longitude"] doubleValue];
        NSString *name = object[@"name"];
        NSString *appModeKey = object[@"appModeKey"];
        unsigned long long roadId = [object[@"roadId"] unsignedLongLongValue];
        OAAvoidRoadInfo *roadInfo = [[OAAvoidRoadInfo alloc] init];
        roadInfo.roadId = roadId;
        roadInfo.location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        roadInfo.name = name;
        if ([OAApplicationMode valueOfStringKey:appModeKey def:nil])
            roadInfo.appModeKey = appModeKey;
        else
            roadInfo.appModeKey = [[OARoutingHelper sharedInstance] getAppMode].stringKey;

        [self.items addObject:roadInfo];
    }
}

- (void) writeItemsToJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (self.items.count > 0)
    {
        for (OAAvoidRoadInfo *avoidRoad in self.items)
        {
            NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
            jsonObject[@"latitude"] = [NSString stringWithFormat:@"%0.5f", avoidRoad.location.coordinate.latitude];
            jsonObject[@"longitude"] = [NSString stringWithFormat:@"%0.5f", avoidRoad.location.coordinate.longitude];
            jsonObject[@"name"] = avoidRoad.name;
            jsonObject[@"appModeKey"] = avoidRoad.appModeKey;
            jsonObject[@"roadId"] = @(avoidRoad.roadId);
            [jsonArray addObject:jsonObject];
        }
        json[@"items"] = jsonArray;
    }
}

@end
