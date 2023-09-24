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

typedef NS_ENUM(NSInteger, EOABaseNavbarStyle)
{
    EOABaseNavbarStyleSimple = 0,
    EOABaseNavbarStyleLargeTitle,
    EOABaseNavbarStyleCustomLargeTitle
};

@class OATableDataModel;

@interface OABaseNavbarViewController : OASuperViewController<UIGestureRecognizerDelegate, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, readonly) OATableDataModel *tableData;

- (void)commonInit;
- (void)postInit;

- (void)updateAppearance;
- (void)updateNavbar;
- (void)updateUI:(BOOL)animated;
- (void)updateUI:(BOOL)animated completion:(void (^)(void))completion;
- (void)updateUIWithoutData:(void (^)(void))completion;
- (void)refreshUI;

- (UIBarButtonItem *)createRightNavbarButton:(NSString *)title
                                    iconName:(NSString *)iconName
                                      action:(SEL)action
                                        menu:(UIMenu *)menu;
- (UIBarButtonItem *)createRightNavbarButton:(NSString *)title
                              systemIconName:(NSString *)iconName
                                      action:(SEL)action
                                        menu:(UIMenu *)menu;
- (void)changeButtonAvailability:(UIBarButtonItem *)barButtonItem isEnabled:(BOOL)isEnabled;

- (NSString *)getTitle;
- (NSString *)getSubtitle;
- (NSString *)getLeftNavbarButtonTitle;
- (UIBarButtonItem *)getLeftNavbarButton;
- (UIImage *)getCustomIconForLeftNavbarButton;
- (NSString *)getCustomAccessibilityForLeftNavbarButton;
- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons;
- (EOABaseNavbarColorScheme)getNavbarColorScheme;
- (BOOL)isNavbarBlurring;
- (BOOL)isNavbarSeparatorVisible;
- (UIImage *)getRightIconLargeTitle;
- (UIColor *)getRightIconTintColorLargeTitle;
- (EOABaseNavbarStyle)getNavbarStyle;
- (NSString *)getTableHeaderDescription;
- (NSAttributedString *)getTableHeaderDescriptionAttr;
- (void)setupTableHeaderView;
- (NSString *)getTableFooterText;

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
- (void)onRowSelected:(NSIndexPath *)indexPath;
- (void)onRowDeselected:(NSIndexPath *)indexPath;

- (void)onRightNavbarButtonPressed;
- (void)onScrollViewDidScroll:(UIScrollView *)scrollView;
- (void)onRotation;
- (BOOL)onGestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer;

// Use to refresh button appearance
- (void)setupNavbarButtons;

@end
