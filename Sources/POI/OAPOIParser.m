//
//  OAPOIParser.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOIParser.h"
#import "OAPOI.h"

// called from libxml functions
@interface OAPOIParser (LibXMLParserMethods)

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


@implementation OAPOIParser {

    NSString *_currentCategoryName;
    NSString *_currentFilterName;
    NSString *_defaultTagName;
    
    NSMutableArray *_poiItems;
    NSMutableDictionary *_poisByCategory;
}

- (NSOperationQueue *)retrieverQueue {
    if(nil == _retrieverQueue) {
        // lazy creation of the queue for retrieving the poi data
        _retrieverQueue = [[NSOperationQueue alloc] init];
        _retrieverQueue.maxConcurrentOperationCount = 1;
    }
    return _retrieverQueue;
}

- (void)getPOIDataSync:(NSString*)poiFileName {
    
    _poiItems = [NSMutableArray array];
    _poisByCategory = [NSMutableDictionary dictionary];
    self.fileName = poiFileName;
    [self parseForData];
}

- (void)getPOIDataAsync:(NSString*)poiFileName {
    
    _poiItems = [[NSMutableArray alloc] init];
    _poisByCategory = [NSMutableDictionary dictionary];
    self.fileName = poiFileName;
    
    // make an operation so we can push it into the queue
    SEL method = @selector(parseForData);
    NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self
                                                                     selector:method
                                                                       object:nil];
    [self.retrieverQueue addOperation:op];
}

- (BOOL)parseWithLibXML2Parser {
    BOOL success = NO;
    self.error = NO;
    
    _xmlParserContext = xmlCreatePushParserCtxt(&simpleSAXHandlerStruct, (__bridge void *)(self), NULL, 0, NULL);
    
    NSData *poiData = [NSData dataWithContentsOfFile:self.fileName];
    xmlParseChunk(_xmlParserContext, (const char *)[poiData bytes], (int)[poiData length], 0);
    xmlParseChunk(_xmlParserContext, NULL, 0, 1);
    _done = YES;
    
    if(self.error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(encounteredError:)]) {
            [self.delegate encounteredError:nil];
        }
    } else {
        
        self.pois = [NSArray arrayWithArray:_poiItems];
        self.poisByCategory = [NSDictionary dictionaryWithDictionary:_poisByCategory];
        
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
        return success;
    }
}

/*
 
 <poi_category name="shop" default_tag="shop">
   <poi_filter name="shop_food">
     <poi_type name="bakery" tag="shop" value="bakery"></poi_type>
 
 */

#pragma mark Parsing Function Callback Methods

static const char *kPoiCategoryElementName = "poi_category";
static NSUInteger kPoiCategoryElementNameLength = 13;
static const char *kPoiFilterElementName = "poi_filter";
static NSUInteger kPoiFilterElementNameLength = 11;
static const char *kPoiTypeElementName = "poi_type";
static NSUInteger kPoiTypeElementNameLength = 9;

static const char *kNameAttributeName = "name";
static NSUInteger kNameAttributeNameLength = 5;
static const char *kDefaultTagAttributeName = "default_tag";
static NSUInteger kDefaultTagAttributeNameLength = 12;
static const char *kTagAttributeName = "tag";
static NSUInteger kTagAttributeNameLength = 4;
static const char *kValueAttributeName = "value";
static NSUInteger kValueAttributeNameLength = 6;


- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix
                 uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount
          namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount
defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes {
    
    if(0 == strncmp((const char *)localname, kPoiCategoryElementName, kPoiCategoryElementNameLength)) {
        
        for(int i = 0;i < attributeCount;i++) {

            if(0 == strncmp((const char*)attributes[i].localname, kNameAttributeName,
                            kNameAttributeNameLength)) {
                
                int length = (int) (attributes[i].end - attributes[i].value);
                _currentCategoryName = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding];
                
            } else if(0 == strncmp((const char*)attributes[i].localname, kDefaultTagAttributeName,
                                   kDefaultTagAttributeNameLength)) {
                
                int length = (int) (attributes[i].end - attributes[i].value);
                _defaultTagName = [[NSString alloc] initWithBytes:attributes[i].value
                                                               length:length
                                                             encoding:NSUTF8StringEncoding];
            }
        }

    } else if(0 == strncmp((const char *)localname, kPoiFilterElementName, kPoiFilterElementNameLength)) {
        
        for(int i = 0;i < attributeCount;i++) {
            
            if(0 == strncmp((const char*)attributes[i].localname, kNameAttributeName,
                            kNameAttributeNameLength)) {
                
                int length = (int) (attributes[i].end - attributes[i].value);
                _currentFilterName = [[NSString alloc] initWithBytes:attributes[i].value
                                                               length:length
                                                             encoding:NSUTF8StringEncoding];
            }
        }
        
    } else if(0 == strncmp((const char *)localname, kPoiTypeElementName, kPoiTypeElementNameLength)) {
        
        self.currentPOIItem = [[OAPOI alloc] init];
        _currentPOIItem.category = _currentCategoryName;
        _currentPOIItem.filter = _currentFilterName;
        _currentPOIItem.tag = _defaultTagName;
        
        for(int i = 0;i < attributeCount;i++) {

            if(0 == strncmp((const char*)attributes[i].localname, kNameAttributeName,
                            kNameAttributeNameLength)) {
                
                int length = (int) (attributes[i].end - attributes[i].value);
                NSString *name = [[NSString alloc] initWithBytes:attributes[i].value
                                                               length:length
                                                             encoding:NSUTF8StringEncoding];
                _currentPOIItem.name = name;
                
            } else if(0 == strncmp((const char*)attributes[i].localname, kTagAttributeName,
                                   kTagAttributeNameLength)) {
                
                int length = (int) (attributes[i].end - attributes[i].value);
                NSString *tag = [[NSString alloc] initWithBytes:attributes[i].value
                                                          length:length
                                                        encoding:NSUTF8StringEncoding];

                _currentPOIItem.tag = tag;

            } else if(0 == strncmp((const char*)attributes[i].localname, kValueAttributeName,
                                   kValueAttributeNameLength)) {
                
                int length = (int) (attributes[i].end - attributes[i].value);
                NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                         length:length
                                                       encoding:NSUTF8StringEncoding];
                _currentPOIItem.value = value;
            }
            
        }
        [_poiItems addObject:_currentPOIItem];
        NSMutableArray *p = [_poisByCategory objectForKey:_currentCategoryName];
        if (!p) {
            p = [NSMutableArray arrayWithObject:_currentPOIItem];
            [_poisByCategory setObject:p forKey:_currentCategoryName];
        } else {
            [p addObject:_currentPOIItem];
        }
    }
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI {

    if(0 == strncmp((const char *)localname, kPoiFilterElementName, kPoiFilterElementNameLength)) {
        _currentFilterName = nil;
        
    } else if(0 == strncmp((const char *)localname, kPoiCategoryElementName, kPoiCategoryElementNameLength)) {
        _currentCategoryName = nil;
        
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
    self.fileName = nil;
    self.pois = nil;
    self.poisByCategory = nil;
}

@end


#pragma mark SAX Parsing Callbacks

static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix,
                            const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces,
                            int nb_attributes, int nb_defaulted, const xmlChar **attributes) {
    [((__bridge OAPOIParser *)ctx) elementFound:localname prefix:prefix uri:URI
                               namespaceCount:nb_namespaces namespaces:namespaces
                               attributeCount:nb_attributes defaultAttributeCount:nb_defaulted
                                   attributes:(xmlSAX2Attributes*)attributes];
}

static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix,
                          const xmlChar *URI) {
    [((__bridge OAPOIParser *)ctx) endElement:localname prefix:prefix uri:URI];
}

static void	charactersFoundSAX(void *ctx, const xmlChar *ch, int len) {
    [((__bridge OAPOIParser *)ctx) charactersFound:ch length:len];
}

static void errorEncounteredSAX(void *ctx, const char *msg, ...) {
    va_list argList;
    va_start(argList, msg);
    [((__bridge OAPOIParser *)ctx) parsingError:msg, argList];
}

static void endDocumentSAX(void *ctx) {
    [((__bridge OAPOIParser *)ctx) endDocument];
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

