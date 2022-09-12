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
#import "OAColors.h"

#define kHeaderViewFont [UIFont systemFontOfSize:34.0 weight:UIFontWeightBold]
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
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = 60.;
    _tableView.contentInset = UIEdgeInsetsMake(defaultNavBarHeight, 0, 0, 0);
    [self setTableHeaderView:self.getTableHeaderTitle];
}

- (void) setTableHeaderView:(NSString *)label
{
    _tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:label
                                                                      font:kHeaderViewFont
                                                                 textColor:UIColor.blackColor
                                                               lineSpacing:0.0 isTitle:YES];
}

- (void) applyLocalization
{
    [_backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (NSString *) getTableHeaderTitle
{
    return @""; // override
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setTableHeaderView:self.getTableHeaderTitle];
        [_tableView reloadData];
    } completion:nil];
}

- (CGFloat) heightForLabel:(NSString *)text
{
    UIFont *labelFont = [UIFont systemFontOfSize:15.0];
    CGFloat textWidth = self.tableView.bounds.size.width - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    return [OAUtilities heightForHeaderViewText:text width:textWidth font:labelFont lineSpacing:6.0];
}

- (IBAction)backImageButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) backButtonClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (UIColor *)navBarBackgroundColor
{
    return UIColorFromRGB(color_bottom_sheet_background);
}

- (void)onScrollViewDidScroll:(UIScrollView *)scrollView
{
}

#pragma mark - UIScrollViewDelegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat alpha = (_tableView.contentOffset.y + defaultNavBarHeight) < 0 ? 0 : ((_tableView.contentOffset.y + defaultNavBarHeight) / (fabs(_tableView.contentSize.height - _tableView.frame.size.height)));
    if (!_isHeaderBlurred && alpha > 0)
    {
        [UIView animateWithDuration:.2 animations:^{
            _titleLabel.hidden = NO;
            [_navBarView addBlurEffect:YES cornerRadius:0. padding:0.];
            _isHeaderBlurred = YES;
        }];
    }
    else if (_isHeaderBlurred && alpha <= 0.)
    {
        [UIView animateWithDuration:.2 animations:^{
            _titleLabel.hidden = YES;
            [_navBarView removeBlurEffect:[self navBarBackgroundColor]];
            _isHeaderBlurred = NO;
        }];
    }
    [self onScrollViewDidScroll:scrollView];
}

@end
