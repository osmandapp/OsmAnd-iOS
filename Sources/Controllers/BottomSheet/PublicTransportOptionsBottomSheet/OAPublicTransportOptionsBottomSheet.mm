//
//  OAPublicTransportOptionsBottomSheet.m
//  OsmAnd
//
//  Created by nnngrach on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAPublicTransportOptionsBottomSheet.h"
#import "OABottomSheetHeaderIconCell.h"
#import "OAIconTextDividerSwitchCell.h"
#import "OAMapStyleSettings.h"
#import "Localization.h"
#import "OAColors.h"
#import "OATableViewCustomHeaderView.h"

#define kButtonsDividerTag 150

typedef void(^OAPublicTransportOptionsCellDataOnSwitch)(BOOL is, NSIndexPath *indexPath);

@interface OAPublicTransportOptionsBottomSheetScreen ()

@end

@implementation OAPublicTransportOptionsBottomSheetScreen
{
    OAMapStyleSettings *_styleSettings;
    OAPublicTransportOptionsBottomSheetViewController *vwController;

    NSArray<NSArray *> *_data;
    NSInteger _transportRoutesSection;
}

@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAPublicTransportOptionsBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAPublicTransportOptionsBottomSheetViewController *)viewController
{
    _styleSettings = [OAMapStyleSettings sharedInstance];
    vwController = viewController;
    tblView = tableView;
    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self initData];
}

- (void) initData
{
    NSMutableArray *data = [NSMutableArray array];

    [data addObject:@[@{
            @"type" : [OABottomSheetHeaderIconCell getCellIdentifier],
            @"title" : OALocalizedString(@"transport"),
            @"description" : @""
    }]];

    NSMutableArray *section = [NSMutableArray array];
    NSArray *parameters = [_styleSettings getParameters:TRANSPORT_CATEGORY];
    for (OAMapStyleParameter *parameter in parameters)
    {
        NSMutableDictionary *cell = [NSMutableDictionary dictionary];
        cell[@"title"] = parameter.title;
        cell[@"value"] = @([parameter.storedValue isEqualToString:@"true"]);
        cell[@"type"] = [OAIconTextDividerSwitchCell getCellIdentifier];
        cell[@"switch"] = ^(BOOL isOn, NSIndexPath *indexPath) {
            parameter.value = isOn ? @"true" : @"false";
            [_styleSettings save:parameter];
            cell[@"value"] = @(isOn);
            [self.tblView reloadRowsAtIndexPaths:@[indexPath]
                                withRowAnimation:UITableViewRowAnimationAutomatic];
        };
        cell[@"icon"] = [OAMapStyleSettings getTransportIconForName:parameter.name];
        cell[@"index"] = @([OAMapStyleSettings getTransportSortIndexForName:parameter.name]);

        if ([parameter.name isEqualToString:@"transportStops"])
        {
            [data addObject:@[cell]];
            continue;
        }

        [section addObject:cell];
    }

    _transportRoutesSection = data.count;

    [data addObject:[section sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        return [obj1[@"index"] compare:obj2[@"index"]];
    }]];

    _data = data;
}

- (void) setupView
{
    [[self.vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
    [vwController.cancelButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
    [self.tblView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
}

- (BOOL) cancelButtonPressed
{
    return YES;
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    UITableViewCell *outCell = nil;
    if ([item[@"type"] isEqualToString:[OABottomSheetHeaderIconCell getCellIdentifier]])
    {
        OABottomSheetHeaderIconCell *cell = [tableView dequeueReusableCellWithIdentifier:[OABottomSheetHeaderIconCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OABottomSheetHeaderIconCell getCellIdentifier] owner:self options:nil];
            cell = (OABottomSheetHeaderIconCell *) nib[0];
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.iconView.hidden = YES;
        }
        if (cell)
        {
            cell.titleView.text = item[@"title"];
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OAIconTextDividerSwitchCell getCellIdentifier]])
    {
        OAIconTextDividerSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTextDividerSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextDividerSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTextDividerSwitchCell *) nib[0];
            cell.dividerView.hidden = YES;
        }
        
        if (cell)
        {
            BOOL isOn = [item[@"value"] boolValue];

            [cell showIcon:YES];
            NSString *iconName = item[@"icon"];
            if (iconName)
            {
                UIImage *icon;
                if ([iconName hasPrefix:@"mx_"])
                    icon = [[OAUtilities getMxIcon:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                else
                    icon = [UIImage templateImageNamed:item[@"icon"]];
                cell.iconView.image = icon;
                cell.iconView.tintColor = isOn ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_tint_gray);
            }

            [cell.textView setText:item[@"title"]];
            [cell.switchView setOn:isOn];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [self numberOfSectionsInTableView:self.tblView] - 1 == section ? 32.0 : 0.001;
}

- (void) tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    view.hidden = YES;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == _transportRoutesSection)
    {
        return [OATableViewCustomHeaderView getHeight:OALocalizedString(@"transport_routes")
                                                width:tableView.bounds.size.width
                                              yOffset:32
                                                 font:[UIFont systemFontOfSize:13]];
    }
    else
    {
        return 0.001;
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == _transportRoutesSection)
    {
        OATableViewCustomHeaderView *customHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
        customHeader.label.text = [OALocalizedString(@"transport_routes") upperCase];
        customHeader.label.font = [UIFont systemFontOfSize:13];
        [customHeader setYOffset:32];
        return customHeader;
    }

    return nil;
}

#pragma mark - Selectors

- (void) onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *)sender;
    if (switchView)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
        NSDictionary *item = _data[indexPath.section][indexPath.row];
        if (item[@"switch"])
            ((OAPublicTransportOptionsCellDataOnSwitch) item[@"switch"])(switchView.isOn, indexPath);
    }
}

@synthesize vwController;

@end


@interface OAPublicTransportOptionsBottomSheetViewController ()

@end

@implementation OAPublicTransportOptionsBottomSheetViewController

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAPublicTransportOptionsBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:nil];
    
    [super setupView];
}

- (void)additionalSetup
{
    [super additionalSetup];
    [super hideDoneButton];
}

@end

