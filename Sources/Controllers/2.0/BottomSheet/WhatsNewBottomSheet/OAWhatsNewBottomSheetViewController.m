//
//  OAWhatsNewBottomSheetViewController.m
//  OsmAnd
//
//  Created by Max Kojin on 26.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAWhatsNewBottomSheetViewController.h"
#import "OAAppVersionDependedConstants.h"
#import "Localization.h"
#import "OABottomSheetHeaderButtonCell.h"
#import "OAColors.h"
#import "OADescrTitleCell.h"
#import "OADividerCell.h"

#define kButtonsTag 1
#define kButtonsDividerTag 150
#define kBottomSheetHeaderButtonCell @"OABottomSheetHeaderButtonCell"
#define kDescrTitleCell @"OADescrTitleCell"


@interface OAWhatsNewBottomSheetScreen ()

@end

@implementation OAWhatsNewBottomSheetScreen
{
    OAWhatsNewBottomSheetViewController *vwController;
    NSArray* _data;
}
@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAWhatsNewBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAWhatsNewBottomSheetViewController *)viewController
{
    vwController = viewController;
    tblView = tableView;
    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self initData];
}

- (void) setupView
{
    [[vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
    NSMutableArray *model = [NSMutableArray new];
    NSMutableArray *arr = [NSMutableArray array];
    
    [arr addObject:@{
                     @"type" : kBottomSheetHeaderButtonCell,
                     @"title" : OALocalizedString(@"what_is_new"),
                     @"description" : @"",
                     @"img" : @"ic_custom_poi.png"
                     }];
    [model addObject:[NSArray arrayWithArray:arr]];
    [arr removeAllObjects];

    NSString *fullAppVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *title = [NSString stringWithFormat:OALocalizedString(@"latest_version"), fullAppVersion];
    NSString *releaseNotesKey = [NSString stringWithFormat:@"ios_release_%@", [OAAppVersionDependedConstants getShortAppVersionWithSeparator:@"_"]];
    
    [arr addObject:@{
                     @"type" : kDescrTitleCell,
                     @"title" : title,
                     @"description" : OALocalizedString(releaseNotesKey)
                     }];
    [model addObject:[NSArray arrayWithArray:arr]];

    _data = [NSArray arrayWithArray:model];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    return UITableViewAutomaticDimension;
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionData = _data[section];
    return sectionData.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
    if ([item[@"type"] isEqualToString:kBottomSheetHeaderButtonCell])
    {
        static NSString* const identifierCell = kBottomSheetHeaderButtonCell;
        OABottomSheetHeaderDescrButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kBottomSheetHeaderButtonCell owner:self options:nil];
            cell = (OABottomSheetHeaderButtonCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.iconView.tintColor = UIColorFromRGB(color_osmand_orange);
        }
        if (cell)
        {
            cell.titleView.text = item[@"title"];
            [cell.iconView setImage:[[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            cell.iconView.hidden = !cell.iconView.image;
            [cell.closeButton removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.closeButton addTarget:self action:@selector(onCloseButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kDescrTitleCell])
    {
        OADescrTitleCell* cell;
        cell = (OADescrTitleCell *)[self.tblView dequeueReusableCellWithIdentifier:kDescrTitleCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kDescrTitleCell owner:self options:nil];
            cell = (OADescrTitleCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.contentView.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.descriptionView.textColor = [UIColor blackColor];
            cell.descriptionView.backgroundColor = UIColor.clearColor;
            cell.textView.hidden = YES;
        }
        if (cell)
        {
            NSString *labelText = [NSString stringWithFormat:@"%@\n\n%@", item[@"title"], item[@"description"]];
            NSRange boldRange = NSMakeRange(0, ((NSString *)item[@"title"]).length);
            NSRange fullRange = NSMakeRange(0, labelText.length);
            
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:labelText];
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            [paragraphStyle setLineSpacing:5];
            [paragraphStyle setLineHeightMultiple:0.8];
            [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:fullRange];
            
            UIFont *regularFont = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
            UIFont *semiboldFont = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
            [attributedString addAttribute:NSFontAttributeName value:regularFont range:fullRange];
            [attributedString addAttribute:NSFontAttributeName value:semiboldFont range:boldRange];
            
            cell.descriptionView.attributedText = attributedString;
        }
        return cell;
    }
    else
    {
        return nil;
    }
}

- (void) onCloseButtonPressed:(id)sender
{
    [vwController dismiss];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.001;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 16.0;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    view.hidden = YES;
}

@end


@interface OAWhatsNewBottomSheetViewController ()

@end

@implementation OAWhatsNewBottomSheetViewController

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAWhatsNewBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];
    
    [super setupView];
}

- (void) setupButtons
{
    [super setupButtons];
    self.doneButton.backgroundColor = UIColorFromRGB(color_primary_purple);
    [self.doneButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.doneButton.tag = kButtonsTag;
    self.cancelButton.tag = kButtonsTag;
}

- (void)additionalSetup
{
    [super additionalSetup];
    self.tableBackgroundView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
    self.buttonsView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
 
    for (UIView *v in self.buttonsView.subviews)
    {
        if (v.tag != kButtonsTag)
            v.backgroundColor = UIColor.clearColor;
    }
}

- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_read_more") forState:UIControlStateNormal];
}

- (void) doneButtonPressed:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kLatestChangesUrl] options: @{} completionHandler:nil];
    [self dismiss];
}

@end
