//
//  OAQuickSearchCoordinateFormatsViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 25.08.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAQuickSearchCoordinateFormatsViewController.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAPointDescription.h"
#import "OAAppSettings.h"
#import "OASimpleTableViewCell.h"
#import "OAMapPanelViewController.h"
#import "OARootViewController.h"
#import "OsmAndApp.h"
#import "OALocationConvert.h"
#import "OATableViewCustomFooterView.h"
#import "OAOsmAndFormatter.h"
#import "GeneratedAssetSymbols.h"

@interface OAQuickSearchCoordinateFormatsViewController() <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAQuickSearchCoordinateFormatsViewController
{
    NSInteger _currentFormat;
    CLLocation *_location;
    NSMutableArray *_data;
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
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : [OAPointDescription formatToHumanString:MAP_GEO_FORMAT_DEGREES],
        @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"shared_string_example"), [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_DEGREES]],
        @"isSelected" : [NSNumber numberWithBool:_currentFormat == MAP_GEO_FORMAT_DEGREES]
    }];
    
    [_data addObject:@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : [OAPointDescription formatToHumanString:MAP_GEO_FORMAT_MINUTES],
        @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"shared_string_example"), [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_MINUTES]],
        @"isSelected" : [NSNumber numberWithBool:_currentFormat == MAP_GEO_FORMAT_MINUTES]
    }];
    
    [_data addObject:@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : [OAPointDescription formatToHumanString:MAP_GEO_FORMAT_SECONDS],
        @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"shared_string_example"), [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_SECONDS]],
        @"isSelected" : [NSNumber numberWithBool:_currentFormat == MAP_GEO_FORMAT_SECONDS]
    }];
    
    [_data addObject:@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : [OAPointDescription formatToHumanString:MAP_GEO_UTM_FORMAT],
        @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"shared_string_example"), [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_UTM]],
        @"isSelected" : [NSNumber numberWithBool:_currentFormat == MAP_GEO_UTM_FORMAT]
    }];
    
    [_data addObject:@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : [OAPointDescription formatToHumanString:MAP_GEO_OLC_FORMAT],
        @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"shared_string_example"), [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_OLC]],
        @"isSelected" : [NSNumber numberWithBool:_currentFormat == MAP_GEO_OLC_FORMAT]
    }];
    
    [_data addObject:@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : [OAPointDescription formatToHumanString:MAP_GEO_MGRS_FORMAT],
        @"description" : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"shared_string_example"), [OAOsmAndFormatter getFormattedCoordinatesWithLat:lat lon:lon outputFormat:FORMAT_MGRS]],
        @"isSelected" : [NSNumber numberWithBool:_currentFormat == MAP_GEO_MGRS_FORMAT]
    }];

}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = OALocalizedString(@"coords_format");
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    self.tableView.separatorColor = [UIColor colorNamed:ACColorNameCustomSeparator];
    self.tableView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self configureNavigationBar];
}

- (void) configureNavigationBar
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = self.tableView.backgroundColor;
    appearance.shadowColor = [UIColor colorNamed:ACColorNameCustomSeparator];
    appearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorPrimary]
    };
    UINavigationBarAppearance *blurAppearance = [[UINavigationBarAppearance alloc] init];

    self.navigationController.navigationBar.standardAppearance = blurAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationController.navigationBar.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"shared_string_back") style:UIBarButtonItemStylePlain target:self action:@selector(onLeftNavbarButtonPressed)];
    [self.navigationController.navigationBar.topItem setLeftBarButtonItem:backButton animated:YES];
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

    UIFont *textFont = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    NSMutableAttributedString * str = [[NSMutableAttributedString alloc] initWithString:url attributes:@{NSFontAttributeName : textFont}];
    [str addAttribute:NSLinkAttributeName value:url range: NSMakeRange(0, str.length)];
    text = [text stringByAppendingString:@" > "];
    NSMutableAttributedString *textStr = [[NSMutableAttributedString alloc] initWithString:text
                                                                                attributes:@{NSFontAttributeName : textFont,
                                                                                            NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorSecondary]}];
    [textStr appendAttributedString:str];
    vw.label.attributedText = textStr;
    return vw;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    NSString *cellType = item[@"type"];
    
    if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            cell.descriptionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
            [cell leftIconVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.descriptionLabel.text = item[@"description"];

            if ([item[@"isSelected"] boolValue])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else
                cell.accessoryType = UITableViewCellAccessoryNone;
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

@end
