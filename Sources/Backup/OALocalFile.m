//
//  OALocalFIle.m
//  OsmAnd Maps
//
//  Created by Paul on 19.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OALocalFile.h"
#import "OASettingsItem.h"
#import "OASettingsItemType.h"

@implementation OALocalFile
{
    NSString *_name;
    NSInteger _sz;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _name = nil;
        _sz = -1;
        _uploadTime = 0;
        _localModifiedTime = 0;
    }
    return self;
}

- (NSString *) getName
{
    if (!_name && _filePath)
        _name = [self formatName:_filePath.lastPathComponent];
    return _name;
}

- (NSString *) formatName:(NSString *)name
{
    int ext = [name lastIndexOf:@"."];
    if (ext != -1)
    {
        name = [name substringWithRange:NSMakeRange(0, ext)];
    }
    return [name stringByReplacingOccurrencesOfString:@"_" withString:@" "];
}

// Usage: AndroidUtils.formatSize(v.getContext(), getSize() * 1024l);
- (NSInteger) getSize
{
    if (_sz == -1)
    {
        if (!_filePath)
            return -1;
        NSDictionary *attrs = [NSFileManager.defaultManager attributesOfItemAtPath:_filePath error:nil];
        _sz = attrs.fileSize;
    }
    return _sz;
}

- (long) getFileDate
{
    if (!_filePath)
        return 0;
    NSDictionary *attrs = [NSFileManager.defaultManager attributesOfItemAtPath:_filePath error:nil];
    return attrs.fileModificationDate.timeIntervalSince1970 * 1000;
}

- (NSString *) getFileName
{
    NSString *result;
    if (_fileName != nil)
        result = _fileName;
    else if (!_filePath)
        result = @"";
    else
        result = _fileName = _filePath.lastPathComponent;

    return result;
}

- (NSString *) getTypeFileName
{
    NSString *type = _item != nil ? [OASettingsItemType typeName:_item.type] : @"";
    NSString *fileName = [self getFileName];
    if (fileName.length > 0)
        return [type stringByAppendingPathComponent:fileName];
    else
        return type;
}


- (NSString *) toString
{
    NSInteger fileSize = -1;
    if (_filePath)
    {
        NSDictionary *attrs = [NSFileManager.defaultManager attributesOfItemAtPath:_filePath error:nil];
        fileSize = attrs.fileSize;
    }
    return [NSString stringWithFormat:@"%@ (%ld) localTime=%ld uploadTime=%ld", self.getFileName, fileSize, _localModifiedTime, _uploadTime];
}

@end
