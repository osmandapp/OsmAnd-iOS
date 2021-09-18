//
//  OAOsmBaseStorage.m
//  OsmAnd
//
//  Created by Paul on 2/8/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmBaseStorage.h"
#import "OAEntity.h"
#import "OANode.h"
#import "OAWay.h"
#import "OARelation.h"
#import "OAEntityInfo.h"
#import "OrderedDictionary.h"
#import "OAEntityInfo.h"

// called from libxml functions
@interface OAOsmBaseStorage (LibXMLParserMethods)

- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix
                 uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount
          namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount
defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes;
- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI;
- (void)charactersFound:(const xmlChar *)characters length:(int)length;
- (void)parsingError:(const char *)msg, ...;
- (void)endDocument;

@end

// Forward reference. The structure is defined in full at the end of the file.
static xmlSAXHandler simpleSAXHandlerStruct;

@implementation OAOsmBaseStorage
{
    OAEntity *_currentParsedEntity;
    int _currentModify;
    OAEntityInfo *_currentParsedEntityInfo;
    
    NSString *_textToParse;
    
    BOOL _parseStarted;
    
    MutableOrderedDictionary<OAEntityId *, OAEntity *> *_entities;
    MutableOrderedDictionary<OAEntityId *, OAEntityInfo *> *_entityInfo;

    BOOL _parseEntityInfo;
    BOOL _convertTagsToLC;
    
    BOOL _done;
    xmlParserCtxtPtr _xmlParserContext;
    
    NSSet<NSString *> *_supportedVersions;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _entities = [[MutableOrderedDictionary alloc] init];
        _entityInfo = [[MutableOrderedDictionary alloc] init];
        _supportedVersions = [NSSet setWithObjects:@"0.6", @"0.5", nil];
        _convertTagsToLC = YES;
        _parseEntityInfo = YES;
    }
    return self;
}

- (void)parseResponseSync:(NSString*)textToParse {
    _textToParse = textToParse;
    [self parseForData];
}

- (BOOL)parseWithLibXML2Parser {
    BOOL success = NO;
    self.error = NO;
    
    _xmlParserContext = xmlCreatePushParserCtxt(&simpleSAXHandlerStruct, (__bridge void *)(self), NULL, 0, NULL);
    
    NSData *osmData = [_textToParse dataUsingEncoding:NSUTF8StringEncoding];
    xmlParseChunk(_xmlParserContext, (const char *)[osmData bytes], (int)[osmData length], 0);
    xmlParseChunk(_xmlParserContext, NULL, 0, 1);
    _done = YES;
    
    if(self.error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(encounteredError:)]) {
            [self.delegate encounteredError:nil];
        }
    } else {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(parserFinished)]) {
            [(id)[self delegate] performSelectorOnMainThread:@selector(parserFinished)
                                                  withObject:nil
                                               waitUntilDone:NO];
        }
        
        success = YES;
    }
    return success;
}


- (BOOL)parseForData {
    
    BOOL success = NO;
    
    @autoreleasepool {
        success = [self parseWithLibXML2Parser];
        [self completeReading];
        return success;
    }
}

-(OrderedDictionary<OAEntityId *, OAEntityInfo *> *) getRegisteredEntityInfo
{
    return _entityInfo;
}

-(OrderedDictionary<OAEntityId *, OAEntity *> *) getRegisteredEntities
{
    return _entities;
}

-(void)completeReading
{
    for(OAEntity *e in _entities.allValues) {
        [e initializeLinks:_entities];
    }
}

-(void) setConvertTagsToLC:(BOOL)convertTagsToLC
{
    _convertTagsToLC = convertTagsToLC;
}

/*
 <osmChange version="0.6" generator="acme osm editor">
    <modify>
        <node id="1234" changeset="42" version="2" lat="12.1234567" lon="-8.7654321">
            <tag k="amenity" v="school"/>
        </node>
    </modify>
 </osmChange>
 */

#pragma mark Parsing Function Callback Methods

static const char * kOsmElementName = "osm";
static NSUInteger kOsmElementNameLength = 4;
//static const char * kOsmChangeElementName = "osmChange";
//static NSUInteger kOsmChangeElementNameLength = 10;
static const char * kNodeElementName = "node";
static NSUInteger kNodeElementNameLength = 5;
static const char * kTagElementName = "tag";
static NSUInteger kTagElementNameLength = 4;
static const char * kWayElementName = "way";
static NSUInteger kWayElementNameLength = 4;
static const char * kNdElementName = "nd";
static NSUInteger kNdElementNameLength = 3;
static const char * kRelationElementName = "relation";
static NSUInteger kRelationElementNameLength = 9;
static const char * kMemberElementName = "member";
static NSUInteger kMemberElementNameLength = 7;
static const char * kModifyElementName = "modify";
static NSUInteger kModifyElementNameLength = 7;
static const char * kCreateElementName = "create";
static NSUInteger kCreateElementNameLength = 7;
static const char * kDeleteElementName = "delete";
static NSUInteger kDeleteElementNameLength = 7;

static const char * kVersionAttributeName = "version";
static NSUInteger kVersionAttributeNameLength = 8;
static const char * kIdAttributeName = "id";
static NSUInteger kIdAttributeNameLength = 3;
static const char * kLatAttributeName = "lat";
static NSUInteger kLatAttributeNameLength = 4;
static const char * kLonAttributeName = "lon";
static NSUInteger kLonAttributeNameLength = 4;
static const char * kTimestampAttributeName = "timestamp";
static NSUInteger kTimestampAttributeNameLength = 10;
static const char * kUidAttributeName = "uid";
static NSUInteger kUidAttributeNameLength = 4;
static const char * kUserAttributeName = "user";
static NSUInteger kUserAttributeNameLength = 5;
static const char * kVisibleAttributeName = "visible";
static NSUInteger kVisibleAttributeNameLength = 8;
static const char * kChangesetAttributeName = "changeset";
static NSUInteger kChangesetAttributeNameLength = 10;
static const char * kKeyAttributeName = "k";
static NSUInteger kKeyAttributeNameLength = 2;
static const char * kValueAttributeName = "v";
static NSUInteger kValueAttributeNameLength = 2;

static const char * kTypeAttributeName = "type";
static NSUInteger kTypeAttributeNameLength = 5;
static const char * kRefAttributeName = "ref";
static NSUInteger kRefAttributeNameLength = 4;
static const char * kRoleAttributeName = "role";
static NSUInteger kRoleAttributeNameLength = 5;


- (NSNumber *) getNumberValue:(int)attributeCount attributes:(xmlSAX2Attributes *)attributes attrName:(const char *)name attrLength:(NSUInteger)length {
    for(int i = 0;i < attributeCount; i++) {
        
        if(0 == strncmp((const char*)attributes[i].localname, name,
                        length)) {
            
            int length = (int) (attributes[i].end - attributes[i].value);
            NSString *latStr = [[NSString alloc] initWithBytes:attributes[i].value
                                                        length:length
                                                      encoding:NSUTF8StringEncoding];
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            f.decimalSeparator = @".";
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            return [f numberFromString:latStr];
        }
    }
    return [NSNumber numberWithInt:-1];
}

- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix
                 uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount
          namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount
defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes {
    if (!_parseStarted)
    {
        if(0 == strncmp((const char *)localname, kOsmElementName, kOsmElementNameLength)) {
            
            for(int i = 0;i < attributeCount;i++) {
                
                if(0 == strncmp((const char*)attributes[i].localname, kVersionAttributeName,
                                kVersionAttributeNameLength)) {
                    
                    int length = (int) (attributes[i].end - attributes[i].value);
                    NSString *version = [[NSString alloc] initWithBytes:attributes[i].value
                                                                 length:length
                                                               encoding:NSUTF8StringEncoding];
                    if ([_supportedVersions containsObject:version])
                        _parseStarted = YES;
                    else
                        @throw [NSException exceptionWithName:@"OsmVersionNotSupported" reason:@"Supplied xml has unsupported osm version" userInfo:nil];
                }
            }
        }
    }
    if (0 == strncmp((const char *)localname, kModifyElementName, kModifyElementNameLength)) {
        _currentModify = MODIFY_MODIFIED;
    } else if (0 == strncmp((const char *)localname, kCreateElementName, kCreateElementNameLength)) {
        _currentModify = MODIFY_CREATED;
    } else if (0 == strncmp((const char *)localname, kDeleteElementName, kDeleteElementNameLength)) {
        _currentModify = MODIFY_DELETED;
    } else if (!_currentParsedEntity)
    {
        if (0 == strncmp((const char *)localname, kNodeElementName, kNodeElementNameLength)) {
            double lat = [self getNumberValue:attributeCount attributes:attributes attrName:kLatAttributeName attrLength:kLatAttributeNameLength].doubleValue;
            double lon = [self getNumberValue:attributeCount attributes:attributes attrName:kLonAttributeName attrLength:kLonAttributeNameLength].doubleValue;
            long long identifier = [self getNumberValue:attributeCount attributes:attributes attrName:kIdAttributeName attrLength:kIdAttributeNameLength].longLongValue;
            NSInteger version = [self getNumberValue:attributeCount attributes:attributes attrName:kVersionAttributeName attrLength:kVersionAttributeNameLength].integerValue;
            
            if (lat != -1 && lon != -1 && identifier != -1)
                _currentParsedEntity = [[OANode alloc] initWithId:identifier latitude:lat longitude:lon];
            
            [_currentParsedEntity setVersion:version == -1 ? 0 : version];
        }
        else if (0 == strncmp((const char *)localname, kWayElementName, kWayElementNameLength))
        {
            _currentParsedEntity = [[OAWay alloc] initWithId:[self getNumberValue:attributeCount attributes:attributes attrName:kIdAttributeName
                                                                       attrLength:kIdAttributeNameLength].longLongValue];
            NSInteger version = [self getNumberValue:attributeCount attributes:attributes attrName:kVersionAttributeName attrLength:kVersionAttributeNameLength].integerValue;
            [_currentParsedEntity setVersion:version == -1 ? 0 : version];
        }
        else if (0 == strncmp((const char *)localname, kRelationElementName, kRelationElementNameLength))
        {
            _currentParsedEntity = [[OARelation alloc] initWithId:[self getNumberValue:attributeCount attributes:attributes attrName:kIdAttributeName
                                                                       attrLength:kIdAttributeNameLength].longLongValue];
        }
        else
        {
            // this situation could be logged as unhandled
            NSLog(@"%@", @"Bad entity type from OSC request");
        }
        
        if (_currentParsedEntity)
        {
            [_currentParsedEntity setModify:_currentModify];
            if (_parseEntityInfo)
            {
                _currentParsedEntityInfo = [[OAEntityInfo alloc] init];
                NSString *changeset = @"";
                NSString *timestamp = @"";
                NSString *user = @"";
                NSString *version = @"";
                NSString *visible = @"";
                NSString *uid = @"";
                for(int i = 0; i < attributeCount; i++) {
                    
                    if(0 == strncmp((const char*)attributes[i].localname, kChangesetAttributeName,
                                    kChangesetAttributeNameLength)) {
                        
                        int length = (int) (attributes[i].end - attributes[i].value);
                        changeset = [[NSString alloc] initWithBytes:attributes[i].value
                                                                     length:length
                                                                   encoding:NSUTF8StringEncoding];
                    }
                    if(0 == strncmp((const char*)attributes[i].localname, kTimestampAttributeName,
                                    kTimestampAttributeNameLength)) {
                        
                        int length = (int) (attributes[i].end - attributes[i].value);
                        timestamp = [[NSString alloc] initWithBytes:attributes[i].value
                                                             length:length
                                                           encoding:NSUTF8StringEncoding];
                    }
                    if(0 == strncmp((const char*)attributes[i].localname, kUserAttributeName,
                                    kUserAttributeNameLength)) {
                        
                        int length = (int) (attributes[i].end - attributes[i].value);
                        user = [[NSString alloc] initWithBytes:attributes[i].value
                                                             length:length
                                                           encoding:NSUTF8StringEncoding];
                    }
                    if(0 == strncmp((const char*)attributes[i].localname, kVersionAttributeName,
                                    kVersionAttributeNameLength)) {
                        
                        int length = (int) (attributes[i].end - attributes[i].value);
                        version = [[NSString alloc] initWithBytes:attributes[i].value
                                                             length:length
                                                           encoding:NSUTF8StringEncoding];
                    }
                    if(0 == strncmp((const char*)attributes[i].localname, kUidAttributeName,
                                     kUidAttributeNameLength)) {
                        
                        int length = (int) (attributes[i].end - attributes[i].value);
                        uid = [[NSString alloc] initWithBytes:attributes[i].value
                                                             length:length
                                                           encoding:NSUTF8StringEncoding];
                    }
                    if(0 == strncmp((const char*)attributes[i].localname, kVisibleAttributeName,
                                     kVisibleAttributeNameLength)) {
                        
                        int length = (int) (attributes[i].end - attributes[i].value);
                        visible = [[NSString alloc] initWithBytes:attributes[i].value
                                                             length:length
                                                           encoding:NSUTF8StringEncoding];
                    }
                }
                [_currentParsedEntityInfo setChangeset:changeset];
                [_currentParsedEntityInfo setTimestamp:timestamp];
                [_currentParsedEntityInfo setUser:user];
                [_currentParsedEntityInfo setVersion:version];
                [_currentParsedEntityInfo setVisible:visible];
                [_currentParsedEntityInfo setUid:uid];
            }
        }
    }
    else
    {
        if (0 == strncmp((const char *)localname, kTagElementName, kTagElementNameLength))
        {
            __block NSString *key = @"";
            __block NSString *value = @"";
            for(int i = 0; i < attributeCount; i++) {
                if(0 == strncmp((const char*)attributes[i].localname, kKeyAttributeName,
                                kKeyAttributeNameLength)) {
                    
                    int length = (int) (attributes[i].end - attributes[i].value);
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        key = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding].xmlStringToString;
                    });
                }
                if(0 == strncmp((const char*)attributes[i].localname, kValueAttributeName,
                                kValueAttributeNameLength)) {
                    
                    int length = (int) (attributes[i].end - attributes[i].value);
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        value = [[NSString alloc] initWithBytes:attributes[i].value
                                                         length:length
                                                       encoding:NSUTF8StringEncoding].xmlStringToString;
                    });
                }
            }
            if (key.length > 0 && value.length > 0)
            {
                if (_convertTagsToLC)
                    [_currentParsedEntity putTag:key value:value];
                else
                    [_currentParsedEntity putTagNoLC:key value:value];
            }
            
        }
        else if (0 == strncmp((const char *)localname, kNdElementName, kNdElementNameLength))
        {
            long long identifier = [self getNumberValue:attributeCount attributes:attributes attrName:kRefAttributeName
                                        attrLength:kRefAttributeNameLength].longLongValue;
            if (identifier != -1 && [_currentParsedEntity isKindOfClass:OAWay.class])
                [((OAWay *)_currentParsedEntity) addNodeById:identifier];
        }
        else if (0 == strncmp((const char *)localname, kMemberElementName, kMemberElementNameLength))
        {
            long long identifier = [self getNumberValue:attributeCount attributes:attributes attrName:kRefAttributeName
                                        attrLength:kRefAttributeNameLength].longLongValue;
            if (identifier != -1 && [_currentParsedEntity isKindOfClass:OARelation.class])
            {
                NSString *entityTypeStr = @"";
                NSString *roleStr = @"";
                for(int i = 0; i < attributeCount; i++) {
                    if(0 == strncmp((const char*)attributes[i].localname, kTypeAttributeName,
                                    kTypeAttributeNameLength)) {
                        
                        int length = (int) (attributes[i].end - attributes[i].value);
                        entityTypeStr = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding];
                    }
                    if(0 == strncmp((const char*)attributes[i].localname, kRoleAttributeName,
                                    kRoleAttributeNameLength)) {
                        
                        int length = (int) (attributes[i].end - attributes[i].value);
                        roleStr = [[NSString alloc] initWithBytes:attributes[i].value
                                                         length:length
                                                       encoding:NSUTF8StringEncoding];
                    }
                }
                if (roleStr.length > 0 && entityTypeStr.length > 0)
                {
                    EOAEntityType type = [OAEntity typeFromString:entityTypeStr];
                    [((OARelation *)_currentParsedEntity) addMember:identifier entityType:type role:roleStr];
                }
            }
            
        }
        else
        {
            // this situation could be logged as unhandled
        }
    }
    
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI {
    EOAEntityType type = UNDEFINED;
    if (0 == strncmp((const char *)localname, kNodeElementName, kNodeElementNameLength))
        type = NODE;
    else if (0 == strncmp((const char *)localname, kWayElementName, kWayElementNameLength))
        type = WAY;
    else if (0 == strncmp((const char *)localname, kRelationElementName, kRelationElementNameLength))
        type = RELATION;
    if (0 == strncmp((const char *)localname, kModifyElementName, kModifyElementNameLength))
        _currentModify = 0;
    else if (0 == strncmp((const char *)localname, kCreateElementName, kCreateElementNameLength))
        _currentModify = 0;
    else if (0 == strncmp((const char *)localname, kDeleteElementName, kDeleteElementNameLength))
        _currentModify = 0;
    
    if (type != UNDEFINED) {
        if (_currentParsedEntity) {
            OAEntityId *entityId = [[OAEntityId alloc] initWithEntityType:type identifier:[_currentParsedEntity getId]];
            [_entities setObject:_currentParsedEntity forKey:entityId];
            if (_parseEntityInfo && _currentParsedEntityInfo)
                [_entityInfo setObject:_currentParsedEntityInfo forKey:entityId];
        }
        _currentParsedEntity = nil;
    }
}

- (void)charactersFound:(const xmlChar *)characters length:(int)length {
}

- (void)parsingError:(const char *)msg, ... {
    self.error = YES;
    _done = YES;
}

-(void)endDocument {
    
}

- (void) dealloc {
    
    xmlFreeParserCtxt(_xmlParserContext);
    _xmlParserContext = NULL;
    
    self.delegate = nil;
    _textToParse = nil;
    _entities = nil;
    _entityInfo = nil;
}

@end

#pragma mark SAX Parsing Callbacks

static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix,
                            const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces,
                            int nb_attributes, int nb_defaulted, const xmlChar **attributes) {
    [((__bridge OAOsmBaseStorage *)ctx) elementFound:localname prefix:prefix uri:URI
                                     namespaceCount:nb_namespaces namespaces:namespaces
                                     attributeCount:nb_attributes defaultAttributeCount:nb_defaulted
                                         attributes:(xmlSAX2Attributes*)attributes];
}

static void    endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix,
                             const xmlChar *URI) {
    [((__bridge OAOsmBaseStorage *)ctx) endElement:localname prefix:prefix uri:URI];
}

static void    charactersFoundSAX(void *ctx, const xmlChar *ch, int len) {
    [((__bridge OAOsmBaseStorage *)ctx) charactersFound:ch length:len];
}

static void errorEncounteredSAX(void *ctx, const char *msg, ...) {
    va_list argList;
    va_start(argList, msg);
    [((__bridge OAOsmBaseStorage *)ctx) parsingError:msg, argList];
}

static void endDocumentSAX(void *ctx) {
    [((__bridge OAOsmBaseStorage *)ctx) endDocument];
}

static xmlSAXHandler simpleSAXHandlerStruct = {
    NULL,                       /* internalSubset */
    NULL,                       /* isStandalone   */
    NULL,                       /* hasInternalSubset */
    NULL,                       /* hasExternalSubset */
    NULL,                       /* resolveEntity */
    NULL,                       /* getEntity */
    NULL,                       /* entityDecl */
    NULL,                       /* notationDecl */
    NULL,                       /* attributeDecl */
    NULL,                       /* elementDecl */
    NULL,                       /* unparsedEntityDecl */
    NULL,                       /* setDocumentLocator */
    NULL,                       /* startDocument */
    endDocumentSAX,             /* endDocument */
    NULL,                       /* startElement*/
    NULL,                       /* endElement */
    NULL,                       /* reference */
    charactersFoundSAX,         /* characters */
    NULL,                       /* ignorableWhitespace */
    NULL,                       /* processingInstruction */
    NULL,                       /* comment */
    NULL,                       /* warning */
    errorEncounteredSAX,        /* error */
    NULL,                       /* fatalError //: unused error() get all the errors */
    NULL,                       /* getParameterEntity */
    NULL,                       /* cdataBlock */
    NULL,                       /* externalSubset */
    XML_SAX2_MAGIC,             // initialized? not sure what it means just do it
    NULL,                       // private
    startElementSAX,            /* startElementNs */
    endElementSAX,              /* endElementNs */
    NULL,                       /* serror */
};
