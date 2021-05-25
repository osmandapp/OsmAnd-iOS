//
//  OAOpenStreetMapRemoteUtil.m
//  OsmAnd
//
//  Created by Paul on 2/1/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOpenStreetMapRemoteUtil.h"
#import "OAEntityInfo.h"
#import "OAEntity.h"
#import "OAGPXDocument.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OANode.h"
#import "OAWay.h"
#import "OAEditPOIData.h"
#import "OAOsmPoint.h"
#import "OATargetPoint.h"
#import "OAOsmMapUtils.h"
#import "OAPOI.h"
#import "OAOsmBaseStorage.h"
#import "OATransportStop.h"
#import "OAPOILocationType.h"
#import "OARootViewController.h"

#include <OsmAndCore/Utilities.h>

#define WAY_MODULO_REMAINDER 1;
static const int AMENITY_ID_RIGHT_SHIFT = 1;
static const int NON_AMENITY_ID_RIGHT_SHIFT = 7;

static const long NO_CHANGESET_ID = -1;
static const NSString* BASE_URL = @"https://api.openstreetmap.org/";
static const NSString* URL_TO_UPLOAD_GPX = @"https://api.openstreetmap.org/api/0.6/gpx/create";

@implementation OAOpenStreetMapRemoteUtil
{
    OAEntityInfo *_entityInfo;
    OAEntityId *_entityInfoId;
    
    long _changeSetId;
    NSTimeInterval _changeSetTimeStamp;
    OAAppSettings *_settings;
}

-(id)init
{
    self = [super init];
    if (self) {
        _changeSetId = NO_CHANGESET_ID;
        _changeSetTimeStamp = NO_CHANGESET_ID;
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

-(NSString *)uploadGPXFile:(NSString *)tagstring description:(NSString *)description visibility:(NSString *)visibility gpxDoc:(OAGPXDocument *)document
{
//    String url = URL_TO_UPLOAD_GPX;
//    Map<String, String> additionalData = new LinkedHashMap<String, String>();
//    additionalData.put("description", description);
//    additionalData.put("tags", tagstring);
//    additionalData.put("visibility", visibility);
//    return NetworkUtils.uploadFile(url, f, settings.USER_NAME.get() + ":" + settings.USER_PASSWORD.get(), "file",
//                                   true, additionalData);
    return @"";
}

-(NSString *)sendRequest:(NSString *)url requestMethod:(NSString *)requestMethod requestBody:(NSString *)requestBody userOperation:(NSString *)userOperation
          doAuthenticate:(BOOL) doAuthenticate
{
    NSLog(@"Sending request: %@", url);
    NSURL *urlObj = [[NSURL alloc] initWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlObj
                                                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                                         timeoutInterval:30.0];
    [request setHTTPMethod:requestMethod];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [request addValue:[NSString stringWithFormat:@"OsmAndiOS %@", version] forHTTPHeaderField:@"User-Agent"];

    if ([requestMethod isEqualToString:@"PUT"] || [requestMethod isEqualToString:@"POST"] || [requestMethod isEqualToString:@"DELETE"])
    {
        [request addValue:@"text/xml" forHTTPHeaderField:@"Content-type"];
        NSData *postData = [requestBody dataUsingEncoding:NSUTF8StringEncoding];
        [request addValue:@(postData.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:postData];
    }
    __block NSString *responseString = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSInteger responseCode = ((NSHTTPURLResponse *)response).statusCode;
        if (data && !error && (responseCode >= 200 && responseCode < 300))
            responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return responseString;
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    if (challenge.previousFailureCount > 1)
    {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
    else
    {
        NSURLCredential *credential = [NSURLCredential credentialWithUser:_settings.osmUserName.get
                                                                 password:_settings.osmUserPassword.get
                                                              persistence:NSURLCredentialPersistenceForSession];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }
}

- (NSString *)createOpenChangesetRequestString:(NSString *)comment {
    QString endXml;
    QXmlStreamWriter xmlWriter(&endXml);
    //    xmlWriter.writeStartDocument(QLatin1String("1.0"), true);
    xmlWriter.writeStartDocument(QStringLiteral("1.0"), true);
    xmlWriter.writeStartElement(QLatin1String("osm"));
    xmlWriter.writeStartElement(QLatin1String("changeset"));
    if (comment)
    {
        xmlWriter.writeStartElement(QLatin1String("tag"));
        xmlWriter.writeAttribute(QStringLiteral("k"), QStringLiteral("comment"));
        xmlWriter.writeAttribute(QStringLiteral("v"), QString::fromNSString(comment));
        xmlWriter.writeEndElement();
    }
    xmlWriter.writeStartElement(QStringLiteral("tag"));
    xmlWriter.writeAttribute(QStringLiteral("k"), QStringLiteral("created_by"));
    xmlWriter.writeAttribute(QStringLiteral("v"), QString::fromNSString([self getAppFullName]));
    // </tag>
    xmlWriter.writeEndElement();
    // </changeset>
    xmlWriter.writeEndElement();
    // </osm>
    xmlWriter.writeEndElement();
    xmlWriter.writeEndDocument();
    
    return endXml.toNSString();
}

-(long) openChangeSet:(NSString *)comment
{
    long identifier = -1;
    NSString *endXml = [self createOpenChangesetRequestString:comment];
    NSString *response = [self sendRequest:[BASE_URL stringByAppendingString:@"api/0.6/changeset/create/"] requestMethod:@"PUT" requestBody:endXml userOperation:OALocalizedString(@"opening_changeset") doAuthenticate:YES];
    if (response && response.length > 0)
    {
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        NSNumber *num = [f numberFromString:response];
        identifier = num.longValue;
    }
    return identifier;
}

-(NSString *)getAppFullName
{
    return [NSString stringWithFormat:@"%@ %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
            [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"]];
}

-(void)writeNode:(OANode *)node entityInfo:(OAEntityInfo *)info xmlWriter:(QXmlStreamWriter &)xmlWriter changesetId:(long)changeSetId user:(NSString *)user
{
    xmlWriter.writeStartElement(QLatin1String("node"));
    xmlWriter.writeAttribute(QStringLiteral("id"), QString::number([node getId]));
    xmlWriter.writeAttribute(QStringLiteral("lat"), QString::number([node getLatitude], 'f', 10));
    xmlWriter.writeAttribute(QStringLiteral("lon"), QString::number([node getLongitude], 'f', 10));
    
    if (info)
    {
        xmlWriter.writeAttribute(QStringLiteral("visible"), QString::fromNSString([info getVisible]));
        xmlWriter.writeAttribute(QStringLiteral("version"), QString::fromNSString([info getVersion]));
    }
    xmlWriter.writeAttribute(QStringLiteral("changeset"), QString::number(_changeSetId));
    
    [self writeTags:node xmlWriter:xmlWriter];
    xmlWriter.writeEndElement();
}

-(void)writeWay:(OAWay *)way info:(OAEntityInfo *)info xmlWriter:(QXmlStreamWriter &)xmlWriter changesetId:(long)changeSetId user:(NSString *)user
{
    xmlWriter.writeStartElement(QLatin1String("way"));
    xmlWriter.writeAttribute(QStringLiteral("id"), QString::number([way getId]));
    
    if (info)
    {
        xmlWriter.writeAttribute(QStringLiteral("visible"), QString::fromNSString([info getVisible]));
        xmlWriter.writeAttribute(QStringLiteral("version"), QString::fromNSString([info getVersion]));
    }
    xmlWriter.writeAttribute(QStringLiteral("changeset"), QString::number(_changeSetId));
    
    [self writeNodesIds:way xmlWriter:xmlWriter];
    [self writeTags:way xmlWriter:xmlWriter];
    xmlWriter.writeEndElement();
}

-(void) writeNodesIds:(OAWay *) way xmlWriter:(QXmlStreamWriter &)xmlWriter
{
    for (NSInteger i = 0; i < way.getNodeIds.count; i++)
    {
        long long nodeId = way.getNodeIds[i].longLongValue;
        if (nodeId > 0)
        {
            xmlWriter.writeStartElement(QStringLiteral("nd"));
            xmlWriter.writeAttribute(QStringLiteral("ref"), QString::number(nodeId));
            xmlWriter.writeEndElement();
        }
    }
}

-(void)writeTags:(OAEntity *)entity xmlWriter:(QXmlStreamWriter &)xmlWriter
{
    for (NSString *k : [entity getTagKeySet]) {
        NSString *val = [entity getTagFromString:k];
        if (val.length == 0 || k.length == 0 || [POI_TYPE_TAG isEqualToString:k] || [k hasPrefix:REMOVE_TAG_PREFIX]
            || [k rangeOfString:REMOVE_TAG_PREFIX].location != NSNotFound)
            continue;
        
        xmlWriter.writeStartElement(QStringLiteral("tag"));
        xmlWriter.writeAttribute(QStringLiteral("k"), QString::fromNSString(k));
        xmlWriter.writeAttribute(QStringLiteral("v"), QString::fromNSString(val));
        xmlWriter.writeEndElement();
    }
}

-(BOOL)isNewChangesetRequired
{
    // first commit
    if (_changeSetId == NO_CHANGESET_ID)
        return YES;
    
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    // changeset is idle for more than 30 minutes (1 hour according specification)
    if (now - _changeSetTimeStamp > 30 * 60 * 1000) {
        return YES;
    }
    return NO;
}

- (void)closeChangeSet
{
    if (_changeSetId != NO_CHANGESET_ID)
    {
        NSString *response = [self sendRequest:[NSString stringWithFormat:@"%@%@%ld%@", BASE_URL, @"api/0.6/changeset/", _changeSetId, @"/close"]
                                requestMethod:@"PUT" requestBody:@"" userOperation:OALocalizedString(@"closing_changeset")
                                doAuthenticate:YES];
        NSLog(@"Response: %@", response);
        _changeSetId = NO_CHANGESET_ID;
    }
}

- (NSString *)createChangeXmlString:(EOAAction)action entity:(OAEntity *)entity info:(OAEntityInfo *)info {
    QString xmlString;
    QXmlStreamWriter xmlWriter(&xmlString);
    xmlWriter.writeStartDocument(QStringLiteral("1.0"), true);
    xmlWriter.writeStartElement(QStringLiteral("osmChange"));
    xmlWriter.writeAttribute(QStringLiteral("version"), QStringLiteral("0.6"));
    xmlWriter.writeAttribute(QStringLiteral("generator"), QString::fromNSString([self getAppFullName]));
    xmlWriter.writeStartElement(QString::fromNSString([OAOsmPoint getStringAction][[NSNumber numberWithInteger:action]]));
    xmlWriter.writeAttribute(QStringLiteral("version"), QStringLiteral("0.6"));
    xmlWriter.writeAttribute(QStringLiteral("generator"), QString::fromNSString([self getAppFullName]));
    if ([entity isKindOfClass:OANode.class])
        [self writeNode:(OANode *)entity entityInfo:info xmlWriter:xmlWriter changesetId:_changeSetId user:_settings.osmUserName.get];
    else if ([entity isKindOfClass:OAWay.class])
        [self writeWay:(OAWay *)entity info:info xmlWriter:xmlWriter changesetId:_changeSetId user:_settings.osmUserName.get];
    // </action>
    xmlWriter.writeEndElement();
    // </osmChange>
    xmlWriter.writeEndElement();
    xmlWriter.writeEndDocument();
    return xmlString.toNSString();
}

- (OAEntity *)commitEntityImpl:(EOAAction)action entity:(OAEntity *)entity entityInfo:(OAEntityInfo *)info comment:(NSString *)comment closeChangeSet:(BOOL)closeChangeSet changedTags:(NSSet<NSString *> *)changedTags
{
    if ([self isNewChangesetRequired])
    {
        _changeSetId = [self openChangeSet:comment];
        _changeSetTimeStamp = [[NSDate date] timeIntervalSince1970];
    }
    if (_changeSetId < 0)
        return nil;

    OAEntity *newEntity = entity;
    NSString *xmlString = [self createChangeXmlString:action entity:entity info:info];
    
    NSString *res = [self sendRequest:[NSString stringWithFormat:@"%@%@%ld%@", BASE_URL, @"api/0.6/changeset/", _changeSetId, @"/upload"]
                       requestMethod:@"POST" requestBody:xmlString userOperation:OALocalizedString(@"commiting_node")
                      doAuthenticate:YES];
    NSLog(@"Response: %@", res);
    if (res) {
        if (CREATE == action) {
            long long newId = [entity getId];
            NSString *searchKeyword = @"new_id=\"";
            NSRange range = [res rangeOfString:searchKeyword];
            
            if(range.location != NSNotFound)
            {
                NSUInteger startPoint = range.location + range.length;
                res = [res substringWithRange:NSMakeRange(startPoint, res.length - 1 - startPoint)];
                range = [res rangeOfString:@"\""];
                if (range.location != NSNotFound)
                {
                    res = [res substringToIndex:range.location];
                    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
                    [f setNumberStyle:NSNumberFormatterDecimalStyle];
                    newId = [f numberFromString:res].longLongValue;
                    if ([entity isKindOfClass:OANode.class])
                        newEntity = [[OANode alloc] initWithNode:(OANode *)entity identifier:newId];
                    else if ([entity isKindOfClass:OAWay.class])
                        newEntity = [[OAWay alloc] initWithId:newId latitude:[entity getLatitude] longitude:[entity getLongitude] ids:[((OAWay *)entity) getNodeIds]];
                }
            }
        }
        _changeSetTimeStamp = [[NSDate date] timeIntervalSince1970];
        if (closeChangeSet)
            [self closeChangeSet];
        return newEntity;
    }
    if (closeChangeSet)
        [self closeChangeSet];
    return nil;
}

- (OAEntityInfo *)getEntityInfo:(long long)identifier {
    if (_entityInfoId && [_entityInfoId getId] == identifier)
        return _entityInfo;
    return nil;
}

- (OAEntity *)loadEntity:(OATargetPoint *)targetPoint
{
    unsigned long long objectId = targetPoint.obfId;
    BOOL isTransportStop = targetPoint.type == OATargetTransportStop;
    if (isTransportStop)
        objectId = ((OATransportStop *)targetPoint.targetObj).poi.obfId;
    
    if (!(objectId > 0 && ((objectId % 2 == AMENITY_ID_RIGHT_SHIFT) || (objectId >> NON_AMENITY_ID_RIGHT_SHIFT) < INT_MAX)))
        return nil;
    BOOL isWay = objectId % 2 == WAY_MODULO_REMAINDER; // check if mapObject is a way
    OAPOI *poi = isTransportStop ? ((OATransportStop *)targetPoint.targetObj).poi : (OAPOI *)targetPoint.targetObj;
    if (!poi)
        return nil;
    
    BOOL isAmenity = poi.type && ![poi.type isKindOfClass:[OAPOILocationType class]];
    unsigned long long entityId = objectId >> (isAmenity ? AMENITY_ID_RIGHT_SHIFT : NON_AMENITY_ID_RIGHT_SHIFT);
    
    NSString *api = isWay ? @"api/0.6/way/" : @"api/0.6/node/";
    NSString *res = [self sendRequest:[NSString stringWithFormat:@"%@%@%llu", BASE_URL, api, entityId]
                        requestMethod:@"GET" requestBody:@"" userOperation:[NSString stringWithFormat:@"%@%llu", OALocalizedString(@"loading_poi_obj"), entityId]
                       doAuthenticate:NO];
    if (res)
    {
        OAOsmBaseStorage *baseStorage = [[OAOsmBaseStorage alloc] init];
        [baseStorage setConvertTagsToLC:NO];
        [baseStorage parseResponseSync:res];
        OAEntityId *enId = [[OAEntityId alloc] initWithEntityType:(isWay ? WAY : NODE) identifier:entityId];
        OAEntity *entity = [baseStorage getRegisteredEntities][enId];
        _entityInfo = [baseStorage getRegisteredEntityInfo][enId];
        _entityInfoId = enId;
        if (entity)
        {
            if (!isWay && [entity isKindOfClass:OANode.class] && OsmAnd::Utilities::distance([entity getLongitude], [entity getLatitude], poi.longitude, poi.latitude) < 50)
            {
                // check whether this is node (because id of node could be the same as relation)
                if (isAmenity)
                    return [self replaceEditOsmTags:poi entity:entity];
                else
                    return entity;
            }
            else if (isWay && [entity isKindOfClass:OAWay.class])
            {
                const CLLocationCoordinate2D latLon = CLLocationCoordinate2DMake(poi.latitude, poi.longitude);
                [entity setLatitude:latLon.latitude];
                [entity setLongitude:latLon.longitude];
                if (isAmenity)
                    return [self replaceEditOsmTags:poi entity:entity];
                else
                    return entity;
            }
        }
    }
    return nil;
}

-(OAEntity *) replaceEditOsmTags:(OAPOI *) poi entity:(OAEntity *) entity
{
    OAPOIType *type = poi.type;
    if (type) {
        if ([type.getEditOsmValue isEqualToString:[entity getTagFromString:type.getEditOsmTag]]) {
            [entity removeTag:type.getEditOsmTag];
            [entity putTagNoLC:POI_TYPE_TAG value:[type.name stringByReplacingOccurrencesOfString:@"_" withString:@" "]];
        } else {
            for (OAPOIType *pt in type.category.poiTypes)
            {
                if ([pt.getEditOsmValue isEqualToString:[entity getTagFromString:pt.getEditOsmTag]])
                {
                    [entity removeTag:pt.getEditOsmTag];
                    [entity putTagNoLC:POI_TYPE_TAG value:[pt.name stringByReplacingOccurrencesOfString:@"_" withString:@" "]];
                }
            }
        }
    }
    return entity;
}

-(OAEntityInfo *)loadEntityFromEntity:(OAEntity *)entity
{
    long long entityId = [entity getId]; // >> 1;
    BOOL isWay = [entity isKindOfClass:OAWay.class];
    NSString *api = isWay ? @"api/0.6/way/" : @"api/0.6/node/";
    NSString *res = [self sendRequest:[NSString stringWithFormat:@"%@%@%lld", BASE_URL, api, entityId]
                        requestMethod:@"GET" requestBody:@"" userOperation:[NSString stringWithFormat:@"%@%lld", OALocalizedString(@"loading_poi_obj"), entityId]
                       doAuthenticate:NO];
    if (res)
    {
        OAOsmBaseStorage *baseStorage = [[OAOsmBaseStorage alloc] init];
        [baseStorage setConvertTagsToLC:NO];
        [baseStorage parseResponseSync:res];
        OAEntityId *enId = [[OAEntityId alloc] initWithEntityType:(isWay ? WAY : NODE) identifier:entityId];
        OAEntity *downloadedEntity = [baseStorage getRegisteredEntities][enId];
        NSMutableDictionary<NSString *, NSString *> *updatedTags = [NSMutableDictionary new];
        for (NSString *tagKey in [entity getTagKeySet]) {
            if (tagKey && ![self deletedTag:entity tag:tagKey])
                [self addIfNotNull:tagKey value:[entity getTagFromString:tagKey] tags:updatedTags];
            
        }
        if ([entity getChangedTags])
        {
            for (NSString *tagKey in [entity getChangedTags]) {
                if (tagKey)
                    [self addIfNotNull:tagKey value:[entity getTagFromString:tagKey] tags:updatedTags];
            }
        }
        [entity replaceTags:updatedTags];
        if (isWay)
        {
            OAWay *foundWay = (OAWay *) downloadedEntity;
            OAWay *currentWay = (OAWay *) entity;
            NSArray <NSNumber *> *nodeIds = foundWay.getNodeIds;
            if (nodeIds)
            {
                for (NSInteger i = 0; i < nodeIds.count; i++)
                {
                    long long nodeId = nodeIds[i].longLongValue;
                    if (nodeId > 0)
                        [currentWay addNodeById:nodeId];
                }
            }
        }
        else if (OsmAnd::Utilities::distance([entity getLongitude], [entity getLatitude], [downloadedEntity getLongitude], [downloadedEntity getLatitude]) < 10 || OsmAnd::Utilities::distance([entity getLongitude], [entity getLatitude], [downloadedEntity getLongitude], [downloadedEntity getLatitude]) > 10000) {
            // avoid shifting due to round error and avoid moving to more than 10 km
            [entity setLatitude:[downloadedEntity getLatitude]];
            [entity setLongitude:[downloadedEntity getLongitude]];
        }
        _entityInfo = [baseStorage getRegisteredEntityInfo][enId];
        _entityInfoId = enId;
        return _entityInfo;
    }
    return nil;
}

-(void) addIfNotNull:(NSString *)key value:(NSString *)value tags:(NSMutableDictionary<NSString *, NSString *> *) tags
{
    if (value)
        [tags setObject:value forKey:key];
}

-(BOOL) deletedTag:(OAEntity *)entity tag:(NSString *) tag
{
    return [[entity getTagKeySet] containsObject:[NSString stringWithFormat:@"%@%@", REMOVE_TAG_PREFIX, tag]];
}

@end
