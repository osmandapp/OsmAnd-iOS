//
//  OABaseNavbarViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 08.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"
#import "OASimpleTableViewCell.h"
#import "OAUtilities.h"
#import "OASizes.h"
#import "OAColors.h"
#import "Localization.h"

@interface OABaseNavbarViewController ()

@property (weak, nonatomic) IBOutlet UIView *navbarBackgroundView;
@property (weak, nonatomic) IBOutlet UIStackView *navbarStackView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *navbarStackViewEstimatedHeightConstraint;

@end

@implementation OABaseNavbarViewController
{
    BOOL _isHeaderBlurred;
    BOOL _isRotating;
}

#pragma mark - Initialization

- (instancetype)init
{
    self = [super initWithNibName:@"OABaseNavbarViewController" bundle:nil];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
}

// use in overridden init method if class properties have complex dependencies
- (void)postInit
{
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;

    [self updateNavbar];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = UIColorFromRGB(color_primary_table_background);
    self.tableView.tintColor = UIColorFromRGB(color_primary_purple);

    [self generateData];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    _isRotating = YES;
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateNavbarStackViewEstimatedHeight];
        [self setupTableHeaderView];
        [self onRotation];
        [self.tableView reloadData];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        _isRotating = NO;
    }];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if ([self getNavbarColorScheme] == EOABaseNavbarColorSchemeOrange)
        return UIStatusBarStyleLightContent;

    return UIStatusBarStyleDarkContent;
}

#pragma mark - Base setup UI

- (void)applyLocalization
{
    self.titleLabel.text = [self getTitle];
    self.subtitleLabel.text = [self getSubtitle];
    [self.leftNavbarButton setTitle:[self getLeftNavbarButtonTitle] forState:UIControlStateNormal];
    [self.rightNavbarButton setTitle:[self getRightNavbarButtonTitle] forState:UIControlStateNormal];
}

- (void)updateNavbar
{
    [self setupNavbarButtons];
    [self setupNavbarFonts];
    [self updateNavbarStackViewEstimatedHeight];
    [self setupTableHeaderView];

    self.titleLabel.textColor = [self getTitleColor];
    NSString *title = [self getTitle];
    self.titleLabel.hidden = !title || title.length == 0;
    NSString *subtitle = [self getSubtitle];
    self.subtitleLabel.hidden = !subtitle || subtitle.length == 0;
    self.separatorNavbarView.hidden = ![self isNavbarSeparatorVisible] && ![self isTableHeaderHasHiddenSeparator];
    self.navbarBackgroundView.backgroundColor = [self getNavbarBackgroundColor];

    if ([self getTableHeaderMode] == EOABaseTableHeaderModeBigTitle)
    {
        self.titleLabel.alpha = 0.;
        self.subtitleLabel.alpha = 0.;
        self.separatorNavbarView.alpha = 0.;
    }
}

- (void)updateUI
{
    [self applyLocalization];
    [self updateNavbar];
    [self generateData];
    [self.tableView reloadData];
}

- (void)updateUIAnimated
{
    [UIView transitionWithView:self.view
                      duration:.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void)
                    {
                        [self updateUI];
                    }
                    completion:nil];
}

- (void)setupNavbarButtons
{
    UIColor *buttonsTintColor = [self getNavbarButtonsTintColor];
    [self.leftNavbarButton setTitleColor:buttonsTintColor forState:UIControlStateNormal];
    self.leftNavbarButton.tintColor = buttonsTintColor;
    [self.rightNavbarButton setTitleColor:buttonsTintColor forState:UIControlStateNormal];
    self.rightNavbarButton.tintColor = buttonsTintColor;

    BOOL isChevronIconVisible = [self isChevronIconVisible];
    [self.leftNavbarButton setImage:isChevronIconVisible ? [UIImage templateImageNamed:@"ic_navbar_chevron"] : nil
                           forState:UIControlStateNormal];
    self.leftNavbarButton.titleEdgeInsets = UIEdgeInsetsMake(0., isChevronIconVisible ? -10. : 0., 0., 0.);

    NSString *leftNavbarButtonTitle = [self getLeftNavbarButtonTitle];
    NSString *rightNavbarButtonTitle = [self getRightNavbarButtonTitle];
    BOOL hasLeftButton = (leftNavbarButtonTitle && leftNavbarButtonTitle.length > 0) || isChevronIconVisible;
    BOOL hasRightButton = rightNavbarButtonTitle && rightNavbarButtonTitle.length > 0;
    self.leftNavbarButton.hidden = !hasLeftButton && !hasRightButton;
    self.rightNavbarButton.hidden = !hasLeftButton && !hasRightButton;
    self.leftNavbarButton.enabled = hasLeftButton;
    self.rightNavbarButton.enabled = hasRightButton;
}

- (void)setupNavbarFonts
{
    self.leftNavbarButton.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightSemibold maximumSize:22.];
    self.rightNavbarButton.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightSemibold maximumSize:22.];
    self.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightSemibold maximumSize:22.];
    self.subtitleLabel.font = [UIFont scaledSystemFontOfSize:13. weight:UIFontWeightSemibold maximumSize:18.];
}

- (void)setupTableHeaderView
{
    EOABaseTableHeaderMode mode = [self getTableHeaderMode];
    UIView *tableHeaderView;
    if (mode != EOABaseTableHeaderModeNone)
    {
        BOOL isBigTitle = mode == EOABaseTableHeaderModeBigTitle;
        tableHeaderView = [OAUtilities setupTableHeaderViewWithText:isBigTitle ? [self getTitle] : [self getTableHeaderDescription]
                                                               font:isBigTitle ? kHeaderBigTitleFont : kHeaderDescriptionFont
                                                          textColor:isBigTitle ? UIColor.blackColor : UIColorFromRGB(color_text_footer)
                                                        isBigTitle:isBigTitle];
        if ([self isTableHeaderHasHiddenSeparator])
        {
            UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0., tableHeaderView.layer.frame.size.height - 1., DeviceScreenWidth, 1.)];
            separator.backgroundColor = UIColorFromRGB(color_tint_gray);
            [tableHeaderView addSubview:separator];
        }
    }
    self.tableView.tableHeaderView = tableHeaderView;
}

- (CGFloat)getNavbarHeight
{
    return self.navbarBackgroundView.frame.size.height;
}

- (CGFloat)getNavbarEstimatedHeight
{
    return self.navbarStackViewEstimatedHeightConstraint.constant;
}

- (void)updateNavbarEstimatedHeight
{
    self.navbarStackViewEstimatedHeightConstraint.constant = [self getNavbarHeight] - ([self isModal] ? 0. : [OAUtilities getTopMargin]);
    self.tableView.contentInset = UIEdgeInsetsMake(self.navbarStackViewEstimatedHeightConstraint.constant, 0, 0, 0);
}

- (void)updateNavbarStackViewEstimatedHeight
{
    CGFloat height = [self isNavbarSeparatorVisible] ? separatorNavBarHeight : 0.;
    height += [self isModal] && ![OAUtilities isLandscape] ? modalNavBarHeight : defaultNavBarHeight;
    self.navbarStackViewEstimatedHeightConstraint.constant = height;
}

- (void)resetNavbarEstimatedHeight
{
    self.navbarStackViewEstimatedHeightConstraint.constant = 0;
}

- (void)adjustScrollStartPosition
{
    self.tableView.contentOffset = CGPointMake(0., -[self getNavbarHeight]);
}

- (void)addAccessibilityLabels
{
    self.leftNavbarButton.accessibilityLabel = OALocalizedString(@"shared_string_back");
}

- (UIColor *)getNavbarBackgroundColor
{
    if ([self getTableHeaderMode] == EOABaseTableHeaderModeBigTitle)
        return UIColorFromRGB(color_primary_table_background);

    EOABaseNavbarColorScheme colorScheme = [self getNavbarColorScheme];
    switch (colorScheme)
    {
        case EOABaseNavbarColorSchemeOrange:
            return UIColorFromRGB(color_primary_orange_navbar_background);
        case EOABaseNavbarColorSchemeWhite:
            return UIColor.whiteColor;
        default:
            return UIColorFromRGB(color_primary_gray_navbar_background);
    }
}

- (UIColor *)getNavbarButtonsTintColor
{
    return [self getNavbarColorScheme] == EOABaseNavbarColorSchemeOrange ? UIColor.whiteColor : UIColorFromRGB(color_primary_purple);
}

- (UIColor *)getTitleColor
{
    return [self getNavbarColorScheme] == EOABaseNavbarColorSchemeOrange ? UIColor.whiteColor : UIColor.blackColor;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return @"";
}

- (NSString *)getSubtitle
{
    return @"";
}

- (NSString *)getLeftNavbarButtonTitle
{
    return @"";
}

- (NSString *)getRightNavbarButtonTitle
{
    return @"";
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeGray;
}

- (BOOL)isNavbarSeparatorVisible
{
    return [self getNavbarColorScheme] != EOABaseNavbarColorSchemeOrange;
}

- (BOOL)isChevronIconVisible
{
    return YES;
}

- (BOOL)isNavbarBlurring
{
    return [self getNavbarColorScheme] != EOABaseNavbarColorSchemeOrange;
}

- (EOABaseTableHeaderMode)getTableHeaderMode
{
    return EOABaseTableHeaderModeNone;
}

- (NSString *)getTableHeaderDescription
{
    return @"";
}

- (BOOL)isTableHeaderHasHiddenSeparator
{
    return NO;
}

#pragma mark - Table data

- (void)generateData
{
}

- (BOOL)hideFirstHeader
{
    return NO;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return @"";
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return @"";
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSInteger)sectionsCount
{
    return 0;
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    return UITableViewAutomaticDimension;
}

- (CGFloat)getCustomHeightForFooter:(NSInteger)section
{
    return UITableViewAutomaticDimension;
}

- (UIView *)getCustomViewForHeader:(NSInteger)section
{
    return nil;
}

- (UIView *)getCustomViewForFooter:(NSInteger)section
{
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
}
- (void)onRowDeselected:(NSIndexPath *)indexPath
{
}

#pragma mark - IBAction

- (IBAction)onRightNavbarButtonPressed:(UIButton *)sender
{
    [self onRightNavbarButtonPressed];
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    [self dismissViewController];
}

- (void)onContentSizeChanged:(NSNotification *)notification
{
    [super onContentSizeChanged:notification];
    [self setupTableHeaderView];
}

- (void)onScrollViewDidScroll:(UIScrollView *)scrollView
{
}

- (void)onRotation
{
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!_isRotating && [self isScreenLoaded])
    {
        if ([self isNavbarBlurring])
        {
            CGFloat y = scrollView.contentOffset.y + [self getNavbarHeight];
            CGFloat tableHeaderHeight = self.tableView.tableHeaderView.frame.size.height;
            BOOL isBigTitle = [self getTableHeaderMode] == EOABaseTableHeaderModeBigTitle;
            if (y > 0)
            {
                if (!_isHeaderBlurred)
                {
                    [UIView animateWithDuration:.2 animations:^{
                        [self.navbarBackgroundView addBlurEffect:YES cornerRadius:0. padding:0.];
                        _isHeaderBlurred = YES;
                    }];
                }
                else if (isBigTitle)
                {
                    if (y > tableHeaderHeight * .75)
                    {
                        if (self.titleLabel.alpha == 0.)
                        {
                            [UIView animateWithDuration:.2 animations:^{
                                self.titleLabel.alpha = 1.;
                                if (!self.subtitleLabel.hidden)
                                    self.subtitleLabel.alpha = 1.;
                            }];
                        }
                        BOOL needToHideSeparator = y <= tableHeaderHeight && self.separatorNavbarView.alpha == 1.;
                        BOOL needToShowSeparator = y >= tableHeaderHeight && self.separatorNavbarView.alpha == 0.;
                        if ([self isTableHeaderHasHiddenSeparator] && (needToHideSeparator || needToShowSeparator))
                            self.separatorNavbarView.alpha = needToHideSeparator ? 0. : 1.;
                    }
                    else if (y < tableHeaderHeight * .75 && self.titleLabel.alpha == 1.)
                    {
                        [UIView animateWithDuration:.2 animations:^{
                            self.titleLabel.alpha = 0.;
                            if (!self.subtitleLabel.hidden)
                                self.subtitleLabel.alpha = 0.;
                        }];
                    }
                }
            }
            else if (y <= 0)
            {
                if (isBigTitle)
                {
                    BOOL isTitleLabelHidden = self.titleLabel.alpha == 0.;
                    BOOL isSeparatorHidden = self.separatorNavbarView.hidden;
                    if (!isTitleLabelHidden)
                    {
                        [UIView animateWithDuration:.2 animations:^{
                            self.titleLabel.alpha = 0.;
                            if (!self.subtitleLabel.hidden)
                                self.subtitleLabel.alpha = 0.;
                        }];
                    }
                    if (!isSeparatorHidden)
                        self.separatorNavbarView.alpha = 0.;
                }

                if (_isHeaderBlurred)
                {
                    [UIView animateWithDuration:.2 animations:^{
                        [self.navbarBackgroundView removeBlurEffect:[self getNavbarBackgroundColor]];
                        _isHeaderBlurred = NO;
                    }];
                }
            }
        }

        [self onScrollViewDidScroll:scrollView];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0 && [self hideFirstHeader])
        return 0.001;

    return [self getCustomHeightForHeader:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [self getCustomHeightForFooter:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [self getCustomViewForHeader:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [self getCustomViewForFooter:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self onRowSelected:indexPath];

    if (!self.tableView.allowsMultipleSelectionDuringEditing)
    {
        UITableViewCell *row = [self getRow:indexPath];
        if (row && row.selectionStyle != UITableViewCellSelectionStyleNone)
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self onRowDeselected:indexPath];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self rowsCount:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self getRow:indexPath];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self sectionsCount];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self getTitleForHeader:section];
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [self getTitleForFooter:section];
}

@end

// !!!
// remove from project:
//
//tableView.separatorInset =
//- (CGFloat)heightForRow:(NSIndexPath *)indexPath
//- (CGFloat)heightForRow:(NSIndexPath *)indexPath estimated:(BOOL)estimated
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
//- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
