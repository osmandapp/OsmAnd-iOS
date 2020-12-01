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
@property (nonatomic) EOASettingsItemFileSubtype subtype;

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
        //[self commonInit]; // shouldn't be commented! Error occurs - No visible @interface for 'OAResourcesSettingsItem' declares the selector 'commonInit'
        NSString *fileName = self.fileName;
        if (fileName.length > 0 && ![fileName hasSuffix:@"/"])
            self.fileName = [fileName stringByAppendingString:@"/"];
    }
    return self;
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeResources;
}

- (void) readFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    self.subtype = EOASettingsItemFileSubtypeOther;
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
    if ([fileName hasSuffix:@"/"])
        return NO;

    NSString *itemFileName = self.fileName;
    if ([itemFileName hasSuffix:@"/"])
    {
        if ([fileName hasPrefix:itemFileName])
        {
            self.filePath = [[self getPluginPath] stringByAppendingString:fileName];
            return YES;
        }
        else
        {
            return NO;
        }
    }
    else
    {
        return [super applyFileName:fileName];
    }
}

- (OASettingsItemWriter *) getWriter
{
    return nil;
}

@end
