//
//  OABasicEditingViewController.m
//  OsmAnd
//
//  Created by Paul on 2/20/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABasicEditingViewController.h"
#import "OAOsmEditingViewController.h"
#import "OAEditPOIData.h"
#import "Localization.h"
#import "OATextInputFloatingCell.h"
#import "OAValueTableViewCell.h"
#import "OAEntity.h"
#import "MaterialTextFields.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAPOICategory.h"
#import "OAPOIType.h"
#import "OAPoiTypeSelectionViewController.h"
#import "OAPOIHelper.h"
#import "OAOSMSettings.h"
#import "OAButtonTableViewCell.h"
#import "OAOpeningHoursSelectionViewController.h"
#import "GeneratedAssetSymbols.h"

#include <openingHoursParser.h>

@interface OABasicEditingViewController () <UITextViewDelegate, UIGestureRecognizerDelegate, MDCMultilineTextInputLayoutDelegate>

@end

static const NSInteger _nameSectionIndex = 0;
static const NSInteger _nameSectionItemCount = 1;
static const NSInteger _poiSectionIndex = 1;
static const NSInteger _hoursSectionIndex = 2;
static const NSInteger _contactInfoSectionIndex = 3;
static const NSInteger _contactInfoSectionCount = 5;

@implementation OABasicEditingViewController
{
    OAEditPOIData *_poiData;
    id<OAOsmEditingDataProtocol> _dataProvider;
    
    NSArray *_poiSectionItems;
    NSArray *_hoursSectionItems;
    NSArray *_contactInfoItems;
    
    NSArray *_tagNames;
    
    OATextInputFloatingCell *_poiNameCell;
    
    NSMutableArray *_floatingTextFieldControllers;
    
    std::shared_ptr<OpeningHoursParser::OpeningHours> _openingHours;
    
    BOOL _isKeyboardShown;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithNibName:@"OABasicEditingViewController" bundle:nil];
    if (self)
    {
        self.view.frame = frame;
    }
    return self;
}

-(void) setDataProvider:(id<OAOsmEditingDataProtocol>)provider
{
    _dataProvider = provider;
}

- (OATextInputFloatingCell *)getInputCellWithHint:(NSString *)hint text:(NSString *)text isFloating:(BOOL)isFloating tag:(NSInteger)tag
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextInputFloatingCell getCellIdentifier] owner:self options:nil];
    OATextInputFloatingCell *resultCell = (OATextInputFloatingCell *)[nib objectAtIndex:0];
    
    MDCMultilineTextField *textField = resultCell.inputField;
    textField.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
    [textField.underline removeFromSuperview];
    textField.placeholder = hint;
    [textField.textView setText:text];
    textField.textView.delegate = self;
    textField.layoutDelegate = self;
    textField.textView.tag = tag;
    textField.clearButton.tag = tag;
    [textField.clearButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [textField.clearButton addTarget:self action:@selector(clearButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    textField.clearButton.imageView.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
    [textField.clearButton setImage:[UIImage templateImageNamed:@"ic_custom_clear_field.png"] forState:UIControlStateNormal];
    [textField.clearButton setImage:[UIImage templateImageNamed:@"ic_custom_clear_field.png"] forState:UIControlStateHighlighted];
    if (!_floatingTextFieldControllers)
        _floatingTextFieldControllers = [NSMutableArray new];
    
    MDCTextInputControllerUnderline *fieldController = [[MDCTextInputControllerUnderline alloc] initWithTextInput:textField];
    fieldController.inlinePlaceholderColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
    fieldController.textInput.textInsetsMode = MDCTextInputTextInsetsModeIfContent;
    if (isFloating)
    {
        fieldController.inlinePlaceholderFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCallout];
        [fieldController setFloatingPlaceholderNormalColor:[UIColor colorNamed:ACColorNameTextColorSecondary]];
        fieldController.floatingPlaceholderActiveColor = fieldController.floatingPlaceholderNormalColor;
        fieldController.textInput.hidesPlaceholderOnInput = NO;
        [_floatingTextFieldControllers addObject:fieldController];
    }
    else
    {
        fieldController.textInput.hidesPlaceholderOnInput = YES;
        fieldController.inlinePlaceholderFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    }
    return resultCell;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onOutsedeCellsTapped)];
    tapGesture.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tapGesture];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    _tagNames = @[[OAOSMSettings getOSMKey:ADDR_STREET],
                  [OAOSMSettings getOSMKey:ADDR_HOUSE_NUMBER],
                  [OAOSMSettings getOSMKey:PHONE],
                  [OAOSMSettings getOSMKey:WEBSITE],
                  [OAOSMSettings getOSMKey:DESCRIPTION]];
    [self setupView];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(void) populatePoiSection
{
    NSMutableArray *dataArr = [NSMutableArray new];
    [dataArr addObject:@{
                         @"name" : @"poi_category",
                         @"title" : OALocalizedString(@"rendering_value_category_name"),
                         @"value" : _poiData.getPoiCategory != [OAPOIHelper sharedInstance].otherPoiCategory ? _poiData.getPoiCategory.nameLocalized :
                             OALocalizedString(@"shared_string_select"),
                         @"type" : [OAValueTableViewCell getCellIdentifier],
                         }];
    [dataArr addObject:@{
                         @"name" : @"poi_type",
                         @"title" : OALocalizedString(@"poi_dialog_poi_type"),
                         @"value" : _poiData.getCurrentPoiType ? _poiData.getLocalizedTypeString :
                             OALocalizedString(@"shared_string_select"),
                         @"type" : [OAValueTableViewCell getCellIdentifier],
                         }];
    _poiSectionItems = [NSArray arrayWithArray:dataArr];
}

- (void) setupView
{
    _poiData = _dataProvider.getData;
    _poiNameCell = [self getInputCellWithHint:OALocalizedString(@"shared_string_name")
                                         text:[_poiData getTag:[OAOSMSettings getOSMKey:NAME]] isFloating:NO tag:-1];
    [self populatePoiSection];
    [self populateOpeningHours];
    [self populateContactInfo];
    [self.tableView reloadData];
}

-(void)populateContactInfo
{
    _floatingTextFieldControllers = [[NSMutableArray alloc] initWithCapacity:_contactInfoSectionCount];
    NSMutableArray *dataArr = [NSMutableArray new];
    NSArray *hints = @[OALocalizedString(@"map_widget_top_text"), OALocalizedString(@"osm_building_num"),
                       OALocalizedString(@"phone"), OALocalizedString(@"website"), OALocalizedString(@"shared_string_description")];
    for (NSInteger i = 0; i < _contactInfoSectionCount; i++)
    {
        OATextInputFloatingCell *cell = [self getInputCellWithHint:hints[i] text:[self getDataForField:i] isFloating:YES tag:i];
        cell.inputField.contentScaleFactor = 0.5;
        [dataArr addObject:cell];
    }
    _contactInfoItems = [NSArray arrayWithArray:dataArr];
}

-(NSString *)getDataForField:(NSInteger)index
{
    return [_poiData getTag:_tagNames[index]];
}

-(void) populateOpeningHours
{
    NSMutableArray *dataArr = [NSMutableArray new];
    NSString *openingHoursString = [_poiData getTag:[OAOSMSettings getOSMKey:OSM_TAG_OPENING_HOURS]];
    if (openingHoursString && openingHoursString.length > 0)
    {
        _openingHours = OpeningHoursParser::parseOpenedHours([openingHoursString UTF8String]);
        for (const auto& rule : _openingHours->getRules())
        {
            [dataArr addObject:@{
                                 @"title" : [NSString stringWithUTF8String:rule->toLocalRuleString().c_str()],
                                 @"type" : [OAValueTableViewCell getCellIdentifier]
                                 }];
        }
    }
    [dataArr addObject:@{
                         @"title" : OALocalizedString(@"osm_add_timespan"),
                         @"type" : [OAButtonTableViewCell getCellIdentifier]
                         }];
    _hoursSectionItems = [NSArray arrayWithArray:dataArr];
}

-(NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    if (indexPath.section == _poiSectionIndex)
        return _poiSectionItems[indexPath.row];
    else if (indexPath.section == _hoursSectionIndex)
        return _hoursSectionItems[indexPath.row];
    else
        return [NSDictionary new];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case _nameSectionIndex:
            return _nameSectionItemCount;
        case _poiSectionIndex:
            return _poiSectionItems.count;
        case _hoursSectionIndex:
            return _hoursSectionItems.count;
        case _contactInfoSectionIndex:
            return _contactInfoSectionCount;
        default:
            return 1;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if (indexPath.section == _nameSectionIndex && indexPath.row == 0)
        return _poiNameCell;
    else if (indexPath.section == _contactInfoSectionIndex)
    {
        OATextInputFloatingCell *cell = _contactInfoItems[indexPath.row];
        cell.inputField.textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        cell.inputField.textView.autocorrectionType = UITextAutocorrectionTypeDefault;
        switch (indexPath.row)
        {
            case 1:
                cell.inputField.textView.keyboardType = UIKeyboardTypeDefault;
                break;
            case 2:
                cell.inputField.textView.keyboardType = UIKeyboardTypePhonePad;
                break;
            case 3:
                cell.inputField.textView.keyboardType = UIKeyboardTypeURL;
                cell.inputField.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
                cell.inputField.textView.autocorrectionType = UITextAutocorrectionTypeNo;
                break;
            default:
                break;
        }
        return cell;
    }
    
    else if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        
        if (cell)
        {
            [cell.titleLabel setText:item[@"title"]];
            [cell.valueLabel setText:item[@"value"]];
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
            [cell.button addTarget:self action:@selector(addOpeningHours) forControlEvents:UIControlEventTouchDown];
        }
        return cell;
    }

    return nil;
}

-(void) addOpeningHours
{
    OAOpeningHoursSelectionViewController *openingHoursSelection = [[OAOpeningHoursSelectionViewController alloc] initWithEditData:_poiData openingHours:_openingHours ruleIndex:-1];
    [self.navigationController pushViewController:openingHoursSelection animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if (indexPath.section == _nameSectionIndex)
        return MAX(_poiNameCell.inputField.intrinsicContentSize.height, 44.0);
    else if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
        return UITableViewAutomaticDimension;
    else if (indexPath.section == _contactInfoSectionIndex)
        return MAX(((OATextInputFloatingCell *)_contactInfoItems[indexPath.row]).inputField.intrinsicContentSize.height, 60.0);
    else
        return 44.0;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == _nameSectionIndex)
        return OALocalizedString(@"shared_string_name");
    else if (section == _poiSectionIndex)
        return OALocalizedString(@"poi_category_and_type");
    else if (section == _hoursSectionIndex)
        return OALocalizedString(@"opening_hours");
    else if (section == _contactInfoSectionIndex)
        return OALocalizedString(@"contact_info");
    else
        return @"";
}

#pragma mark - UITextViewDelegate

-(void)textViewDidChange:(UITextView *)textView
{
    NSString *tagName = textView.tag == -1 ? [OAOSMSettings getOSMKey:NAME] : _tagNames[textView.tag];
    if (textView.text.length > 0)
        [_poiData putTag:tagName value:textView.text];
    else
        [_poiData removeTag:tagName];
    
}

#pragma mark - MDCMultilineTextInputLayoutDelegate
- (void)multilineTextField:(id<MDCMultilineTextInput> _Nonnull)multilineTextField
      didChangeContentSize:(CGSize)size
{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]] && indexPath.section == _poiSectionIndex)
    {
        OAPoiTypeSelectionViewController *detailViewController = [[OAPoiTypeSelectionViewController alloc]
                                                                  initWithType:(indexPath.row == 0 ? CATEGORY_SCREEN : POI_TYPE_SCREEN)];
        detailViewController.dataProvider = _dataProvider;
        [self.navigationController pushViewController:detailViewController animated:YES];
    }
    else if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]] && indexPath.section == _hoursSectionIndex)
    {
        OAOpeningHoursSelectionViewController *openingHoursSelection = [[OAOpeningHoursSelectionViewController alloc] initWithEditData:_poiData openingHours:_openingHours ruleIndex:indexPath.row];
        [self.navigationController pushViewController:openingHoursSelection animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

#pragma mark - Keyboard Notifications

- (void) keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    if (!_isKeyboardShown)
    {
        [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
            [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 44.0, insets.right)];
        } completion:nil];
    }
    _isKeyboardShown = YES;
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    if (_isKeyboardShown)
    {
        [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
            [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0., insets.right)];
            [[self view] layoutIfNeeded];
        } completion:nil];
    }
    _isKeyboardShown = NO;
}

-(void)clearButtonPressed:(UIButton *)sender
{
    BOOL isNameSection = sender.tag == -1;
    NSString *tagName = isNameSection ? [OAOSMSettings getOSMKey:NAME] : _tagNames[sender.tag];
    [_poiData removeTag:tagName];

    [self.tableView beginUpdates];
    OATextInputFloatingCell *cell = isNameSection ? _poiNameCell : (OATextInputFloatingCell *) _contactInfoItems[sender.tag];
    cell.inputField.text = @"";
    [self.tableView endUpdates];
}

#pragma mark - UIGestureRecognizerDelegate

- (void) onOutsedeCellsTapped
{
    [self.view endEditing:YES];
}

@end
