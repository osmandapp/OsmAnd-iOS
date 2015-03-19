//
//  OAPOIHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOIHelper.h"
#import "OAPOI.h"
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
    [parser getPOIDataSync:poiXmlPath];
    _pois = parser.pois;
    _poisByCategory = parser.poisByCategory;
    
}

- (void)updatePhrases
{
    NSString *phrasesXmlPath = [[NSBundle mainBundle] pathForResource:@"phrases" ofType:@"xml"];
    
    OAPhrasesParser *parser = [[OAPhrasesParser alloc] init];
    [parser getPhrasesSync:phrasesXmlPath];
    
    if (parser.phrases.count > 0)
        for (OAPOI *poi in _pois)
            poi.valueLocalized = [parser.phrases objectForKey:[NSString stringWithFormat:@"poi_%@", poi.value]];
    
}

- (NSArray *)categoryPOIs:(NSString *)category;
{
    return [_poisByCategory objectForKey:category];
}

@end
