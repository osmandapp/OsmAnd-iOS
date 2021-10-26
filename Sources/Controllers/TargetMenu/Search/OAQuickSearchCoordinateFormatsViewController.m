//
//  OAQuickSearchCoordinateFormatsViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 25.08.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAQuickSearchCoordinateFormatsViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAPointDescription.h"
#import "OAAppSettings.h"
#import "OAMultiIconTextDescCell.h"
#import "OAMapPanelViewController.h"
#import "OARootViewController.h"
#import "OsmAndApp.h"
#import "OALocationConvert.h"
#import "OATableViewCustomFooterView.h"
#import "OAOsmAndFormatter.h"

#define defaultNavBarHeight 58

@interface OAQuickSearchCoordinateFormatsViewController() <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAQuickSearchCoordinateFormatsViewController
{
    NSInteger _currentFormat;
    CLLocation *_location;
    NSMutableArray *_data;
    UIView *_navBarBackgroundView;
}

- (instancetype) initWithCurrentFormat:(NSInteger)currentFormat location:(CLLocation *)location
{
    self = [super initWithNibName:@"OAQuickSearchCoordinateFormatsViewController" bundle:nil];
    if (self)
    {
        _currentFormat = currentFormat;
        _location = location;
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    [self generateData];
}

- (void) generateData
{
    _data = [NSMutableArray array];
    if (!_location)
        _location = [OARootViewController instance].mapPanel.mapViewController.getMapLocation;
    double lat = _location.coordinate.latitude;
    double lon = _location.coordinate.longitude;

    [_data addObject:@{
        @"type" : [OAMultiIconTextDescCell getCellIdentifier],
        @"title" : [OAPointDescription formatToHumanString:MAP_GEO_FORMAT_DEGREES],
        @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"coordinates_example"), [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_DEGREES]],
        @"isSelected" : [NSNumber numberWithBool:_currentFormat == MAP_GEO_FORMAT_DEGREES]
    }];
    
    [_data addObject:@{
        @"type" : [OAMultiIconTextDescCell getCellIdentifier],
        @"title" : [OAPointDescription formatToHumanString:MAP_GEO_FORMAT_MINUTES],
        @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"coordinates_example"), [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_MINUTES]],
        @"isSelected" : [NSNumber numberWithBool:_currentFormat == MAP_GEO_FORMAT_MINUTES]
    }];
    
    [_data addObject:@{
        @"type" : [OAMultiIconTextDescCell getCellIdentifier],
        @"title" : [OAPointDescription formatToHumanString:MAP_GEO_FORMAT_SECONDS],
        @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"coordinates_example"), [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_SECONDS]],
        @"isSelected" : [NSNumber numberWithBool:_currentFormat == MAP_GEO_FORMAT_SECONDS]
    }];
    
    [_data addObject:@{
        @"type" : [OAMultiIconTextDescCell getCellIdentifier],
        @"title" : [OAPointDescription formatToHumanString:MAP_GEO_UTM_FORMAT],
        @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"coordinates_example"), [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_UTM]],
        @"isSelected" : [NSNumber numberWithBool:_currentFormat == MAP_GEO_UTM_FORMAT]
    }];
    
    [_data addObject:@{
        @"type" : [OAMultiIconTextDescCell getCellIdentifier],
        @"title" : [OAPointDescription formatToHumanString:MAP_GEO_OLC_FORMAT],
        @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"coordinates_example"), [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_OLC]],
        @"isSelected" : [NSNumber numberWithBool:_currentFormat == MAP_GEO_OLC_FORMAT]
    }];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
    self.tableView.contentInset = UIEdgeInsetsMake(defaultNavBarHeight, 0, 0, 0);
    self.doneButton.hidden = YES;
    self.doneButton.enabled = NO;

    self.titleLabel.text = OALocalizedString(@"coords_format");
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    
    _navBarBackgroundView = [self createNavBarBackgroundView];
    _navBarBackgroundView.frame = self.navbarView.bounds;
    [self.navbarView insertSubview:_navBarBackgroundView atIndex:0];
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

#pragma mark - UITableViewDelegate

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    
    NSString *text = OALocalizedString(@"coords_format_descr_quick_search");
    NSString *url = OALocalizedString(@"coords_format");
    OATableViewCustomFooterView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView getCellIdentifier]];

    UIFont *textFont = [UIFont systemFontOfSize:13];
    NSMutableAttributedString * str = [[NSMutableAttributedString alloc] initWithString:url attributes:@{NSFontAttributeName : textFont}];
    [str addAttribute:NSLinkAttributeName value:url range: NSMakeRange(0, str.length)];
    text = [text stringByAppendingString:@" > "];
    NSMutableAttributedString *textStr = [[NSMutableAttributedString alloc] initWithString:text
                                                                                attributes:@{NSFontAttributeName : textFont,
                                                                                            NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)}];
    [textStr appendAttributedString:str];
    vw.label.attributedText = textStr;
    return vw;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    NSString *cellType = item[@"type"];
    
    if ([cellType isEqualToString:[OAMultiIconTextDescCell getCellIdentifier]])
    {
        OAMultiIconTextDescCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAMultiIconTextDescCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMultiIconTextDescCell getCellIdentifier] owner:self options:nil];
            cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
            cell.descView.font = [UIFont systemFontOfSize:13];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descView.text = item[@"description"];

            if ([item[@"isSelected"] boolValue])
                [cell.overflowButton setImage:[UIImage imageNamed:@"ic_checkmark_default"] forState:UIControlStateNormal];
            else
                [cell.overflowButton setImage:nil forState:UIControlStateNormal];
        }
        return cell;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_delegate onCoordinateFormatChanged:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self dismissViewController];
}

#pragma mark - UIScrollViewDelegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat alpha = (self.tableView.contentOffset.y + defaultNavBarHeight) < 0 ? 0 : ((self.tableView.contentOffset.y + defaultNavBarHeight) / (fabs(self.tableView.contentSize.height - self.tableView.frame.size.height)));
    if (alpha > 0)
    {
        [UIView animateWithDuration:.2 animations:^{
            self.navbarView.backgroundColor = UIColor.clearColor;
            _navBarBackgroundView.alpha = 1;
        }];
    }
    else
    {
        [UIView animateWithDuration:.2 animations:^{
            self.navbarView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
            _navBarBackgroundView.alpha = 0;
        }];
    }
}

@end
