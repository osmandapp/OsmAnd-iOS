//
//  OADataSettingsItem.mm
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADataSettingsItem.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"

@interface OADataSettingsItem()

@property (nonatomic) NSString *name;

@end

@implementation OADataSettingsItem

@dynamic type, name, fileName;

- (instancetype) initWithName:(NSString *)name
{
    self = [super init];
    if (self)
        self.name = name;

    return self;
}

- (instancetype) initWithData:(NSData *)data name:(NSString *)name
{
    self = [super init];
    if (self)
    {
        self.name = name;
        _data = data;
    }
    return self;
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeData;
}

- (NSString *) defaultFileExtension
{
    return @".dat";
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
    self.name = json[@"name"];
    NSString *fileName = self.fileName;
    if (fileName.length > 0)
        self.name = [fileName stringByDeletingPathExtension];
}

- (OASettingsItemReader *) getReader
{
   return [[OADataSettingsItemReader alloc] initWithItem:self];
}

- (OASettingsItemWriter *) getWriter
{
    return [[OADataSettingsItemWriter alloc] initWithItem:self];
}

@end

#pragma mark - OADataSettingsItemReader

@implementation OADataSettingsItemReader

- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    NSError *readError;
    NSData *data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&readError];
    if (error && readError)
    {
        *error = readError;
        return NO;
    }
    self.item.data = data;
    return YES;
}

@end

#pragma mark - OADataSettingsItemWriter

@implementation OADataSettingsItemWriter

- (BOOL) writeToFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    NSError *writeError;
    [self.item.data writeToFile:filePath options:NSDataWritingAtomic error:&writeError];
    if (error && writeError)
    {
        *error = writeError;
        return NO;
    }
    return YES;
}

@end
