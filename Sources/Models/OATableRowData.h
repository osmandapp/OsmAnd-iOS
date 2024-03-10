//
//  OATableViewRowData.h
//  OsmAnd Maps
//
//  Created by Paul on 20.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

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

+ (instancetype _Nonnull ) rowData;

- (instancetype _Nonnull)initWithData:(NSDictionary *_Nonnull)data;

@property (nonatomic) NSString * _Nullable cellType;
@property (nonatomic) NSString * _Nullable key;
@property (nonatomic) NSString * _Nullable title;
@property (nonatomic) NSString * _Nullable descr;
@property (nonatomic) NSString * _Nullable iconName;
@property (nonatomic) UIImage * _Nullable icon;
@property (nonatomic) NSInteger iconTint;
@property (nonatomic) UIColor * _Nullable iconTintColor;
@property (nonatomic) UIColor * _Nullable secondaryIconTintColor;
@property (nonatomic) NSString * _Nullable secondaryIconName;
@property (nonatomic) NSString * _Nullable accessibilityLabel;
@property (nonatomic) NSString * _Nullable accessibilityValue;
@property (nonatomic) UITableViewCellAccessoryType accessoryType;

@property (nonatomic, readonly, assign) EOATableRowType rowType;

- (void) setObj:(id _Nonnull )data forKey:(nonnull NSString *)key;
- (id _Nullable ) objForKey:(nonnull NSString *)key;

- (NSString *_Nullable) stringForKey:(nonnull NSString *)key;
- (NSInteger) integerForKey:(nonnull NSString *)key;
- (BOOL) boolForKey:(nonnull NSString *)key;

- (NSInteger) dependentRowsCount;
- (OATableRowData *_Nonnull) getDependentRow:(NSUInteger)index;

@end
