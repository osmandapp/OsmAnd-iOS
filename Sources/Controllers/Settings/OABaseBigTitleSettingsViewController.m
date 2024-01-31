//
//  OABaseBigTitleSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 01.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseBigTitleSettingsViewController.h"
#import "Localization.h"
#import "OASizes.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#define kSidePadding 16

@interface OABaseBigTitleSettingsViewController () <UIScrollViewDelegate>

@end

@implementation OABaseBigTitleSettingsViewController
{
    BOOL _isHeaderBlurred;
}

- (instancetype)init
{
    return [super initWithNibName:@"OABaseBigTitleSettingsViewController" bundle:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupNavBarHeight];
    [self.backImageButton setImage:[UIImage rtlImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = 60.;
    _tableView.contentInset = UIEdgeInsetsMake(self.navBarHeightConstraint.constant, 0, 0, 0);
    [self setTableHeaderView:self.getTableHeaderTitle];
    self.titleLabel.hidden = YES;
    self.separatorView.hidden = YES;
    self.navBarView.backgroundColor = [self navBarBackgroundColor];
}

- (void) setTableHeaderView:(NSString *)label
{
    if (label)
    {
        _tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:label
                                                                          font:kHeaderBigTitleFont
                                                                     textColor:[UIColor colorNamed:ACColorNameTextColorSecondary]
                                                                    isBigTitle:YES
                                                               parentViewWidth:self.view.frame.size.width];
    }
}

- (void) applyLocalization
{
    [_backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

-(void) addAccessibilityLabels
{
    self.backButton.accessibilityLabel = OALocalizedString(@"shared_string_back");
    self.backImageButton.accessibilityLabel = OALocalizedString(@"shared_string_back");
}

- (void)setupNavBarHeight
{
    self.navBarHeightConstraint.constant = [self isModal] ? [OAUtilities isLandscape] ? defaultNavBarHeight : modalNavBarHeight : defaultNavBarHeight;
}

- (BOOL)isSeparatorHidden
{
    return YES;
}

- (NSString *) getTableHeaderTitle
{
    return @""; // override
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setupNavBarHeight];
        _tableView.contentInset = UIEdgeInsetsMake(self.navBarHeightConstraint.constant, 0, 0, 0);
        [self setTableHeaderView:self.getTableHeaderTitle];
        [self onRotation];
        [_tableView reloadData];
    } completion:nil];
}

- (void)onRotation
{
}

- (CGFloat) heightForLabel:(NSString *)text
{
    UIFont *labelFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    CGFloat textWidth = self.tableView.bounds.size.width - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    return [OAUtilities heightForHeaderViewText:text width:textWidth font:labelFont lineSpacing:6.0];
}

- (IBAction)backImageButtonPressed:(id)sender
{
    [self dismissViewController];
}

- (UIColor *)navBarBackgroundColor
{
    return [UIColor colorNamed:ACColorNameViewBg];
}

- (void)onScrollViewDidScroll:(UIScrollView *)scrollView
{
}

#pragma mark - UIScrollViewDelegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat y = scrollView.contentOffset.y;
    CGFloat navbarHeight = self.navBarView.frame.size.height - ([self isModal] ? 0. : [OAUtilities getTopMargin]);
    CGFloat tableHeaderHeight = self.tableView.tableHeaderView.frame.size.height;
    if (y > 0)
    {
        if (!_isHeaderBlurred)
        {
            [UIView animateWithDuration:.2 animations:^{
                [self.navBarView addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:0. padding:0.];
                _isHeaderBlurred = YES;
            }];
        }
    }
    else if (y > -(navbarHeight))
    {
        if (_isHeaderBlurred)
        {
            [UIView animateWithDuration:0.2 animations:^{
                [self.navBarView removeBlurEffect:[self navBarBackgroundColor]];
                _isHeaderBlurred = NO;
            }];
        }
        if (y + navbarHeight > tableHeaderHeight * 0.75)
        {
            if (self.titleLabel.hidden)
            {
                [UIView animateWithDuration:.2 animations:^{
                    self.titleLabel.hidden = NO;
                }];
            }

            BOOL needToHideSeparator = y + navbarHeight <= tableHeaderHeight && !self.separatorView.hidden;
            BOOL needToShowSeparator = y + navbarHeight >= tableHeaderHeight && self.separatorView.hidden;
            if (![self isSeparatorHidden] && (needToHideSeparator || needToShowSeparator))
            {
                [UIView animateWithDuration:.2 animations:^{
                    self.separatorView.hidden = needToHideSeparator;
                }];
            }
        }
        else if (y + navbarHeight < tableHeaderHeight * .75 && !self.titleLabel.hidden)
        {
            [UIView animateWithDuration:.2 animations:^{
                self.titleLabel.hidden = YES;
            }];
        }
    }
    else if (y == -(navbarHeight))
    {
        BOOL isTitleLabelHidden = self.titleLabel.hidden;
        BOOL isSeparatorHidden = self.separatorView.hidden;
        if (!isTitleLabelHidden || !isSeparatorHidden)
        {
            [UIView animateWithDuration:.2 animations:^{
                if (!isTitleLabelHidden)
                    self.titleLabel.hidden = YES;
                if (!isSeparatorHidden)
                    self.separatorView.hidden = YES;
            }];
        }

        if (_isHeaderBlurred)
        {
            [UIView animateWithDuration:.2 animations:^{
                [self.navBarView removeBlurEffect:[self navBarBackgroundColor]];
                _isHeaderBlurred = NO;
            }];
        }
    }

    [self onScrollViewDidScroll:scrollView];
}

@end
