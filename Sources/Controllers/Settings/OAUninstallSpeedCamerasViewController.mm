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

@interface OAUninstallSpeedCamerasViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAUninstallSpeedCamerasViewController
{
    OATableDataModel *_data;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [self setupNavBarHeight];
    [self setupButtons];
    [self generateData];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self setupNavBarHeight];
}

- (void)applyLocalization
{
    [super applyLocalization];

    self.titleLabel.text = OALocalizedString(@"speed_camera_pois");
}

- (void)setupButtons
{
    [self.secondaryBottomButton setTitle:OALocalizedString(@"shared_string_uninstall") forState:UIControlStateNormal];
    [self.primaryBottomButton setTitle:OALocalizedString(@"shared_string_keep_active") forState:UIControlStateNormal];
    self.secondaryBottomButton.tintColor = UIColor.whiteColor;
    self.primaryBottomButton.tintColor = UIColorFromRGB(color_primary_purple);
    [self.secondaryBottomButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.primaryBottomButton setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
    self.primaryBottomButton.backgroundColor = UIColorFromRGB(color_route_button_inactive);
    self.secondaryBottomButton.backgroundColor = UIColorFromRGB(color_primary_red);

    self.bottomBarView.backgroundColor = self.tableView.backgroundColor;
    self.primaryButtonTopMarginYesSecondary.constant = 30.;
    self.buttonSeparator.hidden = YES;
    self.bottomViewHeigh.constant = self.primaryBottomButton.frame.origin.y + self.primaryBottomButton.frame.size.height + [OAUtilities getBottomMargin] + 22.;

    self.additionalNavBarButton.hidden = YES;
    self.backImageButton.hidden = YES;
    self.backButton.hidden = NO;
    [self.backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (void)setupNavBarHeight
{
    self.navBarHeightConstraint.constant = [self isModal] ? [OAUtilities isLandscape] ? defaultNavBarHeight : modalNavBarHeight : defaultNavBarHeight;
}

- (void)setTableHeaderView:(NSString *)label
{
    self.tableView.tableHeaderView =
        [OAUtilities setupTableHeaderViewWithAttributedText:[[NSAttributedString alloc]
                                                                initWithString:label
                                                                    attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:30. weight:UIFontWeightBold]} ]
                                          topCenterIconName:@"img_speed_camera_warning"
                                                   iconSize:92.];
}

- (NSString *)getTableHeaderTitle
{
    return OALocalizedString(@"speed_camera_pois");
}

- (void)generateData
{
    _data = [OATableDataModel model];
    OATableSectionData *descriptionSection = [OATableSectionData sectionData];

    NSString *uninstallStr = OALocalizedString(@"shared_string_uninstall");
    NSString *keepActiveStr = OALocalizedString(@"shared_string_keep_active");
    NSString *text = [NSString stringWithFormat:OALocalizedString(@"speed_cameras_legal_descr"), uninstallStr, keepActiveStr];
    NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:text
                                                                                 attributes:@{
                                                                       NSFontAttributeName : [UIFont systemFontOfSize:15.] }];
    [attrText addAttribute:NSFontAttributeName
                     value:[UIFont systemFontOfSize:15. weight:UIFontWeightMedium]
                     range:[text rangeOfString:uninstallStr]];
    [attrText addAttribute:NSFontAttributeName
                     value:[UIFont systemFontOfSize:15. weight:UIFontWeightMedium]
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

- (void)setDialogShowed
{
    [[OAAppSettings sharedManager].speedCamerasAlertShowed set:YES];
}

- (IBAction)secondaryButtonPressed:(id)sender
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [settings setForbiddenTypes:[NSSet setWithObject:SPEED_CAMERA]];
    [settings.speedCamerasUninstalled set:YES];
    [settings.speakCameras set:NO];
    [settings.showCameras set:NO];
    [self setDialogShowed];

    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
    [[OARootViewController instance].mapPanel refreshMap];

    if (self.delegate)
        [self.delegate onUninstallSpeedCameras];

    [self dismissViewController];
}

- (IBAction)primaryButtonPressed:(id)sender
{
    [self setDialogShowed];
    [self dismissViewController];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OATextMultilineTableViewCell getCellIdentifier]])
    {
        OATextMultilineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextMultilineTableViewCell getCellIdentifier]];
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

@end
