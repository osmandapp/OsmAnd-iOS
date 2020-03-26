//
//  OASettingsHelper.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsHelper.h"

@implementation OASettingsHelper

@end

#pragma mark - OASettingsItem

@implementation OASettingsItem

-(instancetype)initWithType:(EOASettingsItemType)type
{
    self = [super init];
    if (self) {
        _type = type;
    }
    return self;
}
 
-(instancetype)initWithType:(EOASettingsItemType)type json:(NSDictionary*)json
{
    self = [super init];
    if (self) {
        _type = type;
        [self readFromJSON:json];
    }
    return self;
}

-(EOASettingsItemType)getType
{
    return _type;
}

-(NSString*)getName
{
    return nil;
}

-(NSString*)getPublicName //:(Contex)ctx
{
    return nil;
}

-(NSString*)getFileName
{
    return nil;
}

-(BOOL)shouldReadOnCollecting
{
    return NO;
}

-(void)setShouldReplace:(BOOL)shouldReplace
{
    _shouldReplace = shouldReplace;
}

/*
static SettingsItemType parseItemType(@NonNull JSONObject json) throws IllegalArgumentException, JSONException {
    return SettingsItemType.valueOf(json.getString("type"));
}
 */

-(EOASettingsItemType)parseItemType:(NSDictionary*)json
{
    //return [EOASettingsItemType valueForKey:[json objectForKey:@"type"]];
}

-(BOOL)exists
{
    return NO;
}

-(void)apply
{
    // non implemented
}

-(void)readFromJSON:(NSDictionary*)json
{
}

-(void)writeToJSON:(NSDictionary*)json
{
    [json setValue:[NSNumber numberWithInteger:_type] forKey:[self getName]];
    [json setValue:[self getName] forKey:@"name"];
    
}

-(NSString *)toJSON
{
    NSDictionary *JSONDic=[[NSDictionary alloc] init];
    NSError *error;
    [self writeToJSON:JSONDic];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:JSONDic
                                            options:NSJSONWritingPrettyPrinted
                                            error:&error];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

/*
 @NonNull
 abstract SettingsItemReader getReader();

 @NonNull
 abstract SettingsItemWriter getWriter();
 */

//-(SettingsItemReader*)getReader
//{
//    return nil;
//}
//
//-(SettingsItemWriter*)getWriter
//{
//    return nil;
//}

- (NSUInteger)hash
{
    NSInteger result = _type;
    NSString *name = [self getName];
    result = 31 * result + (name != nil ? [name hash] : 0);
    return result;
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
    if (!object)
        return NO;
    
    if ([object isKindOfClass:self.class])
    {
        OASettingsItem *item = (OASettingsItem *) object;
        return _type == item.getType &&
                        [[item getName] isEqual:[self getName]] &&
                        [[item getFileName] isEqual:[self getFileName]];
    }
    else
    {
        return NO;
    }
}

@end

#pragma mark - OAStreamSettingsItem

@implementation OAStreamSettingsItem

-(instancetype)initWithType:(EOASettingsItemType)type name:(NSString*)name
{
    [super setType:type];
    _name = name;
    return self;
}

-(instancetype)initWithType:(EOASettingsItemType)type json:(NSDictionary*)json
{
    self = [super initWithType:type json:json];
    return self;
}

-(instancetype)initWithType:(EOASettingsItemType)type inputStream:(NSInputStream*)inputStream name:(NSString*)name
{
    [super setType:type];
    _name = name;
    _inputStream = inputStream;
    return self;
}

-(NSInputStream*)getInputStream
{
    return _inputStream;
}

-(void)setInputStream:(NSInputStream*)inputStream
{
    _inputStream = inputStream;
}

-(NSString*)getName
{
    return _name;
}

-(NSString*)getPublicName //:(Contex)ctx
{
    return [self getName];
}

-(void)readFromJSON:(NSDictionary*)json
{
    [super readFromJSON:json];
    _name = [[NSString alloc] initWithData:[json objectForKey:@"name"] encoding:NSUTF8StringEncoding];
}

 /*
@NonNull
@Override
public SettingsItemWriter getWriter() {
    return new StreamSettingsItemWriter(this);
}
 */

//-(SettingsItemWriter*)getWriter
//{
//    return nil;
//}

@end


