//
//  OABaseTrackMenuHudViewController.h
//  OsmAnd
//
//  Created by Skalii on 25.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseScrollableHudViewController.h"
#import "OsmAndApp.h"
#import "OASavingTrackHelper.h"
#import "OATableData.h"

typedef NS_ENUM(NSUInteger, EOATrackHudMode)
{
    EOATrackMenuHudMode = 0,
    EOATrackAppearanceHudMode,
};

@class OAGPX, OAGPXDocument, OAGPXTrackAnalysis, OAMapPanelViewController, OAMapViewController;

@interface OABaseTrackMenuHudViewController : OABaseScrollableHudViewController

@property (nonatomic, readonly) OAGPX *gpx;
@property (nonatomic, readonly) OAGPXDocument *doc;
@property (nonatomic, readonly) OAGPXTrackAnalysis *analysis;
@property (nonatomic, readonly) BOOL isCurrentTrack;
@property (nonatomic, readonly) BOOL isShown;

@property (nonatomic, readonly) OsmAndAppInstance app;
@property (nonatomic, readonly) OAAppSettings *settings;
@property (nonatomic, readonly) OASavingTrackHelper *savingHelper;

@property (nonatomic, readonly) OAMapPanelViewController *mapPanelViewController;
@property (nonatomic, readonly) OAMapViewController *mapViewController;
@property (nonatomic, readonly) NSArray<NSDictionary *> *tableData;
@property (nonatomic, readonly) OATableData *menuTableData;

- (instancetype)initWithGpx:(OAGPX *)gpx;

- (void)updateGpxData;
- (void)generateData:(NSInteger)section;
- (void)generateData:(NSInteger)section row:(NSInteger)row;
- (OATableCellData *)getCellData:(NSIndexPath *)indexPath;
- (NSDictionary *)getItem:(NSIndexPath *)indexPath;

- (NSLayoutConstraint *)createBaseEqualConstraint:(UIView *)firstItem
                                   firstAttribute:(NSLayoutAttribute)firstAttribute
                                       secondItem:(UIView *)secondItem
                                  secondAttribute:(NSLayoutAttribute)secondAttribute;

- (NSLayoutConstraint *)createBaseEqualConstraint:(UIView *)firstItem
                                   firstAttribute:(NSLayoutAttribute)firstAttribute
                                       secondItem:(UIView *)secondItem
                                  secondAttribute:(NSLayoutAttribute)secondAttribute
                                         constant:(CGFloat)constant;

@end
