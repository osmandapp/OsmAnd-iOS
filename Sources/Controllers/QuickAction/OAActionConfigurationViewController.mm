//
//  OAActionConfigurationViewController.m
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAActionConfigurationViewController.h"
#import "Localization.h"
#import "OAQuickAction.h"
#import "OrderedDictionary.h"
#import "OAInputTableViewCell.h"
#import "OAMapButtonsHelper.h"
#import "OASizes.h"
#import "OAColors.h"
#import "OASwitchTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OAEditColorViewController.h"
#import "OADefaultFavorite.h"
#import "OAEditGroupViewController.h"
#import "OANativeUtilities.h"
#import "OsmAndApp.h"
#import "OASimpleTableViewCell.h"
#import "OAButtonTableViewCell.h"
#import "MaterialTextFields.h"
#import "OAActionAddCategoryViewController.h"
#import "OAQuickSearchListItem.h"
#import "OAPOIUIFilter.h"
#import "OAPOIBaseType.h"
#import "OATitleDescrDraggableCell.h"
#import "OAActionAddMapStyleViewController.h"
#import "OAActionAddMapSourceViewController.h"
#import "OAActionAddProfileViewController.h"
#import "OATableViewCustomFooterView.h"
#import "OATextInputFloatingCellWithIcon.h"
#import "OAPoiTypeSelectionViewController.h"
#import "OATableViewCustomHeaderView.h"
#import "OAMultilineTextViewCell.h"
#import "OAEditPOIData.h"
#import "OAEntity.h"
#import "OAQuickActionListViewController.h"
#import "OAKeyboardHintBar.h"
#import "OAFavoritesHelper.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#import <AudioToolbox/AudioServices.h>

#define KEY_MESSAGE @"message"

@interface OAActionConfigurationViewController () <OAEditColorViewControllerDelegate, OAEditGroupViewControllerDelegate, OAAddCategoryDelegate, MGSwipeTableCellDelegate, OAAddMapStyleDelegate, OAAddMapSourceDelegate, OAAddProfileDelegate, MDCMultilineTextInputLayoutDelegate, UITextViewDelegate, OAPoiTypeSelectionDelegate, UIGestureRecognizerDelegate, OAKeyboardHintBarDelegate, ActionAddTerrainColorSchemeDelegate>

@end

@implementation OAActionConfigurationViewController
{
    OAQuickAction *_action;
    MutableOrderedDictionary<NSString *, NSArray<NSDictionary *> *> *_data;
    NSString *_originalName;
    
    OAMapButtonsHelper *_mapButtonsHelper;
    QuickActionButtonState *_buttonState;
    
    BOOL _isNew;

    OAEditColorViewController *_colorController;
    OAEditGroupViewController *_groupController;
    
    UIView *_tableHeaderView;
    OAKeyboardHintBar *_hintView;
    
    UITextView *_currentResponderView;
    OAEditPOIData *_poiData;
}

#pragma mark - Initialization

- (instancetype)initWithButtonState:(QuickActionButtonState *)buttonState typeId:(NSInteger)typeId
{
    self = [super init];
    if (self)
    {
        _buttonState = buttonState;
        _isNew = YES;
        _action = [OAMapButtonsHelper produceAction:[_mapButtonsHelper newActionByType:typeId]];
    }
    return self;
}

- (instancetype)initWithButtonState:(QuickActionButtonState *)buttonState action:(OAQuickAction *)action
{
    self = [super init];
    if (self)
    {
        _buttonState = buttonState;
        _isNew = action.id == 0;
        _action = _isNew ? [OAMapButtonsHelper produceAction:[_mapButtonsHelper newActionByType:action.id]] : action;
    }
    return self;
}

- (instancetype)initWithAction:(OAQuickAction *)action isNew:(BOOL)isNew
{
    self = [super init];
    if (self)
    {
        _action = action;
        _isNew = isNew;
    }
    return self;
}

- (void)commonInit
{
    _mapButtonsHelper = [OAMapButtonsHelper sharedInstance];
}

- (void)registerNotifications
{
    [self addNotification:UIKeyboardWillShowNotification selector:@selector(keyboardWillShow:)];
    [self addNotification:UIKeyboardWillHideNotification selector:@selector(keyboardWillHide:)];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setEditing:YES];
    self.tableView.allowsSelectionDuringEditing = YES;
    [self.tableView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    
    _hintView = [[OAKeyboardHintBar alloc] init];
    _hintView.delegate = self;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _action.getName;
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

- (UIImage *)getCustomIconForLeftNavbarButton
{
    return [UIImage templateImageNamed:ACImageNameIcNavbarChevron];
}

- (NSString *)getTableHeaderDescription
{
    if (_action.getActionText)
        return _action.getActionText;
    else
        return nil;
}

- (NSString *)getBottomButtonTitle
{
    return OALocalizedString(@"shared_string_apply");
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    return EOABaseButtonColorSchemePurple;
}

#pragma mark - Table data

- (void)generateData
{
    _data = [self generateDataAction];
    _originalName = [_action getName];
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    NSString *key = _data.allKeys[indexPath.section];
    return _data[key][indexPath.row];
}

- (MutableOrderedDictionary<NSString *, NSArray<NSDictionary *> *> *)generateDataAction
{
    MutableOrderedDictionary *dataModel = [[MutableOrderedDictionary alloc] init];
    NSString *actionName = [_action getExtendedName];
    if (actionName)
    {
        [dataModel setObject:@[@{
            @"type" : [OAInputTableViewCell getCellIdentifier],
            @"title" : actionName
        }] forKey:OALocalizedString(@"shared_string_action_name")];
    }
    
    OrderedDictionary *actionSpecific = _action.getUIModel;
    [dataModel addEntriesFromDictionary:actionSpecific];
    return dataModel;
}

- (OATextInputFloatingCellWithIcon *)getInputCellWithHint:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    OATextInputFloatingCellWithIcon *resultCell = nil;
    resultCell = [self.tableView dequeueReusableCellWithIdentifier:[OATextInputFloatingCellWithIcon getCellIdentifier]];
    if (resultCell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextInputFloatingCellWithIcon getCellIdentifier] owner:self options:nil];
        resultCell = (OATextInputFloatingCellWithIcon *)[nib objectAtIndex:0];
    }
    if (item[@"img"] && ![item[@"img"] isEqualToString:@""]) {
        resultCell.buttonView.hidden = NO;
        [resultCell.buttonView setImage:[UIImage imageNamed:item[@"img"]] forState:UIControlStateNormal];
        [resultCell.buttonView removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [resultCell.buttonView addTarget:self action:@selector(deleteTagPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
        resultCell.buttonView.hidden = YES;
    
    resultCell.fieldLabel.text = item[@"hint"];
    MDCMultilineTextField *textField = resultCell.textField;
    textField.underline.hidden = YES;
    textField.textView.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.placeholder = @"";
    [textField.textView setText:item[@"title"]];
    textField.textView.delegate = self;
    textField.layoutDelegate = self;
    [textField.clearButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [textField.clearButton addTarget:self action:@selector(clearButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    textField.clearButton.imageView.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
    [textField.clearButton setImage:[UIImage templateImageNamed:@"ic_custom_clear_field"] forState:UIControlStateNormal];
    [textField.clearButton setImage:[UIImage templateImageNamed:@"ic_custom_clear_field"] forState:UIControlStateHighlighted];
    
    return resultCell;
}

- (NSArray<NSString *> *)getItemGroups
{
    NSMutableArray *groupNames = [NSMutableArray array];
    for (OAFavoriteGroup *group in [OAFavoritesHelper getFavoriteGroups])
    {
        [groupNames addObject:group.name];
    }
    return groupNames;
}

- (NSMutableArray *)getItemNames
{
    NSMutableArray *arr = [NSMutableArray new];
    for (NSDictionary *item in _data[_data.allKeys.lastObject])
    {
        if (![item[@"type"] isEqualToString:[OAButtonTableViewCell getCellIdentifier]])
            [arr addObject:item[@"title"]];
    }
    return arr;
}

- (NSInteger)sectionsCount
{
    return _data.allKeys.count;
}

- (UIView *)getCustomViewForHeader:(NSInteger)section
{
    NSString *title = _data.allKeys[section];
    OATableViewCustomHeaderView *vw = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    vw.label.text = nil;
    
    if ([title hasPrefix:kSectionNoName])
        return vw;
    vw.label.text = [title upperCase];
    return vw;
}

- (UIView *)getCustomViewForFooter:(NSInteger)section
{
    NSArray *data = _data[_data.allKeys[section]];
    NSString *text = data.lastObject[@"footer"];
    NSString *url = data.lastObject[@"url"];
    if (!text && !url)
        return nil;
    else if (!text)
        text = @"";
    
    OATableViewCustomFooterView *vw = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    if (url)
    {
        NSURL *URL = [NSURL URLWithString:url];
        UIFont *textFont = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        NSMutableAttributedString * str = [[NSMutableAttributedString alloc] initWithString:url attributes:@{NSFontAttributeName : textFont}];
        [str addAttribute:NSLinkAttributeName value:URL range: NSMakeRange(0, str.length)];
        text = [text stringByAppendingString:@"\n"];
        NSMutableAttributedString *textStr = [[NSMutableAttributedString alloc] initWithString:text
                                                                                    attributes:@{NSFontAttributeName : textFont,
                                                                                                 NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorSecondary]}];
        [textStr appendAttributedString:str];
        vw.label.text = nil;
        vw.label.attributedText = textStr;
    }
    else
    {
        vw.label.attributedText = nil;
        vw.label.text = text;
    }
    return vw;
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    NSString *title = _data.allKeys[section];
    if (!title || title.length == 0 || [title hasPrefix:kSectionNoName])
        return 0.01;
    
    return [OATableViewCustomHeaderView getHeight:title width:self.tableView.bounds.size.width];
}

- (CGFloat)getCustomHeightForFooter:(NSInteger)section
{
    NSArray *data = _data[_data.allKeys[section]];
    NSString *text = data.lastObject[@"footer"];
    NSString *url = data.lastObject[@"url"];
    if (!text && !url)
    {
        return 0.01;
    }
    else
    {
        return [OATableViewCustomFooterView getHeight:url ? [NSString stringWithFormat:@"%@ %@", text, OALocalizedString(@"shared_string_read_more")] : text width:self.tableView.bounds.size.width];
    }
}

- (NSInteger)rowsCount:(NSInteger)section
{
    NSString *key = _data.allKeys[section];
    NSString *footer = _data[key].lastObject[@"footer"];
    return _data[key].count - (footer != nil ? 1 : 0);
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OAInputTableViewCell getCellIdentifier]])
    {
        OAInputTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAInputTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAInputTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAInputTableViewCell *) nib[0];
            [cell titleVisibility:NO];
            [cell clearButtonVisibility:NO];
            cell.inputField.textAlignment = NSTextAlignmentNatural;
        }
        if (cell)
        {
            NSString *imgName = item[@"img"];
            [cell leftIconVisibility:imgName && imgName.length > 0];
            if (!cell.leftIconView.hidden)
            {
                [cell.leftIconView setImage:[UIImage templateImageNamed:imgName]];
                cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
            }

            if ([item.allKeys containsObject:@"hint"] && [item[@"hint"] isEqualToString:OALocalizedString(@"quick_action_template_name")])
            {
                cell.inputField.text = item[@"title"];
                cell.inputField.placeholder = item[@"hint"];
                cell.inputField.tag = indexPath.section << 10 | indexPath.row;
                [cell.inputField removeTarget:self action:NULL forControlEvents:UIControlEventEditingChanged];
                [cell.inputField addTarget:self action:@selector(onTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
            }
            else
            {
                cell.userInteractionEnabled = [_action isActionEditable];
                if (cell.userInteractionEnabled)
                {
                    cell.inputField.text = item[@"title"];
                    [cell.inputField removeTarget:self action:NULL forControlEvents:UIControlEventEditingChanged];
                    [cell.inputField addTarget:self action:@selector(onNameChanged:) forControlEvents:UIControlEventEditingChanged];
                }
                else
                {
                    cell.inputField.placeholder = item[@"title"];
                }
            }
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];

            cell.switchView.on = [item[@"value"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            OAFavoriteColor *color = [OADefaultFavorite builtinColors][[item[@"color"] integerValue]];
            if (item[@"img"])
            {
                cell.leftIconView.layer.cornerRadius = 0.;
                cell.leftIconView.image = [UIImage templateImageNamed:item[@"img"]];
                cell.leftIconView.tintColor = color.color;
            }
            else if ([item[@"key"] isEqualToString:@"category_color"])
            {
                cell.leftIconView.layer.cornerRadius = cell.leftIconView.frame.size.height / 2;
                cell.leftIconView.backgroundColor = color.color;
            }
            else
            {
                [cell leftIconVisibility:NO];
            }
            
            cell.valueLabel.text = item[@"value"];
            cell.valueLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = nil;
        cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            UIImage *img = nil;
            NSString *imgName = item[@"img"];
            if (imgName)
                img = [OAUtilities getMxIcon:imgName];
            if (!img)
                img = [OAUtilities getMxIcon:@"user_defined"];
            
            cell.titleLabel.text = item[@"title"];
            NSString *desc = item[@"descr"];
            cell.descriptionLabel.text = desc;
            [cell descriptionVisibility:desc.length != 0];
            [cell.leftIconView setTintColor:[UIColor colorNamed:ACColorNameIconColorDefault]];
            cell.leftIconView.image = img;
            [cell setCustomLeftSeparatorInset:YES];
            cell.separatorInset = UIEdgeInsetsMake(0., 0., 0., 0.);
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAButtonTableViewCell getCellIdentifier]])
    {
        OAButtonTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAButtonTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAButtonTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAButtonTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell titleVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        }
        if (cell)
        {
            [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchDown];
            [cell.button addTarget:self action:NSSelectorFromString(item[@"target"]) forControlEvents:UIControlEventTouchDown];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OATitleDescrDraggableCell getCellIdentifier]])
    {
        OATitleDescrDraggableCell* cell = (OATitleDescrDraggableCell *)[self.tableView dequeueReusableCellWithIdentifier:[OATitleDescrDraggableCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleDescrDraggableCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleDescrDraggableCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText:item[@"title"]];
            cell.descView.hidden = ![item.allKeys containsObject:@"desc"];
            cell.descView.text = [item[@"desc"] stringValue];

            if ([item.allKeys containsObject:@"colorPalette"]
                && [item[@"colorPalette"] isKindOfClass:ColorPalette.class])
            {
                cell.descView.numberOfLines = 1;
                cell.descView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
                cell.descView.lineBreakMode = NSLineBreakByTruncatingTail;
                cell.iconView.layer.cornerRadius = 3;
                ColorPalette *colorPalette = (ColorPalette *) item[@"colorPalette"];
                [PaletteCollectionHandler applyGradientTo:cell.iconView
                                                     with:colorPalette];
            }
            else
            {
                cell.descView.numberOfLines = 0;
                cell.descView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
                cell.descView.lineBreakMode = NSLineBreakByWordWrapping;
                if (item[@"iconColor"])
                {
                    cell.iconView.image = [UIImage templateImageNamed:item[@"img"]];
                    cell.iconView.tintColor = item[@"iconColor"];
                }
                else
                {
                    cell.iconView.image = [UIImage imageNamed:item[@"img"]];
                    cell.iconView.tintColor = nil;
                }
            }

            if (cell.iconView.subviews.count > 0)
                [[cell.iconView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
            cell.delegate = self;
            cell.allowsSwipeWhenEditing = NO;
            cell.overflowButton.hidden = YES;
            cell.separatorInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
            [cell updateConstraintsIfNeeded];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OATextInputFloatingCellWithIcon getCellIdentifier]])
    {
        return [self getInputCellWithHint:indexPath];
    }
    else if ([item[@"type"] isEqualToString:[OAMultilineTextViewCell getCellIdentifier]])
    {
        OAMultilineTextViewCell* cell = (OAMultilineTextViewCell *)[self.tableView dequeueReusableCellWithIdentifier:[OAMultilineTextViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMultilineTextViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAMultilineTextViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            MDCMultilineTextField *textField = cell.inputField;
            textField.underline.hidden = YES;
            textField.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.placeholder = item[@"hint"];
            [textField.textView setText:item[@"title"]];
            textField.textView.delegate = self;
            textField.layoutDelegate = self;
            [textField.clearButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
            [textField.clearButton addTarget:self action:@selector(clearButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            textField.clearButton.imageView.tintColor = UIColorFromRGB(color_icon_color);
            [textField.clearButton setImage:[UIImage templateImageNamed:@"ic_custom_clear_field"] forState:UIControlStateNormal];
            [textField.clearButton setImage:[UIImage templateImageNamed:@"ic_custom_clear_field"] forState:UIControlStateHighlighted];
        }
        return cell;
    }
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"key"] isEqualToString:@"category_name"])
    {
        _groupController = [[OAEditGroupViewController alloc] initWithGroupName:item[@"value"] groups:[self getItemGroups]];
        _groupController.delegate = self;
        [self showViewController:_groupController];
        [self.view endEditing:YES];
    }
    else if ([item[@"key"] isEqualToString:@"category_color"])
    {
        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors][[item[@"color"] integerValue]];
        _colorController = [[OAEditColorViewController alloc] initWithColor:favCol.color];
        _colorController.delegate = self;
        [self showViewController:_colorController];
        [self.view endEditing:YES];
    }
    else if ([item[@"key"] isEqualToString:@"key_category"])
    {
        OAPoiTypeSelectionViewController *poiTypeSelection = [[OAPoiTypeSelectionViewController alloc] initWithType:POI_TYPE_SCREEN];
        poiTypeSelection.delegate = self;
        [self showViewController:poiTypeSelection];
        [self.view endEditing:YES];
    }
    else if ([item[@"type"] isEqualToString:[OATextInputFloatingCellWithIcon getCellIdentifier]])
    {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if ([cell canBecomeFirstResponder])
            [cell becomeFirstResponder];
    }
}

#pragma mark - UITableViewDataSource

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]] || [item[@"type"] isEqualToString:[OATitleDescrDraggableCell getCellIdentifier]])
        return YES;
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSDictionary *item = [self getItem:indexPath];
        NSString *key = _data.allKeys.lastObject;
        NSMutableArray *arr = [NSMutableArray arrayWithArray:_data[key]];
        NSMutableArray *titles = [NSMutableArray new];
        NSMutableArray *oldtitles = [NSMutableArray new];
        for (NSInteger i = 0; i < (NSInteger) arr.count - 1; i++)
        {
            NSDictionary *row = arr[i];
            NSString *title = row[@"title"];
            if (title)
            {
                if (![row isEqualToDictionary:item])
                {
                    [titles addObject:title];
                }
                [oldtitles addObject:title];
            }
        }
        [arr removeObject:item];
        NSString *oldTitle = [_action getTitle:oldtitles];
        [self renameAction:titles oldTitle:oldTitle];
        [_data setObject:arr forKey:key];
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    NSString *key = _data.allKeys[sourceIndexPath.section];
    NSMutableArray *items = [NSMutableArray arrayWithArray:_data[key]];
    NSArray * oldTitles = [self getTitles:items];
    NSDictionary *source = [self getItem:sourceIndexPath];
    NSDictionary *dest = [self getItem:destinationIndexPath];
    [items setObject:source atIndexedSubscript:destinationIndexPath.row];
    [items setObject:dest atIndexedSubscript:sourceIndexPath.row];
    NSArray *titles = [self getTitles:items];
    
    NSMutableDictionary *actionName = [NSMutableDictionary dictionaryWithDictionary:_data[OALocalizedString(@"shared_string_action_name")].firstObject];
    NSString *nameKey = OALocalizedString(@"shared_string_action_name");
    NSString *oldTitle = [_action getTitle:oldTitles];
    NSString *defaultName = [_action getDefaultName];
    if ([actionName[@"title"] isEqualToString:defaultName] || [actionName[@"title"] isEqualToString:oldTitle])
    {
        NSString *newTitle = [_action getTitle:titles];
        [actionName setObject:newTitle forKey:@"title"];
        [_data setObject:@[[NSDictionary dictionaryWithDictionary:actionName]] forKey:nameKey];
        [_action setName:newTitle];
    }
    [_data setObject:[NSArray arrayWithArray:items] forKey:key];
    [self.tableView reloadData];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    return [item[@"type"] isEqualToString:[OATitleDescrDraggableCell getCellIdentifier]];;
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    NSInteger lastItem = [tableView numberOfRowsInSection:sourceIndexPath.section] - 1;
    if (proposedDestinationIndexPath.section != sourceIndexPath.section || proposedDestinationIndexPath.row >= lastItem)
        return sourceIndexPath;
    else
        return proposedDestinationIndexPath;
}

#pragma mark - Additions

- (BOOL)hasChanged
{
    BOOL paramChanged = ![_data isEqualToDictionary:[self generateDataAction]];
    BOOL nameChanged = ![_action.getName isEqualToString:_originalName];
    return paramChanged || nameChanged;
}

- (void)showExitDialog
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"exit_without_saving") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_exit") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [_action setName:_originalName];
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSIndexPath *)indexPathForCellContainingView:(UIView *)view inTableView:(UITableView *)tableView {
    CGPoint viewCenterRelativeToTableview = [tableView convertPoint:CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds)) fromView:view];
    NSIndexPath *cellIndexPath = [tableView indexPathForRowAtPoint:viewCenterRelativeToTableview];
    return cellIndexPath;
}

- (void)addCategory
{
    NSMutableArray * arr = [self getItemNames];
    OAActionAddCategoryViewController *categorySelection = [[OAActionAddCategoryViewController alloc] initWithNames:arr];
    categorySelection.delegate = self;
    [self.navigationController pushViewController:categorySelection animated:YES];
}

- (void)addMapStyle
{
    NSMutableArray * arr = [self getItemNames];
    OAActionAddMapStyleViewController *mapStyleScreen = [[OAActionAddMapStyleViewController alloc] initWithNames:arr];
    mapStyleScreen.delegate = self;
    [self.navigationController pushViewController:mapStyleScreen animated:YES];
}

- (void)addMapOverlay
{
    NSMutableArray * arr = [self getItemNames];
    OAActionAddMapSourceViewController *mapSourceScreen = [[OAActionAddMapSourceViewController alloc] initWithNames:arr type:EOAMapSourceTypeOverlay];
    mapSourceScreen.delegate = self;
    [self.navigationController pushViewController:mapSourceScreen animated:YES];
}

- (void)addMapUnderlay
{
    NSMutableArray * arr = [self getItemNames];
    OAActionAddMapSourceViewController *mapSourceScreen = [[OAActionAddMapSourceViewController alloc] initWithNames:arr type:EOAMapSourceTypeUnderlay];
    mapSourceScreen.delegate = self;
    [self.navigationController pushViewController:mapSourceScreen animated:YES];
}

- (void)addMapSource
{
    NSMutableArray * arr = [self getItemNames];
    OAActionAddMapSourceViewController *mapSourceScreen = [[OAActionAddMapSourceViewController alloc] initWithNames:arr type:EOAMapSourceTypePrimary];
    mapSourceScreen.delegate = self;
    [self.navigationController pushViewController:mapSourceScreen animated:YES];
}

- (void)addProfile
{
    NSArray *arr = [_action getParams][@"stringKeys"] ? [NSMutableArray arrayWithArray:(NSArray *)[_action getParams][@"stringKeys"]] : @[];
    OAActionAddProfileViewController *profilesScreen = [[OAActionAddProfileViewController alloc] initWithNames:arr];
    profilesScreen.delegate = self;
    [self.navigationController pushViewController:profilesScreen animated:YES];
}

- (void)addTerrain
{
    NSArray *arr = [_action getParams][[_action getListKey]];
    ActionAddTerrainColorSchemeViewController *viewController = [[ActionAddTerrainColorSchemeViewController alloc] initWithPalettes:arr];
    viewController.delegate = self;
    [self showViewController:viewController];
}

- (NSArray *)getTitles:(NSArray *)items {
    NSMutableArray *titles = [NSMutableArray new];
    for (NSDictionary *item in items)
    {
        if ([item[@"type"] isEqualToString:[OATitleDescrDraggableCell getCellIdentifier]])
            [titles addObject:item[@"title"]];
    }
    return [NSArray arrayWithArray:titles];
}

- (NSString *)getOldTitle
{
    NSString *listKey = [_action getListKey];
    id params = [_action getParams][listKey];
    return params ? [_action getTitle:params] : [_action getName];
}

#pragma mark - Selectors

- (void)onNameChanged:(UITextView *)textView
{
    NSString *nameKey = OALocalizedString(@"shared_string_action_name");
    NSMutableDictionary *actionName = [NSMutableDictionary dictionaryWithDictionary:_data[nameKey].firstObject];
    NSString *newTitle = textView.text;
    [actionName setObject:newTitle forKey:@"title"];
    [_data setObject:@[[NSDictionary dictionaryWithDictionary:actionName]] forKey:nameKey];
    [_action setName:newTitle];
}

- (void)onTextFieldChanged:(UITextView *)textView
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textView.tag & 0x3FF inSection:textView.tag >> 10];
    NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:[self getItem:indexPath]];
    NSString *key = _data.allKeys[indexPath.section];
    NSMutableArray *arr = [NSMutableArray arrayWithArray:_data[key]];
    [item setObject:textView.text forKey:@"title"];
    [arr setObject:item atIndexedSubscript:indexPath.row];
    [_data setObject:[NSArray arrayWithArray:arr] forKey:key];
}

- (void)deleteTagPressed:(id)sender
{
    NSIndexPath *indexPath = [self indexPathForCellContainingView:sender inTableView:self.tableView];
    [self.tableView beginUpdates];
    NSDictionary *item = [self getItem:indexPath];
    NSString *key = _data.allKeys[indexPath.section];
    NSMutableArray *items = [NSMutableArray arrayWithArray:_data[key]];
    NSIndexPath *valuePath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
    [items removeObject:item];
    [items removeObject:[self getItem:valuePath]];
    [_data setObject:[NSArray arrayWithArray:items] forKey:key];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath, valuePath] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

- (void)clearButtonPressed:(UIButton *)sender
{
    NSIndexPath *indexPath = [self indexPathForCellContainingView:sender inTableView:self.tableView];
    [self.tableView beginUpdates];
    NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:[self getItem:indexPath]];
    NSString *key = _data.allKeys[indexPath.section];
    NSMutableArray *items = [NSMutableArray arrayWithArray:_data[key]];
    [item setObject:@"" forKey:@"title"];
    [items setObject:[NSDictionary dictionaryWithDictionary:item] atIndexedSubscript:indexPath.row];
    [_data setObject:[NSArray arrayWithArray:items] forKey:key];
    [self hideTagToolbar];
    OATextInputFloatingCellWithIcon *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [cell.textField.textView setText:@""];
    [self.tableView endUpdates];
}

- (void)onLeftNavbarButtonPressed
{
    if ([self hasChanged])
        [self showExitDialog];
    else
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)onBottomButtonPressed
{
    if (![_action fillParams:_data])
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"quick_action_fill_params_alert") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    NSArray<OAQuickAction *> *actions = _buttonState.quickActions;
    if ([_mapButtonsHelper isActionNameUnique:actions quickAction:_action])
    {
        if (_isNew)
            [_mapButtonsHelper addQuickAction:_buttonState action:_action];
        else
            [_mapButtonsHelper updateQuickAction:_buttonState action:_action];
        for (UIViewController *controller in self.navigationController.viewControllers)
        {
            if ([controller isKindOfClass:[OAQuickActionListViewController class]])
            {
                [self.navigationController popToViewController:controller animated:YES];
                if (self.delegate)
                    [self.delegate updateData];
                return;
            }
        }
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    else
    {
        _action = [_mapButtonsHelper generateUniqueActionName:actions action:_action];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:OALocalizedString(@"quick_action_name_alert"), [_action getName]] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            if (_isNew)
                [_mapButtonsHelper addQuickAction:_buttonState action:_action];
            else
                [_mapButtonsHelper updateQuickAction:_buttonState action:_action];
            for (UIViewController *controller in self.navigationController.viewControllers)
            {
                if ([controller isKindOfClass:[OAQuickActionListViewController class]])
                {
                    [self.navigationController popToViewController:controller animated:YES];
                    if (self.delegate)
                        [self.delegate updateData];
                    return;
                }
            }
            [self.navigationController popToRootViewControllerAnimated:YES];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *)sender;
        BOOL isChecked = sw.on;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:[self getItem:indexPath]];
        [item setObject:@(isChecked) forKey:@"value"];
        NSString *key = _data.allKeys[indexPath.section];
        NSMutableArray *arr = [NSMutableArray arrayWithArray:_data[key]];
        [arr setObject:item atIndexedSubscript:indexPath.row];
        [_data setObject:[NSArray arrayWithArray:arr] forKey:key];
    }
}

- (void)addTagValue:(id)sender
{
    if ([sender isKindOfClass:UIButton.class])
    {
        [self.tableView beginUpdates];
        UIButton *btn = (UIButton *) sender;
        NSIndexPath *indexPath = [self indexPathForCellContainingView:btn inTableView:self.tableView];
        NSString *key = _data.allKeys[indexPath.section];
        NSMutableArray *arr = [NSMutableArray arrayWithArray:_data[key]];
        NSDictionary *buttonModel = arr.lastObject;
        [arr removeLastObject];
        [arr addObject:@{
            @"type" : [OATextInputFloatingCellWithIcon getCellIdentifier],
            @"hint" : OALocalizedString(@"osm_tag"),
            @"title" : @"",
            @"img" : @"ic_custom_delete"
        }];
        [arr addObject:@{
            @"type" : [OATextInputFloatingCellWithIcon getCellIdentifier],
            @"hint" : OALocalizedString(@"osm_value"),
            @"title" : @"",
            @"img" : @""
        }];
        [arr addObject:buttonModel];
        [_data setObject:[NSArray arrayWithArray:arr] forKey:key];
        NSIndexPath *keyPath = indexPath;
        NSIndexPath *valuePath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        NSIndexPath *newBtnPath = [NSIndexPath indexPathForRow:indexPath.row + 2 inSection:indexPath.section];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView insertRowsAtIndexPaths:@[keyPath, valuePath, newBtnPath] withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView endUpdates];
        [self.tableView scrollToRowAtIndexPath:newBtnPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    NSValue *keyboardBoundsValue = userInfo[UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = [keyboardBoundsValue CGRectValue].size.height;
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        self.buttonsBottomOffsetConstraint.constant = keyboardHeight - [OAUtilities getBottomMargin];
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardHeight + _hintView.frame.size.height, insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        self.buttonsBottomOffsetConstraint.constant = 0;
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0., insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

#pragma mark - OAEditColorViewControllerDelegate

- (void)colorChanged
{
    NSString *key = _data.allKeys.lastObject;
    NSArray *colorItems = _data[key];
    NSMutableArray *newItems = [NSMutableArray new];
    for (NSDictionary *item in colorItems)
    {
        if (!item[@"footer"])
        {
            NSMutableDictionary *mutableItem = [NSMutableDictionary dictionaryWithDictionary:item];
            [mutableItem setObject:@(_colorController.colorIndex) forKey:@"color"];
            if ([item[@"key"] isEqualToString:@"category_color"])
            {
                OAFavoriteColor *col = [OADefaultFavorite builtinColors][_colorController.colorIndex];
                [mutableItem setObject:col.name forKey:@"value"];
            }
            [newItems addObject:[NSDictionary dictionaryWithDictionary:mutableItem]];
        }
        else
        {
            [newItems addObject:item];
        }
    }
    [_data setObject:[NSArray arrayWithArray:newItems] forKey:key];
    [self.tableView reloadData];
}

#pragma mark - OAEditGroupViewControllerDelegate

- (void)groupChanged
{
    NSString *key = _data.allKeys.lastObject;
    NSArray *items = _data[key];
    NSMutableArray *newItems = [NSMutableArray new];
    for (NSDictionary *item in items)
    {
        if ([item[@"key"] isEqualToString:@"category_name"])
        {
            NSMutableDictionary *mutableItem = [NSMutableDictionary dictionaryWithDictionary:item];
            [mutableItem setObject:[OAFavoriteGroup getDisplayName:_groupController.groupName] forKey:@"value"];
            [newItems addObject:[NSDictionary dictionaryWithDictionary:mutableItem]];
        }
        else
        {
            [newItems addObject:item];
        }
    }
    [_data setObject:[NSArray arrayWithArray:newItems] forKey:key];
    [self.tableView reloadData];
}

#pragma mark - OAAddCategoryDelegate

- (void)renameAction:(NSMutableArray *)titles oldTitle:(NSString *)oldTitle
{
    NSString *nameKey = OALocalizedString(@"shared_string_action_name");
    NSMutableDictionary *actionName = [NSMutableDictionary dictionaryWithDictionary:_data[nameKey].firstObject];
    NSString *name = [_action getName];
    
    if ([actionName[@"title"] isEqualToString:name]
        || [actionName[@"title"] isEqualToString:oldTitle])
    {
        NSString *newTitle = [_action getTitle:titles];
        [actionName setObject:newTitle forKey:@"title"];
        [_data setObject:@[[NSDictionary dictionaryWithDictionary:actionName]] forKey:nameKey];
        [_action setName:newTitle];
    }
}

- (void)onCategoriesSelected:(NSArray *)items
{
    NSString *key = _data.allKeys.lastObject;
    NSArray *rows = _data[key];
    NSDictionary *button = rows.lastObject;
    NSMutableArray *newItems = [NSMutableArray new];
    NSMutableArray *titles = [NSMutableArray new];
    for (id item in items)
    {
        if ([item isKindOfClass:OAPOIUIFilter.class])
        {
            OAPOIUIFilter *filter = (OAPOIUIFilter *)item;
            NSString *iconId = filter.getIconId ? filter.getIconId : @"user_defined";
            [newItems addObject:@{
                @"title" : filter.getName,
                @"value" : filter.filterId,
                @"type" : [OASimpleTableViewCell getCellIdentifier],
                @"img" : iconId
            }];
            [titles addObject:filter.getName];
        }
        else if ([item isKindOfClass:OAPOIBaseType.class])
        {
            OAPOIBaseType *filter = (OAPOIBaseType *)item;
            [newItems addObject:@{
                @"title" : filter.nameLocalized,
                @"value" : [STD_PREFIX stringByAppendingString:filter.name],
                @"type" : [OASimpleTableViewCell getCellIdentifier],
                @"img" : filter.name
            }];
            [titles addObject:filter.nameLocalized];
        }
    }
    [newItems addObject:button];
    [_data setObject:[NSArray arrayWithArray:newItems] forKey:key];
    [self renameAction:titles oldTitle:[self getOldTitle]];
    [self.tableView reloadData];
}

#pragma mark - OAAddMapStyleDelegate

- (void)onMapStylesSelected:(NSArray *)items
{
    NSString *key = _data.allKeys.lastObject;
    NSArray *rows = _data[key];
    NSDictionary *button = rows.lastObject;
    NSMutableArray *newItems = [NSMutableArray new];
    NSMutableArray *titles = [NSMutableArray new];
    for (NSDictionary *item in items)
    {
        [newItems addObject:@{
            @"type" : [OATitleDescrDraggableCell getCellIdentifier],
            @"title" : item[@"name"],
            @"img" : item[@"img"]
        }];
        [titles addObject:item[@"name"]];
    }
    [newItems addObject:button];
    [_data setObject:[NSArray arrayWithArray:newItems] forKey:key];
    NSMutableDictionary *actionName = [NSMutableDictionary dictionaryWithDictionary:_data[OALocalizedString(@"shared_string_action_name")].firstObject];
    NSString *nameKey = OALocalizedString(@"shared_string_action_name");
    NSString *defaultName = [_action getDefaultName];
    
    if ([actionName[@"title"] isEqualToString:defaultName] || [actionName[@"title"] isEqualToString:[self getOldTitle]])
    {
        NSString *newTitle = [_action getTitle:titles];
        [actionName setObject:newTitle forKey:@"title"];
        [_data setObject:@[[NSDictionary dictionaryWithDictionary:actionName]] forKey:nameKey];
        [_action setName:newTitle];
    }
    [self.tableView reloadData];
}

#pragma mark - OAAddMapSourceDelegate

- (void)onMapSourceSelected:(NSArray *)items
{
    NSString *key = _data.allKeys.lastObject;
    NSArray *rows = _data[key];
    NSDictionary *button = rows.lastObject;
    NSMutableArray *newItems = [NSMutableArray new];
    NSMutableArray *titles = [NSMutableArray new];
    for (NSArray *item in items)
    {
        [newItems addObject:@{
            @"type" : [OATitleDescrDraggableCell getCellIdentifier],
            @"title" : item.lastObject,
            @"value" : item.firstObject,
            @"img" : @"ic_custom_map_style"
        }];
        [titles addObject:item.lastObject];
    }
    [newItems addObject:button];
    [_data setObject:[NSArray arrayWithArray:newItems] forKey:key];
    [self renameAction:titles oldTitle:[self getOldTitle]];
    [self.tableView reloadData];
}

#pragma mark - OAAddProfileDelegate

- (void)onProfileSelected:(NSArray *)items
{
    NSString *key = _data.allKeys.lastObject;
    NSArray *rows = _data[key];
    NSDictionary *button = rows.lastObject;
    NSMutableArray *newItems = [NSMutableArray new];
    NSMutableArray *titles = [NSMutableArray new];
    for (NSDictionary *item in items)
    {
        [newItems addObject:@{
            @"type" : [OATitleDescrDraggableCell getCellIdentifier],
            @"title" : item[@"name"],
            @"stringKey" : item[@"stringKey"],
            @"img" : item[@"img"],
            @"iconColor" : item[@"iconColor"]
        }];
        [titles addObject:item[@"name"]];
    }
    [newItems addObject:button];
    [_data setObject:[NSArray arrayWithArray:newItems] forKey:key];
    [self renameAction:titles oldTitle:[self getOldTitle]];
    [self.tableView reloadData];
}

#pragma mark - ActionAddTerrainColorSchemeDelegate

- (void)onTerrainsSelected:(NSArray<NSDictionary<NSString *, id> *> *)items
{
    NSString *key = _data.allKeys.lastObject;
    NSArray *rows = _data[key];
    NSDictionary *button = rows.lastObject;
    NSMutableArray *newItems = [NSMutableArray array];
    NSMutableArray *titles = [NSMutableArray array];
    for (NSDictionary *item in items)
    {
        [newItems addObject:@{
            @"type" : [OATitleDescrDraggableCell getCellIdentifier],
            @"title" : item[@"title"],
            @"desc" : item[@"desc"],
            @"colorPalette" : item[@"colorPalette"],
            @"palette" : item[@"palette"]
        }];
        [titles addObject:item[@"title"]];
    }
    [newItems addObject:button];
    [_data setObject:[NSArray arrayWithArray:newItems] forKey:key];
    [self renameAction:titles oldTitle:[self getOldTitle]];
    [self.tableView reloadData];
}

#pragma mark - Swipe Delegate

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction;
{
    return self.tableView.isEditing;
}

- (void)swipeTableCell:(MGSwipeTableCell *)cell didChangeSwipeState:(MGSwipeState)state gestureIsActive:(BOOL)gestureIsActive
{
    if (state != MGSwipeStateNone)
        cell.showsReorderControl = NO;
    else
        cell.showsReorderControl = YES;
}

#pragma mark - MDCMultilineTextInputLayoutDelegate

- (void)multilineTextField:(id<MDCMultilineTextInput> _Nonnull)multilineTextField
      didChangeContentSize:(CGSize)size
{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    [self textChanged:textView userInput:YES];
}

- (void)textChanged:(UITextView * _Nonnull)textView userInput:(BOOL)userInput
{
    NSIndexPath *indexPath = [self indexPathForCellContainingView:textView inTableView:self.tableView];
    NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:[self getItem:indexPath]];
    BOOL showHints = ![item[@"key"] isEqualToString:KEY_MESSAGE];
    if (userInput && showHints)
    {
        _currentResponderView = textView;
        [self toggleTagToolbar];
    }
    NSString *key = _data.allKeys[indexPath.section];
    NSMutableArray *items = [NSMutableArray arrayWithArray:_data[key]];
    [item setObject:textView.text forKey:@"title"];
    [items setObject:[NSDictionary dictionaryWithDictionary:item] atIndexedSubscript:indexPath.row];
    [_data setObject:[NSArray arrayWithArray:items] forKey:key];
    if (userInput && showHints)
    {
        if (indexPath.row % 2 == 0)
            [self updateTagHintsSet:textView.text];
        else
        {
            NSDictionary *tagItem = [self getItem:[NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section]];
            [self updateValueHintsSet:textView.text tag:tagItem[@"title"]];
        }
    }
}

#pragma mark - OAPoiTypeSelectionDelegate

- (void)onPoiTypeSelected:(NSString *)name
{
    NSString *key = OALocalizedString(@"poi_dialog_poi_type");
    NSMutableArray *arr = [NSMutableArray arrayWithArray:_data[key]];
    NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:arr.firstObject];
    [item setObject:name forKey:@"value"];
    [arr setObject:item atIndexedSubscript:0];
    [_data setObject:[NSArray arrayWithArray:arr] forKey:key];
    [self.tableView reloadData];
}

#pragma mark - Hints related methods

- (void)createTagToolbarFor
{
    UITextInputAssistantItem* item = _currentResponderView.inputAssistantItem;
    item.leadingBarButtonGroups = @[];
    item.trailingBarButtonGroups = @[];
    _currentResponderView.inputAccessoryView = _hintView;
    [_currentResponderView reloadInputViews];
}

- (void)toggleTagToolbar
{
    if (_currentResponderView.inputAccessoryView == nil)
        [self createTagToolbarFor];
    else if ([_currentResponderView.text isEqualToString:@""])
        [self hideTagToolbar];
}

- (void)hideTagToolbar
{
    _currentResponderView.inputAccessoryView = nil;
    [_currentResponderView reloadInputViews];
}

- (void)updateTagHintsSet:(NSString *)tag
{
    OAActionConfigurationViewController* __weak weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        if (!_poiData)
            _poiData = [[OAEditPOIData alloc] initWithEntity:[[OAEntity alloc] init]];
        NSArray* hints = [_poiData getTagsMatchingWith:tag];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            OAActionConfigurationViewController* __weak strongSelf = weakSelf;
            [strongSelf updateHints:hints];
        });
    });
}

- (void)updateValueHintsSet:(NSString *)value tag:(NSString *)tag
{
    OAActionConfigurationViewController* __weak weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        if (!_poiData)
            _poiData = [[OAEditPOIData alloc] initWithEntity:[[OAEntity alloc] init]];
        NSArray* hints = [_poiData getValuesMatchingWith:value forTag:tag];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            OAActionConfigurationViewController* __weak strongSelf = weakSelf;
            [strongSelf updateHints:hints];
        });
    });
}

- (void)updateHints:(NSArray *)hints
{
    NSInteger xPosition = 0;
    NSInteger margin = 8;
    
    [_hintView.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _hintView.scrollView.contentSize = CGSizeMake(margin, _hintView.frame.size.height);
    
    if ([hints count] == 0)
    {
        [self hideTagToolbar];
    }
    else
    {
        for (NSString *hint in hints)
        {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            btn.frame = CGRectMake(xPosition + margin, 6, 0, 0);
            btn.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorSecondary];
            btn.layer.masksToBounds = YES;
            btn.layer.cornerRadius = 4.0;
            btn.titleLabel.numberOfLines = 1;
            [btn setTitle:hint forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor colorNamed:ACColorNameButtonTextColorSecondary] forState:UIControlStateNormal];
            [btn sizeToFit];
            
            [btn addTarget:self action:@selector(tagHintTapped:) forControlEvents:UIControlEventTouchUpInside];
            
            CGRect btnFrame = [btn frame];
            btnFrame.size.width = btn.frame.size.width + 15;
            btnFrame.size.height = 32;
            [btn setFrame:btnFrame];
            
            xPosition += btn.frame.size.width + margin;
            
            [_hintView.scrollView addSubview:btn];
        }
    }
    _hintView.scrollView.contentSize = CGSizeMake(xPosition, _hintView.frame.size.height);
    [_currentResponderView reloadInputViews];
}

- (void)removeFromSuperview:(UITapGestureRecognizer *)sender
{
    if ([sender isKindOfClass:[UILabel class]])
    {
        UILabel *label = (UILabel *) sender;
        [label removeFromSuperview];
    }
}

- (void)tagHintTapped:(id)sender
{
    _currentResponderView.text = ((UIButton *)sender).titleLabel.text;
    [self hideTagToolbar];
    [self textChanged:_currentResponderView userInput:NO];
}

- (void)keyboardHintBarDidTapButton
{
    [self.view endEditing:YES];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isEqual:[self.navigationController interactivePopGestureRecognizer]])
    {
        if ([self hasChanged])
            [self showExitDialog];
        else
            [self.navigationController popViewControllerAnimated:YES];
    }
    return NO;
}

@end
