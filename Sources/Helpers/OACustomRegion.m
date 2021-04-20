//
//  OACustomRegion.m
//  OsmAnd Maps
//
//  Created by Paul on 17.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACustomRegion.h"
#import "OAJsonHelper.h"
#import "OAColors.h"
#import "OAResourcesUIHelper.h"

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
        region.name = region.names[@""];
        region.nativeName = region.names[@"en"];
        region.regionId = region.names[@""];
        region.regionNameLocale = [OAJsonHelper getLocalizedResFromMap:region.names defValue:region.name];
    }
    
    region.icons = json[@"icon"];
    region.headers = jsom[@"header"];
    
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
    [items addObjectsFromArray:[self laodIndexItems:self.dynamicItemsJson]];
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
            
            long timestamp = [itemJson[@"timestamp"] longValue] * 1000;
            long contentSize = [itemJson[@"contentSize"] longValue];
            long containerSize = [itemJson[@"containerSize"] longValue];
            
            NSString *indexType = itemJson[@"type"];
            indexType = indexType ? : self.type;
            NSString *fileName = itemJson[@"filename"];
            NSString *downloadUrl = itemJson[@"downloadurl"];
            NSString size = [NSString stringWithFormat:@"%f", containerSize / (1024. * 1024.)];
            
            NSDictionary<NSString *, NSString *> *indexNames = itemsJson[@"name"];
            NSDictionary<NSString *, NSString *> *firstSubNames = itemsJson[@"firstsubname"];
            NSDictionary<NSString *, NSString *> *secondSubNames = jsonItems[@"secondsubname"];
            
            OADownloadDescriptionInfo *descriptionInfo = [OADownloadDescriptionInfo fromJson:itemJson[@"description"]];
            
            DownloadActivityType type = DownloadActivityType.getIndexType(indexType);
            if (type != null) {
                IndexItem indexItem = new CustomIndexItem.CustomIndexItemBuilder()
                .setFileName(fileName)
                .setSubfolder(subfolder)
                .setDownloadUrl(downloadUrl)
                .setNames(indexNames)
                .setFirstSubNames(firstSubNames)
                .setSecondSubNames(secondSubNames)
                .setDescriptionInfo(descriptionInfo)
                .setTimestamp(timestamp)
                .setSize(size)
                .setContentSize(contentSize)
                .setContainerSize(containerSize)
                .setType(type)
                .create();
                
                items.add(indexItem);
            }
        }
        return items;
}

void loadDynamicIndexItems(final OsmandApplication app) {
    if (dynamicItemsJson == null && dynamicDownloadItems != null
            && !Algorithms.isEmpty(dynamicDownloadItems.url)
            && app.getSettings().isInternetConnectionAvailable()) {
        OnRequestResultListener resultListener = new OnRequestResultListener() {
            @Override
            public void onResult(String result) {
                if (!Algorithms.isEmpty(result)) {
                    if ("json".equalsIgnoreCase(dynamicDownloadItems.format)) {
                        dynamicItemsJson = mapJsonItems(result);
                    }
                    app.getDownloadThread().runReloadIndexFilesSilent();
                }
            }
        };

        AndroidNetworkUtils.sendRequestAsync(app, dynamicDownloadItems.getUrl(), null,
                null, false, false, resultListener);
    }
}

private JSONArray mapJsonItems(String jsonStr) {
    try {
        JSONObject json = new JSONObject(jsonStr);
        JSONArray jsonArray = json.optJSONArray(dynamicDownloadItems.itemsPath);
        if (jsonArray != null) {
            JSONArray itemsJson = new JSONArray();
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject jsonObject = jsonArray.getJSONObject(i);
                JSONObject itemJson = mapDynamicJsonItem(jsonObject, dynamicDownloadItems.mapping);

                itemsJson.put(itemJson);
            }
            return itemsJson;
        }
    } catch (JSONException e) {
        LOG.error(e);
    }
    return null;
}

private JSONObject mapDynamicJsonItem(JSONObject jsonObject, JSONObject mapping) throws JSONException {
    JSONObject itemJson = new JSONObject();
    for (Iterator<String> it = mapping.keys(); it.hasNext(); ) {
        String key = it.next();
        Object value = checkMappingValue(mapping.opt(key), jsonObject);
        itemJson.put(key, value);
    }
    return itemJson;
}

private Object checkMappingValue(Object value, JSONObject json) throws JSONException {
    if (value instanceof String) {
        String key = (String) value;
        int index = key.indexOf("@");
        if (index != INVALID_ID) {
            key = key.substring(index + 1);
        }
        return json.opt(key);
    } else if (value instanceof JSONObject) {
        JSONObject checkedJsonObject = (JSONObject) value;
        JSONObject objectJson = new JSONObject();

        for (Iterator<String> iterator = checkedJsonObject.keys(); iterator.hasNext(); ) {
            String key = iterator.next();
            Object checkedValue = checkMappingValue(checkedJsonObject.opt(key), json);
            objectJson.put(key, checkedValue);
        }
        return objectJson;
    } else if (value instanceof JSONArray) {
        JSONArray checkedJsonArray = new JSONArray();
        JSONArray jsonArray = (JSONArray) value;

        for (int i = 0; i < jsonArray.length(); i++) {
            Object checkedValue = checkMappingValue(jsonArray.opt(i), json);
            checkedJsonArray.put(i, checkedValue);
        }
        return checkedJsonArray;
    }
    return value;
}

@end
