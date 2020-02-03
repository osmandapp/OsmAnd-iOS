//
//  OAOnlineTilesEditingViewController.m
//  OsmAnd Maps
//
//  Created by igor on 23.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAOnlineTilesEditingViewController.h"
#import "Localization.h"
#import "OASQLiteTileSource.h"
#import "OATextInputFloatingCell.h"
#import "OAColors.h"
#import "OATimeTableViewCell.h"
#import "OASettingsTableViewCell.h"
#import "OACustomPickerTableViewCell.h"
#import "OATextInputCell.h"
#import "OAOnlineTilesSettingsViewController.h"

#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

#define kNameSection 0
#define kURLSection 1
#define kZoomSection 2
#define kExpireSection 3
#define kMercatorSection 4

#define kCellTypeFloatTextInput @"text_input_Floating_cell"
#define kCellTypeSetting @"settings_cell"
#define kCellTypeZoom @"time_cell"
#define kCellTypePicker @"picker"
#define kCellTypeTextInput @"text_input_cell"

@interface OAOnlineTilesEditingViewController () <UITextViewDelegate, UITextFieldDelegate, MDCMultilineTextInputLayoutDelegate, OACustomPickerTableViewCellDelegate, OAOnlineTilesSettingsViewControllerDelegate>

@end

@implementation OAOnlineTilesEditingViewController
{
    std::shared_ptr<const OsmAnd::IOnlineTileSources::Source> _tileSource;
    
    NSString *_itemName;
    NSString *_itemURL;
    int _minZoom;
    int _maxZoom;
    long _expireTimeMillis;
    BOOL _isEllipticYTile;
    EOASourceFormat _sourceFormat;
    
    NSString *_expireTimeMinutes;
    
    NSDictionary *data;
    NSArray *zoomArray;
    NSArray *sectionHeaderFooterTitles;
    
    //NSMutableArray *_possibleZoomValues;
    NSArray *_possibleZoomValues;
    
    NSIndexPath *pickerIndexPath;
    
    OATextInputFloatingCell *_nameCell;
    OATextInputFloatingCell *_URLCell;
    OATextInputCell *_expireCell;
    
    BOOL _isKeyboardShown;
}
-(void)applyLocalization
{
    _titleView.text = OALocalizedString(@"res_edit_online_map");
    [_saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

-(id) initWithLocalOnlineSourceItem:(OnlineTilesResourceItem *)item
{
    self = [super init];
    if (self) {
        OsmAndAppInstance app = [OsmAndApp instance];

        const auto& resource = app.resourcesManager->getResource(QStringLiteral("online_tiles"));
        if (resource != nullptr)
        {
            const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(resource->metadata)->sources;
            for(const auto& onlineTileSource : onlineTileSources->getCollection())
            {
                if (QString::compare(QString::fromNSString(item.title), onlineTileSource->name) == 0)
                {
                    _tileSource = onlineTileSource;
                }
            }
        }
            
        _itemName = _tileSource->name.toNSString();
        _itemURL = _tileSource->urlToLoad.toNSString();
        _minZoom = _tileSource->minZoom;
        _maxZoom = _tileSource->maxZoom;
        _expireTimeMillis = _tileSource->expirationTimeMillis;
        _isEllipticYTile = _tileSource->ellipticYTile;
        _sourceFormat = EOASourceFormatOnline;
        _expireTimeMinutes = _expireTimeMillis == -1 ? @"" : [NSString stringWithFormat:@"%ld", (_expireTimeMillis / 1000 / 60)];
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [self generateData];
    [self setupView];


    _possibleZoomValues = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", @"13", @"14", @"15", @"16", @"17", @"18", @"19", @"20", @"21", @"22"];

    //    _possibleZoomValues = [NSMutableArray new];
    //    for (int i = 1; i <= 22; i++)
    //        [_possibleZoomValues addObject: @(i)];
    //NSLog (@"The 4th integer is: %ld", [_possibleZoomValues[3] integerValue]);
}

- (void) setupView
{
    _nameCell = [self getInputFloatingCell:data[@"0"][@"title"] tag:100];
    _URLCell = [self getInputFloatingCell:data[@"1"][@"title"] tag:101];
    [self.tableView reloadData];
}

- (void) generateData
{
    NSMutableArray *zoomArr = [NSMutableArray new];
    [zoomArr addObject:@{
                        @"title": OALocalizedString(@"rec_interval_minimum"),
                        @"key" : @"minZoom",
                        @"type" : kCellTypeZoom,
                         }];
    [zoomArr addObject:@{
                        @"title": OALocalizedString(@"shared_string_maximum"),
                        @"key" : @"maxZoom",
                        @"type" : kCellTypeZoom,
                         }];
    [zoomArr addObject:@{
                        @"type" : kCellTypePicker,
                         }];
    zoomArray = [NSArray arrayWithArray: zoomArr];

    NSMutableDictionary *tableData = [NSMutableDictionary new];
    [tableData setObject:@{
                        @"title" : _itemName,
                        @"type" : kCellTypeFloatTextInput,
                    }
                  forKey:@"0"];
    [tableData setObject:@{
                        @"title" : _itemURL,
                        @"type" : kCellTypeFloatTextInput,
                    }
                  forKey:@"1"];
    [tableData setObject: zoomArr
                  forKey:@"2"];
    [tableData setObject:@{
                        @"placeholder" : OALocalizedString(@"shared_string_not_set"),
                        @"type" : kCellTypeTextInput,
                    }
                  forKey:@"3"];
    [tableData setObject:@{
                        @"title": OALocalizedString(@"res_mercator"),
                        @"type" : kCellTypeSetting,
                    }
                  forKey:@"4"];
    data = [NSDictionary dictionaryWithDictionary:tableData];

    NSMutableArray *sectionArr = [NSMutableArray new];
    [sectionArr addObject:@{
                        @"header" : OALocalizedString(@"fav_name"),
                        @"footer" : OALocalizedString(@"res_online_name_descr")
                        }];
    [sectionArr addObject:@{
                        @"header" : OALocalizedString(@"res_url"),
                        @"footer" : OALocalizedString(@"res_online_url_descr")
                        }];
    [sectionArr addObject:@{
                        @"header" : OALocalizedString(@"res_zoom_levels"),
                        @"footer" : OALocalizedString(@"res_zoom_levels_desc")
                        }];
    [sectionArr addObject:@{
                        @"header" : OALocalizedString(@"res_expire_time"),
                        @"footer" : OALocalizedString(@"res_expire_time_desc")
                        }];
    [sectionArr addObject:@{
                        @"header" : @"",
                        @"footer" : @""
                        }];
    sectionHeaderFooterTitles = [NSArray arrayWithArray:sectionArr];
}

- (OATextInputFloatingCell *)getInputFloatingCell:(NSString *)text tag:(NSInteger)tag
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextInputFloatingCell" owner:self options:nil];
    OATextInputFloatingCell *resultCell = (OATextInputFloatingCell *)[nib objectAtIndex:0];
    
    MDCMultilineTextField *textField = resultCell.inputField;
    [textField.underline removeFromSuperview];
    [textField.textView setText:text];
    textField.textView.delegate = self;
    textField.layoutDelegate = self;
    textField.textView.tag = tag;
    textField.clearButton.tag = tag;
    [textField.clearButton addTarget:self action:@selector(clearButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    textField.font = [UIFont systemFontOfSize:17.0];
    textField.clearButton.imageView.tintColor = UIColorFromRGB(color_icon_color);
    [textField.clearButton setImage:[[UIImage imageNamed:@"ic_custom_clear_field"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [textField.clearButton setImage:[[UIImage imageNamed:@"ic_custom_clear_field"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateHighlighted];
    return resultCell;
}

- (IBAction)saveButtonPressed:(UIButton *)sender
{
    NSString *exp = _isEllipticYTile ? @"YES" : @"NO";
    NSLog(@"\nname = %@\nURL = %@\nminZoom = %d\nmaxZoom = %d\nexpireTime = %@\nisElliptic = %@\n", _itemName, _itemURL, _minZoom, _maxZoom, _expireTimeMinutes, exp);
    //NSLog(@"%ld", LONG_MAX);
        
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([_expireTimeMinutes rangeOfCharacterFromSet:notDigits].location == NSNotFound
        && [_expireTimeMinutes integerValue] <= 153722867280912
        && [_expireTimeMinutes integerValue] > 0) // >= 0 ???
    {
        _expireTimeMillis = [_expireTimeMinutes integerValue] * 60 * 1000;
        NSLog(@"%ld", _expireTimeMillis);
    }
    else
        NSLog(@"%@", @"ERROR");
    //_tileSource->name = _itemName;
    
}

- (IBAction)backButtonPressed:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)pickerIsShown
{
    return pickerIndexPath != nil;
}

- (void)hideExistingPicker {
    
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:pickerIndexPath.row inSection:pickerIndexPath.section]]
                          withRowAnimation:UITableViewRowAnimationFade];
    pickerIndexPath = nil;
}

- (NSIndexPath *)calculateIndexPathForNewPicker:(NSIndexPath *)selectedIndexPath {
    NSIndexPath *newIndexPath;
    if (([self pickerIsShown]) && (pickerIndexPath.row < selectedIndexPath.row))
        newIndexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row - 1 inSection:kZoomSection];
    else
        newIndexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row  inSection:kZoomSection];
    
    return newIndexPath;
}

- (void)showNewPickerAtIndex:(NSIndexPath *)indexPath {
    
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:kZoomSection]];
    
    [self.tableView insertRowsAtIndexPaths:indexPaths
                          withRowAnimation:UITableViewRowAnimationFade];
}

-(NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    NSString* section = [NSString stringWithFormat:@"%ld", indexPath.section];
    if (indexPath.section != kZoomSection)
        return data[section];
    else
    {
        NSArray *ar = data[section];
        if ([self pickerIsShown])
        {
            if ([indexPath isEqual:pickerIndexPath])
                return ar[2];
            else if (indexPath.row == 0)
                return ar[0];
            else
                return ar[1];
        }
        else
        {
            if (indexPath.row == 0)
                return ar[0];
            else if (indexPath.row == 1)
                return ar[1];
        }
    }
    return [NSDictionary new];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item =  [self getItem:indexPath];
    
    if ([item[@"type"] isEqualToString:kCellTypeFloatTextInput] && indexPath.section == kNameSection)
    {
        return _nameCell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeFloatTextInput] && indexPath.section == kURLSection)
    {
        return _URLCell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeTextInput])
    {
        static NSString* const identifierCell = @"OATextInputCell";
        OATextInputCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextInputCell" owner:self options:nil];
            cell = (OATextInputCell *)[nib objectAtIndex:0];
        }
        cell.inputField.text = _expireTimeMinutes;
        cell.inputField.placeholder = item[@"placeholder"];
        cell.inputField.delegate = self;
        cell.userInteractionEnabled = YES;
        cell.inputField.keyboardType = UIKeyboardTypeNumberPad;
        
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeSetting])
    {
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }

        if (cell) {
            [cell.textView setText:item[@"title"]];
            cell.descriptionView.text = _isEllipticYTile ? OALocalizedString(@"res_elliptic_mercator") : OALocalizedString(@"res_pseudo_mercator");
        }
        return cell;
    }

    else if ([item[@"type"] isEqualToString:kCellTypeZoom])
    {
        static NSString* const identifierCell = @"OATimeTableViewCell";
        OATimeTableViewCell* cell;
        cell = (OATimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATimeCell" owner:self options:nil];
            cell = (OATimeTableViewCell *)[nib objectAtIndex:0];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.lbTitle.text = item[@"title"];
        if ([item[@"key"] isEqualToString:@"minZoom"])
            cell.lbTime.text = [@(_minZoom) stringValue];
        else if ([item[@"key"] isEqualToString:@"maxZoom"])
            cell.lbTime.text = [@(_maxZoom) stringValue];
        else
            cell.lbTime.text = @"";
        cell.lbTime.textColor = [UIColor blackColor];

        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypePicker])
    {
        static NSString* const identifierCell = @"OACustomPickerTableViewCell";
        OACustomPickerTableViewCell* cell;
        cell = (OACustomPickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OACustomPickerCell" owner:self options:nil];
            cell = (OACustomPickerTableViewCell *)[nib objectAtIndex:0];
        }
        cell.dataArray = _possibleZoomValues;
        [cell.picker selectRow:indexPath.row == 1 ? _minZoom - 1 : _maxZoom - 1 inComponent:0 animated:NO];
        cell.picker.tag = indexPath.row;
        cell.delegate = self;
        return cell;
    }
    else
        return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *data =  [self getItem:indexPath];
    if ([data[@"type"] isEqualToString:kCellTypeZoom])
    {
        [self.tableView beginUpdates];

        if ([self pickerIsShown] && (pickerIndexPath.row - 1 == indexPath.row))
            [self hideExistingPicker];
        else
        {
            NSIndexPath *newPickerIndexPath = [self calculateIndexPathForNewPicker:indexPath];
            if ([self pickerIsShown])
                [self hideExistingPicker];

            [self showNewPickerAtIndex:newPickerIndexPath];
            pickerIndexPath = [NSIndexPath indexPathForRow:newPickerIndexPath.row + 1 inSection:indexPath.section];
        }

        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.tableView endUpdates];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if ([data[@"type"] isEqualToString:kCellTypeSetting])
    {
        OAOnlineTilesSettingsViewController *settingsViewController = [[OAOnlineTilesSettingsViewController alloc] initWithEllipticYTile:_isEllipticYTile];
        settingsViewController.delegate = self;
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kZoomSection)
    {
        if ([self pickerIsShown])
            return 3;
        return 2;
    }
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return sectionHeaderFooterTitles[section][@"header"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return sectionHeaderFooterTitles[section][@"footer"];
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//
//}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if (indexPath.section != kZoomSection)
    {
        if ([item[@"type"] isEqualToString:kCellTypeSetting])
            return [OASettingsTableViewCell getHeight:item[@"title"] value:item[@"value"] cellWidth:self.tableView.bounds.size.width];
        else if ([item[@"type"] isEqualToString:kCellTypeFloatTextInput] && indexPath.section == kNameSection)
        {
            return MAX(_nameCell.inputField.intrinsicContentSize.height, 44.0);
        }
        else if ([item[@"type"] isEqualToString:kCellTypeFloatTextInput] && indexPath.section == kURLSection)
        {
            return MAX(_URLCell.inputField.intrinsicContentSize.height, 44.0);
        }
        else if ([item[@"type"] isEqualToString:kCellTypeTextInput] && indexPath.section == kExpireSection)
        {
            return 44.0;
        }
    }
    else
    {
        if ([indexPath isEqual:pickerIndexPath])
            return 162.0;
        else
            return 44.0;
    }
}

#pragma mark - UITextViewDelegate

-(void)textViewDidChange:(UITextView *)textView
{
    if (textView.tag == 100)
    {
        _itemName = textView.text;
    }
    else if (textView.tag == 101)
    {
        _itemURL = textView.text;
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    _expireTimeMinutes = textField.text;
}

#pragma mark - MDCMultilineTextInputLayoutDelegate
- (void)multilineTextField:(id<MDCMultilineTextInput> _Nonnull)multilineTextField
      didChangeContentSize:(CGSize)size
{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

#pragma mark - OACustomPickerTableViewCellDelegate

- (void)zoomChanged:(NSString *)zoom tag: (NSInteger)pickerTag
{
    if (pickerTag == 1)
    {
        _minZoom = [zoom intValue];
    }
    else if (pickerTag == 2)
    {
        _maxZoom = [zoom intValue];
    }
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:pickerIndexPath.row - 1 inSection:pickerIndexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
}


#pragma mark - OAOnlineTilesSettingsViewControllerDelegate

- (void) onMercatorChanged:(BOOL)isEllipticYTile
{
    _isEllipticYTile = isEllipticYTile;
    [_tableView reloadData];
}

- (void) onStorageFormatChanged:(EOASourceFormat)sourceFormat
{
    _sourceFormat = sourceFormat;
    [_tableView reloadData];
}

#pragma mark - Keyboard Notifications

- (void) keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [_tableView contentInset];
    NSValue* keyboardFrameBegin = [userInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    CGFloat keyboardHeight = keyboardFrameBeginRect.size.height;
    if (!_isKeyboardShown) {
        [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
            [_tableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardHeight, insets.right)];
        } completion:nil];
    }
    _isKeyboardShown = YES;
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [_tableView contentInset];
    if (_isKeyboardShown)
    {
        [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
            [_tableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0., insets.right)];
            [self.view layoutIfNeeded];
        } completion:nil];
    }
    _isKeyboardShown = NO;
}

-(void) clearButtonPressed:(UIButton *)sender
{
    if (sender.tag == 100)
    {
        _itemName = @"";
    }
    else if (sender.tag == 101)
    {
        _itemURL = @"";
    }
}

@end

