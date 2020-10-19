//
//  OAImportProfileViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAImportProfileViewController.h"
#import "OAAppSettings.h"
#import "OAIconTextDescCell.h"
#import "OAIconTextTableViewCell.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16
#define kTopPadding 6
#define kBottomPadding 32
#define kCellTypeSectionHeader @"OAIconTextNoDescCell"
#define kCellTypeTitleDescription @"OAIconTextWithDescCell"
#define kCellTypeTitle @"OAIconTextCell"

@interface TableGroupToImport : NSObject
    @property NSString* type;
    @property BOOL isOpen;
    @property NSString* groupName;
    @property NSString* selectedItems;
    @property NSMutableArray* groupItems;
@end

@implementation TableGroupToImport

-(id) init {
    self = [super init];
    if (self) {
        self.groupItems = [[NSMutableArray alloc] init];
    }
    return self;
}

@end

@interface OAImportProfileViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAImportProfileViewController
{
    OAAppSettings *_settings;
    NSMutableArray *_data;
    
    CGFloat _heightForHeader;
    NSMutableArray<NSIndexPath *> *_selectedItems;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

- (void) applyLocalization
{
    [super applyLocalization];
    
    [self.backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.additionalNavBarButton setTitle:OALocalizedString(@"select_all") forState:UIControlStateNormal];
    [self.primaryBottomButton setTitle:OALocalizedString(@"shared_string_continue") forState:UIControlStateNormal];
}

- (void) updateNavigationBarItem
{
    [self.additionalNavBarButton setTitle:_selectedItems.count >= 2 ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"select_all") forState:UIControlStateNormal];
}

- (NSString *) getTableHeaderTitle
{
    return OALocalizedString(@"import_profile");
}

- (void) viewDidLoad
{
    [self generateData];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setEditing:YES];
    self.tableView.tintColor = UIColorFromRGB(color_primary_purple);
    
    [self.additionalNavBarButton addTarget:self action:@selector(selectDeselectAllItems:) forControlEvents:UIControlEventTouchUpInside];
    self.secondaryBottomButton.hidden = YES;
    self.backImageButton.hidden = YES;
    _selectedItems = [[NSMutableArray alloc] init];
    [super viewDidLoad];
}

- (void) generateData // to change
{
    NSMutableArray *data = [NSMutableArray array];
    
    TableGroupToImport *profilesSection = [[TableGroupToImport alloc] init];
    profilesSection.groupName = @"Profiles";
    profilesSection.selectedItems = @"0 of 20";
    profilesSection.type = kCellTypeSectionHeader;
    profilesSection.isOpen = NO;
   
    [profilesSection.groupItems addObject:@{
            @"icon" : @"ic_action_car_dark",
            @"color" : UIColor.greenColor,
            @"title" : @"Driving",
            @"description" : @"Navigaton type: Car",
            @"type" : kCellTypeTitleDescription,
        }];
    
    [profilesSection.groupItems addObject:@{
            @"icon" : @"ic_action_bicycle_dark",
            @"color" : UIColor.redColor,
            @"title" : @"Cycling",
            @"description" : @"Navigaton type: Bicycle",
            @"type" : kCellTypeTitleDescription,
        }];
    
    TableGroupToImport *quickActionSection = [[TableGroupToImport alloc] init];
    quickActionSection.groupName = @"Quick actions";
    quickActionSection.selectedItems = @"0 of 20";
    quickActionSection.type = kCellTypeSectionHeader;
    quickActionSection.isOpen = NO;
    
    [quickActionSection.groupItems addObject:@{
            @"icon" : @"ic_custom_favorites",
            @"color" : UIColor.orangeColor,
            @"title" : @"Add favorite",
            @"type" : kCellTypeTitle,
    }];
    
    [quickActionSection.groupItems addObject:@{
            @"icon" : @"ic_action_create_poi",
            @"color" : UIColor.orangeColor,
            @"title" : @"Add POI",
            @"type" : kCellTypeTitle,
    }];
    
    [quickActionSection.groupItems addObject:@{
            @"icon" : @"ic_action_create_poi",
            @"color" : UIColor.orangeColor,
            @"title" : @"Change map source",
            @"type" : kCellTypeTitle,
    }];
    
    [quickActionSection.groupItems addObject:@{
            @"icon" : @"ic_custom_overlay_map",
            @"color" : UIColor.orangeColor,
            @"title" : @"Change map overlay",
            @"type" : kCellTypeTitle,
    }];
    
    [data addObject:profilesSection];
    [data addObject:quickActionSection];
    
    _data = [NSMutableArray arrayWithArray:data];
}

- (void) selectDeselectAllItems:(id)sender
{
    if (_selectedItems.count > 0)
        for (NSInteger section = 0; section < [self.tableView numberOfSections]; section++)
            [self deselectAllGroup:[NSIndexPath indexPathForRow:0 inSection:section]];
    else
        for (NSInteger section = 0; section < [self.tableView numberOfSections]; section++)
            [self selectAllGroup:[NSIndexPath indexPathForRow:0 inSection:section]];
    [self updateNavigationBarItem];
}

- (void) openCloseGroupButtonAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
    
    [self openCloseGroup:indexPath];
}

- (void) openCloseGroup:(NSIndexPath *)indexPath
{
    TableGroupToImport* groupData = [_data objectAtIndex:indexPath.section];
    
    if (groupData.isOpen)
    {
        groupData.isOpen = NO;
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
        if ([_selectedItems containsObject: [NSIndexPath indexPathForRow:0 inSection:indexPath.section]])
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        groupData.isOpen = YES;
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
        
        [self selectPreselectedCells:indexPath];
    }
}

#pragma mark - Table View

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    TableGroupToImport* groupData = [_data objectAtIndex:section];

    if (groupData.isOpen)
        return [groupData.groupItems count] + 1;
    return 1;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        UIView *vw = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, tableView.bounds.size.width - OAUtilities.getLeftMargin * 2, _heightForHeader)];
        CGFloat textWidth = self.tableView.bounds.size.width - (kSidePadding + OAUtilities.getLeftMargin) * 2;
        UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(kSidePadding + OAUtilities.getLeftMargin, 6.0, textWidth, _heightForHeader)];
        UIFont *labelFont = [UIFont systemFontOfSize:15.0];
        description.font = labelFont;
        [description setTextColor: UIColorFromRGB(color_text_footer)];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:6];
        description.attributedText = [[NSAttributedString alloc] initWithString:OALocalizedString(@"Import_profile_descr") attributes:@{NSParagraphStyleAttributeName : style}];
        description.numberOfLines = 0;
        [vw addSubview:description];
        return vw;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        _heightForHeader = [self heightForLabel:OALocalizedString(@"Import_profile_descr")];
        return _heightForHeader + kBottomPadding + kTopPadding;
    }
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TableGroupToImport* groupData = [_data objectAtIndex:indexPath.section];
    
    if (indexPath.row == 0)
    {
        static NSString* const identifierCell = @"OAIconTextDescCell";
        OAIconTextDescCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
            cell.arrowIconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.hidden = YES;
            cell.openCloseGroupButton.hidden = NO;
        }
        if (cell)
        {
            cell.textView.text = groupData.groupName;
            cell.descView.text = groupData.selectedItems;
            cell.openCloseGroupButton.tag = indexPath.section << 10 | indexPath.row;
            [cell.openCloseGroupButton addTarget:self action:@selector(openCloseGroupButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            if (groupData.isOpen)
            {
                cell.arrowIconView.image = [[UIImage imageNamed:@"ic_custom_arrow_up"]
                imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            else
            {
                cell.arrowIconView.image = [[UIImage imageNamed:@"ic_custom_arrow_down"]
                imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate].imageFlippedForRightToLeftLayoutDirection;
                if ([cell isDirectionRTL])
                    [cell.arrowIconView setImage:cell.arrowIconView.image.imageFlippedForRightToLeftLayoutDirection];
            }
        }
        return cell;
    }
    else
    {
        NSInteger dataIndex = indexPath.row - 1;
        NSDictionary* item = [groupData.groupItems objectAtIndex:dataIndex];
        NSString *cellType = item[@"type"];
        if ([cellType isEqualToString:kCellTypeTitleDescription])
        {
            static NSString* const identifierCell = @"OAIconTextDescCell";
            OAIconTextDescCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
                cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
                cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
                cell.arrowIconView.hidden = YES;
            }
            if (cell)
            {
                cell.textView.text = item[@"title"];
                cell.descView.text = item[@"description"];
                cell.iconView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.iconView.tintColor = item[@"color"];
            }
            return cell;
        }
        else if ([cellType isEqualToString:kCellTypeTitle])
        {
            
            static NSString* const identifierCell = kCellTypeTitle;
            OAIconTextTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
                cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
                cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
                cell.arrowIconView.hidden = YES;
            }
            if (cell)
            {
                cell.textView.text = item[@"title"];
                cell.iconView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.iconView.tintColor = item[@"color"];
            }
            return cell;
        }
    }
    return nil;
}

#pragma mark - Items selection

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        [self selectAllGroup:indexPath];
    else
        [self selectGroupItem:indexPath];
    [self updateNavigationBarItem];
}

- (void) tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        [self deselectAllGroup:indexPath];
    else
        [self deselectGroupItem:indexPath];
    [self updateNavigationBarItem];
}

- (void) selectAllItemsInGroup:(NSIndexPath *)indexPath selectHeader:(BOOL)selectHeader
{
    NSInteger rowsCount = [self.tableView numberOfRowsInSection:indexPath.section];

    [self.tableView beginUpdates];
    if (selectHeader)
        for (int i = 0; i < rowsCount; i++)
        {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
            [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
        }
    else
        for (int i = 0; i < rowsCount; i++)
        {
            [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section] animated:YES];
        }
    [self.tableView endUpdates];
}

- (void) selectAllGroup:(NSIndexPath *)indexPath
{
    TableGroupToImport* groupData = [_data objectAtIndex:indexPath.section];
    
    if (!groupData.isOpen)
        for (NSInteger i = 0; i <= groupData.groupItems.count; i++)
            [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
    [self selectAllItemsInGroup:indexPath selectHeader:YES];
}

- (void) deselectAllGroup:(NSIndexPath *)indexPath
{
    NSMutableArray *tmp = [[NSMutableArray alloc] initWithArray:_selectedItems];
    for (NSUInteger i = 0; i < tmp.count; i++)
        [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
    [self selectAllItemsInGroup:indexPath selectHeader: NO];
}

- (void) selectGroupItem:(NSIndexPath *)indexPath
{
    if ([self.tableView isEditing])
    {
        BOOL isGroupHeaderSelected = [self.tableView.indexPathsForSelectedRows containsObject:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
        NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
        NSInteger numberOfRowsInSection = [self.tableView numberOfRowsInSection:indexPath.section] - 1;
        NSInteger numberOfSelectedRowsInSection = 0;
        for (NSIndexPath *item in selectedRows)
        {
            if(item.section == indexPath.section)
                numberOfSelectedRowsInSection++;
            [self addIndexPathToSelectedCellsArray:item];
        }
        if (numberOfSelectedRowsInSection == numberOfRowsInSection && !isGroupHeaderSelected)
        {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
            [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
        }
        else
        {
            [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES];
        }
        return;
    }
}

- (void) deselectGroupItem:(NSIndexPath *)indexPath
{
    if ([self.tableView isEditing])
    {
        BOOL isGroupHeaderSelected = [self.tableView.indexPathsForSelectedRows containsObject:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
        NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
        NSInteger numberOfRowsInSection = [self.tableView numberOfRowsInSection:indexPath.section] - 1;
        NSInteger numberOfSelectedRowsInSection = 0;
        for (NSIndexPath *item in selectedRows)
        {
            if(item.section == indexPath.section)
                numberOfSelectedRowsInSection++;
        }
        [self removeIndexPathFromSelectedCellsArray:indexPath];
        
        if (indexPath.row == 0)
        {
            [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES];
        }
        else if (numberOfSelectedRowsInSection == numberOfRowsInSection && isGroupHeaderSelected)
        {
            [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES];
        }
        return;
    }
}

- (void) addIndexPathToSelectedCellsArray:(NSIndexPath *)indexPath
{
    if (![_selectedItems containsObject:indexPath])
         [_selectedItems addObject:indexPath];
}

- (void) removeIndexPathFromSelectedCellsArray:(NSIndexPath *)indexPath
{
    if ([_selectedItems containsObject:indexPath])
        [_selectedItems removeObject:indexPath];
}

- (void) selectPreselectedCells:(NSIndexPath *)indexPath
{
    for (NSIndexPath *itemPath in _selectedItems)
        if (itemPath.section == indexPath.section)
            [self.tableView selectRowAtIndexPath:itemPath animated:YES scrollPosition:UITableViewScrollPositionNone];
}

@end
