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
    UIView *_navBarBackgroundView;
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
    
    _navBarBackgroundView = [self createNavBarBackgroundView];
    _navBarBackgroundView.frame = _navBarView.bounds;
    [_navBarView insertSubview:_navBarBackgroundView atIndex:0];
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

- (UIView *) createNavBarBackgroundView
{
    if (!UIAccessibilityIsReduceTransparencyEnabled())
    {
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        blurEffectView.alpha = 0;
        return blurEffectView;
    }
    else
    {
        UIView *res = [[UIView alloc] init];
        res.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        res.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
        res.alpha = 0;
        return res;
    }
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

#pragma mark - UIScrollViewDelegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    
    CGFloat alpha = (_tableView.contentOffset.y + defaultNavBarHeight) < 0 ? 0 : ((_tableView.contentOffset.y + defaultNavBarHeight) / (fabs(_tableView.contentSize.height - _tableView.frame.size.height)));
    if (alpha > 0)
    {
        [UIView animateWithDuration:.2 animations:^{
            _titleLabel.hidden = NO;
            _navBarView.backgroundColor = UIColor.clearColor;
            _navBarBackgroundView.alpha = 1;
        }];
    }
    else
    {
        [UIView animateWithDuration:.2 animations:^{
            _titleLabel.hidden = YES;
            _navBarView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
            _navBarBackgroundView.alpha = 0;
        }];
    }
}

@end
