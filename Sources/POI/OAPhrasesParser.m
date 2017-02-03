//
//  OAPhrasesParser.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPhrasesParser.h"

// called from libxml functions
@interface OAPhrasesParser (LibXMLParserMethods)

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


@implementation OAPhrasesParser {
    
    // libxml2 parsing stuff
    NSString *_currentName;
    NSString *_currentString;
    BOOL _parsingString;
    
    NSMutableDictionary *_dictionary;
    
    BOOL _done;
    xmlParserCtxtPtr _xmlParserContext;
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

- (void)getPhrasesSync:(NSString*)fileName {
    
    _dictionary = [NSMutableDictionary dictionary];
    self.fileName = fileName;
    [self parseForData];
}

- (void)getPhrasesAsync:(NSString*)fileName {
    
    _dictionary = [NSMutableDictionary dictionary];
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
        
        self.phrases = [NSDictionary dictionaryWithDictionary:_dictionary];
        
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
 
	<string name="poi_shop">Shop</string>
	<string name="poi_emergency">Emergency</string>
	<string name="poi_transportation">Transportation</string>
 
 */

#pragma mark Parsing Function Callback Methods

static const char *kStringElementName = "string";
static NSUInteger kStringElementNameLength = 7;

static const char *kNameAttributeName = "name";
static NSUInteger kNameAttributeNameLength = 5;


- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix
                 uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount
          namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount
defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes {
    
    if(0 == strncmp((const char *)localname, kStringElementName, kStringElementNameLength)) {
        
        for(int i = 0;i < attributeCount;i++) {
            
            if(0 == strncmp((const char*)attributes[i].localname, kNameAttributeName,
                            kNameAttributeNameLength)) {
                
                int length = (int) (attributes[i].end - attributes[i].value);
                _currentName = [[NSString alloc] initWithBytes:attributes[i].value
                                                                length:length
                                                              encoding:NSUTF8StringEncoding];
                if ([_currentName isEqualToString:@"poi_amenity_atm"])
                    _currentName = @"poi_osmand_amenity_atm";
            }
        }
        _parsingString = YES;
    }
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI {
    
    if(0 == strncmp((const char *)localname, kStringElementName, kStringElementNameLength)) {
        
        if (_currentString && _currentName)
            [_dictionary setObject:_currentString forKey:_currentName];
        
        _currentString = nil;
        _currentName = nil;
        _parsingString = NO;
    }
}

- (void)charactersFound:(const xmlChar *)characters length:(int)length {
    if(_parsingString) {
        NSString *value = [[[NSString alloc] initWithBytes:(const void *)characters
                                                   length:length encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceCharacterSet]];
        
        if (_currentString)
            _currentString = [NSString stringWithFormat:@"%@ %@", _currentString, value];
        else
            _currentString = value;
    }
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
    self.phrases = nil;
}

@end


#pragma mark SAX Parsing Callbacks

static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix,
                            const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces,
                            int nb_attributes, int nb_defaulted, const xmlChar **attributes) {
    [((__bridge OAPhrasesParser *)ctx) elementFound:localname prefix:prefix uri:URI
                                 namespaceCount:nb_namespaces namespaces:namespaces
                                 attributeCount:nb_attributes defaultAttributeCount:nb_defaulted
                                     attributes:(xmlSAX2Attributes*)attributes];
}

static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix,
                          const xmlChar *URI) {
    [((__bridge OAPhrasesParser *)ctx) endElement:localname prefix:prefix uri:URI];
}

static void	charactersFoundSAX(void *ctx, const xmlChar *ch, int len) {
    [((__bridge OAPhrasesParser *)ctx) charactersFound:ch length:len];
}

static void errorEncounteredSAX(void *ctx, const char *msg, ...) {
    va_list argList;
    va_start(argList, msg);
    [((__bridge OAPhrasesParser *)ctx) parsingError:msg, argList];
}

static void endDocumentSAX(void *ctx) {
    [((__bridge OAPhrasesParser *)ctx) endDocument];
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

