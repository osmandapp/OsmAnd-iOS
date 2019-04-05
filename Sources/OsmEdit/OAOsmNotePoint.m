//
//  OAOsmNotePoint.m
//  OsmAnd
//
//  Created by Paul on 1/30/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmNotePoint.h"

// static const long serialVersionUID = 729654300829771468L;

@implementation OAOsmNotePoint
{
    long long _id;
    NSString *_text;
    double _latitude;
    double _longitude;
    NSString *_author;
}

-(NSString *)getText
{
    return _text;
}

- (EOAGroup)getGroup
{
    return BUG;
}

-(NSString *)getAuthor
{
    return _author;
}

-(void)setId:(long long)identifier
{
    _id = identifier;
}

-(void)setText:(NSString *)text
{
    _text = text;
}

-(void)setLatitude:(double)latitude
{
    _latitude = latitude;
}

-(void)setLongitude:(double)longitude
{
    _longitude = longitude;
}

-(void)setAuthor:(NSString *)author
{
    _author = author;
}

-(NSString *) toNSString
{
    return [NSString stringWithFormat:@"OsmBug Point %@ %@ %@ (%lld): [(%f, %f)]", [self getActionString], [self getText], [self getAuthor],
                [self getId], [self getLatitude], [self getLongitude]];
}

- (long long)getId {
    return _id;
}


- (double)getLatitude {
    return _latitude;
}


- (double)getLongitude {
    return _longitude;
}

-(NSDictionary<NSString *, NSString *> *)getTags
{
    return [NSDictionary dictionaryWithObjectsAndKeys:_author, @"author", _text, @"comment", nil];
}

-(NSString *)getName
{
    return _text ? _text : @"";
}


@end
