//
//  OABaseTrackMenuHudViewController.h
//  OsmAnd
//
//  Created by Skalii on 25.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseScrollableHudViewController.h"
#import "OATrackMenuHeaderView.h"

typedef NS_ENUM(NSUInteger, EOATrackHudMode)
{
    EOATrackMenuHudMode = 0,
    EOATrackAppearanceHudMode,
};

@class OAGPX;

@interface OABaseTrackMenuHudViewController : OABaseScrollableHudViewController

@property (weak, nonatomic) IBOutlet UIView *backButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *backButtonLeadingConstraint;

- (instancetype)initWithGpx:(OAGPX *)gpx;

- (void)commonInit;
- (void)dismiss:(void (^)(void))onComplete;
- (void)setupView;
- (void)setupHeaderView;
- (void)generateData;
- (void)generateData:(NSInteger)section;
- (void)generateData:(NSInteger)section row:(NSInteger)row;
- (NSArray<NSDictionary *> *)getCellsDataForSection:(NSInteger)section;
- (NSDictionary *)getCellDataForRow:(NSInteger)row section:(NSInteger)section;
- (NSDictionary *)getItem:(NSIndexPath *)indexPath;

@end
