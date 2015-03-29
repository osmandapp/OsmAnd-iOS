//
//  OAPOIParser.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOIParser.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIFilter.h"

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
    
    NSMutableArray *_pTypes;
    NSMutableDictionary *_pCategories;
    NSMutableDictionary *_pFilters;
    
    xmlParserCtxtPtr _xmlParserContext;
    
    BOOL _done;

    OAPOIType *_currentPOIType;
    OAPOICategory *_currentPOICategory;
    OAPOIFilter *_currentPOIFilter;
    NSMutableString *_propertyValue;
    NSOperationQueue *_retrieverQueue;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _retrieverQueue = [[NSOperationQueue alloc] init];
        _retrieverQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void)getPOITypesSync:(NSString*)fileName {
    
    _pTypes = [NSMutableArray array];
    _pCategories = [NSMutableDictionary dictionary];
    _pFilters = [NSMutableDictionary dictionary];

    self.fileName = fileName;
    [self parseForData];
}

- (void)getPOITypesAsync:(NSString*)fileName {
    
    _pTypes = [NSMutableArray array];
    _pCategories = [NSMutableDictionary dictionary];
    _pFilters = [NSMutableDictionary dictionary];

    self.fileName = fileName;
    
    // make an operation so we can push it into the queue
    SEL method = @selector(parseForData);
    NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self
                                                                     selector:method
                                                                       object:nil];
    [_retrieverQueue addOperation:op];
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
        
        self.poiTypes = [NSArray arrayWithArray:_pTypes];
        self.poiCategories = [NSDictionary dictionaryWithDictionary:_pCategories];
        self.poiFilters = [NSDictionary dictionaryWithDictionary:_pFilters];
        
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
        
        _currentPOICategory = [[OAPOICategory alloc] init];

        for(int i = 0;i < attributeCount;i++) {

            if(0 == strncmp((const char*)attributes[i].localname, kNameAttributeName,
                            kNameAttributeNameLength)) {
                
                int length = (int) (attributes[i].end - attributes[i].value);
                _currentPOICategory.name = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding];
                
            } else if(0 == strncmp((const char*)attributes[i].localname, kDefaultTagAttributeName,
                                   kDefaultTagAttributeNameLength)) {
                
                int length = (int) (attributes[i].end - attributes[i].value);
                _currentPOICategory.tag = [[NSString alloc] initWithBytes:attributes[i].value
                                                               length:length
                                                             encoding:NSUTF8StringEncoding];
            }
            
        }

    } else if(0 == strncmp((const char *)localname, kPoiFilterElementName, kPoiFilterElementNameLength)) {
        
        _currentPOIFilter = [[OAPOIFilter alloc] init];
        _currentPOIFilter.category = _currentPOICategory.name;

        for(int i = 0;i < attributeCount;i++) {
            
            if(0 == strncmp((const char*)attributes[i].localname, kNameAttributeName,
                            kNameAttributeNameLength)) {
                
                int length = (int) (attributes[i].end - attributes[i].value);
                _currentPOIFilter.name = [[NSString alloc] initWithBytes:attributes[i].value
                                                               length:length
                                                             encoding:NSUTF8StringEncoding];
            }
        }
        
    } else if(0 == strncmp((const char *)localname, kPoiTypeElementName, kPoiTypeElementNameLength)) {
        
        _currentPOIType = [[OAPOIType alloc] init];
        _currentPOIType.category = _currentPOICategory.name;
        _currentPOIType.filter = _currentPOIFilter ? _currentPOIFilter.name : nil;
        _currentPOIType.tag = _currentPOICategory.tag;
        
        for(int i = 0;i < attributeCount;i++) {

            if(0 == strncmp((const char*)attributes[i].localname, kNameAttributeName,
                            kNameAttributeNameLength)) {
                
                int length = (int) (attributes[i].end - attributes[i].value);
                NSString *name = [[NSString alloc] initWithBytes:attributes[i].value
                                                               length:length
                                                             encoding:NSUTF8StringEncoding];
                _currentPOIType.name = name;
                
            } else if(0 == strncmp((const char*)attributes[i].localname, kTagAttributeName,
                                   kTagAttributeNameLength)) {
                
                int length = (int) (attributes[i].end - attributes[i].value);
                NSString *tag = [[NSString alloc] initWithBytes:attributes[i].value
                                                          length:length
                                                        encoding:NSUTF8StringEncoding];

                _currentPOIType.tag = tag;

            } else if(0 == strncmp((const char*)attributes[i].localname, kValueAttributeName,
                                   kValueAttributeNameLength)) {
                
                int length = (int) (attributes[i].end - attributes[i].value);
                NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                         length:length
                                                       encoding:NSUTF8StringEncoding];
                _currentPOIType.value = value;
            }
            
        }
        [_pTypes addObject:_currentPOIType];
        
        // Category
        OAPOICategory *key;
        for (OAPOICategory *k in _pCategories.allKeys)
            if ([k.name isEqualToString:_currentPOICategory.name])
                key = k;
        
        if (!key) {
            NSMutableArray *p = [NSMutableArray arrayWithObject:_currentPOIType];
            [_pCategories setObject:p forKey:_currentPOICategory];
        } else {
            NSMutableArray *p = [_pCategories objectForKey:key];
            [p addObject:_currentPOIType];
        }
        
        // Filter
        if (_currentPOIFilter)
        {
            OAPOIFilter *filterKey;
            for (OAPOIFilter *k in _pFilters.allKeys)
                if ([k.name isEqualToString:_currentPOIFilter.name])
                    filterKey = k;
            
            if (!filterKey) {
                NSMutableArray *p = [NSMutableArray arrayWithObject:_currentPOIType];
                [_pFilters setObject:p forKey:_currentPOIFilter];
            } else {
                NSMutableArray *p = [_pFilters objectForKey:filterKey];
                [p addObject:_currentPOIType];
            }
        }
    }
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI {

    if(0 == strncmp((const char *)localname, kPoiFilterElementName, kPoiFilterElementNameLength)) {
        _currentPOIFilter = nil;
        
    } else if(0 == strncmp((const char *)localname, kPoiCategoryElementName, kPoiCategoryElementNameLength)) {
        _currentPOICategory = nil;

    } else if(0 == strncmp((const char *)localname, kPoiTypeElementName, kPoiTypeElementNameLength)) {
        _currentPOIType = nil;
    
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
    self.poiTypes = nil;
    self.poiCategories = nil;
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

