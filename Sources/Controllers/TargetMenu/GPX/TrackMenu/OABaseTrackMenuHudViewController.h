//
//  OABaseTrackMenuHudViewController.h
//  OsmAnd
//
//  Created by Skalii on 25.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseScrollableHudViewController.h"

#define kCellType @"type"
#define kCellTitle @"title"
#define kCellDesc @"desc"
#define kCellLeftIcon @"left_icon"
#define kCellRightIconName @"right_icon_name"
#define kCellToggle @"toggle"
#define kCellTintColor @"tint_color"
#define kCellIsDisabled @"is_disabled"

#define kSectionHeader @"header"
#define kSectionHeaderHeight @"header_height"
#define kSectionFooter @"footer"
#define kSectionFooterHeight @"footer_height"

#define kTableKey @"key"
#define kTableSubjects @"subjects"
#define kTableValues @"values"

typedef NS_ENUM(NSUInteger, EOATrackHudMode)
{
    EOATrackMenuHudMode = 0,
    EOATrackAppearanceHudMode,
};

@class OAMapPanelViewController, OAMapViewController, OASavingTrackHelper, OAAppSettings;

@class OASGpxTrackAnalysis, OASGpxFile, OASTrackItem;

@interface OAGPXBaseTableData : NSObject

@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSMutableDictionary<NSString *, id> *values;
@property (nonatomic, readonly) NSMutableArray<OAGPXBaseTableData *> *subjects;

+ (instancetype)withData:(NSDictionary *)data;
- (void)setData:(NSDictionary *)data;
- (OAGPXBaseTableData *)getSubject:(NSString *)key;

@end

@interface OAGPXTableCellData : OAGPXBaseTableData

@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *desc;
@property (nonatomic, readonly) UIImage *leftIcon;
@property (nonatomic, readonly) NSString *rightIconName;
@property (nonatomic, readonly) BOOL toggle;
@property (nonatomic, readonly) UIColor *tintColor;
@property (nonatomic, readonly) BOOL isDisabled;
@property (nonatomic, readonly) NSMutableArray<OAGPXTableCellData *> *subjects;

+ (instancetype)withData:(NSDictionary *)data;
- (OAGPXTableCellData *)getSubject:(NSString *)key;

@end

@interface OAGPXTableSectionData : OAGPXBaseTableData

@property (nonatomic, readonly) NSString *header;
@property (nonatomic, readonly) CGFloat headerHeight;
@property (nonatomic, readonly) NSString *footer;
@property (nonatomic, readonly) CGFloat footerHeight;
@property (nonatomic, readonly) NSMutableArray<OAGPXTableCellData *> *subjects;

+ (instancetype)withData:(NSDictionary *)data;
- (OAGPXTableCellData *)getSubject:(NSString *)key;

@end

@interface OAGPXTableData : OAGPXBaseTableData

@property (nonatomic, readonly) NSMutableArray<OAGPXTableSectionData *> *subjects;

+ (instancetype)withData:(NSDictionary *)data;
- (OAGPXTableSectionData *)getSubject:(NSString *)key;

@end

@interface OABaseTrackMenuHudViewController : OABaseScrollableHudViewController

@property (nonatomic, readonly) OASTrackItem *gpx;
@property (nonatomic) OASGpxFile *doc;
@property (nonatomic) OASGpxTrackAnalysis *analysis;
@property (nonatomic, readonly) BOOL isCurrentTrack;
@property (nonatomic, readonly) BOOL isShown;

@property (nonatomic, readonly) OAAppSettings *settings;
@property (nonatomic, readonly) OASavingTrackHelper *savingHelper;

@property (weak, nonatomic, readonly) OAMapPanelViewController *mapPanelViewController;
@property (weak, nonatomic, readonly) OAMapViewController *mapViewController;

- (instancetype)initWithGpx:(OASTrackItem *)gpx;

- (void)updateGpxData:(BOOL)replaceGPX updateDocument:(BOOL)updateDocument;
- (void)updateAnalysis;
- (BOOL)changeTrackVisible;

- (NSLayoutConstraint *)createBaseEqualConstraint:(UIView *)firstItem
                                   firstAttribute:(NSLayoutAttribute)firstAttribute
                                       secondItem:(UIView *)secondItem
                                  secondAttribute:(NSLayoutAttribute)secondAttribute;

- (NSLayoutConstraint *)createBaseEqualConstraint:(UIView *)firstItem
                                   firstAttribute:(NSLayoutAttribute)firstAttribute
                                       secondItem:(UIView *)secondItem
                                  secondAttribute:(NSLayoutAttribute)secondAttribute
                                         constant:(CGFloat)constant;

- (void)adjustViewPort:(BOOL)landscape;
- (BOOL)isAdjustedMapViewPort;

@end
