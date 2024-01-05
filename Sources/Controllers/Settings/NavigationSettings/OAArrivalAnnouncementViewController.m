//
//  OAArrivalAnnouncementViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAArrivalAnnouncementViewController.h"
#import "OASimpleTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OATextMultilineTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OATableCollapsableRowData.h"
#import "OAAnnounceTimeDistances.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"
#import "Localization.h"
#import "OAColors.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#define kSidePadding 20.

@implementation OAArrivalAnnouncementViewController
{
    OAAppSettings *_settings;
    OAAnnounceTimeDistances *_announceTimeDistances;
    OATableDataModel *_data;
    NSIndexPath *_selectedIndexPath;
    NSIndexPath *_collapsedCellIndexPath;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

- (void)postInit
{
    _announceTimeDistances = [[OAAnnounceTimeDistances alloc] initWithAppMode:self.appMode];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"arrival_distance");
}

- (void)setupTableHeaderView
{
    NSString *text = OALocalizedString(@"announcement_time_descr");
    CGFloat textWidth = self.tableView.frame.size.width - (kSidePadding + [OAUtilities getLeftMargin]) * 2;
    CGFloat textHeight = [OAUtilities heightForHeaderViewText:text width:textWidth font:kHeaderDescriptionFontSmall lineSpacing:6.0];

    UIView *topImageDivider = [[UIView alloc] initWithFrame:CGRectMake(0., 0., self.tableView.frame.size.width, .5)];
    topImageDivider.backgroundColor = [UIColor colorNamed:ACColorNameIconColorDefault];

    UIImage *image = [UIImage imageNamed:@"img_help_announcement_time_day"];
    CGFloat aspectRatio = MIN(self.tableView.frame.size.width, self.tableView.frame.size.height) / image.size.width;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0., 0., self.tableView.frame.size.width, image.size.height * aspectRatio)];
    imageView.image = image;
    imageView.contentMode = UIViewContentModeScaleAspectFit;

    UIView *imageBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0., 0.5, self.tableView.frame.size.width, imageView.frame.size.height)];
    imageBackgroundView.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];

    UIView *bottomImageDivider = [[UIView alloc] initWithFrame:CGRectMake(0., imageView.frame.origin.y + imageView.frame.size.height, self.tableView.frame.size.width, .5)];
    bottomImageDivider.backgroundColor = UIColorFromRGB(color_tint_gray);

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kSidePadding + [OAUtilities getLeftMargin], imageView.frame.size.height + 13., textWidth, textHeight)];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.minimumLineHeight = 17.;
    label.attributedText = [[NSAttributedString alloc] initWithString:text
                                                           attributes:@{ NSParagraphStyleAttributeName : style,
                                                                         NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer),
                                                                         NSFontAttributeName : kHeaderDescriptionFontSmall,
                                                                         NSBackgroundColorAttributeName : UIColor.clearColor }];
    label.numberOfLines = 0;

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

#pragma mark - Table data

- (void) generateData
{
    _data = [OATableDataModel model];

    OATableSectionData *arrivalSection = [OATableSectionData sectionData];
    [_data addSection:arrivalSection];

    double selectedValue = [_settings.arrivalDistanceFactor get:self.appMode];
    NSArray<NSNumber *> *arrivalValues = @[ @1.5f, @1.f, @0.5f, @0.25f ];
    NSArray<NSString *> *arrivalNames =  @[
        OALocalizedString(@"arrival_distance_factor_early"),
        OALocalizedString(@"arrival_distance_factor_normally"),
        OALocalizedString(@"arrival_distance_factor_late"),
        OALocalizedString(@"arrival_distance_factor_at_last")];

    for (int i = 0; i < arrivalNames.count; i++)
    {
        NSNumber *value = arrivalValues[i];
        [arrivalSection addRowFromDictionary:@{
            kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
            kCellTitleKey : arrivalNames[i],
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
    _collapsedCellIndexPath = [NSIndexPath indexPathForRow:[infoSection rowCount] - 1 inSection:[_data sectionCount] - 1];

    [infoCollapsableRow addDependentRow:[[OATableRowData alloc] initWithData:@{
        kCellTypeKey : [OATextMultilineTableViewCell getCellIdentifier]
    }]];
}

- (BOOL)hideFirstHeader
{
    return YES;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.accessoryType = _selectedIndexPath == indexPath ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.rightIconView.image = [UIImage templateImageNamed:((OATableCollapsableRowData *) item).collapsed ? @"ic_custom_arrow_right" : @"ic_custom_arrow_down"];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OATextMultilineTableViewCell getCellIdentifier]])
    {
        OATextMultilineTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OATextMultilineTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextMultilineTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextMultilineTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell clearButtonVisibility:NO];
        }
        if (cell)
        {
            cell.textView.attributedText = [_announceTimeDistances getIntervalsDescription];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return [_data sectionCount];
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    if (indexPath.section == _selectedIndexPath.section)
    {
        NSIndexPath *oldSelectedIndexPath = _selectedIndexPath;
        _selectedIndexPath = indexPath;
        [self updateArrivalDistanceFactorValue];
        [_announceTimeDistances setArrivalDistances:[_settings.arrivalDistanceFactor get:self.appMode]];
        NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray arrayWithObjects:_selectedIndexPath, oldSelectedIndexPath, nil];
        if (_collapsedCellIndexPath)
        {
            OATableCollapsableRowData *collapsableRow = (OATableCollapsableRowData *) [_data itemForIndexPath:_collapsedCellIndexPath];
            if (!collapsableRow.collapsed)
            {
                for (NSInteger i = 1; i <= collapsableRow.dependentRowsCount; i++)
                {
                    [indexPaths addObject:[NSIndexPath indexPathForRow:(_collapsedCellIndexPath.row + i) inSection:_collapsedCellIndexPath.section]];
                }
            }
        }
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    }
    else if ([[_data itemForIndexPath:indexPath].key isEqualToString:@"infoCollapsableCell"])
    {
        [self onCollapseButtonPressed:indexPath];
    }
}

#pragma mark - Selectors

- (void)updateArrivalDistanceFactorValue
{
    [_settings.arrivalDistanceFactor set:((NSNumber *) [[_data itemForIndexPath:_selectedIndexPath] objForKey:@"value"]).doubleValue
                                    mode:self.appMode];
    if (self.delegate)
        [self.delegate onSettingsChanged];
}

- (void)onCollapseButtonPressed:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if (item.rowType == EOATableRowTypeCollapsable)
    {
        [_announceTimeDistances setArrivalDistances:[_settings.arrivalDistanceFactor get:self.appMode]];
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
                [self.tableView deleteRowsAtIndexPaths:rowIndexes withRowAnimation:UITableViewRowAnimationAutomatic];
            else
                [self.tableView insertRowsAtIndexPaths:rowIndexes withRowAnimation:UITableViewRowAnimationAutomatic];
        } completion:nil];
    }
}

@end
