//
//  OACustomRegion.m
//  OsmAnd Maps
//
//  Created by Paul on 17.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACustomRegion.h"
#import "OAWorldRegion+Protected.h"
#import "OAJsonHelper.h"
#import "OAColors.h"
#import "OAResourcesUIHelper.h"
#import "OADownloadDescriptionInfo.h"
#import "OAOcbfHelper.h"
#import "OsmAndApp.h"
#import "Reachability.h"

#import <TTTColorFormatter.h>

@interface OADynamicDownloadItems ()

@property (nonatomic) NSString *url;
@property (nonatomic) NSString *format;
@property (nonatomic) NSString *itemsPath;
@property (nonatomic) NSDictionary *mapping;

@end

@implementation OADynamicDownloadItems


+ (instancetype) fromJson:(NSDictionary *)object
{
    OADynamicDownloadItems *dynamicDownloadItems = [[OADynamicDownloadItems alloc] init];
    dynamicDownloadItems.url = object[@"url"];
    dynamicDownloadItems.format = object[@"format"];
    dynamicDownloadItems.itemsPath = object[@"items-path"];
    dynamicDownloadItems.mapping = object[@"mapping"];
    
    return dynamicDownloadItems;
}

- (NSDictionary *) toJson
{
    NSMutableDictionary *jsonObject = [NSMutableDictionary new];
    
    jsonObject[@"url"] = self.url;
    jsonObject[@"format"] = self.format;
    jsonObject[@"items-path"] = self.itemsPath;
    jsonObject[@"mapping"] = self.mapping;
    
    return jsonObject;
}

@end

@interface OACustomRegion()

@property (nonatomic, readwrite) NSString *path;
@property (nonatomic, readwrite) NSString *parentPath;
@property (nonatomic, readwrite) NSString *type;
@property (nonatomic, readwrite) NSString *subfolder;

@property (nonatomic, readwrite) NSDictionary<NSString *, NSString *> *names;
@property (nonatomic, readwrite) NSDictionary<NSString *, NSString *> *icons;
@property (nonatomic, readwrite) NSDictionary<NSString *, NSString *> *headers;

@property (nonatomic) NSArray *downloadItemsJson;
@property (nonatomic) NSArray *dynamicItemsJson;

@property (nonatomic) OADynamicDownloadItems *dynamicDownloadItems;
@property (nonatomic) OADownloadDescriptionInfo *descriptionInfo;

@property (nonatomic) UIColor *headerColor;

@end

@implementation OACustomRegion
{
    NSString *_scopeId;
    
    NSArray *_downloadItemsJson;
    NSArray *_dynamicItemsJson;
}

+ (instancetype) fromJson:(NSDictionary *)json
{
    NSString *scopeId = json[@"scope-id"];
    NSString *path = json[@"path"];
    NSString *type = json[@"type"];
    
    OACustomRegion *region = [[self alloc] initWithScopeId:scopeId path:path type:type];
    region.subfolder = json[@"subfolder"];
    
    if (path.pathComponents.count > 1)
        region.parentPath = [path stringByDeletingLastPathComponent];
    
    region.names = json[@"name"];
    if (region.names.count > 0)
    {
        region.localizedName = [OAJsonHelper getLocalizedResFromMap:region.names defValue:region.name];
        region.nativeName = region.names[@""];
    }
    
    region.icons = json[@"icon"];
    region.headers = json[@"header"];
    
    region.downloadItemsJson = json[@"items"];
    region.dynamicItemsJson = json[@"dynamic-items"];
    
    NSDictionary *urlItemsJson = json[@"items-url"];
    if (urlItemsJson)
        region.dynamicDownloadItems = [OADynamicDownloadItems fromJson:urlItemsJson];
    
    NSString *headerColor = json[@"header-color"];
    if (headerColor.length > 0)
        region.headerColor = UIColorFromRGB([headerColor substringFromIndex:1].integerValue);
    else
        region.headerColor = UIColorFromRGB(color_osmand_orange);
    
    region.descriptionInfo = [OADownloadDescriptionInfo fromJson:json[@"description"]];
    
    return region;
}

- (instancetype) initWithScopeId:(NSString *)scopeId path:(NSString *)path type:(NSString *)type
{
    self = [super initWithId:path andLocalizedName:nil];
    if (self) {
        _scopeId = scopeId;
        _path = path;
        _type = type;
    }
    return self;
}

- (NSString *) getIconName
{
    return [OAJsonHelper getLocalizedResFromMap:_icons defValue:nil];
}

- (NSDictionary *) toJson
{
    NSMutableDictionary *json = [NSMutableDictionary new];
    
    json[@"scope-id"] = _scopeId;
    json[@"path"] = self.path;
    json[@"type"] = self.type;
    json[@"subfolder"] = self.subfolder;
    
    
    json[@"name"] = self.names;
    json[@"icon"] = self.icons;
    json[@"header"] = self.headers;
    
    if (self.headerColor != UIColorFromRGB(color_osmand_orange))
    {
        TTTColorFormatter *colorFormatter = [[TTTColorFormatter alloc] init];
        json[@"header-color"] = [colorFormatter hexadecimalStringFromColor:self.headerColor];
    }
    
    if (self.descriptionInfo)
        json[@"description"] = [self.descriptionInfo toJson];
    json[@"items"] = self.downloadItemsJson;
    json[@"dynamic-items"] = self.dynamicItemsJson;
    if (self.dynamicDownloadItems)
        json[@"items-url"] = [self.dynamicDownloadItems toJson];
    return json;
}

- (NSArray<OAResourceItem *> *) loadIndexItems
{
    NSMutableArray<OAResourceItem *> *items = [NSMutableArray new];
    [items addObjectsFromArray:[self loadIndexItems:self.downloadItemsJson]];
    [items addObjectsFromArray:[self loadIndexItems:self.dynamicItemsJson]];
    return items;
}

- (NSArray<OAResourceItem *> *) loadIndexItems:(NSArray *)itemsJson
{
    NSMutableArray<OAResourceItem *> *items = [NSMutableArray new];
    if (itemsJson)
    {
        for (NSInteger i = 0; i < itemsJson.count; i++)
        {
            NSDictionary *itemJson = itemsJson[i];
            
//            long timestamp = [itemJson[@"timestamp"] longValue] * 1000;
            long contentSize = [itemJson[@"contentSize"] longValue];
            long containerSize = [itemJson[@"containerSize"] longValue];
            
            NSString *indexType = itemJson[@"type"];
            indexType = indexType ? : self.type;
            NSString *fileName = itemJson[@"filename"];
            NSString *downloadUrl = itemJson[@"downloadurl"];
//            long size = containerSize / (1024. * 1024.);
            
            NSDictionary<NSString *, NSString *> *indexNames = itemJson[@"name"];
            NSDictionary<NSString *, NSString *> *firstSubNames = itemJson[@"firstsubname"];
            NSDictionary<NSString *, NSString *> *secondSubNames = itemJson[@"secondsubname"];
            
            OADownloadDescriptionInfo *descriptionInfo = [OADownloadDescriptionInfo fromJson:itemJson[@"description"]];
            
            const auto typeStr = QString::fromNSString(indexType);
            const QStringRef typeRef(&typeStr);
            OsmAnd::ResourcesManager::ResourceType type = OsmAnd::ResourcesManager::getIndexType(typeRef);
            if (type != OsmAnd::ResourcesManager::ResourceType::Unknown)
            {
                OACustomResourceItem *indexItem = [[OACustomResourceItem alloc] init];
                indexItem.resourceId = QString::fromNSString(fileName.lowerCase);
                indexItem.title = fileName;
                indexItem.subfolder = _subfolder;
                indexItem.downloadUrl = downloadUrl;
                indexItem.names = indexNames;
                indexItem.firstSubNames = firstSubNames;
                indexItem.secondSubNames = secondSubNames;
                indexItem.descriptionInfo = descriptionInfo;
//                indexItem.timestamp = timestamp;
                indexItem.size = contentSize;
                indexItem.sizePkg = containerSize;
                indexItem.resourceType = type;
                
                [items addObject:indexItem];
            }
        }
    }
    return items;
}

- (void) loadDynamicIndexItems
{
    if (!_dynamicItemsJson && _dynamicDownloadItems
        && _dynamicDownloadItems.url.length > 0
        && [Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
    {
        NSURL *urlObj = [[NSURL alloc] initWithString:_dynamicDownloadItems.url];
        NSURLSession *aSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        [[aSession dataTaskWithURL:urlObj completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (((NSHTTPURLResponse *)response).statusCode == 200)
            {
                if (data && !error)
                {
                    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                    if (jsonDict)
                    {
                        if ([_dynamicDownloadItems.format.lowerCase isEqualToString:@"json"])
                        {
                            _dynamicItemsJson = [self mapJsonItems:jsonDict];
                        }
                        OsmAndAppInstance app = OsmAndApp.instance;
                        [OAOcbfHelper downloadOcbfIfUpdated];
                        [app loadWorldRegions];
                        [app startRepositoryUpdateAsync:NO];
                    }
                }
            }
        }] resume];
    }
}

- (NSArray *) mapJsonItems:(NSDictionary *)json
{
    NSArray *jsonArray = json[_dynamicDownloadItems.itemsPath];
    if (jsonArray)
    {
        NSMutableArray *itemsJson = [NSMutableArray array];
        for (NSDictionary *jsonObject in jsonArray)
        {
            NSDictionary *itemJson = [self mapDynamicJsonItem:jsonObject mapping:_dynamicDownloadItems.mapping];
            
            if (itemsJson)
                [itemsJson addObject:itemJson];
        }
        return itemsJson;
    }
    return nil;
}

- (NSDictionary *) mapDynamicJsonItem:(NSDictionary *)jsonObject mapping:(NSDictionary *)mapping
{
    NSMutableDictionary *itemJson = [NSMutableDictionary dictionary];
    [mapping enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        id value = [self checkMappingValue:key json:jsonObject];
        if (value)
            itemJson[key] = value;
    }];
    return itemJson;
}

- (id) checkMappingValue:(id)value json:(NSDictionary *)json
{
    if ([value isKindOfClass:NSString.class])
    {
        NSString *key = value;
        NSInteger index = [key indexOf:@"@"];
        if (index != -1)
            key = [key substringFromIndex:index + 1];
        return json[key];
    }
    else if ([value isKindOfClass:NSDictionary.class])
    {
        NSMutableDictionary *checkedJsonObject = [NSMutableDictionary dictionary];
        NSDictionary *objectJson = value;
        
        [objectJson enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            id checkedValue = [self checkMappingValue:value json:json];
            checkedJsonObject[key] = checkedValue;
        }];
        return checkedJsonObject;
    }
    else if ([value isKindOfClass:NSArray.class])
    {
        NSMutableArray *checkedJsonArray = [NSMutableArray array];
        NSArray *jsonArray = value;

        [jsonArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            id checkedValue = [self checkMappingValue:obj json:json];
            [checkedJsonArray addObject:checkedValue];
        }];
        return checkedJsonArray;
    }
    return value;
}

@end
