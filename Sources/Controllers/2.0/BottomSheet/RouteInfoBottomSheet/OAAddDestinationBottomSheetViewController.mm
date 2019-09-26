//
//  OAAddDestinationBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 4/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAAddDestinationBottomSheetViewController.h"
#import "OAActionConfigurationViewController.h"
#import "Localization.h"
#import "OABottomSheetHeaderCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OAAppSettings.h"
#import "OABottomSheetActionCell.h"
#import "OAMapSource.h"

#define kButtonsDividerTag 150
#define kMessageFieldIndex 1

#define kBottomSheetActionCell @"OABottomSheetActionCell"

@interface OAAddDestinationBottomSheetScreen ()

@end

@implementation OAAddDestinationBottomSheetScreen
{
    OsmAndAppInstance _app;
    OAAddDestinationBottomSheetViewController *vwController;
    NSArray* _data;
    
    EOADestinationType _type;
}

@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAAddDestinationBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _type = viewController.type;
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAAddDestinationBottomSheetViewController *)viewController
{
    _app = [OsmAndApp instance];
    
    vwController = viewController;
    tblView = tableView;
    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self initData];
}

- (NSString *) getTitle
{
    switch (_type) {
        case EOADestinationTypeHome:
            return OALocalizedString(@"add_home");
        case EOADestinationTypeWork:
            return OALocalizedString(@"add_work");
        case EOADestinationTypeStart:
            return OALocalizedString(@"add_start");
        case EOADestinationTypeFinish:
            return OALocalizedString(@"add_destination");
        case EOADestinationTypeIntermediate:
            return OALocalizedString(@"add_intermediate");
        default:
            return @"";
    }
}

- (void) setupView
{
    [[self.vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
    NSMutableArray *arr = [NSMutableArray array];
    [arr addObject:@{
                     @"type" : @"OABottomSheetHeaderCell",
                     @"title" : [self getTitle],
                     @"description" : @""
                     }];
    
    _data = [NSArray arrayWithArray:arr];
}

- (void) initData
{
}

- (void) onDonePressed:(id)sender
{
    [self.vwController dismiss];
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = _data[indexPath.row];
    
    if ([item[@"type"] isEqualToString:@"OABottomSheetHeaderCell"])
    {
        return [OABottomSheetHeaderCell getHeight:item[@"title"] cellWidth:DeviceScreenWidth];
    }
    else if ([item[@"type"] isEqualToString:kBottomSheetActionCell])
    {
        return [OABottomSheetActionCell getHeight:item[@"title"] value:item[@"descr"] cellWidth:tableView.bounds.size.width];
    }
    else
    {
        return 44.0;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    
    if ([item[@"type"] isEqualToString:@"OABottomSheetHeaderCell"])
    {
        static NSString* const identifierCell = @"OABottomSheetHeaderCell";
        OABottomSheetHeaderCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OABottomSheetHeaderCell" owner:self options:nil];
            cell = (OABottomSheetHeaderCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleView.text = item[@"title"];
            cell.sliderView.layer.cornerRadius = 3.0;
            if (!cell.accessoryView)
            {
                UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
                UIFont *font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
                NSString *btnText = OALocalizedString(@"shared_string_done");
                CGFloat w = [btnText sizeWithAttributes:@{NSFontAttributeName : font}].width;
                doneButton.frame = CGRectMake(0., 0., w, cell.bounds.size.height);
                [doneButton setTitle:btnText forState:UIControlStateNormal];
                [doneButton setTintColor:UIColorFromRGB(color_primary_purple)];
                doneButton.titleLabel.font = font;
                [doneButton addTarget:self action:@selector(onDonePressed:) forControlEvents:UIControlEventTouchUpInside];
                cell.accessoryView = doneButton;
            }
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kBottomSheetActionCell])
    {
        static NSString* const identifierCell = kBottomSheetActionCell;
        OABottomSheetActionCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kBottomSheetActionCell owner:self options:nil];
            cell = (OABottomSheetActionCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
        }
        
        if (cell)
        {
            UIImage *img = nil;
            NSString *imgName = item[@"img"];
            if (imgName)
                img = [UIImage imageNamed:imgName];
            
            cell.textView.text = item[@"title"];
            NSString *desc = item[@"descr"];
            cell.descView.text = desc;
            cell.descView.hidden = desc.length == 0;
            cell.iconView.image = img;
            if (!cell.accessoryView)
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_cell_selected"]];
        }
        return cell;
    }
    else
    {
        return nil;
    }
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.row];
}


- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 10.0;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    view.hidden = YES;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if (![item[@"type"] isEqualToString:@"OABottomSheetHeaderCell"])
        return indexPath;
    else
        return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    [self.vwController dismiss];
}

@synthesize vwController;

@end

@interface OAAddDestinationBottomSheetViewController ()

@end

@implementation OAAddDestinationBottomSheetViewController

- (instancetype) initWithType:(EOADestinationType)type
{
    _type = type;
    return [super initWithParam:nil];
}

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAAddDestinationBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];
    
    [super setupView];
}

- (void)additionalSetup
{
    [super additionalSetup];
    [self hideDoneButton];
}

- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
}

@end
