//
//  OAAddFavoriteGroupViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 16.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAAddFavoriteGroupViewController.h"
#import "OAColors.h"
#import "OADefaultFavorite.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAFavoritesHelper.h"
#import "OATextInputCell.h"
#import "OAColorsTableViewCell.h"
#import "OsmAndApp.h"

#define kCellTypeInput @"OATextInputCell"
#define kCellTypeColorCollection @"OAColorsTableViewCell"

@interface OAAddFavoriteGroupViewController() <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, OAColorsTableViewCellDelegate>

@end

@implementation OAAddFavoriteGroupViewController
{
    OsmAndAppInstance _app;
    NSArray<NSArray<NSDictionary *> *> *_data;
    NSString *_newGropuName;
    OAFavoriteColor *_selectedColor;
    int _selectedColorIndex;
    NSArray<NSNumber *> *_colors;
}

- (instancetype) init
{
    self = [super initWithNibName:@"OABaseTableViewController" bundle:nil];
    if (self)
    {
        _app = [OsmAndApp instance];
        [self setupColors];
        [self generateData];
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
    self.doneButton.hidden = NO;
    self.doneButton.enabled = NO;
    _newGropuName = @"";
}

- (void) setupColors
{
    _selectedColor = [OADefaultFavorite builtinColors][0];
    _selectedColorIndex = 0;
    
    NSMutableArray *tempColors = [NSMutableArray new];
    for (OAFavoriteColor *favColor in [OADefaultFavorite builtinColors])
    {
        [tempColors addObject:[NSNumber numberWithInt:[OAUtilities colorToNumber:favColor.color]]];
    }
    _colors = [NSArray arrayWithArray:tempColors];
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    [data addObject:@[
        @{
            @"header" : OALocalizedString(@"group_name"),
            @"footer" : @"",
            @"type" : kCellTypeInput,
            @"title" : @""
        }
    ]];
    [data addObject:@[
        @{
            @"header" : OALocalizedString(@"default_color"),
            @"footer" : OALocalizedString(@"default_color_descr"),
            @"type" : kCellTypeColorCollection,
            @"title" : OALocalizedString(@"fav_color"),
            @"value" : _selectedColor.name,
            @"index" : [NSNumber numberWithInt:_selectedColorIndex],
        }
    ]];
    _data = data;
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"fav_add_new_group");
}

- (void)onDoneButtonPressed
{
    [self.delegate onFavoriteGroupAdded:_newGropuName color:_selectedColor.color];
}

#pragma mark - UITableViewDataSource

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    
    if ([cellType isEqualToString:kCellTypeInput])
    {
        static NSString* const identifierCell = @"OATextInputCell";
        OATextInputCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextInputCell" owner:self options:nil];
            cell = (OATextInputCell *)[nib objectAtIndex:0];
            [cell.inputField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
            cell.inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            cell.inputField.placeholder = OALocalizedString(@"fav_enter_group_name");
        }
        cell.inputField.text = item[@"title"];
        cell.inputField.delegate = self;
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypeColorCollection])
    {
        static NSString* const identifierCell = @"OAColorsTableViewCell";
        OAColorsTableViewCell *cell = nil;
        cell = (OAColorsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAColorsTableViewCell" owner:self options:nil];
            cell = (OAColorsTableViewCell *)[nib objectAtIndex:0];
            cell.dataArray = _colors;
            cell.delegate = self;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsZero;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = item[@"value"];
            cell.valueLabel.tintColor = UIColorFromRGB(color_text_footer);
            int selectedIndex = [item[@"index"] intValue];
            cell.currentColor = selectedIndex;
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }
    
    return nil;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _data[section][0][@"header"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return _data[section][0][@"footer"];
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    return YES;
}

- (void) textViewDidChange:(UITextView *)textView
{
    if (textView.text.length == 0 ||
        [self isIncorrectFileName: textView.text] ||
        [textView.text isEqualToString:OALocalizedString(@"favorites")] || [OAFavoritesHelper getGroupByName:textView.text])
    {
        self.doneButton.enabled = NO;
    }
    else
    {
        _newGropuName = textView.text;
        self.doneButton.enabled = YES;
    }
}

- (BOOL) isIncorrectFileName:(NSString *)fileName
{
    NSCharacterSet* illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>:;.,"];
    return [fileName rangeOfCharacterFromSet:illegalFileNameCharacters].length != 0;
}

#pragma mark - OAColorsTableViewCellDelegate

- (void)colorChanged:(NSInteger)tag
{
    _selectedColorIndex = tag;
    _selectedColor = [OADefaultFavorite builtinColors][tag];
    [self generateData];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
}

@end

