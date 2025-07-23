//
//  OAGPXListDeletingBottomSheet.m
//  OsmAnd Maps
//
//  Created by nnngrach on 15.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAGPXListDeletingBottomSheet.h"

#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "OATextLineViewCell.h"
#import "OAFilledButtonCell.h"
#import "GeneratedAssetSymbols.h"

#define kOABottomSheetWidth 320.
#define kOABottomSheetWidthIPad (DeviceScreenWidth / 2)
#define kLabelVerticalMargin 16.
#define kButtonHeight 42.
#define kButtonsVerticalMargin 16.
#define kHorizontalMargin 20.

@interface OAGPXListDeletingBottomSheetViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *messageView;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end

@implementation OAGPXListDeletingBottomSheetViewController
{
    NSMutableArray<NSDictionary *> *_data;
}

- (instancetype) init
{
    self = [super initWithNibName:@"OABaseBottomSheetViewController" bundle:nil];

    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsZero;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.layoutMargins = UIEdgeInsetsMake(0, 20, 0, 20);
    self.buttonsView.layoutMargins = UIEdgeInsetsMake(0, 20, 0, 20);
    self.buttonsSectionDividerView.backgroundColor = UIColor.clearColor;

    [self.rightButton removeFromSuperview];
    self.closeButton.hidden = YES;
    self.headerDividerView.hidden = YES;
    [self hideSliderView];
    
    self.leftIconView.tintColor = [UIColor colorNamed:ACColorNameButtonBgColorDisruptive];
    [self.leftIconView setImage:[UIImage templateImageNamed:@"ic_custom_remove_outlined.png"]];
    
    self.exitButton.layer.cornerRadius = 9.;
    self.deleteButton.layer.cornerRadius = 9.;
    self.cancelButton.layer.cornerRadius = 9.;
    
    self.titleView.font = [UIFont scaledSystemFontOfSize:17 weight:UIFontWeightMedium];
    
    self.isFullScreenAvailable = NO;
}

- (void) applyLocalization
{
    self.titleView.text = OALocalizedString(@"delete_tracks_bottom_sheet_title");
    [self.deleteButton setTitle:OALocalizedString(@"shared_string_delete") forState:UIControlStateNormal];
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (CGFloat) initialHeight
{
    CGFloat width;
    if (OAUtilities.isIPad)
        width = kOABottomSheetWidthIPad;
    else if ([OAUtilities isLandscape])
        width = kOABottomSheetWidth;
    else
        width = DeviceScreenWidth;
    
    width -= 2 * kHorizontalMargin;
    CGFloat headerHeight = self.headerView.frame.size.height;
    NSString *description = [OALocalizedString(@"delete_tracks_bottom_sheet_description_regular_part") stringByAppendingString:[NSString stringWithFormat:OALocalizedString(@"delete_tracks_bottom_sheet_description_bold_part"), self.deletingTracksCount]];
    CGFloat textHeight = [OAUtilities calculateTextBounds:description width:width font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]].height + kLabelVerticalMargin * 2;
    CGFloat contentHeight = textHeight + 1 * kButtonHeight + 1 * kButtonsVerticalMargin;
    CGFloat buttonsHeight = [self buttonsViewHeight];
    return headerHeight + contentHeight + buttonsHeight;
}

- (CGFloat) getLandscapeHeight
{
    return [self initialHeight];
}

- (void) generateData
{
    _data = [NSMutableArray new];
    
    [_data addObject: @{
        @"type" : [OATextLineViewCell getCellIdentifier],
        @"title_regular_part" : OALocalizedString(@"delete_tracks_bottom_sheet_description_regular_part"),
        @"title_bold_part" : [NSString stringWithFormat:OALocalizedString(@"delete_tracks_bottom_sheet_description_bold_part"), self.deletingTracksCount],
    }];

    [_data addObject: @{
        @"type" : [OAFilledButtonCell getCellIdentifier],
        @"title" : OALocalizedString(@"shared_string_delete"),
        @"buttonColor" : [UIColor colorNamed:ACColorNameButtonBgColorDisruptive],
        @"textColor" : [UIColor colorNamed:ACColorNameButtonTextColorPrimary],
        @"action": @"deleteButtonPressed"
    }];
}

- (BOOL) isDraggingUpAvailable
{
    return NO;
}

#pragma mark - Actions

- (void) deleteButtonPressed
{
    [self hide:YES];
    if (_delegate)
        [_delegate onDeleteConfirmed];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section];
    NSString *type = item[@"type"];
    
    if ([type isEqualToString:[OATextLineViewCell getCellIdentifier]])
    {
        OATextLineViewCell* cell;
        cell = (OATextLineViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATextLineViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextLineViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextLineViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.backgroundColor = UIColor.clearColor;
            NSString *regularPart = item[@"title_regular_part"];
            NSString *boldPart = item[@"title_bold_part"];
            NSString *fullDescription = [regularPart stringByAppendingString:boldPart];
            cell.textView.attributedText = [OAUtilities getStringWithBoldPart:fullDescription mainString:fullDescription boldString:boldPart lineSpacing:0 fontSize:17];
        }
        return cell;
    }
    else if ([type isEqualToString:[OAFilledButtonCell getCellIdentifier]])
    {
        OAFilledButtonCell* cell;
        cell = (OAFilledButtonCell *)[self.tableView dequeueReusableCellWithIdentifier:[OAFilledButtonCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFilledButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAFilledButtonCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
            [cell.button setBackgroundColor:item[@"buttonColor"]];
            [cell.button setTitleColor:item[@"textColor"] forState:UIControlStateNormal];
            [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
            cell.button.layer.cornerRadius = 9.;
            cell.topMarginConstraint.constant = 0;
            cell.bottomMarginConstraint.constant = 0;
            cell.heightConstraint.constant = 42;
            
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.button addTarget:self action:NSSelectorFromString(item[@"action"]) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 1)
        return kButtonsVerticalMargin;
    else
        return kLabelVerticalMargin;
}

@end
