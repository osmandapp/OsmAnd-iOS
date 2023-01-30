//
//  OAArrivalAnnouncementViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAArrivalAnnouncementViewController.h"
#import "OARightIconTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OATableCollapsableRowData.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"
#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 20.

@interface OAArrivalAnnouncementViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAArrivalAnnouncementViewController
{
    OAAppSettings *_settings;
    OATableDataModel *_data;
    NSIndexPath *_selectedIndexPath;
}

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super initWithAppMode:appMode];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"arrival_distance");
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    [self generateData];
    [self setupTableHeaderViewWithText:OALocalizedString(@"announcement_time_descr")];
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setupTableHeaderViewWithText:OALocalizedString(@"announcement_time_descr")];
        [self.tableView reloadData];
    } completion:nil];
}

- (void) generateData
{
    _data = [OATableDataModel model];

    OATableSectionData *arrivalSection = [OATableSectionData sectionData];
    [_data addSection:arrivalSection];

    double selectedValue = [_settings.arrivalDistanceFactor get:self.appMode];
    NSArray<NSNumber *> *arrivalValues = @[ @1.5f, @1.f, @0.5f, @0.25f ];
    NSArray<NSString *> *arrivalNames =  @[
        @"arrival_distance_factor_early",
        @"arrival_distance_factor_normally",
        @"arrival_distance_factor_late",
        @"arrival_distance_factor_at_last"];

    for (int i = 0; i < arrivalNames.count; i++)
    {
        NSString *key = arrivalNames[i];
        NSNumber *value = arrivalValues[i];
        [arrivalSection addRowFromDictionary:@{
            kCellKeyKey : key,
            kCellTypeKey : [OARightIconTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(key),
            @"value" : value
        }];
        if (value.doubleValue == selectedValue)
            _selectedIndexPath = [NSIndexPath indexPathForRow:i inSection:[_data sectionCount] - 1];
    }

    OATableSectionData *infoSection = [OATableSectionData sectionData];
    [_data addSection:infoSection];

    OATableCollapsableRowData *infoCollapsableRow = [[OATableCollapsableRowData alloc] initWithData:@{
        kCellKeyKey : @"infoCollapsableCell",
        kCellTypeKey : [OARightIconTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"announcement_time_intervals")
    }];
    [infoSection addRow:infoCollapsableRow];
}

- (void)updateArrivalDistanceFactorValue
{
    [_settings.arrivalDistanceFactor set:((NSNumber *) [[_data itemForIndexPath:_selectedIndexPath] objForKey:@"value"]).doubleValue
                                    mode:self.appMode];
    if (self.delegate)
        [self.delegate onSettingsChanged];
}

- (void)setupTableHeaderViewWithText:(NSString *)text
{
    CGFloat textWidth = DeviceScreenWidth - (kSidePadding + [OAUtilities getLeftMargin]) * 2;
    CGFloat textHeight = [self heightForLabel:text];

    UIView *topImageDivider = [[UIView alloc] initWithFrame:CGRectMake(0., 0., DeviceScreenWidth, .5)];
    topImageDivider.backgroundColor = UIColorFromRGB(color_tint_gray);

    UIImage *image = [UIImage imageNamed:@"img_help_announcement_time_day"];
    CGFloat aspectRatio = MIN(DeviceScreenWidth, DeviceScreenHeight) / image.size.width;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0., 0., DeviceScreenWidth, image.size.height * aspectRatio)];
    imageView.image = image;
    imageView.contentMode = UIViewContentModeScaleAspectFit;

    UIView *imageBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0., 0.5, DeviceScreenWidth, imageView.frame.size.height)];
    imageBackgroundView.backgroundColor = UIColor.whiteColor;

    UIView *bottomImageDivider = [[UIView alloc] initWithFrame:CGRectMake(0., imageView.frame.origin.y + imageView.frame.size.height, DeviceScreenWidth, .5)];
    bottomImageDivider.backgroundColor = UIColorFromRGB(color_tint_gray);

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kSidePadding + [OAUtilities getLeftMargin], imageView.frame.size.height + 13., textWidth, textHeight)];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.minimumLineHeight = 17.;
    label.attributedText = [[NSAttributedString alloc] initWithString:text
                                                           attributes:@{ NSParagraphStyleAttributeName : style,
                                                                         NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer),
                                                                         NSFontAttributeName : [UIFont systemFontOfSize:[self fontSizeForLabel]],
                                                                         NSBackgroundColorAttributeName : UIColor.clearColor }];
    label.numberOfLines = 0;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    CGFloat headerHeight = label.frame.origin.y + label.frame.size.height + 26.;
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0., 0., DeviceScreenWidth, headerHeight)];
    [tableHeaderView addSubview:imageBackgroundView];
    [tableHeaderView addSubview:imageView];
    [tableHeaderView addSubview:topImageDivider];
    [tableHeaderView addSubview:bottomImageDivider];
    [tableHeaderView addSubview:label];
    tableHeaderView.backgroundColor = UIColor.clearColor;
    self.tableView.tableHeaderView = tableHeaderView;
}

- (CGFloat)fontSizeForLabel
{
    return 13.;
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_data sectionCount];
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[_data sectionDataForIndex:section] rowCount];
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.rightIconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            if (item.rowType == EOATableRowTypeCollapsable)
                cell.rightIconView.image = [UIImage templateImageNamed:((OATableCollapsableRowData *) item).collapsed ? @"ic_custom_arrow_right" : @"ic_custom_arrow_down"];
            else
                cell.rightIconView.image = _selectedIndexPath == indexPath ? [UIImage imageNamed:@"ic_checkmark_default"] : nil;

            [cell rightIconVisibility:cell.rightIconView.image];
            cell.titleLabel.text = item.title;
        }
        return cell;
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == _selectedIndexPath.section)
    {
        NSIndexPath *oldSelectedIndexPath = _selectedIndexPath;
        _selectedIndexPath = indexPath;
        [self updateArrivalDistanceFactorValue];
        [self.tableView reloadRowsAtIndexPaths:@[_selectedIndexPath, oldSelectedIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    else if ([[_data itemForIndexPath:indexPath].key isEqualToString:@"infoCollapsableCell"])
    {
        [self onCollapseButtonPressed:indexPath];
    }
}

- (void)onCollapseButtonPressed:(NSIndexPath *)indexPath
{
    OATableCollapsableRowData *collapsableRow = (OATableCollapsableRowData *) [_data itemForIndexPath:indexPath];
    collapsableRow.collapsed = !collapsableRow.collapsed;
    NSMutableArray<NSIndexPath *> *rowIndexes = [NSMutableArray array];
    for (NSInteger i = 1; i <= collapsableRow.dependentRowsCount; i++)
    {
        [rowIndexes addObject:[NSIndexPath indexPathForRow:(indexPath.row + i) inSection:indexPath.section]];
    }

    [self.tableView performBatchUpdates:^{
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        if (collapsableRow.collapsed)
            [self.tableView deleteRowsAtIndexPaths:rowIndexes withRowAnimation:UITableViewRowAnimationBottom];
        else
            [self.tableView insertRowsAtIndexPaths:rowIndexes withRowAnimation:UITableViewRowAnimationBottom];
    } completion:nil];
}

@end
