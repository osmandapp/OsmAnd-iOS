//
//  OABaseNavbarViewController.h
//  OsmAnd
//
//  Created by Skalii on 08.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OASuperViewController.h"

typedef NS_ENUM(NSInteger, EOABaseNavbarColorScheme)
{
    EOABaseNavbarColorSchemeOrange = 0,
    EOABaseNavbarColorSchemeGray,
    EOABaseNavbarColorSchemeWhite
};

typedef NS_ENUM(NSInteger, EOABaseTableHeaderMode)
{
    EOABaseTableHeaderModeNone = 0,
    EOABaseTableHeaderModeDescription,
    EOABaseTableHeaderModeBigTitle,
    EOABaseTableHeaderModeBigTitleWithRightIcon
};

@interface OABaseNavbarViewController : OASuperViewController<UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIButton *leftNavbarButton;
@property (weak, nonatomic) IBOutlet UIButton *rightNavbarButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIView *separatorNavbarView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (void)commonInit;
- (void)postInit;

- (void)setupTableHeaderView;
- (NSString *)getTitle;
- (NSString *)getSubtitle;
- (NSString *)getLeftNavbarButtonTitle;
- (NSString *)getRightNavbarButtonTitle;
- (EOABaseNavbarColorScheme)getNavbarColorScheme;
- (BOOL)isNavbarSeparatorVisible;
- (BOOL)isChevronIconVisible;
- (BOOL)isNavbarBlurring;
- (EOABaseTableHeaderMode)getTableHeaderMode;
- (NSString *)getTableHeaderDescription;
- (BOOL)isTableHeaderHasHiddenSeparator;

- (void)generateData;
- (BOOL)hideFirstHeader;
- (NSString *)getTitleForHeader:(NSInteger)section;
- (NSString *)getTitleForFooter:(NSInteger)section;
- (NSInteger)rowsCount:(NSInteger)section;
- (UITableViewCell *)getRow:(NSIndexPath *)indexPath;
- (NSInteger)sectionsCount;
- (CGFloat)getCustomHeightForHeader:(NSInteger)section;
- (CGFloat)getCustomHeightForFooter:(NSInteger)section;
- (UIView *)getCustomViewForHeader:(NSInteger)section;
- (UIView *)getCustomViewForFooter:(NSInteger)section;
- (void)onRowPressed:(NSIndexPath *)indexPath;

- (void)onScrollViewDidScroll:(UIScrollView *)scrollView;
- (void)onRotation;
- (IBAction)onLeftNavbarButtonPressed:(UIButton *)sender;
- (IBAction)onRightNavbarButtonPressed:(UIButton *)sender;

@end
