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
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

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

- (EOABaseNavbarStyle)getNavbarStyle
{
    return EOABaseNavbarStyleCustomLargeTitle;
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
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:[self getTitle]
                                                                         attributes:@{
        NSParagraphStyleAttributeName : paragraphStyle,
        NSFontAttributeName : [UIFont scaledSystemFontOfSize:30. weight:UIFontWeightBold]
    }];
    self.tableView.tableHeaderView =
        [OAUtilities setupTableHeaderViewWithAttributedText:attributedText
                                          topCenterIconName:@"img_speed_camera_warning"
                                                   iconSize:92.
                                            parentViewWidth:self.view.frame.size.width];
}

#pragma mark - Table data

- (void)generateData
{
    _data = [OATableDataModel model];
    OATableSectionData *descriptionSection = [OATableSectionData sectionData];

    NSString *uninstallStr = OALocalizedString(@"shared_string_uninstall");
    NSString *keepActiveStr = OALocalizedString(@"shared_string_keep_active");
    NSString *text = [NSString stringWithFormat:OALocalizedString(@"speed_cameras_legal_descr"), keepActiveStr, uninstallStr];
    NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:text
                                                                                 attributes:@{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleBody],
        NSForegroundColorAttributeName: [UIColor colorNamed:ACColorNameTextColorPrimary]
    }];
    [attrText addAttribute:NSFontAttributeName
                     value:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]
                     range:[text rangeOfString:uninstallStr]];
    [attrText addAttribute:NSFontAttributeName
                     value:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]
                     range:[text rangeOfString:keepActiveStr]];
    NSMutableParagraphStyle *attrTextParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    attrTextParagraphStyle.minimumLineHeight = 22.;
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

- (void)onTopButtonPressed
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

    UIAlertController *alert =
                [UIAlertController alertControllerWithTitle:OALocalizedString(@"restart_is_required_title")
                                                    message:OALocalizedString(@"restart_is_required")
                                             preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok")
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                        [self dismissViewController];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
}

- (void)onBottomButtonPressed
{
    [self setDialogShown];
    [self dismissViewController];
}

- (void)setDialogShown
{
    [[OAAppSettings sharedManager].speedCamerasAlertShown set:YES];
}

@end
