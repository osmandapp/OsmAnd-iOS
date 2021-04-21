//
//  OADownloadDescriptionInfo.m
//  OsmAnd Maps
//
//  Created by Paul on 20.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OADownloadDescriptionInfo.h"
#import "OAJsonHelper.h"

@implementation OADownloadActionButton

- (instancetype) initWithActionType:(NSString *)actionType name:(NSString *)name url:(NSString *)url
{
    self = [super init];
    if (self) {
        _actionType = actionType;
        _name = name;
        _url = url;
    }
    return self;
}

@end

@implementation OADownloadDescriptionInfo
{
    NSArray *_buttonsJson;
    NSDictionary<NSString *, NSString *> *_localizedDescription;
}

+ (instancetype) fromJson:(NSDictionary *)json
{
    if (json)
    {
        OADownloadDescriptionInfo *downloadDescriptionInfo = [[OADownloadDescriptionInfo alloc] initWithLocalizedDescription:json[@"text"] imageUrls:json[@"image"] buttonsJson:json[@"button"]];
        return downloadDescriptionInfo;
    }
    return nil;
}

- (instancetype) initWithLocalizedDescription:(NSDictionary<NSString *, NSString *> *)localizedDescription imageUrls:(NSArray<NSString *> *)imageUrls buttonsJson:(NSArray *)buttonsJson
{
    self = [super init];
    if (self) {
        _localizedDescription = localizedDescription;
        _imageUrls = imageUrls;
        _buttonsJson = buttonsJson;
    }
    return self;
}

- (NSString *) getLocalizedDescription
{
    NSString *description = [OAJsonHelper getLocalizedResFromMap:_localizedDescription defValue:nil];
    return description ? [[NSAttributedString alloc] initWithData:[description dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding]} documentAttributes:nil error:nil].string : nil;
}

- (NSArray<OADownloadActionButton *> *) getActionButtons
{
    NSMutableArray<OADownloadActionButton *> *actionButtons = [NSMutableArray new];
    if (_buttonsJson)
    {
        for (NSDictionary *obj in _buttonsJson)
        {
            NSString *url = obj[@"url"];
            NSString *actionType = obj[@"action"];
            NSString *name = [OAJsonHelper getLocalizedResFromMap:obj defValue:nil];
            
            OADownloadActionButton *actionButton = [[OADownloadActionButton alloc] initWithActionType:actionType name:name url:url];
            [actionButtons addObject:actionButton];
        }
    }
    return actionButtons;
}

- (NSDictionary *) toJson
{
    NSMutableDictionary *json = [NSMutableDictionary new];
    
    if (_localizedDescription)
        json[@"text"] = _localizedDescription;
    
    if (_imageUrls)
        json[@"image"] = _imageUrls;
    
    if (_buttonsJson)
        json[@"button"] = _buttonsJson;
    
    return json;
}

@end
