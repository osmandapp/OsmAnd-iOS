//
//  OASpeedLimitToleranceViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASpeedLimitToleranceViewController.h"
#import "OASettingsTitleTableViewCell.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16

@interface OASpeedLimitToleranceViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OASpeedLimitToleranceViewController
{
    NSArray<NSArray *> *_data;
    NSArray<NSNumber *> *_speedLimitsKm;
    UIView *_tableHeaderView;
}

- (instancetype) init
{
    self = [super initWithNibName:@"OAAppSettingsViewController" bundle:nil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self setupTableHeaderViewWithText:OALocalizedString(@"speed_limit_tolerance_descr")];
    [self setupView];
}

- (void) commonInit
{
    [self generateData];
}

- (void) generateData
{
    _speedLimitsKm = @[ @-10.f, @-7.f, @-5.f, @0.f, @5.f, @7.f, @10.f, @15.f, @20.f ];
    NSMutableArray *dataArr = [NSMutableArray array];
    for (int i = 0; i < _speedLimitsKm.count; i++)
    {
        [dataArr addObject:
         @{
           @"name" : _speedLimitsKm[i],
           @"title" : [NSString stringWithFormat:@"%d %@", _speedLimitsKm[i].intValue, OALocalizedString(@"units_kmh")],
           @"isSelected" : @NO,
           @"type" : @"OASettingsTitleCell"
         }];
    }
    _data = [NSArray arrayWithObject:dataArr];
}

-(void) applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"impassable_road");
    self.subtitleLabel.text = OALocalizedString(@"app_mode_car");
}

- (void) setupTableHeaderViewWithText:(NSString *)text
{
    CGFloat textWidth = DeviceScreenWidth - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    CGFloat textHeight = [self heightForLabel:text];
    _tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, textHeight + kSidePadding)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kSidePadding + OAUtilities.getLeftMargin, kSidePadding, textWidth, textHeight)];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:6];
    label.attributedText = [[NSAttributedString alloc] initWithString:text
                                                        attributes:@{NSParagraphStyleAttributeName : style,
                                                        NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer),
                                                        NSFontAttributeName : [UIFont systemFontOfSize:15.0],
                                                        NSBackgroundColorAttributeName : UIColor.clearColor}];
    label.textAlignment = NSTextAlignmentJustified;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _tableHeaderView.backgroundColor = UIColor.clearColor;
    [_tableHeaderView addSubview:label];
    self.tableView.tableHeaderView = _tableHeaderView;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setupTableHeaderViewWithText:OALocalizedString(@"speed_limit_tolerance_descr")];
        [self.tableView reloadData];
    } completion:nil];
}

- (void) setupView
{
    
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"OASettingsTitleCell"])
    {
        static NSString* const identifierCell = @"OASettingsTitleCell";
        OASettingsTitleTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.iconView.image = [[UIImage imageNamed:@"ic_checkmark_default"]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.hidden = item[@"isSelected"];
        }
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 17.0;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
