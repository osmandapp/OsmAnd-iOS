//
//  OADeleteWaypointsGroupBottomSheetViewController.mm
//  OsmAnd
//
//  Created by Skalii on 20.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OADeleteWaypointsGroupBottomSheetViewController.h"
#import "OABaseTrackMenuHudViewController.h"
#import "OATextLineViewCell.h"
#import "OAFilledButtonCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OATrackMenuHudViewController.h"

#define kOABottomSheetWidth 320.
#define kOABottomSheetWidthIPad (DeviceScreenWidth / 2)
#define kButtonHeight 42.
#define kHorizontalMargin 20.

@interface OADeleteWaypointsGroupBottomSheetViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OADeleteWaypointsGroupBottomSheetViewController
{
    NSArray<OAGPXTableSectionData *> *_tableData;

    NSString *_groupName;
}

- (instancetype)init
{
    self = [super initWithNibName:@"OABaseBottomSheetViewController" bundle:nil];

    return self;
}

- (instancetype)initWithGroupName:(NSString *)groupName
{
    self = [super init];
    if (self)
    {
        _groupName = groupName;
        [self generateData];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.isFullScreenAvailable = NO;

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorInset = UIEdgeInsetsZero;

    self.buttonsView.layoutMargins = UIEdgeInsetsMake(0, 20, 0, 20);
    self.leftIconView.tintColor = UIColorFromRGB(color_primary_red);
    [self.leftIconView setImage:[UIImage templateImageNamed:@"ic_custom_remove_outlined"]];
    [self hideSliderView];
    [self.rightButton removeFromSuperview];
    [self.closeButton removeFromSuperview];
    [self.headerDividerView removeFromSuperview];
    [self.buttonsSectionDividerView removeFromSuperview];
}

- (void)applyLocalization
{
    self.titleView.text = OALocalizedString(@"delete_group_confirm_short");
    [self.leftButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (void)generateData
{
    OAGPXTableCellData *deleteCellData = [OAGPXTableCellData withData:@{
            kCellKey: @"delete",
            kCellType: [OAFilledButtonCell getCellIdentifier],
            kTableValues: @{ @"title_color_value_integer": @color_icon_color_night },
            kCellTitle: OALocalizedString(@"shared_string_delete"),
            kCellTintColor: @color_primary_red
    }];
    deleteCellData.onButtonPressed = ^() {
        [self hide:YES completion:^{
            if (self.trackMenuDelegate)
            {
                [self.trackMenuDelegate deleteWaypointsGroup:_groupName
                                           selectedWaypoints:nil];
                [self.trackMenuDelegate refreshLocationServices];
            }
        }];
    };

    _tableData = @[
            [OAGPXTableSectionData withData:@{
                    kSectionCells: @[[OAGPXTableCellData withData:@{
                            kCellKey: @"confirm",
                            kCellType: [OATextLineViewCell getCellIdentifier],
                            kCellTitle: [NSString stringWithFormat:OALocalizedString(@"delete_group_confirm"), _groupName]
                    }]]
            }],
            [OAGPXTableSectionData withData:@{ kSectionCells: @[deleteCellData] }]
    ];
}

- (CGFloat)initialHeight
{
    CGFloat textHeight =
            [OAUtilities calculateTextBounds:[NSString stringWithFormat:OALocalizedString(@"delete_group_confirm"), _groupName]
                                       width:self.tableView.frame.size.width - kHorizontalMargin * 2
                                        font:[UIFont systemFontOfSize:17.]].height;
    CGFloat contentHeight = textHeight + kButtonHeight + 60.;
    return self.headerView.frame.size.height + contentHeight + self.buttonsView.frame.size.height;
}

- (CGFloat)getLandscapeHeight
{
    return [self initialHeight];
}

- (BOOL)isDraggingUpAvailable
{
    return NO;
}

- (IBAction)leftButtonPressed:(id)sender
{
    [self hide:YES completion:^{
        if (self.trackMenuDelegate)
            [self.trackMenuDelegate openWaypointsGroupOptionsScreen:_groupName];
    }];
}

- (OAGPXTableCellData *)getCellData:(NSIndexPath *)indexPath
{
    return _tableData[indexPath.section].cells[indexPath.row];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _tableData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _tableData[section].cells.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    if ([cellData.type isEqualToString:[OATextLineViewCell getCellIdentifier]])
    {
        OATextLineViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextLineViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextLineViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextLineViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
            cell.textView.textColor = UIColor.blackColor;
        }
        if (cell)
        {
            cell.textView.text = cellData.title;
        }
        return cell;
    }
    else if ([cellData.type isEqualToString:[OAFilledButtonCell getCellIdentifier]])
    {
        OAFilledButtonCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAFilledButtonCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFilledButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAFilledButtonCell *) nib[0];
        }
        if (cell)
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
            [cell.button setBackgroundColor:UIColorFromRGB(cellData.tintColor)];
            [cell.button setTitleColor:UIColorFromRGB([cellData.values[@"title_color_value_integer"] intValue])
                              forState:UIControlStateNormal];
            [cell.button setTitle:cellData.title forState:UIControlStateNormal];
            cell.button.layer.cornerRadius = 9.;
            cell.topMarginConstraint.constant = 0;
            cell.bottomMarginConstraint.constant = 0;

            cell.button.tag = indexPath.section << 10 | indexPath.row;
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.button addTarget:self action:@selector(cellButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }

    return nil;
}

#pragma mark - UItableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section != 0 ? 25. : 0.001;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    if ([cellData.type isEqualToString:[OAFilledButtonCell getCellIdentifier]])
        return kButtonHeight;

    return UITableViewAutomaticDimension;
}

#pragma mark - selectors

- (void)cellButtonPressed:(id)sender
{
    UIButton *switchView = (UIButton *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
    OAGPXTableCellData *cellData = [self getCellData:indexPath];

    if (cellData.onButtonPressed)
        cellData.onButtonPressed();
}

@end
