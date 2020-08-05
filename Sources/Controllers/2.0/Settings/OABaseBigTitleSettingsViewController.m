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

@interface OABaseBigTitleSettingsViewController ()

@end

@implementation OABaseBigTitleSettingsViewController
{
    UIView *_navBarBackgroundView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = 60.;
    _tableView.contentInset = UIEdgeInsetsMake(defaultNavBarHeight, 0, 0, 0);
    _tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:self.getTableHeaderTitle
                                                                      font:kHeaderViewFont
                                                                 textColor:UIColor.blackColor
                                                               lineSpacing:0.0 isTitle:YES];
    
    _navBarBackgroundView = [self createNavBarBackgroundView];
    _navBarBackgroundView.frame = _navBarView.bounds;
    [_navBarView insertSubview:_navBarBackgroundView atIndex:0];
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
        _tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:self.getTableHeaderTitle
                                                                          font:kHeaderViewFont
                                                                     textColor:UIColor.blackColor
                                                                   lineSpacing:0.0 isTitle:YES];
        [_tableView reloadData];
    } completion:nil];
}

@end
