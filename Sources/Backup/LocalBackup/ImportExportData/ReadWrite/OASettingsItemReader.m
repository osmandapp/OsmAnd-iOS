//
//  OASettingsItemReader.m
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsItemReader.h"
#import "OASettingsHelper.h"
#import "OASettingsItem.h"
#import "OALog.h"

@interface OASettingsItemReader<__covariant ObjectType : OASettingsItem *>()

@property (nonatomic) ObjectType item;

@end

@implementation OASettingsItemReader

- (instancetype) initWithItem:(id)item
{
    self = [super init];
    if (self) {
        _item = item;
    }
    return self;
}

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    if (self.item.read)
    {
        if (error)
            *error = [NSError errorWithDomain:kSettingsItemErrorDomain code:kSettingsItemErrorCodeAlreadyRead userInfo:nil];

        return NO;
    }

    NSError *readError;
    NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&readError];
    if (readError)
    {
        if (error)
            *error = readError;
        
        return NO;
    }
    if (data.length == 0)
    {
        if (error)
            *error = [NSError errorWithDomain:kSettingsHelperErrorDomain code:kSettingsHelperErrorCodeEmptyJson userInfo:nil];
        
        return NO;
    }
    
    NSError *jsonError;
    id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
    if (jsonError)
    {
        if (error)
            *error = jsonError;
        
        return NO;
    }
    NSError *parsingError;
    [self.item readFromJson:json error:&parsingError];
    if (parsingError)
    {
        OALog(@"Json parsing error");
        return NO;
    }

    self.item.read = YES;
    return YES;
}

@end
