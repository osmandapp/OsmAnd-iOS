//
//  OAGPXListDeletingBottomSheet.m
//  OsmAnd Maps
//
//  Created by nnngrach on 15.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAGPXListDeletingBottomSheet.h"

#import "Localization.h"
#import "OAColors.h"
#import "OATextLineViewCell.h"
#import "OAFilledButtonCell.h"

#define kOABottomSheetWidth 320.
#define kOABottomSheetWidthIPad (DeviceScreenWidth / 2)
#define kLabelVerticalMargin 16.
#define kButtonHeight 42.
#define kButtonsVerticalMargin 16.
#define kHorizontalMargin 20.

@interface OAGPXListDeletingBottomSheetViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UILabel *messageView;
@property (strong, nonatomic) IBOutlet UIButton *exitButton;
@property (strong, nonatomic) IBOutlet UIButton *deleteButton;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;

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
    self.buttonsSectionDividerView.backgroundColor = UIColor.clearColor;;

    [self.rightButton removeFromSuperview];
    self.closeButton.hidden = YES;
    self.headerDividerView.hidden = YES;
    [self hideSliderView];
    
    self.leftIconView.tintColor = UIColorFromRGB(color_support_red);
    [self.leftIconView setImage:[UIImage templateImageNamed:@"ic_custom_remove_outlined.png"]];
    
    self.exitButton.layer.cornerRadius = 9.;
    self.deleteButton.layer.cornerRadius = 9.;
    self.cancelButton.layer.cornerRadius = 9.;
    
    self.titleView.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    
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
    NSString *description = [NSString stringWithFormat:OALocalizedString(@"delete_tracks_bottom_sheet_description"), self.deletingTracksCount];
    CGFloat textHeight = [OAUtilities calculateTextBounds:description width:width font:[UIFont systemFontOfSize:17.]].height + kLabelVerticalMargin * 2;
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
        @"title" : [NSString stringWithFormat:OALocalizedString(@"delete_tracks_bottom_sheet_description"), self.deletingTracksCount],
    }];

    [_data addObject: @{
        @"type" : [OAFilledButtonCell getCellIdentifier],
        @"title" : OALocalizedString(@"shared_string_delete"),
        @"buttonColor" : UIColorFromRGB(color_support_red),
        @"textColor" : UIColor.whiteColor,
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
            NSString *originalText = item[@"title"];
            int startIndex = [originalText indexOf:@"{"];
            int endIndex = [originalText indexOf:@"}"];
            NSString *boldText = [originalText substringWithRange:NSMakeRange(startIndex + 1, endIndex - startIndex - 1)];
            originalText = [originalText stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"{%@}", boldText] withString:boldText];
            cell.textView.attributedText = [OAUtilities getStringWithBoldPart:originalText mainString:originalText boldString:boldText lineSpacing:0 fontSize:17];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
        return UITableViewAutomaticDimension;
    else
        return 42;
}

@end
