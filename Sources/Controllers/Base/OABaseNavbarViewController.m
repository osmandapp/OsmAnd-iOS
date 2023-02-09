//
//  OABaseNavbarViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 08.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"
#import "OAUtilities.h"
#import "OASizes.h"
#import "OAColors.h"

@interface OABaseNavbarViewController ()

@property (weak, nonatomic) IBOutlet UIView *navbarBackgroundView;
@property (weak, nonatomic) IBOutlet UIStackView *navbarStackView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *navBarHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *leftNavbarMarginView;
@property (weak, nonatomic) IBOutlet UIView *rightNavbarMarginView;

@property (weak, nonatomic) IBOutlet UIStackView *leftNavbarButtonStackView;
@property (weak, nonatomic) IBOutlet UIView *leftNavbarButtonMarginView;

@property (weak, nonatomic) IBOutlet UIStackView *rightNavbarButtonStackView;
@property (weak, nonatomic) IBOutlet UIView *rightNavbarButtonMarginView;

@end

@implementation OABaseNavbarViewController
{
    BOOL _isHeaderBlurred;
}

- (instancetype)init
{
    self = [super initWithNibName:@"OABaseNavbarViewController" bundle:nil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onContentSizeChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];

    [self setupNavbarButtons];
    [self setupNavbarFonts];
    [self setupNavBarHeightConstraint];

    self.navbarBackgroundView.backgroundColor = [self getNavbarColor];

//    self.tableView.dataSource = self;
//    self.tableView.delegate = self;
    self.tableView.contentInset = UIEdgeInsetsMake([self getNavbarHeight], 0, 0, 0);

    NSString *subtitle = [self getSubtitle];
    self.subtitleLabel.hidden = !subtitle || subtitle.length == 0;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self setupNavBarHeightConstraint];
        self.tableView.contentInset = UIEdgeInsetsMake([self getNavbarHeight], 0, 0, 0);
        [self onRotation];
        [self.tableView reloadData];
    } completion:nil];
}

- (void)applyLocalization
{
    [super applyLocalization];

    self.titleLabel.text = [self getTitle];
    self.subtitleLabel.text = [self getSubtitle];
    [self.leftNavbarButton setTitle:[self getLeftNavbarButtonTitle] forState:UIControlStateNormal];
    [self.rightNavbarButton setTitle:[self getRightNavbarButtonTitle] forState:UIControlStateNormal];
}

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

- (UIColor *)getNavbarColor
{
    return UIColorFromRGB(color_bottom_sheet_background);
}

- (UIColor *)getNavbarButtonsTintColor
{
    return UIColorFromRGB(color_primary_purple);
}

- (BOOL)hasChevronIcon
{
    return YES;
}

- (BOOL)blurringNavbar
{
    return NO;
}

- (void)setupNavbarButtons
{
    [self.leftNavbarButton setTitleColor:[self getNavbarButtonsTintColor] forState:UIControlStateNormal];
    self.leftNavbarButton.tintColor = [self getNavbarButtonsTintColor];
    [self.rightNavbarButton setTitleColor:[self getNavbarButtonsTintColor] forState:UIControlStateNormal];
    self.rightNavbarButton.tintColor = [self getNavbarButtonsTintColor];

    BOOL hasChevronIcon = [self hasChevronIcon];
    [self.leftNavbarButton setImage:hasChevronIcon ? [UIImage templateImageNamed:@"ic_navbar_chevron"] : nil
                           forState:UIControlStateNormal];
    self.leftNavbarButton.titleEdgeInsets = UIEdgeInsetsMake(0., hasChevronIcon ? -10. : 0., 0., 0.);

    NSString *leftNavbarButtonTitle = [self getLeftNavbarButtonTitle];
    BOOL hasLeftButton = !leftNavbarButtonTitle || leftNavbarButtonTitle.length == 0 || hasChevronIcon;
    self.leftNavbarButton.hidden = !hasLeftButton;
    self.leftNavbarButtonMarginView.hidden = !hasLeftButton || hasChevronIcon;

    NSString *rightNavbarButtonTitle = [self getRightNavbarButtonTitle];
    BOOL hasRightButton = !rightNavbarButtonTitle || rightNavbarButtonTitle.length == 0;
    self.rightNavbarButton.hidden = !hasRightButton;
    self.rightNavbarButtonMarginView.hidden = !hasRightButton;

    self.leftNavbarButtonStackView.hidden = !hasLeftButton || !hasRightButton;
    self.rightNavbarButtonStackView.hidden = !hasLeftButton || !hasRightButton;
}

- (void)setupNavbarFonts
{
    self.leftNavbarButton.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightSemibold maximumSize:22.];
    self.rightNavbarButton.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightSemibold maximumSize:22.];
    self.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightSemibold maximumSize:22.];
    self.subtitleLabel.font = [UIFont scaledSystemFontOfSize:13. weight:UIFontWeightSemibold maximumSize:18.];
}

- (void)setupNavBarHeightConstraint
{
    self.navBarHeightConstraint.constant = (!self.separatorNavbarView.hidden ? separatorNavBarHeight : 0)
        + ([self isModal] ? [OAUtilities isLandscape] ? defaultNavBarHeight : modalNavBarHeight : defaultNavBarHeight);
}

- (CGFloat)getNavbarHeight
{
    return self.navbarBackgroundView.frame.size.height;
}

#pragma mark - Selectors

// for UI components with adjustsFontForContentSizeCategory = NO
- (void)onContentSizeChanged:(NSNotification *)notification
{
}

- (void)onScrollViewDidScroll:(UIScrollView *)scrollView
{    
}

- (void)onRotation
{
}

- (IBAction)onLeftNavbarButtonPressed:(UIButton *)sender
{
    [self dismissViewController];
}

- (IBAction)onRightNavbarButtonPressed:(UIButton *)sender
{
    [self dismissViewController];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self blurringNavbar])
    {
        CGFloat y = scrollView.contentOffset.y + [OAUtilities getTopMargin];
        CGFloat navbarHeight = [self getNavbarHeight];
        if (!_isHeaderBlurred && y > -(navbarHeight))
        {
            [UIView animateWithDuration:.2 animations:^{
                [self.navbarBackgroundView addBlurEffect:YES cornerRadius:0. padding:0.];
                _isHeaderBlurred = YES;
            }];
        }
        else if (_isHeaderBlurred && y <= -(navbarHeight))
        {
            [UIView animateWithDuration:.2 animations:^{
                [self.navbarBackgroundView removeBlurEffect:[self getNavbarColor]];
                _isHeaderBlurred = NO;
            }];
        }
    }

    [self onScrollViewDidScroll:scrollView];
}

@end
