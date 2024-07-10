//
//  OACoordinatesFormatViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 02.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACoordinatesFormatViewController.h"
#import "OASimpleTableViewCell.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OALinks.h"
#import "OALocationServices.h"
#import "OsmAndApp.h"
#import "OALocationConvert.h"
#import "OATableViewCustomFooterView.h"
#import "OAOsmAndFormatter.h"

#import "Localization.h"
#import "OAColors.h"

@implementation OACoordinatesFormatViewController
{
    NSArray<NSDictionary *> *_data;
    OAAppSettings *_settings;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

#pragma mark - UIViewController

- (void) viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"coords_format");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

#pragma mark - Table data

- (void)generateData
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    CLLocation *location = [OsmAndApp instance].locationServices.lastKnownLocation;
    if (!location)
        location = mapPanel.mapViewController.getMapLocation;
    double lat = location.coordinate.latitude;
    double lon = location.coordinate.longitude;
    _data = @[
        @{
        @"name" : @"navigate_point_format_D",
        @"title" : OALocalizedString(@"navigate_point_format_D"),
        @"selected" : @([_settings.settingGeoFormat get:self.appMode] == MAP_GEO_FORMAT_DEGREES),
        @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"shared_string_example"), [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_DEGREES]],
        @"type" : [OASimpleTableViewCell getCellIdentifier],
    },
    @{
        @"name" : @"navigate_point_format_DM",
        @"title" : OALocalizedString(@"navigate_point_format_DM"),
        @"selected" : @([_settings.settingGeoFormat get:self.appMode] == MAP_GEO_FORMAT_MINUTES),
        @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"shared_string_example"), [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_MINUTES]],
        @"type" : [OASimpleTableViewCell getCellIdentifier],
    },
    @{
       @"name" : @"navigate_point_format_DMS",
       @"title" : OALocalizedString(@"navigate_point_format_DMS"),
       @"selected" : @([_settings.settingGeoFormat get:self.appMode] == MAP_GEO_FORMAT_SECONDS),
       @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"shared_string_example"), [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_SECONDS]],
       @"type" : [OASimpleTableViewCell getCellIdentifier],
    },
    @{
        @"name" : @"utm_format",
        @"title" : OALocalizedString(@"UTM"),
        @"selected" : @([_settings.settingGeoFormat get:self.appMode] == MAP_GEO_UTM_FORMAT),
        @"description" : [NSString stringWithFormat:@"%@: %@\n%@\n%@\n", OALocalizedString(@"shared_string_example"), [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_UTM], OALocalizedString(@"utm_description"), OALocalizedString(@"shared_string_read_more")],
        @"url" : kUrlWikipediaUtmFormat,
        @"type" : [OASimpleTableViewCell getCellIdentifier],
    },
    @{
       @"name" : @"olc_format",
       @"title" : OALocalizedString(@"navigate_point_format_OLC"),
       @"selected" : @([_settings.settingGeoFormat get:self.appMode] == MAP_GEO_OLC_FORMAT),
       @"description" : [NSString stringWithFormat:@"%@: %@. %@\n", OALocalizedString(@"shared_string_example"), [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_OLC], OALocalizedString(@"shared_string_read_more")],
       @"url" : kUrlWikipediaOpenLocationCode,
       @"icon" : @"ic_custom_direction_compass",
       @"type" : [OASimpleTableViewCell getCellIdentifier],
    },
    @{
        @"name" : @"mgrs_format",
        @"title" : OALocalizedString(@"MGRS"),
        @"selected" : @([_settings.settingGeoFormat get:self.appMode] == MAP_GEO_MGRS_FORMAT),
        @"description" : [NSString stringWithFormat:@"%@: %@\n%@\n%@\n", OALocalizedString(@"shared_string_example"), [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_MGRS], OALocalizedString(@"mgrs_format_descr"), OALocalizedString(@"shared_string_read_more")],
        @"url" : kUrlWikipediaMgrsFormat,
        @"type" : [OASimpleTableViewCell getCellIdentifier],
    }];
}

- (NSDictionary *) getItem:(NSInteger )section
{
    return _data[section];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath.section];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            [cell leftIconVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.accessoryType = [item[@"selected"] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    return 17.;
}

- (CGFloat)getCustomHeightForFooter:(NSInteger)section
{
    NSDictionary *item = [self getItem:section];
    NSString *text = item[@"description"];
    NSString *url = item[@"url"];
    return [OATableViewCustomFooterView getHeight:url ? [NSString stringWithFormat:@"%@ %@", text, url] : text width:self.tableView.bounds.size.width];
}

- (UIView *)getCustomViewForFooter:(NSInteger)section
{
    NSDictionary *item = [self getItem:section];
    NSString *text = item[@"description"];
    NSString *url = item[@"url"];
    OATableViewCustomFooterView *vw = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    if (url)
    {
        NSURL *URL = [NSURL URLWithString:url];
        UIFont *textFont = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        NSMutableAttributedString * str = [[NSMutableAttributedString alloc] initWithString:url attributes:@{NSFontAttributeName : textFont}];
        [str addAttribute:NSLinkAttributeName value:URL range: NSMakeRange(0, str.length)];
        text = [text stringByAppendingString:@""];
        NSMutableAttributedString *textStr = [[NSMutableAttributedString alloc] initWithString:text
                                                                                    attributes:@{NSFontAttributeName : textFont,
                                                                                                 NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)}];
        [textStr appendAttributedString:str];
        vw.label.attributedText = textStr;
    }
    else
    {
        vw.label.text = text;
    }
    return vw;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath.section];
    [self selectSettingGeoCode:item[@"name"]];
    [self generateData];
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
    [self dismissViewController];
}

#pragma mark - Selectors

- (void) selectSettingGeoCode:(NSString *)name
{
    if ([name isEqualToString:@"navigate_point_format_D"])
        [_settings.settingGeoFormat set:MAP_GEO_FORMAT_DEGREES mode:self.appMode];
    else if ([name isEqualToString:@"navigate_point_format_DM"])
        [_settings.settingGeoFormat set:MAP_GEO_FORMAT_MINUTES mode:self.appMode];
    else if ([name isEqualToString:@"navigate_point_format_DMS"])
        [_settings.settingGeoFormat set:MAP_GEO_FORMAT_SECONDS mode:self.appMode];
    else if ([name isEqualToString:@"utm_format"])
        [_settings.settingGeoFormat set:MAP_GEO_UTM_FORMAT mode:self.appMode];
    else if ([name isEqualToString:@"olc_format"])
        [_settings.settingGeoFormat set:MAP_GEO_OLC_FORMAT mode:self.appMode];
    else if ([name isEqualToString:@"mgrs_format"])
        [_settings.settingGeoFormat set:MAP_GEO_MGRS_FORMAT mode:self.appMode];
}

@end
