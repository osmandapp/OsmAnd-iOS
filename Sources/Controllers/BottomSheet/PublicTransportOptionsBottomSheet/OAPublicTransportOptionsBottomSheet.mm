//
//  OAPublicTransportOptionsBottomSheet.m
//  OsmAnd
//
//  Created by nnngrach on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAPublicTransportOptionsBottomSheet.h"
#import "OABottomSheetHeaderIconCell.h"
#import "OASwitchTableViewCell.h"
#import "OAMapStyleSettings.h"
#import "Localization.h"
#import "OAColors.h"
#import "OATableViewCustomHeaderView.h"
#import "GeneratedAssetSymbols.h"

#define kButtonsDividerTag 150

@interface OAPublicTransportOptionsBottomSheetScreen ()

@end

@implementation OAPublicTransportOptionsBottomSheetScreen
{
    OAMapStyleSettings *_styleSettings;
    OAPublicTransportOptionsBottomSheetViewController *vwController;

    NSArray<NSArray<NSMutableDictionary *> *> *_data;
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

    NSMutableDictionary *headerIconCell = [NSMutableDictionary dictionary];
    headerIconCell[@"type"] = [OABottomSheetHeaderIconCell getCellIdentifier];
    headerIconCell[@"title"] = OALocalizedString(@"transport");
    headerIconCell[@"description"] = @"";
    [data addObject:@[headerIconCell]];

    NSMutableArray *section = [NSMutableArray array];
    NSArray *parameters = [_styleSettings getParameters:TRANSPORT_CATEGORY];
    for (OAMapStyleParameter *parameter in parameters)
    {
        NSMutableDictionary *cell = [NSMutableDictionary dictionary];
        cell[@"parameter"] = parameter;
        cell[@"title"] = parameter.title;
        cell[@"value"] = @([parameter.storedValue isEqualToString:@"true"]);
        cell[@"type"] = [OASwitchTableViewCell getCellIdentifier];
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

- (void)onSwitch:(BOOL)toggle cell:(NSMutableDictionary *)cell indexPath:(NSIndexPath *)indexPath
{
    OAMapStyleParameter *parameter = cell[@"parameter"];
    parameter.value = toggle ? @"true" : @"false";
    [_styleSettings save:parameter];
    cell[@"value"] = @(toggle);
    [self.tblView reloadRowsAtIndexPaths:@[indexPath]
                        withRowAnimation:UITableViewRowAnimationAutomatic];
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
    else if ([item[@"type"] isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            BOOL isOn = [item[@"value"] boolValue];
            NSString *iconName = item[@"icon"];
            if (iconName)
            {
                UIImage *icon;
                if ([iconName hasPrefix:@"mx_"])
                    icon = [[OAUtilities getMxIcon:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                else
                    icon = [UIImage templateImageNamed:item[@"icon"]];
                cell.leftIconView.image = icon;
                cell.leftIconView.tintColor = isOn ? [UIColor colorNamed:ACColorNameIconColorActive] : [UIColor colorNamed:ACColorNameIconColorDisabled];
            }
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
        return [OATableViewCustomHeaderView getHeight:OALocalizedString(@"transport_Routes")
                                                width:tableView.bounds.size.width
                                              yOffset:32
                                                 font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]];
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
        customHeader.label.text = [OALocalizedString(@"transport_Routes") upperCase];
        customHeader.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
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
        NSMutableDictionary *item = _data[indexPath.section][indexPath.row];
        [self onSwitch:switchView.isOn cell:item indexPath:indexPath];
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

