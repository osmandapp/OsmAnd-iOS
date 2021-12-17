//
//  OABaseTrackMenuHudViewController.h
//  OsmAnd
//
//  Created by Skalii on 25.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseScrollableHudViewController.h"

#define kCellKey @"key"
#define kCellType @"type"
#define kCellTitle @"title"
#define kCellDesc @"desc"
#define kCellLeftIcon @"left_icon"
#define kCellRightIconName @"right_icon_name"
#define kCellToggle @"toggle"
#define kCellTintColor @"tint_color"

#define kSectionCells @"cells"
#define kSectionHeader @"header"
#define kSectionHeaderHeight @"header_height"
#define kSectionFooter @"footer"
#define kSectionFooterHeight @"footer_height"

#define kTableSections @"sections"
#define kTableValues @"values"

typedef NS_ENUM(NSUInteger, EOATrackHudMode)
{
    EOATrackMenuHudMode = 0,
    EOATrackAppearanceHudMode,
};

typedef void(^OAGPXTableCellDataOnSwitch)(BOOL toggle);
typedef BOOL(^OAGPXTableCellDataIsOn)();
typedef void(^OAGPXTableDataUpdateData)();
typedef void(^OAGPXTableDataUpdateProperty)(id value);

@class OAGPX, OAGPXDocument, OAGPXTrackAnalysis, OAMapPanelViewController, OAMapViewController, OASavingTrackHelper, OAAppSettings;

@interface OAGPXTableCellData : NSObject

+ (instancetype)withData:(NSDictionary *)data;

@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSDictionary *values;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *desc;
@property (nonatomic, readonly) UIImage *leftIcon;
@property (nonatomic, readonly) NSString *rightIconName;
@property (nonatomic, readonly) BOOL toggle;
@property (nonatomic, readonly) NSInteger tintColor;
@property (nonatomic) OAGPXTableCellDataOnSwitch onSwitch;
@property (nonatomic) OAGPXTableCellDataIsOn isOn;
@property (nonatomic) OAGPXTableDataUpdateData updateData;
@property (nonatomic) OAGPXTableDataUpdateData onButtonPressed;
@property (nonatomic) OAGPXTableDataUpdateProperty updateProperty;

- (void)setData:(NSDictionary *)data;

@end

@interface OAGPXTableSectionData : NSObject

+ (instancetype)withData:(NSDictionary *)data;

@property (nonatomic, readonly) NSMutableArray<OAGPXTableCellData *> *cells;
@property (nonatomic, readonly) NSString *header;
@property (nonatomic, readonly) CGFloat headerHeight;
@property (nonatomic, readonly) NSString *footer;
@property (nonatomic, readonly) CGFloat footerHeight;
@property (nonatomic, readonly) NSDictionary *values;
@property (nonatomic) OAGPXTableDataUpdateData updateData;
@property (nonatomic) OAGPXTableDataUpdateProperty updateProperty;

- (void)setData:(NSDictionary *)data;
- (BOOL)containsCell:(NSString *)key;

@end

@interface OAGPXTableData : NSObject

+ (instancetype)withData:(NSDictionary *)data;

@property (nonatomic, readonly) NSMutableArray<OAGPXTableSectionData *> *sections;
@property (nonatomic) OAGPXTableDataUpdateData updateData;
@property (nonatomic) OAGPXTableDataUpdateProperty updateProperty;

- (void)setData:(NSDictionary *)data;

@end

@interface OABaseTrackMenuHudViewController : OABaseScrollableHudViewController

@property (nonatomic, readonly) OAGPX *gpx;
@property (nonatomic, readonly) OAGPXDocument *doc;
@property (nonatomic, readonly) OAGPXTrackAnalysis *analysis;
@property (nonatomic, readonly) BOOL isCurrentTrack;
@property (nonatomic, readonly) BOOL isShown;

@property (nonatomic, readonly) OAAppSettings *settings;
@property (nonatomic, readonly) OASavingTrackHelper *savingHelper;

@property (nonatomic, readonly) OAMapPanelViewController *mapPanelViewController;
@property (nonatomic, readonly) OAMapViewController *mapViewController;

- (instancetype)initWithGpx:(OAGPX *)gpx;

- (void)updateGpxData;

- (NSLayoutConstraint *)createBaseEqualConstraint:(UIView *)firstItem
                                   firstAttribute:(NSLayoutAttribute)firstAttribute
                                       secondItem:(UIView *)secondItem
                                  secondAttribute:(NSLayoutAttribute)secondAttribute;

- (NSLayoutConstraint *)createBaseEqualConstraint:(UIView *)firstItem
                                   firstAttribute:(NSLayoutAttribute)firstAttribute
                                       secondItem:(UIView *)secondItem
                                  secondAttribute:(NSLayoutAttribute)secondAttribute
                                         constant:(CGFloat)constant;

- (void)adjustMapViewPort;
- (BOOL)isAdjustedMapViewPort;

@end
