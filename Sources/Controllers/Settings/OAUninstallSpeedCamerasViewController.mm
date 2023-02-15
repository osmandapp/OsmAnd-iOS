//
//  OAUninstallSpeedCamerasViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 22.01.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAUninstallSpeedCamerasViewController.h"
#import "OARootViewController.h"
#import "OATextMultilineTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAPOIHelper.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAUtilities.h"
#import "OASizes.h"
#import "OAColors.h"
#import "Localization.h"

@implementation OAUninstallSpeedCamerasViewController
{
    OATableDataModel *_data;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"speed_camera_pois");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (BOOL)isNavbarSeparatorVisible
{
    return NO;
}

- (BOOL)isChevronIconVisible
{
    return NO;
}

- (EOABaseTableHeaderMode)getTableHeaderMode
{
    return EOABaseTableHeaderModeBigTitle;
}

- (NSString *)getTopButtonTitle
{
    return OALocalizedString(@"shared_string_uninstall");
}

- (NSString *)getBottomButtonTitle
{
    return OALocalizedString(@"shared_string_keep_active");
}

- (EOABaseButtonColorScheme)getTopButtonColorScheme
{
    return EOABaseButtonColorSchemeRed;
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    return EOABaseButtonColorSchemeGraySimple;
}

- (CGFloat)getSpaceBetweenButtons
{
    return 14.;
}

- (BOOL)isBottomSeparatorVisible
{
    return NO;
}

- (void)setupTableHeaderView
{
    self.tableView.tableHeaderView =
        [OAUtilities setupTableHeaderViewWithAttributedText:[[NSAttributedString alloc]
                                                                initWithString:[self getTitle]
                                                                    attributes:@{ NSFontAttributeName : [UIFont scaledSystemFontOfSize:30. weight:UIFontWeightBold]} ]
                                          topCenterIconName:@"img_speed_camera_warning"
                                                   iconSize:92.];
}

#pragma mark - Table data

- (void)generateData
{
    _data = [OATableDataModel model];
    OATableSectionData *descriptionSection = [OATableSectionData sectionData];

    NSString *uninstallStr = OALocalizedString(@"shared_string_uninstall");
    NSString *keepActiveStr = OALocalizedString(@"shared_string_keep_active");
    NSString *text = [NSString stringWithFormat:OALocalizedString(@"speed_cameras_legal_descr"), uninstallStr, keepActiveStr];
    NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:text
                                                                                 attributes:@{
                                                                       NSFontAttributeName : [UIFont scaledSystemFontOfSize:15.] }];
    [attrText addAttribute:NSFontAttributeName
                     value:[UIFont scaledSystemFontOfSize:15. weight:UIFontWeightMedium]
                     range:[text rangeOfString:uninstallStr]];
    [attrText addAttribute:NSFontAttributeName
                     value:[UIFont scaledSystemFontOfSize:15. weight:UIFontWeightMedium]
                     range:[text rangeOfString:keepActiveStr]];
    NSMutableParagraphStyle *attrTextParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    attrTextParagraphStyle.minimumLineHeight = 21.;
    [attrText addAttribute:NSParagraphStyleAttributeName
                     value:attrTextParagraphStyle
                     range:NSMakeRange(0, attrText.length)];
    [descriptionSection addRowFromDictionary:@{
        kCellTypeKey : [OATextMultilineTableViewCell getCellIdentifier],
        @"attributedTitle" : attrText
    }];
    [_data addSection:descriptionSection];
}

- (BOOL)hideFirstHeader
{
    return YES;
}

#pragma mark - UITableViewDataSource

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data sectionDataForIndex:section].rowCount;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OATextMultilineTableViewCell getCellIdentifier]])
    {
        OATextMultilineTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OATextMultilineTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextMultilineTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextMultilineTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell clearButtonVisibility:NO];
            cell.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            cell.textView.attributedText = [item objForKey:@"attributedTitle"];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.sectionCount;
}

#pragma mark - Selectors

- (IBAction)onTopButtonPressed:(UIButton *)sender
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [settings setDisabledTypes:[NSSet setWithObject:SPEED_CAMERA]];
    [settings.speedCamerasUninstalled set:YES];
    [settings.speakCameras set:NO];
    [settings.showCameras set:NO];
    [self setDialogShown];

    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
    [[OARootViewController instance].mapPanel refreshMap];

    if (self.delegate)
        [self.delegate onUninstallSpeedCameras];

    [self dismissViewController];
}

- (IBAction)onBottomButtonPressed:(UIButton *)sender
{
    [self setDialogShown];
    [self dismissViewController];
}

- (void)setDialogShown
{
    [[OAAppSettings sharedManager].speedCamerasAlertShown set:YES];
}

@end
