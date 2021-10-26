//
//  OAEditWaypointsGroupOptionsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 21.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAEditWaypointsGroupOptionsViewController.h"
#import "OABaseTrackMenuHudViewController.h"
#import "OATextInputCell.h"
#import "OAColorsTableViewCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OADefaultFavorite.h"
#import "OAFavoritesHelper.h"

@interface OAEditWaypointsGroupOptionsViewController() <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, OAColorsTableViewCellDelegate>

@end

@implementation OAEditWaypointsGroupOptionsViewController
{
    EOAEditWaypointsGroupScreen _screenType;
    NSString *_groupName;
    NSString *_newGroupName;

    UIColor *_groupColor;
    OAFavoriteColor *_selectedColor;
    NSArray<NSNumber *> *_colors;

    NSArray<OAGPXTableSectionData *> *_tableData;
}

- (instancetype)init
{
    self = [super initWithNibName:@"OABaseTableViewController" bundle:nil];
    return self;
}

- (instancetype)initWithScreenType:(EOAEditWaypointsGroupScreen)screenType
                         groupName:(NSString *)groupName
                         groupColor:(UIColor *)groupColor
{
    self = [super init];
    if (self)
    {
        _screenType = screenType;
        _groupName = groupName;
        _groupColor = groupColor;
        [self commonInit];
        [self generateData];
    }
    return self;
}

- (void)commonInit
{
    if (_groupColor)
    {
        _selectedColor = [OADefaultFavorite getFavoriteColor:_groupColor];
        NSMutableArray<NSNumber *> *tempColors = [NSMutableArray new];
        for (OAFavoriteColor *favColor in [OADefaultFavorite builtinColors])
        {
            [tempColors addObject:@([OAUtilities colorToNumber:favColor.color])];
        }
        _colors = tempColors;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
    self.doneButton.hidden = NO;
    self.doneButton.enabled = NO;
    _newGroupName = @"";
}

- (void)applyLocalization
{
    [super applyLocalization];
    if (_screenType == EOAEditWaypointsGroupRenameScreen)
    {
        self.titleLabel.text = OALocalizedString(@"fav_rename");
    }
    else if (_screenType == EOAEditWaypointsGroupColorScreen)
    {
        self.titleLabel.text = OALocalizedString(@"select_color");
    }
}

- (void)generateData
{
    OAGPXTableSectionData *sectionData;
    OAGPXTableCellData *cellData;

    if (_screenType == EOAEditWaypointsGroupRenameScreen)
    {
        cellData = [OAGPXTableCellData withData:@{
                kCellKey: @"new_name",
                kCellType: [OATextInputCell getCellIdentifier],
                kCellTitle: _groupName,
                kCellDesc: OALocalizedString(@"fav_enter_group_name")
        }];

        sectionData = [OAGPXTableSectionData withData:@{
                kSectionCells: @[cellData],
                kSectionHeader: OALocalizedString(@"fav_name")
        }];
    }
    else if (_screenType == EOAEditWaypointsGroupColorScreen)
    {
        cellData = [OAGPXTableCellData withData:@{
                kCellKey: @"color_grid",
                kCellType: [OAColorsTableViewCell getCellIdentifier],
                kTableValues: @{
                        @"int_value": @([OAUtilities colorToNumber:_selectedColor.color]),
                        @"array_value": _colors
                },
                kCellTitle: OALocalizedString(@"fav_color"),
                kCellDesc: _selectedColor.name
        }];

        [cellData setData:@{
                kTableUpdateData: ^() {
                    [cellData setData:@{
                            kTableValues: @{
                                    @"int_value": @([OAUtilities colorToNumber:_selectedColor.color]),
                                    @"array_value": _colors
                            },
                            kCellDesc: _selectedColor.name
                    }];
                }
        }];

        sectionData = [OAGPXTableSectionData withData:@{
                kSectionCells: @[cellData],
                kSectionHeader: OALocalizedString(@"default_color"),
                kSectionFooter: OALocalizedString(@"default_color_descr")
        }];
    }

    [sectionData setData:@{
            kTableUpdateData: ^() {
                for (OAGPXTableCellData *cell in sectionData.cells)
                {
                    if (cell.updateData)
                        cell.updateData();
                }
            }
    }];

    _tableData = @[sectionData];
}

- (OAGPXTableCellData *)getCellData:(NSIndexPath *)indexPath
{
    return _tableData[indexPath.section].cells[indexPath.row];
}

- (void)onDoneButtonPressed
{
    if (self.delegate)
    {
        if (_screenType == EOAEditWaypointsGroupRenameScreen)
        {
            [self.delegate updateWaypointsGroup:_newGroupName groupColor:nil];
        }
        else if (_screenType == EOAEditWaypointsGroupColorScreen)
        {
            [self.delegate updateWaypointsGroup:nil groupColor:_selectedColor.color];
        }
    }
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _tableData[section].header;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return _tableData[section].footer;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    UITableViewCell *outCell = nil;
    if ([cellData.type isEqualToString:[OATextInputCell getCellIdentifier]])
    {
        OATextInputCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextInputCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextInputCell getCellIdentifier] owner:self options:nil];
            cell = (OATextInputCell *) nib[0];
            [cell.inputField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
            cell.inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            cell.inputField.placeholder = cellData.desc;
        }
        if (cell)
        {
            cell.inputField.text = cellData.title;
            cell.inputField.delegate = self;
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OAColorsTableViewCell getCellIdentifier]])
    {
        NSArray<NSNumber *> *arrayValue = cellData.values[@"array_value"];
        OAColorsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAColorsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAColorsTableViewCell getCellIdentifier]
                                                         owner:self
                                                       options:nil];
            cell = (OAColorsTableViewCell *) nib[0];
            cell.dataArray = arrayValue;
            cell.delegate = self;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsZero;
            [cell showLabels:YES];
        }
        if (cell)
        {
            cell.titleLabel.text = cellData.title;
            cell.valueLabel.text = cellData.desc;
            cell.valueLabel.tintColor = UIColorFromRGB(color_text_footer);
            cell.currentColor = [arrayValue indexOfObject:cellData.values[@"int_value"]];

            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (textView.text.length == 0 ||
            [self isIncorrectFileName:textView.text] ||
            [OAFavoritesHelper getGroupByName:textView.text] ||
            [textView.text isEqualToString:OALocalizedString(@"favorites")] ||
            [textView.text isEqualToString:OALocalizedString(@"personal_category_name")] ||
            [textView.text isEqualToString:kPersonalCategory] ||
            [textView.text isEqualToString:_groupName])
    {
        self.doneButton.enabled = NO;
    }
    else
    {
        _newGroupName = textView.text;
        self.doneButton.enabled = YES;
    }
}

- (BOOL) isIncorrectFileName:(NSString *)fileName
{
    NSCharacterSet *illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>:;.,"];
    return [fileName rangeOfCharacterFromSet:illegalFileNameCharacters].length != 0;
}

#pragma mark - OAColorsTableViewCellDelegate

- (void)colorChanged:(NSInteger)tag
{
    _selectedColor = [OADefaultFavorite builtinColors][tag];
    self.doneButton.enabled = ![_selectedColor.color isEqual:_groupColor];

    _tableData[0].updateData();
    [UIView setAnimationsEnabled:NO];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                          withRowAnimation:UITableViewRowAnimationNone];
    [UIView setAnimationsEnabled:YES];
}

@end
