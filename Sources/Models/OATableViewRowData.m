//
//  OATableViewRowData.m
//  OsmAnd Maps
//
//  Created by Paul on 20.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OATableViewRowData.h"

@implementation OATableViewRowData
{
    NSMutableDictionary *_data;
}

+ (instancetype) rowData
{
    return [[self.class alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _data = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype)initWithData:(NSDictionary *)data
{
    self = [super init];
    if (self) {
        _data = [NSMutableDictionary dictionaryWithDictionary:data];
    }
    return self;
}

- (NSString *)cellType
{
    return _data[kCellTypeKey];
}

- (void)setCellType:(NSString *)cellType
{
    _data[kCellTypeKey] = cellType;
}

- (NSString *)key
{
    return _data[kCellKeyKey];
}

- (void)setKey:(NSString *)key
{
    _data[kCellKeyKey] = key;
}

- (NSString *)title
{
    return _data[kCellTitleKey];
}

- (void)setTitle:(NSString *)title
{
    _data[kCellTitleKey] = title;
}

- (NSString *)descr
{
    return _data[kCellDescrKey];
}

- (void)setDescr:(NSString *)descr
{
    _data[kCellDescrKey] = descr;
}

- (NSString *)iconName
{
    return _data[kCellIconNameKey];
}

- (void)setIconName:(NSString *)iconName
{
    _data[kCellIconNameKey] = iconName;
}

- (NSString *)secondaryIconName
{
    return _data[kCellSecondaryIconName];
}

- (void)setSecondaryIconName:(NSString *)secondaryIconName
{
    _data[kCellSecondaryIconName] = secondaryIconName;
}

- (NSInteger)iconTint
{
    return [_data[kCellIconTint] integerValue];
}

- (void)setIconTint:(NSInteger)iconTint
{
    _data[kCellIconTint] = @(iconTint);
}

- (void) setObj:(id)data forKey:(nonnull NSString *)key
{
    _data[key] = data;
}

- (id) objForKey:(nonnull NSString *)key
{
    return _data[key];
}

- (NSString *) stringForKey:(nonnull NSString *)key
{
    return [_data[key] stringValue];
}

- (NSInteger) integerForKey:(nonnull NSString *)key
{
    return [_data[key] integerValue];
}

- (BOOL) boolForKey:(nonnull NSString *)key
{
    return [_data[key] boolValue];
}

@end
