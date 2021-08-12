//
//  OAResourcesSettingsItem.mm
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAResourcesSettingsItem.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"

@interface OAResourcesSettingsItem()

@property (nonatomic) NSString *filePath;
@property (nonatomic) NSString *fileName;

@end

@implementation OAResourcesSettingsItem

@dynamic filePath, fileName, subtype;

- (instancetype _Nullable) initWithJson:(NSDictionary *)json error:(NSError * _Nullable *)error
{
    NSError *initError;
    self = [super initWithJson:json error:&initError];
    if (initError)
    {
        if (error)
            *error = initError;
        return nil;
    }
    if (self)
    {
        self.shouldReplace = YES;
    }
    return self;
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeResources;
}

- (EOASettingsItemFileSubtype)subtype
{
    return EOASettingsItemFileSubtypeOther;
}

- (void) readFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSError *readError;
    [super readFromJson:json error:&readError];
    if (readError)
    {
        if (error)
            *error = readError;
        return;
    }
}

- (void) writeToJson:(id)json
{
    [super writeToJson:json];
    NSString *fileName = self.fileName;
    if (fileName.length > 0)
    {
        if ([fileName hasSuffix:@"/"])
        {
            fileName = [fileName substringToIndex:fileName.length - 1];
        }
        json[@"file"] = fileName;
    }
}

- (BOOL) applyFileName:(NSString *)fileName
{
    NSString *itemFileName = self.fileName;
    if ([fileName hasSuffix:@"/"])
        fileName = [fileName substringToIndex:fileName.length - 1];
    
    if ([fileName isEqualToString:itemFileName])
    {
        self.filePath = [[self getPluginPath] stringByAppendingPathComponent:fileName];
        return YES;
    }
    else
    {
        return NO;
    }
}

@end
