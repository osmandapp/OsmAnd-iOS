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
#import "OAAppSettings.h"

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
    
    NSMutableArray<OAPOIType *> *_pTypes;
    NSMapTable<NSString *, OAPOIType *> *_pTypesByName;
    NSMutableArray<OAPOICategory *> *_pCategories;
    NSMutableArray<OAPOIFilter *> *_pFilters;
    NSMutableArray<OAPOIType *> *_textPoiAdditionals;
    NSMutableDictionary<NSString *, NSString *> *_poiAdditionalCategoryIcons;

    xmlParserCtxtPtr _xmlParserContext;
    
    BOOL _done;

    OAPOIType *_currentPOIType;
    OAPOICategory *_currentPOICategory;
    OAPOIFilter *_currentPOIFilter;
    NSString *_currentPOIAdditionalCategory;
    NSMutableString *_propertyValue;
    NSOperationQueue *_retrieverQueue;

    NSMutableSet<NSString *> *_currentCategoryPoiAdditionalsCategories;
    NSMutableSet<NSString *> *_currentFilterPoiAdditionalsCategories;
    NSMutableSet<NSString *> *_currentTypePoiAdditionalsCategories;
    NSMapTable<OAPOIBaseType *, NSMutableSet<NSString *> *> *_abstractTypeAdditionalCategories;
    NSMapTable<NSString *, NSMutableArray<OAPOIType *> *> *_categoryPoiAdditionalMap;
    NSMapTable<NSString *, NSString *> *_deprecatedTags;
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

- (void)commonInit:(NSString*)fileName
{
    _pTypes = [NSMutableArray array];
    _pTypesByName = [NSMapTable strongToStrongObjectsMapTable];
    _pCategories = [NSMutableArray array];
    _pFilters = [NSMutableArray array];
    _textPoiAdditionals = [NSMutableArray array];
    _poiAdditionalCategoryIcons = [NSMutableDictionary dictionary];
    _otherMapCategory = [[OAPOICategory alloc] initWithName:@"Other"];
    [_pCategories addObject:_otherMapCategory];
    
    _currentCategoryPoiAdditionalsCategories = [NSMutableSet set];
    _currentFilterPoiAdditionalsCategories = [NSMutableSet set];
    _currentTypePoiAdditionalsCategories = [NSMutableSet set];
    _abstractTypeAdditionalCategories = [NSMapTable strongToStrongObjectsMapTable];
    _categoryPoiAdditionalMap = [NSMapTable strongToStrongObjectsMapTable];
    _deprecatedTags = [NSMapTable strongToStrongObjectsMapTable];

    self.fileName = fileName;
}

- (void)getPOITypesSync:(NSString*)fileName
{
    [self commonInit:fileName];
    [self parseData];
}

- (void)getPOITypesAsync:(NSString*)fileName
{
    [self commonInit:fileName];
    
    // make an operation so we can push it into the queue
    SEL method = @selector(parseForData);
    NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self
                                                                     selector:method
                                                                       object:nil];
    [_retrieverQueue addOperation:op];
}

- (BOOL)parseWithLibXML2Parser
{
    BOOL success = NO;
    self.error = NO;
    
    _xmlParserContext = xmlCreatePushParserCtxt(&simpleSAXHandlerStruct, (__bridge void *)(self), NULL, 0, NULL);
    
    NSData *poiData = [NSData dataWithContentsOfFile:self.fileName];
    xmlParseChunk(_xmlParserContext, (const char *)[poiData bytes], (int)[poiData length], 0);
    xmlParseChunk(_xmlParserContext, NULL, 0, 1);

    NSEnumerator<OAPOIBaseType *> *keys = _abstractTypeAdditionalCategories.keyEnumerator;
    for (OAPOIBaseType *key in keys)
    {
        NSMutableSet<NSString *> *value = [_abstractTypeAdditionalCategories objectForKey:key];
        for (NSString *category in value)
        {
            NSArray<OAPOIType *> *poiAdditionals = [_categoryPoiAdditionalMap objectForKey:category];
            if (poiAdditionals)
            {
                for (OAPOIType *poiType in poiAdditionals)
                    [self buildPoiAdditionalReference:poiType parent:key];
            }
        }
    }
        
    _done = YES;
    
    if (self.error)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(encounteredError:)])
        {
            [self.delegate encounteredError:nil];
        }
    }
    else
    {
        self.poiTypes = _pTypes;
        self.poiTypesByName = _pTypesByName;
        self.poiCategories = _pCategories;
        self.poiFilters = _pFilters;
        self.textPoiAdditionals = _textPoiAdditionals;
        self.poiAdditionalCategoryIcons = _poiAdditionalCategoryIcons;
        self.deprecatedTags = _deprecatedTags;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(parserFinished)])
        {
            [(id)[self delegate] performSelectorOnMainThread:@selector(parserFinished)
                                                  withObject:nil
                                               waitUntilDone:NO];
        }
        
        success = YES;
    }
    return success;
}

- (OAPOIType *) buildPoiAdditionalReference:(OAPOIType *)poiAdditional  parent:(OAPOIBaseType *)parent
{
    OAPOICategory *lastCategory = nil;
    OAPOIFilter *lastFilter = nil;
    OAPOIType *lastType = nil;
    OAPOIType *ref = nil;
    if ([parent isKindOfClass:[OAPOICategory class]])
    {
        lastCategory = (OAPOICategory *)parent;
        ref = [[OAPOIType alloc] initWithName:poiAdditional.name category:lastCategory];
    }
    else if ([parent isKindOfClass:[OAPOIFilter class]])
    {
        lastFilter = (OAPOIFilter *)parent;
        ref = [[OAPOIType alloc] initWithName:poiAdditional.name category:lastCategory filter:lastFilter];
    }
    else if ([parent isKindOfClass:[OAPOIType class]])
    {
        lastType = (OAPOIType *)parent;
        ref = [[OAPOIType alloc] initWithName:poiAdditional.name category:lastType.category filter:lastType.filter];
    }
    if (!ref)
        return nil;

    if (poiAdditional.reference)
        [ref setReferenceType:poiAdditional.referenceType];
    else
        [ref setReferenceType:poiAdditional];
    
    ref.baseLangType = poiAdditional.baseLangType;
    ref.lang = poiAdditional.lang;
    [ref setAdditional:(lastType ? lastType : (lastFilter ? lastFilter : lastCategory))];
    ref.top = poiAdditional.top;
    ref.isText = poiAdditional.isText;
    ref.order = poiAdditional.order;
    ref.tag = poiAdditional.tag;
    ref.nonEditableOsm = poiAdditional.nonEditableOsm;
    ref.value = poiAdditional.value;
    ref.tag2 = poiAdditional.tag2;
    ref.value2 = poiAdditional.value2;
    ref.editTag = poiAdditional.editTag;
    ref.editValue = poiAdditional.editValue;
    ref.poiAdditionalCategory = poiAdditional.poiAdditionalCategory;
    ref.filterOnly = poiAdditional.filterOnly;
    if (lastType)
        [lastType addPoiAdditional:ref];
    else if (lastFilter)
        [lastFilter addPoiAdditional:ref];
    else if (lastCategory)
        [lastCategory addPoiAdditional:ref];
    
    if (ref.isText)
        [_textPoiAdditionals addObject:ref];

    return ref;
}

- (BOOL)parseData
{
    BOOL success = NO;
    
    @autoreleasepool
    {
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
static const char *kPoiReferenceElementName = "poi_reference";
static NSUInteger kPoiReferenceElementNameLength = 14;
static const char *kPoiAdditionalElementName = "poi_additional";
static NSUInteger kPoiAdditionalElementNameLength = 15;
static const char *kPoiAdditionalCategoryElementName = "poi_additional_category";
static NSUInteger kPoiAdditionalCategoryElementNameLength = 24;

static const char *kNameAttributeName = "name";
static NSUInteger kNameAttributeNameLength = 5;
static const char *kDefaultTagAttributeName = "default_tag";
static NSUInteger kDefaultTagAttributeNameLength = 12;
static const char *kTagAttributeName = "tag";
static NSUInteger kTagAttributeNameLength = 4;
static const char *kValueAttributeName = "value";
static NSUInteger kValueAttributeNameLength = 6;
static const char *kTag2AttributeName = "tag2";
static NSUInteger kTag2AttributeNameLength = 5;
static const char *kValue2AttributeName = "value2";
static NSUInteger kValue2AttributeNameLength = 7;
static const char *kNoEditAttributeName = "no_edit";
static NSUInteger kNoEditAttributeNameLength = 8;
static const char *kEditTagAttributeName = "edit_tag";
static NSUInteger kEditTagAttributeNameLength = 9;
static const char *kEditValueAttributeName = "edit_value";
static NSUInteger kEditValueAttributeNameLength = 11;
static const char *kTopAttributeName = "top";
static NSUInteger kTopAttributeNameLength = 4;
static const char *kMapAttributeName = "map";
static NSUInteger kMapAttributeNameLength = 4;
static const char *kOrderAttributeName = "order";
static NSUInteger kOrderAttributeNameLength = 6;
static const char *kTypeAttributeName = "type";
static NSUInteger kTypeAttributeNameLength = 5;
static const char *kLangAttributeName = "lang";
static NSUInteger kLangAttributeNameLength = 5;
static const char *kPoiAdditionalCategoryAttributeName = "poi_additional_category";
static NSUInteger kPoiAdditionalCategoryAttributeNameLength = 24;
static const char *kExcludedPoiAdditionalCategoryAttributeName = "excluded_poi_additional_category";
static NSUInteger kExcludedPoiAdditionalCategoryAttributeNameLength = 33;
static const char *kFilterOnlyAttributeName = "filter_only";
static NSUInteger kFilterOnlyAttributeNameLength = 12;
static const char *kIconAttributeName = "icon";
static NSUInteger kIconAttributeNameLength = 5;
static const char *kDeprecatedOfAttributeName = "deprecated_of";
static NSUInteger kDeprecatedOfAttributeNameLength = 14;


- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix
                 uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount
          namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount
defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
    if (0 == strncmp((const char *)localname, kPoiCategoryElementName, kPoiCategoryElementNameLength))
    {
        NSString *name = nil;
        NSString *tag = nil;
        BOOL top = NO;
        BOOL nonEditable = NO;
        NSArray<NSString *> *poiAdditionalCategories = nil;
        NSArray<NSString *> *excludedPoiAdditionalCategories = nil;
        
        for (int i = 0; i < attributeCount; i++)
        {
            if (0 == strncmp((const char*)attributes[i].localname, kNameAttributeName,
                            kNameAttributeNameLength))
            {
                int length = (int) (attributes[i].end - attributes[i].value);
                name = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding];
            }
            else if (0 == strncmp((const char*)attributes[i].localname, kDefaultTagAttributeName,
                                   kDefaultTagAttributeNameLength))
            {
                int length = (int) (attributes[i].end - attributes[i].value);
                tag = [[NSString alloc] initWithBytes:attributes[i].value
                                                               length:length
                                                             encoding:NSUTF8StringEncoding];
            }
            else if (0 == strncmp((const char*)attributes[i].localname, kTopAttributeName,
                                  kTopAttributeNameLength))
            {
                int length = (int) (attributes[i].end - attributes[i].value);
                NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                           length:length
                                                         encoding:NSUTF8StringEncoding];
                
                top = [[value lowercaseString] isEqualToString:@"true"];
            }
            else if (0 == strncmp((const char*)attributes[i].localname, kNoEditAttributeName,
                                  kNoEditAttributeNameLength))
            {
                int length = (int) (attributes[i].end - attributes[i].value);
                nonEditable = [[[NSString alloc] initWithBytes:attributes[i].value
                                                        length:length
                                                      encoding:NSUTF8StringEncoding] isEqualToString:@"true"];
            }
            else if (0 == strncmp((const char*)attributes[i].localname, kPoiAdditionalCategoryAttributeName,
                                  kPoiAdditionalCategoryAttributeNameLength))
            {
                int length = (int) (attributes[i].end - attributes[i].value);
                NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                           length:length
                                                         encoding:NSUTF8StringEncoding];
                
                poiAdditionalCategories = [value componentsSeparatedByString:@","];
            }
            else if (0 == strncmp((const char*)attributes[i].localname, kExcludedPoiAdditionalCategoryAttributeName,
                                  kExcludedPoiAdditionalCategoryAttributeNameLength))
            {
                int length = (int) (attributes[i].end - attributes[i].value);
                NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                           length:length
                                                         encoding:NSUTF8StringEncoding];
                
                excludedPoiAdditionalCategories = [value componentsSeparatedByString:@","];
            }
        }

        _currentPOICategory = [[OAPOICategory alloc] initWithName:name];
        _currentPOICategory.tag = tag;
        _currentPOICategory.top = top;
        _currentPOICategory.nonEditableOsm = nonEditable;
        
        if (poiAdditionalCategories.count > 0)
            [_currentCategoryPoiAdditionalsCategories addObjectsFromArray:poiAdditionalCategories];
        if (excludedPoiAdditionalCategories.count > 0)
        {
            [_currentPOICategory addExcludedPoiAdditionalCategories:excludedPoiAdditionalCategories];
            [_currentCategoryPoiAdditionalsCategories minusSet:[NSSet setWithArray:_currentPOICategory.excludedPoiAdditionalCategories]];
        }
        
        if (![_pCategories containsObject:_currentPOICategory])
        {
            [_pCategories addObject:_currentPOICategory];
        }
    }
    else if (0 == strncmp((const char *)localname, kPoiFilterElementName, kPoiFilterElementNameLength))
    {
        NSString *name = nil;
        BOOL top = NO;
        NSArray<NSString *> *poiAdditionalCategories = nil;
        NSArray<NSString *> *excludedPoiAdditionalCategories = nil;

        for (int i = 0; i < attributeCount; i++)
        {
            if (0 == strncmp((const char*)attributes[i].localname, kNameAttributeName,
                            kNameAttributeNameLength))
            {
                int length = (int) (attributes[i].end - attributes[i].value);
                name = [[NSString alloc] initWithBytes:attributes[i].value
                                                               length:length
                                                             encoding:NSUTF8StringEncoding];
            }
            else if (0 == strncmp((const char*)attributes[i].localname, kTopAttributeName,
                                  kTopAttributeNameLength))
            {
                int length = (int) (attributes[i].end - attributes[i].value);
                NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                           length:length
                                                         encoding:NSUTF8StringEncoding];
                
                top = [[value lowercaseString] isEqualToString:@"true"];
            }
            else if (0 == strncmp((const char*)attributes[i].localname, kPoiAdditionalCategoryAttributeName,
                                  kPoiAdditionalCategoryAttributeNameLength))
            {
                int length = (int) (attributes[i].end - attributes[i].value);
                NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                           length:length
                                                         encoding:NSUTF8StringEncoding];
                
                poiAdditionalCategories = [value componentsSeparatedByString:@","];
            }
            else if (0 == strncmp((const char*)attributes[i].localname, kExcludedPoiAdditionalCategoryAttributeName,
                                  kExcludedPoiAdditionalCategoryAttributeNameLength))
            {
                int length = (int) (attributes[i].end - attributes[i].value);
                NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                           length:length
                                                         encoding:NSUTF8StringEncoding];
                
                excludedPoiAdditionalCategories = [value componentsSeparatedByString:@","];
            }
        }
        
        _currentPOIFilter = [[OAPOIFilter alloc] initWithName:name category:_currentPOICategory];
        _currentPOIFilter.top = top;
        
        [_currentFilterPoiAdditionalsCategories addObjectsFromArray:[_currentCategoryPoiAdditionalsCategories allObjects]];
        if (poiAdditionalCategories.count > 0)
            [_currentFilterPoiAdditionalsCategories addObjectsFromArray:poiAdditionalCategories];
        if (excludedPoiAdditionalCategories.count > 0)
        {
            [_currentPOIFilter addExcludedPoiAdditionalCategories:excludedPoiAdditionalCategories];
            [_currentFilterPoiAdditionalsCategories minusSet:[NSSet setWithArray:_currentPOIFilter.excludedPoiAdditionalCategories]];
        }

        if (_currentPOICategory)
        {
            [_currentPOICategory addPoiFilter:_currentPOIFilter];
        }

        if (![_pFilters containsObject:_currentPOIFilter])
        {
            [_pFilters addObject:_currentPOIFilter];
        }
    }
    else if (0 == strncmp((const char *)localname, kPoiTypeElementName, kPoiTypeElementNameLength) ||
             0 == strncmp((const char *)localname, kPoiReferenceElementName, kPoiReferenceElementNameLength))
    {
        _currentPOIType = [self parsePoiType:localname attributeCount:attributeCount attributes:attributes];
    }
    else if (0 == strncmp((const char *)localname, kPoiAdditionalCategoryElementName, kPoiAdditionalCategoryElementNameLength))
    {
        NSString *name = nil;
        NSString *icon = nil;
        for (int i = 0; i < attributeCount; i++)
        {
            if (0 == strncmp((const char*)attributes[i].localname, kNameAttributeName,
                             kNameAttributeNameLength))
            {
                int length = (int) (attributes[i].end - attributes[i].value);
                name = [[NSString alloc] initWithBytes:attributes[i].value
                                                length:length
                                              encoding:NSUTF8StringEncoding];
            }
            else if (0 == strncmp((const char*)attributes[i].localname, kIconAttributeName,
                             kIconAttributeNameLength))
            {
                int length = (int) (attributes[i].end - attributes[i].value);
                icon = [[NSString alloc] initWithBytes:attributes[i].value
                                                length:length
                                              encoding:NSUTF8StringEncoding];
            }

            if (icon)
                [_poiAdditionalCategoryIcons setObject:icon forKey:name];
        }
        _currentPOIAdditionalCategory = name;
    }
    else if (0 == strncmp((const char *)localname, kPoiAdditionalElementName, kPoiAdditionalElementNameLength))
    {
        BOOL lang = NO;
        
        for (int i = 0; i < attributeCount; i++)
        {
            if (0 == strncmp((const char*)attributes[i].localname, kLangAttributeName,
                             kLangAttributeNameLength))
            {
                int length = (int) (attributes[i].end - attributes[i].value);
                NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                           length:length
                                                         encoding:NSUTF8StringEncoding];
                
                lang = [[value lowercaseString] isEqualToString:@"true"];
            }
        }
        
        OAPOIType *baseType = [self parsePoiAdditional:localname attributeCount:attributeCount attributes:attributes lang:nil baseType:nil];
        if (lang)
        {
            for (NSString *lng in [[OAAppSettings sharedManager] mapLanguages])
            {
                [self parsePoiAdditional:localname attributeCount:attributeCount attributes:attributes lang:lng baseType:baseType];
            }
            [self parsePoiAdditional:localname attributeCount:attributeCount attributes:attributes lang:@"en" baseType:nil];
        }
        
        if (_currentPOIAdditionalCategory)
        {
            NSMutableArray<OAPOIType *> *categoryAdditionals = [_categoryPoiAdditionalMap objectForKey:_currentPOIAdditionalCategory];
            if (!categoryAdditionals)
            {
                categoryAdditionals = [NSMutableArray array];
                [_categoryPoiAdditionalMap setObject:categoryAdditionals forKey:_currentPOIAdditionalCategory];
            }
            [categoryAdditionals addObject:baseType];
        }
    }
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
    if(0 == strncmp((const char *)localname, kPoiFilterElementName, kPoiFilterElementNameLength))
    {
        if (_currentFilterPoiAdditionalsCategories.count > 0)
        {
            [_abstractTypeAdditionalCategories setObject:[NSMutableSet setWithSet:_currentFilterPoiAdditionalsCategories] forKey:_currentPOIFilter];
            [_currentFilterPoiAdditionalsCategories removeAllObjects];
        }
        _currentPOIFilter = nil;
    }
    else if(0 == strncmp((const char *)localname, kPoiCategoryElementName, kPoiCategoryElementNameLength))
    {
        if (_currentCategoryPoiAdditionalsCategories.count > 0)
        {
            [_abstractTypeAdditionalCategories setObject:[NSMutableSet setWithSet:_currentCategoryPoiAdditionalsCategories] forKey:_currentPOICategory];
            [_currentCategoryPoiAdditionalsCategories removeAllObjects];
        }
        _currentPOICategory = nil;
    }
    else if(0 == strncmp((const char *)localname, kPoiTypeElementName, kPoiTypeElementNameLength))
    {
        if (_currentTypePoiAdditionalsCategories.count > 0)
        {
            if (_currentPOIType)
                [_abstractTypeAdditionalCategories setObject:[NSMutableSet setWithSet:_currentTypePoiAdditionalsCategories] forKey:_currentPOIType];
            
            [_currentTypePoiAdditionalsCategories removeAllObjects];
        }
        _currentPOIType = nil;
    }
    else if(0 == strncmp((const char *)localname, kPoiAdditionalCategoryElementName, kPoiAdditionalCategoryElementNameLength))
    {
        _currentPOIAdditionalCategory = nil;
    }
}

- (void)charactersFound:(const xmlChar *)characters length:(int)length
{
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

- (OAPOIType *)parsePoiType:(const xmlChar *)localname attributeCount:(int)attributeCount
                 attributes:(xmlSAX2Attributes *)attributes
{
    if (!_currentPOICategory)
        _currentPOICategory = _otherMapCategory;

    NSString *name = nil;
    NSString *tag = nil;
    NSString *value = nil;
    NSString *tag2 = nil;
    NSString *value2 = nil;
    NSString *editTag = nil;
    NSString *editValue = nil;
    BOOL nonEditable = NO;
    BOOL top = NO;
    int order = 90;
    BOOL mapOnly = NO;
    BOOL reference = NO;
    BOOL isText = NO;
    NSString *deprecatedOf = nil;
    NSArray<NSString *> *poiAdditionalCategories = nil;
    NSArray<NSString *> *excludedPoiAdditionalCategories = nil;
    
    for(int i = 0; i < attributeCount; i++)
    {
        if (0 == strncmp((const char*)attributes[i].localname, kNameAttributeName,
                         kNameAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            name = [[NSString alloc] initWithBytes:attributes[i].value
                                                      length:length
                                                    encoding:NSUTF8StringEncoding];
            if (0 == strncmp((const char *)localname, kPoiReferenceElementName, kPoiReferenceElementNameLength))
                reference = YES;
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kTagAttributeName,
                              kTagAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            tag = [[NSString alloc] initWithBytes:attributes[i].value
                                                     length:length
                                                   encoding:NSUTF8StringEncoding];
            
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kValueAttributeName,
                              kValueAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            value = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kTag2AttributeName,
                              kTag2AttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            tag2 = [[NSString alloc] initWithBytes:attributes[i].value
                                             length:length
                                           encoding:NSUTF8StringEncoding];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kValue2AttributeName,
                              kValue2AttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            value2 = [[NSString alloc] initWithBytes:attributes[i].value
                                            length:length
                                          encoding:NSUTF8StringEncoding];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kNoEditAttributeName,
                              kNoEditAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            nonEditable = [[[NSString alloc] initWithBytes:attributes[i].value
                                                    length:length
                                                  encoding:NSUTF8StringEncoding] isEqualToString:@"true"];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kEditTagAttributeName,
                              kEditTagAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            editTag = [[NSString alloc] initWithBytes:attributes[i].value
                                            length:length
                                          encoding:NSUTF8StringEncoding];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kEditValueAttributeName,
                              kEditValueAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            editValue = [[NSString alloc] initWithBytes:attributes[i].value
                                              length:length
                                            encoding:NSUTF8StringEncoding];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kDeprecatedOfAttributeName,
                              kDeprecatedOfAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            deprecatedOf = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kMapAttributeName,
                              kMapAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding];
            mapOnly = [[value lowercaseString] isEqualToString:@"true"];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kOrderAttributeName,
                              kOrderAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding];
            order = [value intValue];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kTypeAttributeName,
                              kTypeAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding];
            isText = [[value lowercaseString] isEqualToString:@"text"];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kPoiAdditionalCategoryAttributeName,
                              kPoiAdditionalCategoryAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding];
            
            poiAdditionalCategories = [value componentsSeparatedByString:@","];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kExcludedPoiAdditionalCategoryAttributeName,
                              kExcludedPoiAdditionalCategoryAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding];
            
            excludedPoiAdditionalCategories = [value componentsSeparatedByString:@","];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kTopAttributeName,
                              kTopAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding];
            
            top = [[value lowercaseString] isEqualToString:@"true"];
        }
    }
    
    if (deprecatedOf)
    {
        [_deprecatedTags setObject:deprecatedOf forKey:name];
        return nil;
    }
    
    OAPOIType *poiType = [[OAPOIType alloc] initWithName:name category:_currentPOICategory];
    poiType.filter = _currentPOIFilter;
    poiType.tag = tag ? tag : _currentPOICategory.tag;
    poiType.value = value;
    poiType.tag2 = tag2;
    poiType.value2 = value2;
    poiType.nonEditableOsm = nonEditable;
    poiType.top = top;
    poiType.editTag = editTag;
    poiType.editValue = editValue;
    poiType.reference = reference;
    poiType.mapOnly = mapOnly;
    poiType.order = order;
    poiType.isText = isText;

    [_pTypes addObject:poiType];
    if (!reference)
        [_pTypesByName setObject:poiType forKey:poiType.name];

    [_currentTypePoiAdditionalsCategories addObjectsFromArray:[_currentCategoryPoiAdditionalsCategories allObjects]];
    [_currentTypePoiAdditionalsCategories addObjectsFromArray:[_currentFilterPoiAdditionalsCategories allObjects]];
    if (poiAdditionalCategories.count > 0)
        [_currentTypePoiAdditionalsCategories addObjectsFromArray:poiAdditionalCategories];
    if (excludedPoiAdditionalCategories.count > 0)
    {
        [poiType addExcludedPoiAdditionalCategories:excludedPoiAdditionalCategories];
        [_currentTypePoiAdditionalsCategories minusSet:[NSSet setWithArray:poiType.excludedPoiAdditionalCategories]];
    }

    // Category
    if (_currentPOICategory)
    {
        [_currentPOICategory addPoiType:poiType];
    }
    
    // Filter
    if (_currentPOIFilter)
    {
        [_currentPOIFilter addPoiType:poiType];
    }
    
    return poiType;
}

- (OAPOIType *)parsePoiAdditional:(const xmlChar *)localname attributeCount:(int)attributeCount
                       attributes:(xmlSAX2Attributes *)attributes lang:(NSString *)lang baseType:(OAPOIBaseType *)baseType
{
    if (!_currentPOICategory)
        _currentPOICategory = _otherMapCategory;
    
    NSString *name = nil;
    NSString *tag = nil;
    NSString *value = nil;
    NSString *tag2 = nil;
    NSString *value2 = nil;
    NSString *editTag = nil;
    NSString *editValue = nil;
    BOOL nonEditable = NO;
    int order = 90;
    BOOL mapOnly = NO;
    BOOL reference = NO;
    BOOL isText = NO;
    BOOL filterOnly = NO;
    BOOL top = NO;
    
    for(int i = 0; i < attributeCount; i++)
    {
        if (0 == strncmp((const char*)attributes[i].localname, kNameAttributeName,
                         kNameAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            name = [[NSString alloc] initWithBytes:attributes[i].value
                                                      length:length
                                                    encoding:NSUTF8StringEncoding];

            if (0 == strncmp((const char *)localname, kPoiReferenceElementName, kPoiReferenceElementNameLength))
                reference = YES;
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kTagAttributeName,
                              kTagAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            tag = [[NSString alloc] initWithBytes:attributes[i].value
                                                     length:length
                                                   encoding:NSUTF8StringEncoding];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kValueAttributeName,
                              kValueAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            value = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kTag2AttributeName,
                              kTag2AttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            tag2 = [[NSString alloc] initWithBytes:attributes[i].value
                                            length:length
                                          encoding:NSUTF8StringEncoding];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kValue2AttributeName,
                              kValue2AttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            value2 = [[NSString alloc] initWithBytes:attributes[i].value
                                              length:length
                                            encoding:NSUTF8StringEncoding];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kNoEditAttributeName,
                              kNoEditAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            nonEditable = [[[NSString alloc] initWithBytes:attributes[i].value
                                                    length:length
                                                  encoding:NSUTF8StringEncoding] isEqualToString:@"true"];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kEditTagAttributeName,
                              kEditTagAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            editTag = [[NSString alloc] initWithBytes:attributes[i].value
                                               length:length
                                             encoding:NSUTF8StringEncoding];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kEditValueAttributeName,
                              kEditValueAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            editValue = [[NSString alloc] initWithBytes:attributes[i].value
                                                 length:length
                                               encoding:NSUTF8StringEncoding];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kMapAttributeName,
                              kMapAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding];
            mapOnly = [[value lowercaseString] isEqualToString:@"true"];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kOrderAttributeName,
                              kOrderAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding];
            order = [value intValue];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kTypeAttributeName,
                              kTypeAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding];
            isText = [[value lowercaseString] isEqualToString:@"text"];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kFilterOnlyAttributeName,
                              kFilterOnlyAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding];
            filterOnly = [[value lowercaseString] isEqualToString:@"true"];
        }
        else if (0 == strncmp((const char*)attributes[i].localname, kTopAttributeName,
                              kTopAttributeNameLength))
        {
            int length = (int) (attributes[i].end - attributes[i].value);
            NSString *value = [[NSString alloc] initWithBytes:attributes[i].value
                                                       length:length
                                                     encoding:NSUTF8StringEncoding];
            
            top = [[value lowercaseString] isEqualToString:@"true"];
        }
    }
    
    if (lang)
    {
        name = [name stringByAppendingString:[NSString stringWithFormat:@":%@", lang]];
    }
    if (lang && tag)
    {
        tag = [tag stringByAppendingString:[NSString stringWithFormat:@":%@", lang]];
    }
    
    OAPOIType *poiType = [[OAPOIType alloc] initWithName:name category:_currentPOICategory];
    poiType.filter = _currentPOIFilter;
    poiType.tag = _currentPOICategory.tag;
    poiType.baseLangType = baseType;
    poiType.lang = lang;
    poiType.tag = tag ? tag : _currentPOICategory.tag;
    poiType.value = value;
    poiType.tag2 = tag2;
    poiType.value2 = value2;
    poiType.editTag = editTag;
    poiType.editValue = editValue;
    poiType.nonEditableOsm = nonEditable;
    poiType.reference = reference;
    poiType.mapOnly = mapOnly;
    poiType.order = order;
    poiType.isText = isText;
    poiType.filterOnly = filterOnly;
    poiType.top = top;
    [poiType setAdditional:_currentPOIType ? _currentPOIType : (_currentPOIFilter ? _currentPOIFilter : _currentPOICategory)];
    poiType.poiAdditionalCategory = _currentPOIAdditionalCategory;
    
    if (isText)
        [_textPoiAdditionals addObject:poiType];
    
    if (_currentPOIType)
    {
        [_currentPOIType addPoiAdditional:poiType];
    }
    else if (_currentPOIFilter)
    {
        [_currentPOIFilter addPoiAdditional:poiType];
    }
    else if (_currentPOICategory)
    {
        [_currentPOICategory addPoiAdditional:poiType];
    }
    
    return poiType;
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

