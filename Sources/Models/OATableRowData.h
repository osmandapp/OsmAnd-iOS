//
//  OATableViewRowData.h
//  OsmAnd Maps
//
//  Created by Paul on 20.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EOATableRowType) {
    EOATableRowTypeRegular,
    EOATableRowTypeCollapsable
};

@interface OATableRowData : NSObject

#define kCellTypeKey @"cellType"
#define kCellKeyKey @"key"
#define kCellTitleKey @"title"
#define kCellDescrKey @"descr"
#define kCellIconNameKey @"iconName"
#define kCellIconKey @"icon"
#define kCellIconTint @"iconTint"
#define kCellIconTintColor @"iconTintColor"
#define kCellSecondaryIconTintColor @"secondaryIconTintColor"
#define kCellSecondaryIconName @"secondaryIconName"
#define kCellAccessoryType @"accessoryType"
#define kCellAccessibilityLabel @"accessibilityLabel"
#define kCellAccessibilityValue @"accessibilityValue"

+ (instancetype) rowData;

- (instancetype)initWithData:(NSDictionary *)data;

@property (nonatomic, nullable) NSString *cellType;
@property (nonatomic, nullable) NSString *key;
@property (nonatomic, nullable) NSString *title;
@property (nonatomic, nullable) NSString *descr;
@property (nonatomic, nullable) NSString *iconName;
@property (nonatomic, nullable) UIImage *icon;
@property (nonatomic) NSInteger iconTint;
@property (nonatomic, nullable) UIColor *iconTintColor;
@property (nonatomic, nullable) UIColor *secondaryIconTintColor;
@property (nonatomic, nullable) NSString *secondaryIconName;
@property (nonatomic, nullable) NSString *accessibilityLabel;
@property (nonatomic, nullable) NSString *accessibilityValue;
@property (nonatomic) UITableViewCellAccessoryType accessoryType;

@property (nonatomic, readonly, assign) EOATableRowType rowType;

- (void) setObj:(id)data forKey:(NSString *)key;
- (nullable id) objForKey:(NSString *)key;

- (nullable NSString *) stringForKey:(NSString *)key;
- (NSInteger) integerForKey:(NSString *)key;
- (BOOL) boolForKey:(NSString *)key;

- (NSInteger) dependentRowsCount;
- (OATableRowData *) getDependentRow:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
