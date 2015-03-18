//
//  OAPOIHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOIHelper.h"
#import "OAPOIParser.h"

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
    }
    return self;
}

-(void)readPOI
{
    NSString *poiXmlPath = [[NSBundle mainBundle] pathForResource:@"poi_types" ofType:@"xml"];
    
    OAPOIParser *parser = [[OAPOIParser alloc] init];
    [parser getPOIDataSync:poiXmlPath];
    _pois = parser.pois;
    _categories = parser.categories;
}

- (NSArray *)categoryPOIs:(NSString *)category;
{
    return nil;
}

@end
