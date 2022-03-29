//
//  OAAlertBottomSheetViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 11.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAAlertBottomSheetViewController.h"
#import "OARootViewController.h"
#import "OARoutePlanningHudViewController.h"
#import "OATitleIconRoundCell.h"
#import "OsmAndApp.h"
#import "OAUtilities.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAOsmAndFormatter.h"
#import "OATextLineViewCell.h"

#define kVerticalMargin 18.
#define kHorizontalMargin 20.
#define kApproximateEmptyMenuHeight 250.
#define kApproximateCellHeight 48.
#define kOABottomSheetWidth 320.
#define kOABottomSheetWidthIPad (DeviceScreenWidth / 2)
#define kLabelVerticalMargin 16.
#define kButtonHeight 42.
#define kButtonsVerticalMargin 32.

@interface OAAlertBottomSheetViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAAlertBottomSheetViewController
{
    NSString *_title;
    NSString *_titleIcon;
    NSString *_message;
    NSString *_doneTitle;
    NSString *_cancelTitle;
    NSArray<NSString *> *_selectableItemsTitles;
    NSArray<NSString *> *_selectableItemsImages;
    OAAlertBottomSheetDoneCompletionBlock _doneCompletitionBlock;
    OAAlertBottomSheetSelectCompletionBlock _selectCompletitionBlock;
    
    NSArray<NSArray *> *_data;
    CGFloat _separatorHeight;
}

+ (void) showAlertWithMessage:(NSString *)message cancelTitle:(NSString *)cancelTitle
{
    OAAlertBottomSheetViewController *bottomSheet = [[OAAlertBottomSheetViewController alloc] initWithTitle:nil titleIcon:nil message:message cancelTitle:cancelTitle doneTitle:nil selectableItemsTitles:nil selectableItemsImages:nil contentView:nil doneColpletition:nil selectColpletition:nil];
    
    [bottomSheet presentInViewController:OARootViewController.instance];
}

+ (void) showAlertWithTitle:(NSString *)title titleIcon:(NSString *)titleIcon message:(NSString *)message cancelTitle:(NSString *)cancelTitle
{
    OAAlertBottomSheetViewController *bottomSheet = [[OAAlertBottomSheetViewController alloc] initWithTitle:title titleIcon:titleIcon message:message cancelTitle:cancelTitle doneTitle:nil selectableItemsTitles:nil selectableItemsImages:nil contentView:nil doneColpletition:nil selectColpletition:nil];
    
    [bottomSheet presentInViewController:OARootViewController.instance];
}

+ (void) showAlertWithTitle:(NSString *)title titleIcon:(NSString *)titleIcon message:(NSString *)message cancelTitle:(NSString *)cancelTitle  doneTitle:(NSString *)doneTitle doneColpletition:(OAAlertBottomSheetDoneCompletionBlock)doneColpletition
{
    OAAlertBottomSheetViewController *bottomSheet = [[OAAlertBottomSheetViewController alloc] initWithTitle:title titleIcon:titleIcon message:message cancelTitle:cancelTitle doneTitle:doneTitle selectableItemsTitles:nil selectableItemsImages:nil contentView:nil doneColpletition:doneColpletition selectColpletition:nil];
    
    [bottomSheet presentInViewController:OARootViewController.instance];
}

+ (void) showAlertWithTitle:(NSString *)title titleIcon:(NSString *)titleIcon cancelTitle:(NSString *)cancelTitle selectableItemsTitles:(NSArray<NSString *> *)selectableItemsTitles selectableItemsImages:(NSArray<NSString *> *)selectableItemsImages  selectColpletition:(OAAlertBottomSheetSelectCompletionBlock)selectColpletition
{
    OAAlertBottomSheetViewController *bottomSheet = [[OAAlertBottomSheetViewController alloc] initWithTitle:title titleIcon:titleIcon message:nil cancelTitle:cancelTitle doneTitle:nil selectableItemsTitles:selectableItemsTitles selectableItemsImages:selectableItemsImages contentView:nil doneColpletition:nil selectColpletition:selectColpletition];
    
    [bottomSheet presentInViewController:OARootViewController.instance];
}

+ (void) showAlertWithTitle:(NSString *)title titleIcon:(NSString *)titleIcon message:(NSString *)message cancelTitle:(NSString *)cancelTitle doneTitle:(NSString *)doneTitle selectableItemsTitles:(NSArray<NSString *> *)selectableItemsTitles selectableItemsImages:(NSArray<NSString *> *)selectableItemsImages doneColpletition:(OAAlertBottomSheetDoneCompletionBlock)doneColpletition selectColpletition:(OAAlertBottomSheetSelectCompletionBlock)selectColpletition
{
    OAAlertBottomSheetViewController *bottomSheet = [[OAAlertBottomSheetViewController alloc] initWithTitle:title titleIcon:titleIcon message:message cancelTitle:cancelTitle doneTitle:doneTitle selectableItemsTitles:selectableItemsTitles selectableItemsImages:selectableItemsImages contentView:nil doneColpletition:doneColpletition selectColpletition:selectColpletition];
    
    [bottomSheet presentInViewController:OARootViewController.instance];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil == nil ? @"OAAlertBottomSheetViewController" : nibNameOrNil bundle:nil];
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self generateData];
    }
    return self;
}

- (instancetype) initWithTitle:(NSString *)title titleIcon:(NSString *)titleIcon message:(NSString *)message cancelTitle:(NSString *)cancelTitle doneTitle:(NSString *)doneTitle selectableItemsTitles:(NSArray<NSString *> *)selectableItemsTitles selectableItemsImages:(NSArray<NSString *> *)selectableItemsImages contentView:(UIView *)contentView doneColpletition:(OAAlertBottomSheetDoneCompletionBlock)doneColpletition selectColpletition:(OAAlertBottomSheetSelectCompletionBlock)selectColpletition
{
    self = [super init];
    if (self)
    {
        _title = title;
        _titleIcon = titleIcon;
        _message = message;
        _doneTitle = doneTitle;
        _cancelTitle = cancelTitle;
        _selectableItemsTitles = selectableItemsTitles;
        _selectableItemsImages = selectableItemsImages;
        _doneCompletitionBlock = doneColpletition;
        _selectCompletitionBlock = selectColpletition;
        [self generateData];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _separatorHeight = 1.0 / [UIScreen mainScreen].scale;
    
    self.headerDividerView.hidden = YES;
    self.buttonsSectionDividerView.hidden = YES;
    
    [self.leftIconView setImage:[UIImage imageNamed:_titleIcon]];
    if (!_titleIcon)
    {
        self.tileLeftConstraint.priority = 1;
        self.tileLeftNoIconConstraint.priority = 999;
    }
    
    if (!_title)
    {
        self.headerViewCollapsedHeight.constant = 0;
        self.leftIconView.hidden = YES;
        self.closeButton.hidden = YES;
        self.titleView.hidden = YES;
    }
    
    if (!_doneTitle)
        [self.rightButton removeFromSuperview];
}

- (void) applyLocalization
{
    self.titleView.text = _title ? _title : @"";
    [self.leftButton setTitle:_cancelTitle ? _cancelTitle : OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.rightButton setTitle:_doneTitle ? _doneTitle : @"" forState:UIControlStateNormal];
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
    CGFloat headerHeight = _title ? self.headerView.frame.size.height : 0;
    CGFloat contentHeight = 0;
    
    if (_message)
        contentHeight += [OAUtilities calculateTextBounds:_message width:width font:[UIFont systemFontOfSize:15.]].height + kLabelVerticalMargin * 3;
    
    if (_selectableItemsTitles && _selectableItemsTitles.count > 0)
        contentHeight += _selectableItemsTitles.count * kApproximateCellHeight + 2 * kVerticalMargin;
    
    CGFloat height = headerHeight + contentHeight + [self buttonsViewHeight];
    int maxHeight = DeviceScreenHeight / 3 * 2;
    if (height > maxHeight)
        height = maxHeight;
    return height;
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    NSMutableArray *messageSection = [NSMutableArray new];
    NSMutableArray *actionSection = [NSMutableArray new];

    if (_message)
    {
        [messageSection addObject: @{
            @"type" : [OATextLineViewCell getCellIdentifier],
            @"title" : _message,
        }];
        [data addObject:messageSection];
    }
    
    if (_selectableItemsTitles)
    {
        for (int i = 0; i < _selectableItemsTitles.count; i++)
        {
            NSString *title = _selectableItemsTitles[i];
            NSString *image = @"";
            if (_selectableItemsImages && _selectableItemsImages.count == _selectableItemsTitles.count)
                image = _selectableItemsImages[i];
            
            [actionSection addObject: @{
                @"type" : [OATitleIconRoundCell getCellIdentifier],
                @"title" : title,
                @"img" : image,
                @"tintColor" : UIColorFromRGB(color_primary_purple),
                @"key" : [NSString stringWithFormat:@"%d", i]
            }];
        }
    }
    [data addObject:actionSection];
    _data = data;
}


- (void) onRightButtonPressed
{
    if (_doneCompletitionBlock)
        _doneCompletitionBlock();
    [super onRightButtonPressed];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *type = item[@"type"];
    if ([type isEqualToString:[OATitleIconRoundCell getCellIdentifier]])
    {
        OATitleIconRoundCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OATitleIconRoundCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleIconRoundCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleIconRoundCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.textColorNormal = UIColor.blackColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            [cell roundCorners:(indexPath.row == 0) bottomCorners:(indexPath.row == _data[indexPath.section].count - 1)];
            cell.titleView.text = item[@"title"];
            UIColor *tintColor = item[@"tintColor"];
            
            NSString *img = item[@"img"];
            if (img && img.length > 0)
            {
                if (tintColor)
                {
                    cell.iconColorNormal = tintColor;
                    cell.iconView.image = [UIImage templateImageNamed:img];
                }
                else
                {
                    cell.iconView.image = [UIImage imageNamed:img];
                }
            }
            cell.separatorView.hidden = indexPath.row == _data[indexPath.section].count - 1;
            cell.separatorView.backgroundColor = UIColorFromRGB(color_tint_gray);
        }
        return cell;
    }
    else if ([type isEqualToString:[OATextLineViewCell getCellIdentifier]])
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
            [cell.textView setTextColor:[UIColor blackColor]];
            [cell.textView setText:item[@"title"]];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kVerticalMargin;
}

#pragma mark - UItableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[OATitleIconRoundCell getCellIdentifier]])
    {
        return [OATitleIconRoundCell getHeight:item[@"title"] cellWidth:tableView.bounds.size.width];
    }
    return UITableViewAutomaticDimension;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    
    if (key)
    {
        [self hide:YES completion:^{
            if (_selectCompletitionBlock)
                _selectCompletitionBlock([key intValue]);
        }];
    }
}

@end
