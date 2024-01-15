//
//  OABaseNavbarViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 08.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAUtilities.h"
#import "OASizes.h"
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import "GeneratedAssetSymbols.h"

#define kRightIconLargeTitleSmall 34.
#define kRightIconLargeTitleLarge 40.
#define kDefaultBarButtonSize 44.

@implementation OABaseNavbarViewController
{
    BOOL _isHeaderBlurred;
    BOOL _isRotating;
    CGFloat _navbarHeightCurrent;
    CGFloat _navbarHeightSmall;
    CGFloat _navbarHeightLarge;
    UIView *_rightIconLargeTitle;

    UIBarButtonItem *_leftNavbarButton;
    UILongPressGestureRecognizer *_leftButtonLongTapRecognizer;
}

#pragma mark - Initialization

- (instancetype)init
{
    self = [super initWithNibName:@"OABaseNavbarViewController" bundle:nil];
    if (self)
    {
        [self initTableData];
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

- (void)initTableData
{
    _tableData = [[OATableDataModel alloc] init];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.refreshOnAppear)
        [self generateData];
    
    if ([self getNavbarStyle] == EOABaseNavbarStyleCustomLargeTitle)
        [self.navigationItem hideTitleInStackView:YES defaultTitle:[self getTitle] defaultSubtitle:[self getSubtitle]];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    NSString *tableFooterText = [self getTableFooterText];
    if (tableFooterText && tableFooterText.length > 0)
    {
        self.tableView.tableFooterView = [OAUtilities setupTableHeaderViewWithText:tableFooterText
                                                                              font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]
                                                                         textColor:[UIColor colorNamed:ACColorNameTextColorSecondary]
                                                                        isBigTitle:NO
                                                                   parentViewWidth:self.view.frame.size.width];
        
        self.tableView.tableFooterView.backgroundColor = [UIColor colorNamed:ACColorNameViewBg];
    }

    [self updateNavbar];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;

    if (self.refreshOnAppear)
    {
        [self generateData];
        [self.tableView reloadData];
    }

    self.navigationController.navigationBar.prefersLargeTitles = YES;
    if ([self.navigationController isNavigationBarHidden] && [self isNavbarVisible])
        [self.navigationController setNavigationBarHidden:NO animated:YES];

    [self updateAppearance];

    if (_navbarHeightSmall == 0)
        _navbarHeightSmall = self.navigationController.navigationBar.frame.size.height;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (!_isRotating && [self isScreenLoaded])
        [self setupTableHeaderView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    CGFloat navbarHeight = self.navigationController.navigationBar.frame.size.height;
    _navbarHeightCurrent = navbarHeight;
    [self updateRightIconLargeTitle];
    [self moveAndResizeImage:_navbarHeightCurrent];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (_rightIconLargeTitle)
    {
        [_rightIconLargeTitle removeFromSuperview];
        _rightIconLargeTitle = nil;
    }

    if (![self.navigationController isNavigationBarHidden])
    {
        //hide root navbar if open screen without navbar
        if (![self.navigationController.viewControllers.lastObject isNavbarVisible])
            [self.navigationController setNavigationBarHidden:YES animated:YES];

        //reset navbar to default appearance
        NSArray<UIViewController *> *viewControllers = self.navigationController.viewControllers;
        BOOL closeEntireStack = viewControllers.count == 2 && [viewControllers.firstObject isKindOfClass:self.class];
        if (viewControllers.count <= 1 || closeEntireStack)
        {
            self.navigationController.navigationBar.prefersLargeTitles = NO;
            UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
            [appearance configureWithDefaultBackground];
            self.navigationController.navigationBar.standardAppearance = appearance;
            self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
            self.navigationController.navigationBar.tintColor = nil;
        }
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    _isRotating = YES;
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    __weak OABaseNavbarViewController *weakSelf = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [weakSelf updateNavbar];
        [weakSelf updateRightIconLargeTitle];
        [weakSelf moveAndResizeImage:weakSelf.navigationController.navigationBar.frame.size.height];
        [weakSelf onRotation];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        _isRotating = NO;
    }];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if ([self getNavbarColorScheme] == EOABaseNavbarColorSchemeOrange || self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark)
        return UIStatusBarStyleLightContent;

    return UIStatusBarStyleDarkContent;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
        [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - Base setup UI

- (void)applyLocalization
{
    self.title = [self getTitle];
    NSString *sub = [self getSubtitle];
    UIImage *centerIcon = [self getCenterIconAboveTitle];
    if ((sub && sub.length > 0))
    {
        BOOL isTitleHidden = [self.navigationItem isTitleInStackViewHidden];
        if (isTitleHidden)
        {
            [self.navigationItem hideTitleInStackView:YES defaultTitle:[self getTitle] defaultSubtitle:[self getSubtitle]];
        }
        else
        {
            [self.navigationItem setStackViewWithTitle:[self getTitle]
                                            titleColor:[self getTitleColor]
                                             titleFont:[UIFont scaledSystemFontOfSize:17. weight:UIFontWeightSemibold maximumSize:22.]
                                              subtitle:sub
                                         subtitleColor:[UIColor colorNamed:ACColorNameTextColorSecondary]
                                          subtitleFont:[UIFont scaledSystemFontOfSize:13. maximumSize:18.]];
        }
    }
    else if (centerIcon)
    {
        [self.navigationItem setStackViewWithCenterIcon:centerIcon];
    }
    if (_leftNavbarButton)
    {
        UIButton *leftButton = _leftNavbarButton.customView;
        [leftButton setTitle:[self getLeftNavbarButtonTitle] forState:UIControlStateNormal];
    }
}

- (BOOL)isNavbarVisible
{
    return YES;
}

- (void)updateAppearance
{
    BOOL isLargeTitle = [self getNavbarStyle] == EOABaseNavbarStyleLargeTitle;

    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = [self getNavbarBackgroundColor];
    appearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : [self getNavbarStyle] == EOABaseNavbarStyleCustomLargeTitle ? UIColor.clearColor : [self getTitleColor]
    };
    appearance.largeTitleTextAttributes = @{
        NSForegroundColorAttributeName : [self getLargeTitleColor]
    };

    UINavigationBarAppearance *blurAppearance = [[UINavigationBarAppearance alloc] init];
    
    if (![self isNavbarSeparatorVisible])
    {
        appearance.shadowImage = nil;
        appearance.shadowColor = nil;
        blurAppearance.shadowColor = nil;
        blurAppearance.shadowImage = nil;
    }
    
    if ([self getNavbarColorScheme] == EOABaseNavbarColorSchemeOrange)
    {
        blurAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
        blurAppearance.backgroundColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
        blurAppearance.titleTextAttributes = @{
            NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
            NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameNavBarTextColorPrimary]
        };
    }
    
    self.navigationController.navigationBar.standardAppearance = blurAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;

    self.navigationController.navigationBar.tintColor = [self getNavbarButtonsTintColor];
    self.navigationItem.largeTitleDisplayMode = isLargeTitle ? UINavigationItemLargeTitleDisplayModeAlways : UINavigationItemLargeTitleDisplayModeNever;
}

- (void)updateNavbar
{
    [self setupNavbarButtons];
    if ([self isScreenLoaded])
        [self setupTableHeaderView];
    if (_rightIconLargeTitle)
        [self updateRightIconLargeTitle];
}

- (void)refreshUI
{
    [self applyLocalization];
    [self updateNavbar];
}

- (void)updateUI
{
    [self updateUI:NO completion:nil];
}

- (void)updateUIAnimated:(void (^)(BOOL finished))completion
{
    [self updateUI:YES completion:completion];
}

- (void)updateUI:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
    [self reloadDataWithAnimated:animated completion:completion];
    [self refreshUI];
}

- (void)updateWithoutData
{
    [self refreshUI];
    [self.tableView reconfigureRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows];
}

- (void)reloadDataWithAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
    [self generateData];
    if (animated)
    {
        [UIView transitionWithView:self.view
                          duration:.2
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^(void)
                        {
                            [self.tableView reloadData];
                        }
                        completion:completion];
    }
    else
    {
        [self.tableView reloadData];
        if (completion)
            completion(YES);
    }
}

- (void)updateRightIconLargeTitle
{
    if (_rightIconLargeTitle)
    {
        [_rightIconLargeTitle removeFromSuperview];
        _rightIconLargeTitle = nil;
    }

    if (self.navigationController.viewControllers.lastObject != self)
        return;

    UIImage *rightIconLargeTitle = [self getRightIconLargeTitle];
    if (rightIconLargeTitle && [self getNavbarStyle] == EOABaseNavbarStyleLargeTitle)
    {
        CGFloat navbarHeight = _navbarHeightCurrent;
        if (navbarHeight > _navbarHeightSmall)
        {
            navbarHeight -= _navbarHeightSmall;
            if (_navbarHeightLarge == 0)
                _navbarHeightLarge = navbarHeight;
        }
        CGFloat baseIconSize = navbarHeight == _navbarHeightLarge ? kRightIconLargeTitleLarge : kRightIconLargeTitleSmall;
        CGFloat iconFrameOffsetSize = 2.;
        CGFloat iconFrameSize = baseIconSize - iconFrameOffsetSize * 2;

        UIImageView *iconView = [[UIImageView alloc] init];
        UIView *iconContainer = [[UIView alloc] init];
        [iconContainer addSubview:iconView];

        iconView.clipsToBounds = YES;
        iconView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [iconView.leadingAnchor constraintEqualToAnchor:iconContainer.leadingAnchor constant:iconFrameOffsetSize],
            [iconView.topAnchor constraintEqualToAnchor:iconContainer.topAnchor constant:iconFrameOffsetSize],
            [iconView.heightAnchor constraintEqualToConstant:iconFrameSize],
            [iconView.widthAnchor constraintEqualToAnchor:iconView.heightAnchor]
        ]];

        iconContainer.backgroundColor = UIColor.whiteColor;
        iconView.contentMode = UIViewContentModeCenter;
        iconView.image = rightIconLargeTitle.imageFlippedForRightToLeftLayoutDirection;
        UIColor *tintColor = [self getRightIconTintColorLargeTitle];
        if (tintColor)
            iconView.tintColor = tintColor;

        [self.navigationController.navigationBar addSubview:iconContainer];
        iconContainer.layer.cornerRadius = baseIconSize / 2;
        iconContainer.clipsToBounds = YES;
        iconContainer.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *horizontalConstraint;
        if ([self.view isDirectionRTL])
            horizontalConstraint = [iconContainer.leftAnchor constraintEqualToAnchor:self.navigationController.navigationBar.leftAnchor constant:16. + [OAUtilities getLeftMargin]];
        else
            horizontalConstraint = [iconContainer.rightAnchor constraintEqualToAnchor:self.navigationController.navigationBar.rightAnchor constant:-(16. + [OAUtilities getLeftMargin])];
        
        [NSLayoutConstraint activateConstraints:@[
            horizontalConstraint,
            [iconContainer.bottomAnchor constraintEqualToAnchor:self.navigationController.navigationBar.bottomAnchor constant:-((navbarHeight - baseIconSize) / 2)],
            [iconContainer.heightAnchor constraintEqualToConstant:baseIconSize],
            [iconContainer.widthAnchor constraintEqualToAnchor:iconContainer.heightAnchor]
        ]];
        _rightIconLargeTitle = iconContainer;
    }
}

- (void)setupNavbarButtons
{
    NSString *leftButtonTitle = [self getLeftNavbarButtonTitle];
    UIImage *leftNavbarButtonCustomIcon = [self getCustomIconForLeftNavbarButton];
    if ((([self isModal] && !leftButtonTitle) || (![self isModal] && leftButtonTitle && leftButtonTitle.length == 0)) && !leftNavbarButtonCustomIcon)
        leftNavbarButtonCustomIcon = [UIImage templateImageNamed:@"ic_navbar_chevron"];

    CGFloat freeSpaceForTitle = DeviceScreenWidth - (kPaddingOnSideOfContent + [OAUtilities getLeftMargin]) * 2;
    CGFloat freeSpaceForNavbarButton = freeSpaceForTitle;
    if (leftNavbarButtonCustomIcon)
        freeSpaceForTitle -= 71.;

    NSMutableParagraphStyle *titleParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    titleParagraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    NSDictionary<NSAttributedStringKey, id> *titleAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSParagraphStyleAttributeName : titleParagraphStyle
    };
    CGFloat titleWidth = [OAUtilities calculateTextBounds:[[NSAttributedString alloc] initWithString:self.title
                                                                                          attributes:titleAttributes]
                                                    width:freeSpaceForTitle].width;
    freeSpaceForNavbarButton -= titleWidth;
    freeSpaceForNavbarButton /= 2;
    freeSpaceForNavbarButton -= 12.;
    BOOL isLongTitle = freeSpaceForNavbarButton < 50.;

    _leftNavbarButton = nil;
    if (leftButtonTitle || leftNavbarButtonCustomIcon)
    {
        UIButton *leftButton = [[UIButton alloc] initWithFrame:CGRectMake(0., 0., freeSpaceForNavbarButton, 30.)];
        leftButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeading;
        leftButton.titleLabel.textAlignment = NSTextAlignmentLeft;
        leftButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        leftButton.titleLabel.numberOfLines = 1;
        leftButton.titleLabel.adjustsFontForContentSizeCategory = YES;
        leftButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        [leftButton setTintColor:[self getNavbarButtonsTintColor]];
        [leftButton setTitleColor:[self getNavbarButtonsTintColor] forState:UIControlStateNormal];
        [leftButton setTitleColor:[[self getNavbarButtonsTintColor] colorWithAlphaComponent:.3] forState:UIControlStateHighlighted];
        [leftButton setTitle:isLongTitle ? nil : leftButtonTitle forState:UIControlStateNormal];
        if (isLongTitle && !leftNavbarButtonCustomIcon)
        {
            leftNavbarButtonCustomIcon = [UIImage templateImageNamed:@"ic_navbar_chevron"];
            freeSpaceForNavbarButton = 30.;
        }
        [leftButton setImage:leftNavbarButtonCustomIcon forState:UIControlStateNormal];
        [leftButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [leftButton addTarget:self action:@selector(onLeftNavbarButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        leftButton.translatesAutoresizingMaskIntoConstraints = NO;
        [leftButton.widthAnchor constraintLessThanOrEqualToConstant:freeSpaceForNavbarButton].active = YES;
        
        _leftButtonLongTapRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLeftNavbarButtonLongtapPressed:)];
        [leftButton addGestureRecognizer:_leftButtonLongTapRecognizer];
        leftButton.userInteractionEnabled = YES;

        NSString *accessibilityLabel = [self getCustomAccessibilityForLeftNavbarButton];
        if (!accessibilityLabel)
            accessibilityLabel = leftButtonTitle ? leftButtonTitle : OALocalizedString(@"shared_string_back");
        _leftNavbarButton = [[UIBarButtonItem alloc] initWithCustomView:leftButton];
        _leftNavbarButton.accessibilityLabel = accessibilityLabel;
        [self.navigationItem setLeftBarButtonItem:_leftNavbarButton animated:YES];
    }
    else
    {
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    }

    NSArray<UIBarButtonItem *> *rightNavbarButtons = [self getRightNavbarButtons];
    if (rightNavbarButtons && rightNavbarButtons.count > 0)
    {
        NSMutableArray<UIBarButtonItem *> *rightNavbarButtonsWithSpaces = [NSMutableArray array];
        if (rightNavbarButtons.count > 1)
        {
            freeSpaceForNavbarButton -= (rightNavbarButtons.count - 1) * 8.;
            freeSpaceForNavbarButton /= rightNavbarButtons.count;
        }
        if (freeSpaceForNavbarButton < kDefaultBarButtonSize)
            freeSpaceForNavbarButton = kDefaultBarButtonSize;
        for (NSInteger i = 0; i < rightNavbarButtons.count; i++)
        {
            UIBarButtonItem *buttonItem = rightNavbarButtons[i];
            [rightNavbarButtonsWithSpaces addObject:buttonItem];
            UIButton *button = buttonItem.customView;
            if (button)
            {
                CGFloat buttonWidth = kDefaultBarButtonSize;
                NSString *buttonTitle = [button titleForState:UIControlStateNormal];
                if (buttonTitle && buttonTitle.length > 0)
                    buttonWidth = [OAUtilities calculateTextBounds:buttonTitle width:freeSpaceForNavbarButton font:button.titleLabel.font].width;
                [button.widthAnchor constraintEqualToConstant:buttonWidth].active = YES;
                button.contentHorizontalAlignment = i == 0 ? UIControlContentHorizontalAlignmentTrailing : UIControlContentHorizontalAlignmentCenter;
                button.titleLabel.textAlignment = i == 0 ? NSTextAlignmentRight : NSTextAlignmentCenter;
            }
        }
        [self.navigationItem setRightBarButtonItems:rightNavbarButtonsWithSpaces animated:YES];
    }
    else
    {
        [self.navigationItem setRightBarButtonItems:nil animated:YES];
    }
}

- (UIBarButtonItem *)createRightNavbarButton:(NSString *)title
                              systemIconName:(NSString *)iconName
                                      action:(SEL)action
                                        menu:(UIMenu *)menu
{
    return [self createRightNavbarButton:title icon:[UIImage systemImageNamed:iconName withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:24.]] action:action menu:menu];
}

- (UIBarButtonItem *)createRightNavbarButton:(NSString *)title
                                    iconName:(NSString *)iconName
                                      action:(SEL)action
                                        menu:(UIMenu *)menu
{
    return [self createRightNavbarButton:title icon:[UIImage templateImageNamed:iconName] action:action menu:menu];
}

- (UIBarButtonItem *)createRightNavbarButton:(NSString *)title
                                    icon:(UIImage *)icon
                                      action:(SEL)action
                                        menu:(UIMenu *)menu
{
    return [self.class createRightNavbarButton:title icon:icon color:[self getNavbarButtonsTintColor] action:action menu:menu];
}

+ (UIBarButtonItem *)createRightNavbarButton:(NSString *)title
                                    icon:(UIImage *)icon
                                       color:(UIColor *)color
                                      action:(SEL)action
                                        menu:(UIMenu *)menu
{
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0., 0., kDefaultBarButtonSize, 30.)];
    button.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    button.titleLabel.numberOfLines = 1;
    button.titleLabel.adjustsFontForContentSizeCategory = YES;
    button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    [button setTintColor:color];
    [button setTitleColor:color forState:UIControlStateNormal];
    [button setTitleColor:[color colorWithAlphaComponent:.3] forState:UIControlStateHighlighted];
    [button setTitle:title forState:UIControlStateNormal];
    [button setImage:icon forState:UIControlStateNormal];
    [button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    if (menu)
    {
        button.showsMenuAsPrimaryAction = YES;
        button.menu = menu;
    }
    UIBarButtonItem *rightNavbarButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    if (title)
        rightNavbarButton.accessibilityLabel = title;
    return rightNavbarButton;
}

- (void)changeButtonAvailability:(UIBarButtonItem *)barButtonItem isEnabled:(BOOL)isEnabled
{
    if (barButtonItem.customView && [barButtonItem.customView isKindOfClass:UIButton.class])
    {
        UIButton *button = barButtonItem.customView;
        button.enabled = isEnabled;
        button.tintColor = isEnabled ? [self getNavbarButtonsTintColor] : UIColor.lightGrayColor;
        [button setTitleColor:isEnabled ? [self getNavbarButtonsTintColor] : UIColor.lightGrayColor forState:UIControlStateNormal];
    }
}

- (BOOL)isAnyLargeTitle
{
    return [self getNavbarStyle] == EOABaseNavbarStyleLargeTitle || [self getNavbarStyle] == EOABaseNavbarStyleCustomLargeTitle;
}

- (UIColor *)getNavbarBackgroundColor
{
    if ([self isAnyLargeTitle])
        return self.tableView.backgroundColor;

    EOABaseNavbarColorScheme colorScheme = [self getNavbarColorScheme];
    switch (colorScheme)
    {
        case EOABaseNavbarColorSchemeOrange:
            return [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
        case EOABaseNavbarColorSchemeWhite:
            return [UIColor colorNamed:ACColorNameGroupBg];
        default:
            return self.tableView.backgroundColor;
    }
}

- (UIColor *)getNavbarButtonsTintColor
{
    return [self getNavbarColorScheme] == EOABaseNavbarColorSchemeOrange ? [UIColor colorNamed:ACColorNameNavBarTextColorPrimary] : [UIColor colorNamed:ACColorNameIconColorActive];
}

- (UIColor *)getTitleColor
{
    return [self getNavbarColorScheme] == EOABaseNavbarColorSchemeOrange ? [UIColor colorNamed:ACColorNameNavBarTextColorPrimary] : [UIColor colorNamed:ACColorNameTextColorPrimary];
}

- (UIColor *)getLargeTitleColor
{
    return [UIColor colorNamed:ACColorNameTextColorPrimary];
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
    return nil;
}

- (UIBarButtonItem *)getLeftNavbarButton
{
    return _leftNavbarButton;
}

- (UIImage *)getCustomIconForLeftNavbarButton
{
    return nil;
}

- (NSString *)getCustomAccessibilityForLeftNavbarButton
{
    return nil;
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    return nil;
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeGray;
}

- (BOOL)isNavbarBlurring
{
    return [self getNavbarColorScheme] != EOABaseNavbarColorSchemeOrange;
}

- (BOOL)isNavbarSeparatorVisible
{
    return [self getNavbarColorScheme] != EOABaseNavbarColorSchemeOrange;
}

- (UIImage *)getCenterIconAboveTitle
{
    return nil;
}

- (UIImage *)getRightIconLargeTitle
{
    return nil;
}

- (UIColor *)getRightIconTintColorLargeTitle
{
    return nil;
}

- (EOABaseNavbarStyle)getNavbarStyle
{
    return EOABaseNavbarStyleSimple;
}

- (NSString *)getTableHeaderDescription
{
    return @"";
}

- (NSAttributedString *)getTableHeaderDescriptionAttr
{
    return nil;
}

- (void)setupTableHeaderView
{
    EOABaseNavbarStyle style = [self getNavbarStyle];
    UIView *tableHeaderView;
    BOOL isCustomLargeTitle = style == EOABaseNavbarStyleCustomLargeTitle;
    NSString *tableHeaderDescription = [self getTableHeaderDescription];
    NSAttributedString *tableHeaderDescriptionAttr = [self getTableHeaderDescriptionAttr];
    if (isCustomLargeTitle || (tableHeaderDescription && tableHeaderDescription.length > 0))
    {
        tableHeaderView = [OAUtilities setupTableHeaderViewWithText:isCustomLargeTitle ? [self getTitle] : tableHeaderDescription
                                                               font:isCustomLargeTitle ? kHeaderBigTitleFont : kHeaderDescriptionFontSmall
                                                          textColor:isCustomLargeTitle ? [UIColor colorNamed:ACColorNameTextColorPrimary] : [UIColor colorNamed:ACColorNameTextColorSecondary]
                                                         isBigTitle:isCustomLargeTitle
                                                    parentViewWidth:self.view.frame.size.width];
    }
    else if (tableHeaderDescriptionAttr && tableHeaderDescriptionAttr.length > 0)
    {
        tableHeaderView = [OAUtilities setupTableHeaderViewWithText:tableHeaderDescriptionAttr
                                                         isBigTitle:NO
                                                      rightIconName:nil
                                                          tintColor:nil
                                                    parentViewWidth:self.view.frame.size.width];
    }
    if (![self useCustomTableViewHeader])
    {
        self.tableView.tableHeaderView = tableHeaderView;
        self.tableView.tableHeaderView.backgroundColor = [UIColor colorNamed:ACColorNameViewBg];
    }
}

- (NSString *)getTableFooterText
{
    return @"";
}

- (CGFloat)getNavbarHeight
{
    return [OAUtilities getTopMargin] + _navbarHeightCurrent;
}

#pragma mark - Table data

- (void)generateData
{
}

- (BOOL)useCustomTableViewHeader
{
    return NO;
}

- (BOOL)hideFirstHeader
{
    return NO;
}

- (BOOL) refreshOnAppear
{
    return NO;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    if (self.tableData.sectionCount > 0)
        return [self.tableData sectionDataForIndex:section].headerText;
    return nil;
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    if (self.tableData.sectionCount > 0)
        return [self.tableData sectionDataForIndex:section].footerText;
    return nil;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    if (self.tableData.sectionCount > 0)
        return [self.tableData rowCount:section];
    return 0;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSInteger)sectionsCount
{
    return self.tableData.sectionCount;
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

#pragma mark - Selectors

- (IBAction)onLeftNavbarButtonLongtapPressed:(UIButton *)sender
{
    [self onLeftNavbarButtonLongtapPressed];
}

- (void)onLeftNavbarButtonLongtapPressed
{
    [self dismissViewController];
}

- (void)onRightNavbarButtonPressed
{
    [self dismissViewController];
}

// override with super to work correctly
- (void)onContentSizeChanged:(NSNotification *)notification
{
    [self setupTableHeaderView];
    [self generateData];
    [self.tableView reloadData];
}

- (void)onScrollViewDidScroll:(UIScrollView *)scrollView
{
}

- (void)onRotation
{
}

- (BOOL)onGestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return [self onGestureRecognizerShouldBegin:gestureRecognizer];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - UIScrollViewDelegate

- (void)moveAndResizeImage:(CGFloat)height
{
    if (_rightIconLargeTitle && [self getNavbarStyle] == EOABaseNavbarStyleLargeTitle)
    {
        CGFloat delta = height - _navbarHeightSmall;
        CGFloat heightDifferenceBetweenStates = _navbarHeightLarge - _navbarHeightSmall;
        CGFloat coeff = delta / heightDifferenceBetweenStates;
        CGFloat factor = kRightIconLargeTitleSmall / kRightIconLargeTitleLarge;
        CGFloat sizeAddendumFactor = coeff * (1. - factor);
        CGFloat scale = MIN(1., sizeAddendumFactor + factor);

        CGFloat sizeDiff = kRightIconLargeTitleLarge * (1. - factor);
        CGFloat iconBottomMarginForLargeState = (_navbarHeightLarge - kRightIconLargeTitleLarge) / 2;
        CGFloat iconBottomMarginForSmallState = (_navbarHeightSmall - kRightIconLargeTitleSmall) / 2;
        CGFloat maxYTranslation = iconBottomMarginForLargeState - iconBottomMarginForSmallState + sizeDiff;
        CGFloat yTranslation = MAX(0, MIN(maxYTranslation, (maxYTranslation - coeff * (iconBottomMarginForSmallState + sizeDiff))));
        CGFloat xTranslation = MAX(0, sizeDiff - coeff * sizeDiff);

        _rightIconLargeTitle.transform = CGAffineTransformTranslate(CGAffineTransformScale(CGAffineTransformIdentity, scale, scale), xTranslation, yTranslation);
    }
}

- (CGFloat)getCustomTitleHeaderTopOffset
{
    return 0.;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!_isRotating && [self isScreenLoaded])
    {
        CGFloat navbarHeight = self.navigationController.navigationBar.frame.size.height;
        if (_navbarHeightCurrent != navbarHeight && (navbarHeight >= (_navbarHeightLarge + _navbarHeightSmall) && [self getNavbarStyle] == EOABaseNavbarStyleLargeTitle))
        {
            _navbarHeightCurrent = _navbarHeightLarge + _navbarHeightSmall;
            [self updateRightIconLargeTitle];
        }

        [self moveAndResizeImage:self.navigationController.navigationBar.frame.size.height];

        if ([self getNavbarStyle] == EOABaseNavbarStyleCustomLargeTitle)
        {
            UINavigationBarAppearance *appearance = self.navigationController.navigationBar.standardAppearance;
            BOOL hasSubtitle = [self getSubtitle] && [self getSubtitle].length > 0;
            BOOL isTitleHidden = hasSubtitle ? [self.navigationItem isTitleInStackViewHidden] : [appearance.titleTextAttributes[NSForegroundColorAttributeName] isEqual:UIColor.clearColor];
            CGFloat y = scrollView.contentOffset.y + _navbarHeightSmall + _navbarHeightLarge;
            if (![self isModal])
                y += [OAUtilities getTopMargin];
            CGFloat titleVisiblePosition = (self.tableView.tableHeaderView ? self.tableView.tableHeaderView.frame.size.height : (_navbarHeightCurrent + 56.)) * .75 + [self getCustomTitleHeaderTopOffset];
            if (y > 0)
            {
                if (y > titleVisiblePosition && isTitleHidden)
                {
                    if (hasSubtitle)
                    {
                        [self.navigationItem hideTitleInStackView:NO defaultTitle:[self getTitle] defaultSubtitle:[self getSubtitle]];
                    }
                    else
                    {
                        appearance.titleTextAttributes = @{
                            NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
                            NSForegroundColorAttributeName : [self getTitleColor]
                        };
                    }
                }
                else if (y < titleVisiblePosition && !isTitleHidden)
                {
                    if (hasSubtitle)
                    {
                        [self.navigationItem hideTitleInStackView:YES defaultTitle:[self getTitle] defaultSubtitle:[self getSubtitle]];
                    }
                    else
                    {
                        appearance.titleTextAttributes = @{
                            NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
                            NSForegroundColorAttributeName : UIColor.clearColor
                        };
                    }
                }
            }
            else if (y <= 0 && !isTitleHidden)
            {
                if (hasSubtitle)
                {
                    [self.navigationItem hideTitleInStackView:YES defaultTitle:[self getTitle] defaultSubtitle:[self getSubtitle]];
                }
                else
                {
                    appearance.titleTextAttributes = @{
                        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
                        NSForegroundColorAttributeName : UIColor.clearColor
                    };
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

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
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
