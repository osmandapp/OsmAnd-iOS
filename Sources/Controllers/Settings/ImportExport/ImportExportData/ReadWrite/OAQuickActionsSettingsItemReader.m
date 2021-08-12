//
//  OAQuickActionsSettingsItemReader.m
//  OsmAnd
//
//  Created by nnngrach on 02.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAQuickActionsSettingsItemReader.h"
#import "OASettingsHelper.h"
#import "OASettingsItem.h"

@implementation OAQuickActionsSettingsItemReader

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
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
    
    NSDictionary<NSString *, NSString *> *settings = (NSDictionary *) json;
    [self.item readFromJson:json error:error];
    if (error)
        return NO;
    
    return YES;
}

@end
