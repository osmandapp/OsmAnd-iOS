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
#import "OAResourcesBaseViewController.h"
#import "OAManageResourcesViewController.h"

#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

#define kNameSection 0
#define kURLSection 1
#define kZoomSection 2
#define kExpireSection 3

#define kNameCellTag 100
#define kURLCellTag 101

#define kMaxExpireMin 10000000

#define kCellTypeFloatTextInput @"text_input_floating_cell"
#define kCellTypeSetting @"settings_cell"
#define kCellTypeZoom @"time_cell"
#define kCellTypePicker @"picker"
#define kCellTypeTextInput @"text_input_cell"

@interface OAOnlineTilesEditingViewController () <UITextViewDelegate, UITextFieldDelegate, MDCMultilineTextInputLayoutDelegate, OACustomPickerTableViewCellDelegate, OAOnlineTilesSettingsViewControllerDelegate>

@end

@implementation OAOnlineTilesEditingViewController
{
    std::shared_ptr<const OsmAnd::IOnlineTileSources::Source> _tileSource;
    OsmAndAppInstance _app;
    OnlineTilesResourceItem *_item;
    OAResourcesBaseViewController *_baseController;
    
    NSString *_itemName;
    NSString *_itemURL;
    int _minZoom;
    int _maxZoom;
    long _expireTimeMillis;
    BOOL _isEllipticYTile;
    EOASourceFormat _sourceFormat;
    
    NSString *_expireTimeMinutes;
    
    NSArray *_data;
    NSArray<NSDictionary *> *_zoomArray;
    NSArray<NSDictionary *> *_sectionHeaderFooterTitles;
    
    NSArray<NSString *> *_possibleZoomValues;
    NSIndexPath *_pickerIndexPath;
    
    OATextInputFloatingCell *_nameCell;
    OATextInputFloatingCell *_URLCell;
    
    BOOL _isKeyboardShown;
}
-(void)applyLocalization
{
    _titleView.text = OALocalizedString(@"res_edit_online_map");
    [_saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

-(id) initWithLocalOnlineSourceItem:(OnlineTilesResourceItem *)item baseController: (OAResourcesBaseViewController *)baseController
{
    self = [super init];
    if (self) {
        _item = item;
        _app = [OsmAndApp instance];
        _baseController = baseController;
        
        const auto& resource = _app.resourcesManager->getResource(QStringLiteral("online_tiles"));
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

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
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
}

- (void) setupView
{
    [self applySafeAreaMargins];
    
    _nameCell = [self getInputFloatingCell:[_data objectAtIndex:0][@"title"] tag:kNameCellTag];
    _URLCell = [self getInputFloatingCell:[_data objectAtIndex:1][@"title"] tag:kURLCellTag];
    
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
    _zoomArray = [NSArray arrayWithArray: zoomArr];
    
    NSMutableArray *tableData = [NSMutableArray new];
    [tableData addObject:@{
                        @"title" : _itemName,
                        @"type" : kCellTypeFloatTextInput,
                    }];
    [tableData addObject:@{
                        @"title" : _itemURL,
                        @"type" : kCellTypeFloatTextInput,
                    }];
    [tableData addObject: zoomArr];
    [tableData addObject:@{
                        @"placeholder" : OALocalizedString(@"shared_string_not_set"),
                        @"type" : kCellTypeTextInput,
                    }];
    [tableData addObject:@{
                        @"title": OALocalizedString(@"res_mercator"),
                        @"type" : kCellTypeSetting,
                    }];
    _data = [NSArray arrayWithArray:tableData];

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
    _sectionHeaderFooterTitles = [NSArray arrayWithArray:sectionArr];
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

-(std::shared_ptr<OsmAnd::IOnlineTileSources::Source>) createEditedTileSource
{
    const auto result = std::shared_ptr<OsmAnd::IOnlineTileSources::Source>(new OsmAnd::OnlineTileSources::Source(QString::fromNSString(_itemName)));

    result->urlToLoad = QString::fromNSString(_itemURL);
    result->minZoom = OsmAnd::ZoomLevel(_minZoom);
    result->maxZoom = OsmAnd::ZoomLevel(_maxZoom);
    result->expirationTimeMillis = _expireTimeMillis;
    result->ellipticYTile = _isEllipticYTile;
    
    result->priority = _tileSource->priority;
    result->tileSize = _tileSource->tileSize;
    result->ext = _tileSource->ext;
    result->avgSize = _tileSource->avgSize;
    result->bitDensity = _tileSource->bitDensity;
    result->invertedYTile = _tileSource->invertedYTile;
    result->randoms = _tileSource->randoms;
    result->randomsArray = _tileSource->randomsArray;
    result->rule = _tileSource->rule;
    
    return result;
}

- (IBAction)saveButtonPressed:(UIButton *)sender
{
    NSMutableArray *errorArray = [NSMutableArray new];
    
    if ([_itemName isEqualToString:(@"")])
        [errorArray addObject:[@"- " stringByAppendingString:OALocalizedString(@"res_name_warning")]];
    
    if ([_itemURL isEqualToString:(@"")])
        [errorArray addObject:[@"- " stringByAppendingString:OALocalizedString(@"res_url_warning")]];
    
    if (_minZoom >= _maxZoom)
        [errorArray addObject:[@"- " stringByAppendingString:OALocalizedString(@"res_zoom_warning")]];
    
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([_expireTimeMinutes rangeOfCharacterFromSet:notDigits].location == NSNotFound
        && [_expireTimeMinutes integerValue] <= kMaxExpireMin
        && [_expireTimeMinutes integerValue] >= 0)
    {
        if ([_expireTimeMinutes isEqualToString:@""])
            _expireTimeMillis = -1;
        else
            _expireTimeMillis = [_expireTimeMinutes integerValue] * 60 * 1000;
    }
    else
    {
        [errorArray addObject:[@"- " stringByAppendingString:OALocalizedString(@"res_expire_warning")]];
    }
    
    
    if (errorArray.count > 0)
    {
        NSString *title = [errorArray componentsJoinedByString: @"\n\n"];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"" preferredStyle:UIAlertControllerStyleAlert];
        
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.alignment = NSTextAlignmentLeft;
        NSAttributedString *attributedString = [NSAttributedString.alloc initWithString:title attributes: @{NSParagraphStyleAttributeName: paragraphStyle}];
        [alert setValue:attributedString forKey:@"attributedTitle"];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil];
        [alert addAction: cancelAction];
        [alert setPreferredAction:cancelAction];
        [self presentViewController: alert animated: YES completion: nil];
    }
    else
    {
        [[NSFileManager defaultManager] removeItemAtPath:_item.path error:nil];
        _app.resourcesManager->uninstallTilesResource(_tileSource->name);
        
        const auto item = [self createEditedTileSource];

        OsmAnd::OnlineTileSources::installTileSource(item, QString::fromNSString(_app.cachePath));
        _app.resourcesManager->installTilesResource(item);
        _baseController.dataInvalidated = YES;

        [self.navigationController popViewControllerAnimated:NO];
        if (_delegate)
            [_delegate onTileSourceSaved];
    }
}

- (IBAction)backButtonPressed:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)pickerIsShown
{
    return _pickerIndexPath != nil;
}

- (void)hideExistingPicker {
    
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row inSection:_pickerIndexPath.section]]
                          withRowAnimation:UITableViewRowAnimationFade];
    _pickerIndexPath = nil;
}

- (NSIndexPath *)calculateIndexPathForNewPicker:(NSIndexPath *)selectedIndexPath {
    NSIndexPath *newIndexPath;
    if (([self pickerIsShown]) && (_pickerIndexPath.row < selectedIndexPath.row))
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
    if (indexPath.section != kZoomSection)
        return [_data objectAtIndex:indexPath.section];
    else
    {
        NSArray *ar = [_data objectAtIndex:indexPath.section];
        if ([self pickerIsShown])
        {
            if ([indexPath isEqual:_pickerIndexPath])
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
        cell.userInteractionEnabled = YES;
        [cell.inputField removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
        [cell.inputField addTarget:self action:@selector(textChanged:) forControlEvents:UIControlEventEditingChanged];
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
            cell.lbTime.text = [NSString stringWithFormat:@"%d", _minZoom];
        else if ([item[@"key"] isEqualToString:@"maxZoom"])
            cell.lbTime.text = [NSString stringWithFormat:@"%d", _maxZoom];
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

        if ([self pickerIsShown] && (_pickerIndexPath.row - 1 == indexPath.row))
            [self hideExistingPicker];
        else
        {
            NSIndexPath *newPickerIndexPath = [self calculateIndexPathForNewPicker:indexPath];
            if ([self pickerIsShown])
                [self hideExistingPicker];

            [self showNewPickerAtIndex:newPickerIndexPath];
            _pickerIndexPath = [NSIndexPath indexPathForRow:newPickerIndexPath.row + 1 inSection:indexPath.section];
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
    return _sectionHeaderFooterTitles[section][@"header"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return _sectionHeaderFooterTitles[section][@"footer"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
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
        if ([indexPath isEqual:_pickerIndexPath])
            return 162.0;
        else
            return 44.0;
    }
}

#pragma mark - UITextViewDelegate

-(void)textViewDidChange:(UITextView *)textView
{
    if (textView.tag == kNameCellTag)
        _itemName = textView.text;
    else if (textView.tag == kURLCellTag)
        _itemURL = textView.text;
}

- (void)textChanged:(UITextView *)textView
{
    _expireTimeMinutes = textView.text;
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
        _minZoom = [zoom intValue];
    else if (pickerTag == 2)
        _maxZoom = [zoom intValue];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row - 1 inSection:_pickerIndexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
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
    if (sender.tag == kNameCellTag)
        _itemName = @"";
    else if (sender.tag == kURLCellTag)
        _itemURL = @"";
}

@end

