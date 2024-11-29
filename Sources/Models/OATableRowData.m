//
//  OATableRowData.m
//  OsmAnd Maps
//
//  Created by Paul on 20.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OATableRowData.h"

@implementation OATableRowData
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

- (UIImage *)icon
{
    return _data[kCellIconKey];
}

- (void)setIcon:(UIImage *)icon
{
    _data[kCellIconKey] = icon;
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
    return _data[kCellIconTint] ? [_data[kCellIconTint] integerValue] : -1;
}

- (void)setIconTint:(NSInteger)iconTint
{
    _data[kCellIconTint] = @(iconTint);
}

- (UIColor *)iconTintColor
{
    return _data[kCellIconTintColor];
}

- (void)setIconTintColor:(UIColor *)color;
{
    _data[kCellIconTintColor] = color;
}

- (UIColor *)secondIconTintColor
{
    return _data[kCellSecondaryIconTintColor];
}

- (void)setSecondIconTintColor:(UIColor *)color;
{
    _data[kCellSecondaryIconTintColor] = color;
}

- (UITableViewCellAccessoryType)accessoryType
{
    return _data[kCellAccessoryType] ? [_data[kCellAccessoryType] integerValue] : UITableViewCellAccessoryNone;
}

- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType
{
    _data[kCellAccessoryType] = @(accessoryType);
}

- (NSString *)accessibilityLabel
{
    return _data[kCellAccessibilityLabel];
}

- (void)setAccessibilityLabel:(NSString *)accessibilityLabel
{
    _data[kCellAccessibilityLabel] = accessibilityLabel;
}

- (NSString *)accessibilityValue
{
    return _data[kCellAccessibilityValue];
}

- (void)setAccessibilityValue:(NSString *)accessibilityValue
{
    _data[kCellAccessibilityValue] = accessibilityValue;
}

- (void) setObj:(id)data forKey:(nonnull NSString *)key
{
    _data[key] = data;
}

- (id) objForKey:(nonnull NSString *)key
{
    return _data[key];
}

- (void)removeObjectForKey:(nonnull NSString *)key
{
   [_data removeObjectForKey:key];
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

- (EOATableRowType)rowType
{
    return EOATableRowTypeRegular;
}

- (NSInteger)dependentRowsCount
{
    return 0;
}

- (OATableRowData *) getDependentRow:(NSUInteger)index
{
    return nil;
}

@end
