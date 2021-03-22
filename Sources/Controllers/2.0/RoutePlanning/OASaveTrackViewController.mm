//
//  OASaveTrackViewController.mm
//  OsmAnd
//
//  Created by Anna Bibyk on 14.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASaveTrackViewController.h"
#import "OARootViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OATextViewResizingCell.h"
#import "OASwitchTableViewCell.h"
#import "OASaveTrackBottomSheetViewController.h"
#import "OAGPXDatabase.h"
#import "OAMapLayers.h"
#import "OAMapRendererView.h"
#import "OASettingsTableViewCell.h"
#import "OAFolderCardsCell.h"
#import "OASelectTrackFolderViewController.h"
#import "OAAddTrackFolderViewController.h"

#define kTextInputCell @"OATextViewResizingCell"
#define kRouteGroupsCell @""
#define kSwitchCell @"OASwitchTableViewCell"
#define kCellTypeTitle @"OASettingsCell"
#define kFolderCardsCell @"OAFolderCardsCell"

@interface OASaveTrackViewController() <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, OASelectTrackFolderDelegate, OAFolderCardsCellDelegate, OAAddTrackFolderDelegate>

@end

@implementation OASaveTrackViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
    OAAppSettings *_settings;
    
    NSString *_fileName;
    NSString *_sourceFileName;
    NSString *_filePath;
    NSString *_selectedFolderName;
    NSArray<NSString *> *_allFolders;
    BOOL _showSimplifiedButton;
    BOOL _rightButtonEnabled;
    
    BOOL _simplifiedTrack;
    BOOL _showOnMap;
    
    NSString *_inputFieldError;
    int _selectedFolderIndex;
}

- (instancetype) initWithFileName:(NSString *)fileName filePath:(NSString *)filePath showOnMap:(BOOL)showOnMap simplifiedTrack:(BOOL)simplifiedTrack
{
    self = [super init];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
        _fileName = fileName;
        _sourceFileName = fileName;
        _showSimplifiedButton = simplifiedTrack;
        _showOnMap = showOnMap;
        
        _rightButtonEnabled = YES;
        _simplifiedTrack = NO;
        
        [self commonInit];
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.cancelButton.layer.cornerRadius = 9.0;
    self.saveButton.layer.cornerRadius = 9.0;
    
    [self updateBottomButtons];
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"save_new_track");
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

- (NSString *) getDisplayingFolderName:(NSString *)filePath
{
    NSString *folderName = [filePath stringByDeletingLastPathComponent];
    if (folderName.length == 0)
        return OALocalizedString(@"tracks");
    else
        return folderName;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void) commonInit
{
    [self updateAllFoldersList];
    _selectedFolderName = [self getDisplayingFolderName:_filePath];
    _selectedFolderIndex = (int)[_allFolders indexOfObject:_selectedFolderName];
    [self generateData];
}

- (void) updateAllFoldersList
{
    _allFolders = [OAUtilities getGpxFoldersListSorted:YES shouldAddTracksFolder:YES];
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    
    [data addObject:@[
        @{
            @"type" : kTextInputCell,
            @"fileName" : _fileName,
            @"header" : OALocalizedString(@"fav_name"),
            @"key" : @"input_name",
        }
    ]];
    
    [data addObject:@[
        @{
            @"type" : kCellTypeTitle,
            @"header" : OALocalizedString(@"plan_route_folder"),
            @"title" : @"Select folder",
            @"value" : _selectedFolderName,
        },
        @{
            @"type" : @"OAFolderCardsCell",
            @"selectedValue" : [NSNumber numberWithInt:_selectedFolderIndex],
            @"values" : _allFolders,
            @"addButtonTitle" : OALocalizedString(@"add_folder")
        },
    ]];

    if (_showSimplifiedButton)
    {
        [data addObject:@[
            @{
                @"type" : kSwitchCell,
                @"title" : OALocalizedString(@"simplified_track"),
                @"key" : @"simplified_track",
                @"footer" : OALocalizedString(@"simplified_track_description")
            }
        ]];
    }
    
    [data addObject:@[
        @{
            @"type" : kSwitchCell,
            @"title" : OALocalizedString(@"map_settings_show"),
            @"key" : @"map_settings_show"
        }
    ]];
    
    _data = data;
}

- (void) updateBottomButtons
{
    self.saveButton.userInteractionEnabled = _rightButtonEnabled;
    [self.saveButton setBackgroundColor:_rightButtonEnabled ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_icon_inactive)];
}

- (BOOL) cellValueByKey:(NSString *)key
{
    if ([key isEqualToString:@"simplified_track"])
        return _simplifiedTrack;
    if ([key isEqualToString:@"map_settings_show"])
        return _showOnMap;
    return NO;
}

- (void) showSelectFolderScreen
{
    OASelectTrackFolderViewController *selectFolderView = [[OASelectTrackFolderViewController alloc] initWithSelectedFolderName:_selectedFolderName];
    selectFolderView.delegate = self;
    [self presentViewController:selectFolderView animated:YES completion:nil];
}

- (void) showAddFolderScreen
{
    OAAddTrackFolderViewController * addFolderVC = [[OAAddTrackFolderViewController alloc] init];
    addFolderVC.delegate = self;
    [self presentViewController:addFolderVC animated:YES completion:nil];
}

- (void) showEmptyNameAlert
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"empty_filename") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Actions

- (IBAction)cancelButtonPressed:(id)sender
{
    [self dismissViewController];
}

- (IBAction)saveButtonPressed:(id)sender
{
    if (_fileName.length == 0)
    {
        [self showEmptyNameAlert];
    }
    else
    {        
        [self dismissViewControllerAnimated:NO completion:nil];
        NSString *savingPath;
        if ([_selectedFolderName isEqualToString:OALocalizedString(@"tracks")])
            savingPath = _fileName;
        else
            savingPath = [_selectedFolderName stringByAppendingPathComponent:_fileName];
        
        if (self.delegate)
            [self.delegate onSaveAsNewTrack:savingPath showOnMap:_showOnMap simplifiedTrack:_simplifiedTrack];
    }
}

#pragma mark - UITableViewDataSource

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:kTextInputCell])
    {
        OATextViewResizingCell* cell = [tableView dequeueReusableCellWithIdentifier:kTextInputCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kTextInputCell owner:self options:nil];
            cell = (OATextViewResizingCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        if (cell)
        {
            cell.inputField.text = item[@"fileName"];
            cell.inputField.delegate = self;
            cell.inputField.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
            cell.clearButton.tag = cell.inputField.tag;
            [cell.clearButton removeTarget:NULL action:NULL forControlEvents:UIControlEventTouchUpInside];
            [cell.clearButton addTarget:self action:@selector(clearButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        return cell;
    }
    else if ([cellType isEqualToString:kSwitchCell])
    {
        OASwitchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kSwitchCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            NSString *itemKey = item[@"key"];
            BOOL value = [self cellValueByKey:itemKey];
            cell.switchView.on = value;
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypeTitle])
    {
        static NSString* const identifierCell = kCellTypeTitle;
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
            cell.descriptionView.font = [UIFont systemFontOfSize:17.0];
            cell.descriptionView.numberOfLines = 1;
            cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate].imageFlippedForRightToLeftLayoutDirection;
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., 0, 0, CGFLOAT_MAX);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
        }
        return cell;
    }
    else if ([cellType isEqualToString:kFolderCardsCell])
    {
        static NSString* const identifierCell = kFolderCardsCell;
        OAFolderCardsCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAFolderCardsCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.delegate = self;
            [cell setValues:item[@"values"] sizes:nil colors:nil addButtonTitle:item[@"addButtonTitle"] withSelectedIndex:(int)[item[@"selectedValue"] intValue]];
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

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *) view;
        headerView.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *) view;
        headerView.textLabel.textColor = _inputFieldError != nil && section == 0 ? UIColorFromRGB(color_primary_red) : UIColorFromRGB(color_text_footer);
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *item = _data[section].firstObject;
    
    return item[@"header"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0)
        return _inputFieldError;
    NSDictionary *item = _data[section].firstObject;
    
    return item[@"footer"];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:kCellTypeTitle])
    {
        [self showSelectFolderScreen];
    }
}

-(void) clearButtonPressed:(UIButton *)sender
{
    _fileName = @"";
    
    UIButton *btn = (UIButton *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:btn.tag & 0x3FF inSection:btn.tag >> 10];
    
    [_tableView beginUpdates];
    UITableViewCell *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section]];
    if ([cell isKindOfClass:OATextViewResizingCell.class])
        ((OATextViewResizingCell *) cell).inputField.text = @"";
    [_tableView endUpdates];
}

- (void) applyParameter:(id)sender
{
    UISwitch *sw = (UISwitch *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    if ([key isEqualToString:@"simplified_track"])
    {
        _simplifiedTrack = !_simplifiedTrack;
        [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    if ([key isEqualToString:@"map_settings_show"])
    {
        _showOnMap = !_showOnMap;
        [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - UITextViewDelegate

- (void) textViewDidChange:(UITextView *)textView
{
    [self updateFileNameFromEditText:textView.text];
    
    [textView sizeToFit];
    [self.tableView beginUpdates];
    UITableViewHeaderFooterView *footer = [self.tableView footerViewForSection:0];
    footer.textLabel.textColor = _inputFieldError != nil ? UIColorFromRGB(color_primary_red) : UIColorFromRGB(color_text_footer);
    footer.textLabel.text = _inputFieldError;
    [footer sizeToFit];
    [self.tableView endUpdates];
}

- (void) updateFileNameFromEditText:(NSString *)name
{
    _rightButtonEnabled = NO;
    NSString *text = name.trim;
    if (text.length == 0)
    {
        _inputFieldError = OALocalizedString(@"empty_filename");
    }
    else if ([self isFileExist:name])
    {
        _inputFieldError = OALocalizedString(@"gpx_already_exsists");
    }
    else
    {
        _inputFieldError = nil;
        _fileName = text;
        _rightButtonEnabled = YES;
    }
    [self updateBottomButtons];
}

- (BOOL) isFileExist:(NSString *)name
{
    NSString *filePath = [[OsmAndApp.instance.gpxPath stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"gpx"];
    return [NSFileManager.defaultManager fileExistsAtPath:filePath];
}

#pragma mark - Keyboard Notifications

- (CGFloat)getModalPresentationOffset:(BOOL)keyboardShown
{
    CGFloat modalOffset = 0;
    if (@available(iOS 13.0, *)) {
        // accounts for additional top offset in modal presentation 
        modalOffset = keyboardShown ? 6. : 10.;
    }
    return modalOffset;
}

- (void) keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGRect keyboardBounds;
    [[userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        self.view.frame = CGRectMake(0., 0., self.view.frame.size.width, DeviceScreenHeight - OAUtilities.getStatusBarHeight - keyboardBounds.size.height - [self getModalPresentationOffset:YES]);
    } completion:nil];
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        self.view.frame = CGRectMake(0., 0., self.view.frame.size.width, DeviceScreenHeight - OAUtilities.getStatusBarHeight - [self getModalPresentationOffset:NO]);
    } completion:nil];
}

#pragma mark - OASelectTrackFolderDelegate

- (void) onFolderSelected:(NSString *)selectedFolderName
{
    _selectedFolderName = selectedFolderName;
    _selectedFolderIndex = [_allFolders indexOfObject:selectedFolderName];
    [self generateData];
    [self.tableView reloadData];
}

- (void) onNewFolderAdded
{
    [self updateAllFoldersList];
    _selectedFolderIndex = [_allFolders indexOfObject:_selectedFolderName];
    [self generateData];
    [self.tableView reloadData];
}

#pragma mark - OAAddTrackFolderDelegate

- (void) onTrackFolderAdded:(NSString *)folderName
{
    NSString *newFolderPath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:folderName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:newFolderPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:newFolderPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    [self onNewFolderAdded];
}

#pragma mark - OAFolderCardsCellDelegate

- (void) onItemSelected:(int)index
{
    _selectedFolderIndex = index;
    _selectedFolderName = _allFolders[index];
    [self generateData];
    [self.tableView reloadData];
}

- (void) onAddFolderButtonPressed
{
    [self showAddFolderScreen];
}

@end
