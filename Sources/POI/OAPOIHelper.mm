//
//  OAPOIHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOIHelper.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIParser.h"
#import "OAPhrasesParser.h"

@implementation OAPOIHelper

+ (OAPOIHelper *)sharedInstance {
    static dispatch_once_t once;
    static OAPOIHelper * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self readPOI];
        [self updatePhrases];
    }
    return self;
}

- (void)readPOI
{
    NSString *poiXmlPath = [[NSBundle mainBundle] pathForResource:@"poi_types" ofType:@"xml"];
    
    OAPOIParser *parser = [[OAPOIParser alloc] init];
    [parser getPOITypesSync:poiXmlPath];
    _poiTypes = parser.poiTypes;
    _poiCategories = parser.poiCategories;
    
}

- (void)updatePhrases
{
    NSString *phrasesXmlPath = [[NSBundle mainBundle] pathForResource:@"phrases" ofType:@"xml"];
    
    OAPhrasesParser *parser = [[OAPhrasesParser alloc] init];
    [parser getPhrasesSync:phrasesXmlPath];
    
    if (parser.phrases.count > 0) {
        for (OAPOIType *poiType in _poiTypes)
            poiType.nameLocalized = [parser.phrases objectForKey:[NSString stringWithFormat:@"poi_%@", poiType.value]];
        for (OAPOICategory *c in _poiCategories.allKeys)
            c.nameLocalized = [parser.phrases objectForKey:[NSString stringWithFormat:@"poi_%@", c.name]];
    }
    
}

- (NSArray *)poiTypesForCategory:(NSString *)categoryName;
{
    for (OAPOICategory *c in _poiCategories.allKeys)
        if ([c.name isEqualToString:categoryName])
            return [_poiCategories objectForKey:c];

    return nil;
}

+ (UIImage *)categoryIcon:(NSString *)categoryName
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-hdpi/mx_%@", categoryName]];
}

@end
