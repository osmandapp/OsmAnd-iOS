//
//  OAEditPointViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 05.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAEditPointViewController.h"
#import "OAFavoriteGroupEditorViewController.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "OAUtilities.h"
#import "OADefaultFavorite.h"
#import "OARightIconTableViewCell.h"
#import "OATextInputFloatingCell.h"
#import "OAValueTableViewCell.h"
#import "OAShapesTableViewCell.h"
#import "OASelectFavoriteGroupViewController.h"
#import "OAReplaceFavoriteViewController.h"
#import "OAFolderCardsCell.h"
#import "OAFavoritesHelper.h"
#import "OAFavoriteItem.h"
#import "OAGpxWptItem.h"
#import "OAGPXDocumentPrimitives.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OATargetInfoViewController.h"
#import "OATargetPointsHelper.h"
#import "OACollectionViewCellState.h"
#import "OABasePointEditingHandler.h"
#import "OAFavoriteEditingHandler.h"
#import "OAGpxWptEditingHandler.h"
#import "OAPointDescription.h"
#import "OAGPXDatabase.h"
#import "OATrackMenuHudViewController.h"
#import "OAAppSettings.h"
#import "OAPOI.h"
#import "OrderedDictionary.h"
#import "OAGPXAppearanceCollection.h"
#import "OAColorsPaletteCell.h"
#import "OAColorCollectionHandler.h"
#import "OATargetMenuViewController.h"
#import "MaterialTextFields.h"
#import "OAIconsPaletteCell.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#define kNameKey @"kNameKey"
#define kDescKey @"kDescKey"
#define kAddressKey @"kAddressKeyd"
#define kIconsKey @"kIconsKey"
#define kBackgroundsKey @"kBackgroundsKey"
#define kSelectGroupKey @"kSelectGroupKey"
#define kSelectGroupDescKey @"kSelectGroupDescKey"
#define kReplaceKey @"kReplaceKey"
#define kDeleteKey @"kDeleteKey"
#define kLastUsedIconsKey @"kLastUsedIconsKey"

#define kCategoryCellIndex 0
#define kPoiCellIndex 1
#define kLastUsedIconsLimit 20

#define kSubviewVerticalOffset 8.

@interface OAEditPointViewController() <UITextFieldDelegate, UITextViewDelegate, OAShapesTableViewCellDelegate, MDCMultilineTextInputLayoutDelegate, OAReplacePointDelegate, OAFolderCardsCellDelegate, OASelectFavoriteGroupDelegate, UIAdaptivePresentationControllerDelegate, OACollectionCellDelegate, OAEditorDelegate>

@end

@implementation OAEditPointViewController
{
    OsmAndAppInstance _app;
    BOOL _isNewItemAdding;
    BOOL _wasChanged;
    BOOL _isUnsaved;
    NSString *_initialName;
    NSString *_initialGroupName;
    EOAEditPointType _editPointType;
    OAFavoriteItem *_favorite;
    OAGpxWptItem *_waypoint;
    
    OABasePointEditingHandler *_pointHandler;
    
    NSArray<NSArray<NSDictionary *> *> *_data;
    NSArray<NSString *> *_backgroundIcons;
    NSArray<NSString *> *_backgroundIconNames;
    NSArray<NSString *> *_backgroundContourIconNames;
    
    NSArray<NSString *> *_groupNames;
    NSArray<NSNumber *> *_groupSizes;
    NSArray<UIColor *> *_groupColors;
    NSArray<NSNumber *> *_groupHidden;
    NSString *_selectedIconName;
    NSInteger _selectedBackgroundIndex;
    
    NSInteger _selectCategorySectionIndex;
    NSInteger _selectCategoryLabelRowIndex;
    NSInteger _selectCategoryCardsRowIndex;
    NSInteger _selectCategoryDescriptionRowIndex;
    NSInteger _appearenceSectionIndex;
    NSInteger _poiIconRowIndex;
    NSInteger _colorLabelRowIndex;
    NSInteger _allColorsRowIndex;
    NSInteger _shapeRowIndex;
    NSIndexPath *_replaceIndexPath;

    OACollectionViewCellState *_scrollCellsState;
    NSString *_renamedPointAlertMessage;
    OATargetMenuViewControllerState *_targetMenuState;
    
    OATextInputFloatingCell *_nameTextField;
    OATextInputFloatingCell *_descTextField;
    OATextInputFloatingCell *_addressTextField;
    NSMutableArray *_floatingTextFieldControllers;

    OAColorCollectionHandler *_colorCollectionHandler;
    OAGPXAppearanceCollection *_appearanceCollection;
    NSMutableArray<OAColorItem *> *_sortedColorItems;
    OAColorItem *_selectedColorItem;
    NSIndexPath *_editColorIndexPath;
    BOOL _isNewColorSelected;
    BOOL _needToScrollToSelectedColor;
    OAColorsPaletteCell *_colorsPaletteCell;
    
    PoiIconCollectionHandler *_poiIconCollectionHandler;

    UILabel *_subtitle;
    CGFloat _originalSubviewHeight;
}

#pragma mark - Initialization

- (instancetype)initWithFavorite:(OAFavoriteItem *)favorite
{
    self = [super init];
    if (self)
    {
        _editPointType = EOAEditPointTypeFavorite;
        _app = [OsmAndApp instance];
        _isNewItemAdding = NO;
        _isUnsaved = YES;
        _pointHandler = [[OAFavoriteEditingHandler alloc] initWithItem:favorite];
        _favorite = favorite;
        self.name = [favorite getDisplayName];
        self.desc = [favorite getDescription];
        self.address = [favorite getAddress];
        self.groupTitle = [favorite getCategoryDisplayName];
        [self postInit];
    }
    return self;
}

- (instancetype)initWithGpxWpt:(OAGpxWptItem *)gpxWpt
{
    self = [super init];
    if (self)
    {
        _editPointType = EOAEditPointTypeWaypoint;
        _app = [OsmAndApp instance];
        _isNewItemAdding = NO;
        _isUnsaved = YES;
        _pointHandler = [[OAGpxWptEditingHandler alloc] initWithItem:gpxWpt];
        self.name = gpxWpt.point.name;
        _waypoint = gpxWpt;
        self.desc = gpxWpt.point.desc;
        self.address = [gpxWpt.point getAddress];
        self.groupTitle = [self getGroupTitle]/*gpxWpt.point.type*/;
        [self postInit];
    }
    return self;
}

- (instancetype)initWithLocation:(CLLocationCoordinate2D)location
                           title:(NSString *)formattedTitle
                         address:(NSString *)address
                     customParam:(NSString *)customParam
                       pointType:(EOAEditPointType)pointType
                 targetMenuState:(OATargetMenuViewControllerState *)targetMenuState
                             poi:(OAPOI *)poi
{
    self = [super init];
    if (self)
    {
        _editPointType = pointType;
        _isNewItemAdding = YES;
        _isUnsaved = YES;
        _app = [OsmAndApp instance];
        _targetMenuState = targetMenuState;

        if (_editPointType == EOAEditPointTypeFavorite)
        {
            _pointHandler = [[OAFavoriteEditingHandler alloc] initWithLocation:location title:formattedTitle address:address poi:poi];
            self.address = address ? address : @"";
        }
        else if (_editPointType == EOAEditPointTypeWaypoint)
        {
            _pointHandler = [[OAGpxWptEditingHandler alloc] initWithLocation:location title:formattedTitle address:address gpxFileName:customParam poi:poi];
            self.gpxFileName = customParam ? customParam : @"";
            self.address = ((OAGpxWptEditingHandler *)_pointHandler).getAddress;
        }
        
        self.name = formattedTitle ? formattedTitle : @"";
        self.desc = @"";
        self.groupTitle = [self getGroupTitle];

        _selectedIconName = DEFAULT_ICON_NAME_KEY;
        _selectedBackgroundIndex = 0;

        [self postInit];
    }
    return self;
}

- (void)commonInit
{
    _originalSubviewHeight = [OAUtilities calculateTextBounds:[self getTitle]
                                                        width:DeviceScreenWidth - (20. + [OAUtilities getLeftMargin]) * 2
                                                         font:[UIFont scaledSystemFontOfSize:17 weight:UIFontWeightSemibold]].height + kSubviewVerticalOffset;
    _wasChanged = NO;
    _needToScrollToSelectedColor = YES;

    _selectCategorySectionIndex = -1;
    _selectCategoryLabelRowIndex = -1;
    _selectCategoryCardsRowIndex = -1;
    _selectCategoryDescriptionRowIndex = -1;
    _appearenceSectionIndex = -1;
    _poiIconRowIndex = -1;
    _allColorsRowIndex = -1;
    _shapeRowIndex = -1;
    _scrollCellsState = [[OACollectionViewCellState alloc] init];
    _floatingTextFieldControllers = [NSMutableArray array];
}

- (void)postInit
{
    _initialName = self.name;
    _initialGroupName = self.groupTitle;

    _nameTextField = [self getInputCellWithHint:OALocalizedString(@"shared_string_name") text:(self.name ? self.name : @"") tag:0 isEditable:![_pointHandler isSpecialPoint]];
    _descTextField = [self getInputCellWithHint:OALocalizedString(@"shared_string_description") text:(self.desc ? self.desc : @"") tag:1 isEditable:YES];
    _addressTextField = [self getInputCellWithHint:OALocalizedString(@"shared_string_address") text:(self.address ? self.address : @"") tag:2 isEditable:YES];

    [self setupGroups];
    [self setupColors];
    [self setupIconHandler];
    [self setupIcons];
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
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    self.navigationController.presentationController.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self setupHeaderWithVerticalOffset:self.tableView.contentOffset.y];
}

#pragma mark - Base setup UI

- (void)applyLocalization
{
    [super applyLocalization];

    if (_subtitle)
        _subtitle.text = [self getTitle];
}

- (void)updateNavbar
{
    [super updateNavbar];
    [self setupNavbarButtons];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    if (self.name.length > 0)
    {
        return self.name;
    }
    else
    {
        if (_editPointType == EOAEditPointTypeFavorite)
            return _isNewItemAdding ? OALocalizedString(@"add_favorite") : OALocalizedString(@"ctx_mnu_edit_fav");
        else if (_editPointType == EOAEditPointTypeWaypoint)
            return _isNewItemAdding ? OALocalizedString(@"add_waypoint_short") : OALocalizedString(@"edit_waypoint_short");
    }
    return @"";
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    UIBarButtonItem *rightButton = [self createRightNavbarButton:OALocalizedString(@"shared_string_save")
                                                        iconName:nil
                                                          action:@selector(onRightNavbarButtonPressed)
                                                            menu:nil];
    rightButton.accessibilityLabel = OALocalizedString(@"shared_string_save");
    return @[rightButton];
}

- (UIImage *)getCenterIconAboveTitle
{
    return [OAFavoritesHelper getCompositeIcon:_selectedIconName
                                backgroundIcon:_backgroundIconNames[_selectedBackgroundIndex]
                                         color:[_selectedColorItem getColor]];
}

- (UIView *)createSubview
{
    _subtitle = [[UILabel alloc] init];
    _subtitle.numberOfLines = 1;
    _subtitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _subtitle.textAlignment = NSTextAlignmentCenter;
    _subtitle.adjustsFontForContentSizeCategory = YES;
    _subtitle.font = [UIFont scaledSystemFontOfSize:17 weight:UIFontWeightSemibold];
    _subtitle.text = [self getTitle];
    _subtitle.backgroundColor = UIColor.clearColor;
    return _subtitle;
}

#pragma mark - Table data

- (void)setupColors
{
    _appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
    UIColor *selectedColor;
    if (_isNewItemAdding && _editPointType == EOAEditPointTypeFavorite)
        selectedColor = [OAFavoritesHelper getGroupByName:[OAFavoriteGroup convertDisplayNameToGroupIdName:self.groupTitle]].color;
    else
        selectedColor = [_pointHandler getColor];
    if (!selectedColor)
        selectedColor = [OADefaultFavorite getDefaultColor];
    
    _selectedColorItem = [_appearanceCollection getColorItemWithValue:[selectedColor toARGBNumber]];
    _sortedColorItems = [NSMutableArray arrayWithArray:[_appearanceCollection getAvailableColorsSortingByLastUsed]];
    
    _colorCollectionHandler = [[OAColorCollectionHandler alloc] initWithData:@[_sortedColorItems] collectionView:nil];
    _colorCollectionHandler.delegate = self;
    _colorCollectionHandler.hostVC = self;
}

- (void) setupGroups
{
    NSMutableArray *names = [NSMutableArray new];
    NSMutableArray *sizes = [NSMutableArray new];
    NSMutableArray *colors = [NSMutableArray new];
    NSMutableArray *hidden = [NSMutableArray new];

    if (_editPointType == EOAEditPointTypeFavorite)
    {
        NSArray<OAFavoriteGroup *> *allGroups = [OAFavoritesHelper getFavoriteGroups];
        if (![[OAFavoritesHelper getGroups].allKeys containsObject:@""])
        {
            [names addObject:OALocalizedString(@"favorites_item")];
            [sizes addObject:@0];
            [colors addObject:[OADefaultFavorite getDefaultColor]];
            [hidden addObject:@(NO)];
        }

        for (OAFavoriteGroup *group in allGroups)
        {
            [names addObject:[OAFavoriteGroup getDisplayName:group.name]];
            [sizes addObject:@(group.points.count)];
            [colors addObject:group.color];
            [hidden addObject:@(!group.isVisible)];
        }
    }
    else if (_editPointType == EOAEditPointTypeWaypoint)
    {
        for (NSDictionary<NSString *, NSString *> *group in [(OAGpxWptEditingHandler *) _pointHandler getGroups])
        {
            [names addObject:group[@"title"]];
            [colors addObject:group[@"color"] ? [UIColor colorFromString:group[@"color"]] : [UIColor colorNamed:ACColorNameIconColorActive]];
            [sizes addObject:group[@"count"]];
        }
    }

    _groupNames = [NSArray arrayWithArray:names];
    _groupSizes = [NSArray arrayWithArray:sizes];
    _groupColors = [NSArray arrayWithArray:colors];
    _groupHidden = [NSArray arrayWithArray:hidden];
}

- (void)setupIcons
{
    NSString *preselectedIconName = [_pointHandler getIcon];
    if (!preselectedIconName)
        preselectedIconName = [self getDefaultIconName];
    _selectedIconName = preselectedIconName;
    
    OAFavoriteGroup *selectedGroup = [OAFavoritesHelper getGroupByName:self.groupTitle];
    if (_isNewItemAdding && selectedGroup)
        _selectedIconName = selectedGroup.iconName;
    else if (!_selectedIconName || _selectedIconName.length == 0)
        _selectedIconName = DEFAULT_ICON_NAME_KEY;
    [_poiIconCollectionHandler setIconName:_selectedIconName];
    
    _backgroundIconNames = [OAFavoritesHelper getFlatBackgroundIconNamesList];
    _backgroundContourIconNames = [OAFavoritesHelper getFlatBackgroundContourIconNamesList];

    NSMutableArray * tempBackgroundIcons = [NSMutableArray new];
    for (NSString *iconName in _backgroundIconNames)
        [tempBackgroundIcons addObject:[NSString stringWithFormat:@"bg_point_%@", iconName]];

    _backgroundIcons = [NSArray arrayWithArray:tempBackgroundIcons];

    _selectedBackgroundIndex = [_backgroundIconNames indexOfObject:_isNewItemAdding && selectedGroup ? selectedGroup.backgroundType : [_pointHandler getBackgroundIcon]];
    if (_selectedBackgroundIndex == -1 || _selectedBackgroundIndex >= _backgroundIconNames.count)
        _selectedBackgroundIndex = 0;
}

- (void) setupIconHandler
{
    _poiIconCollectionHandler = [[PoiIconCollectionHandler alloc] init];
    _poiIconCollectionHandler.delegate = self;
    _poiIconCollectionHandler.hostVC = self;
    _poiIconCollectionHandler.customTitle = OALocalizedString(@"profile_icon");
    _poiIconCollectionHandler.regularIconColor = [UIColor colorNamed:ACColorNameIconColorSecondary];
    _poiIconCollectionHandler.selectedIconColor = [_selectedColorItem getColor];
    [_poiIconCollectionHandler setItemSizeWithSize:48];
    [_poiIconCollectionHandler setIconBackgroundSizeWithSize:36];
    [_poiIconCollectionHandler setIconSizeWithSize:24];
    [_poiIconCollectionHandler setSpacingWithSpacing:6];
}

- (void)generateData
{
    NSMutableArray *data = [NSMutableArray new];

    if (self.groupTitle.length == 0)
        self.groupTitle = [self getGroupTitle];

    NSMutableArray *section = [NSMutableArray new];
    [section addObject:@{
        @"header" : OALocalizedString(@"name_and_descr"),
        @"type" : [OATextInputFloatingCell getCellIdentifier],
        @"key" : kNameKey,
        @"cell" : _nameTextField
    }];
    [section addObject:@{
        @"type" : [OATextInputFloatingCell getCellIdentifier],
        @"key" : kDescKey,
        @"cell" : _descTextField
    }];
    [section addObject:@{
        @"type" : [OATextInputFloatingCell getCellIdentifier],
        @"key" : kAddressKey,
        @"cell" : _addressTextField
    }];
    [data addObject:[NSArray arrayWithArray:section]];

    section = [NSMutableArray new];
    [section addObject:@{
        @"header" : OALocalizedString(@"fav_group"),
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"select_group"),
        @"value" : self.groupTitle ? self.groupTitle : @"",
        @"key" : kSelectGroupKey
    }];
    _selectCategoryLabelRowIndex = section.count -1;

    NSUInteger selectedGroupIndex = [_groupNames indexOfObject:self.groupTitle];
    if (selectedGroupIndex < 0)
        selectedGroupIndex = 0;
    [section addObject:@{
        @"type" : [OAFolderCardsCell getCellIdentifier],
        @"selectedValue" : @(selectedGroupIndex),
        @"values" : _groupNames,
        @"sizes" : _groupSizes,
        @"colors" : _groupColors,
        @"hidden" : _groupHidden,
        @"addButtonTitle" : OALocalizedString(@"add_group")
    }];
    _selectCategoryCardsRowIndex = section.count - 1;
    
    _selectCategoryDescriptionRowIndex = -1;
    if (_groupHidden.count > selectedGroupIndex)
    {
        BOOL selectedGroupHidden = _groupHidden[selectedGroupIndex].boolValue;
        if (selectedGroupHidden)
        {
            [section addObject:@{
                @"type" : [OASimpleTableViewCell getCellIdentifier],
                @"title" : [NSString stringWithFormat:OALocalizedString(@"add_hidden_group_info"), OALocalizedString(@"shared_string_my_places")],
                @"key" : kSelectGroupDescKey
            }];
            _selectCategoryDescriptionRowIndex = section.count - 1;
        }
    }

    [data addObject:[NSArray arrayWithArray:section]];
    _selectCategorySectionIndex = data.count - 1;

    section = [NSMutableArray new];
    [section addObject:@{
        @"header" : OALocalizedString(@"shared_string_appearance"),
        @"type" : [OAIconsPaletteCell getCellIdentifier],
        @"title" : OALocalizedString(@"shared_string_icon"),
        @"descr" : OALocalizedString(@"shared_string_all_icons"),
        @"key" : kIconsKey
    }];
    _poiIconRowIndex = section.count - 1;
    
    [section addObject:@{
        @"key" : @"color_cell",
        @"type" : [OAColorsPaletteCell getCellIdentifier],
        @"title" : OALocalizedString(@"shared_string_coloring"),
        @"descr" : OALocalizedString(@"shared_string_all_colors")
    }];
    _allColorsRowIndex = section.count - 1;

    [section addObject:@{
        @"type" : [OAShapesTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"shared_string_shape"),
        @"value" : OALocalizedString([NSString stringWithFormat:@"shared_string_%@", _backgroundIconNames[_selectedBackgroundIndex]]),
        @"index" : @(_selectedBackgroundIndex),
        @"icons" : _backgroundIcons,
        @"contourIcons" : _backgroundContourIconNames,
        @"key" : kBackgroundsKey
    }];
    _shapeRowIndex = section.count - 1;

    [data addObject:[NSArray arrayWithArray:section]];
    _appearenceSectionIndex = data.count - 1;

    section = [NSMutableArray new];
    [section addObject:@{
        @"header" : OALocalizedString(@"shared_string_actions").upperCase,
        @"type" : [OARightIconTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"update_existing"),
        @"img" : @"ic_custom_replace",
        @"color" : [UIColor colorNamed:ACColorNameIconColorActive],
        @"key" : kReplaceKey
    }];
    _replaceIndexPath = [NSIndexPath indexPathForRow:section.count - 1 inSection:section.count];
    if (!_isNewItemAdding)
    {
        [section addObject:@{
            @"type" : [OARightIconTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"shared_string_delete"),
            @"img" : @"ic_custom_remove_outlined",
            @"color" : [UIColor colorNamed:ACColorNameButtonBgColorDisruptive],
            @"key" : kDeleteKey
        }];
    }
    [data addObject:[NSArray arrayWithArray:section]];

    _data = [NSArray arrayWithArray:data];
}

- (OATextInputFloatingCell *) getInputCellWithHint:(NSString *)hint text:(NSString *)text tag:(NSInteger)tag isEditable:(BOOL)isEditable
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
    textField.adjustsFontForContentSizeCategory = YES;
    textField.clearButton.imageView.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
    [textField.clearButton setImage:[UIImage templateImageNamed:@"ic_custom_clear_field.png"] forState:UIControlStateNormal];
    [textField.clearButton setImage:[UIImage templateImageNamed:@"ic_custom_clear_field.png"] forState:UIControlStateHighlighted];

    if (!_floatingTextFieldControllers)
        _floatingTextFieldControllers = [NSMutableArray new];
    MDCTextInputControllerUnderline *fieldController = [[MDCTextInputControllerUnderline alloc] initWithTextInput:textField];
    fieldController.inlinePlaceholderFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCallout];
    fieldController.inlinePlaceholderColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
    [fieldController setFloatingPlaceholderNormalColor:[UIColor colorNamed:ACColorNameTextColorSecondary]];
    fieldController.floatingPlaceholderActiveColor = fieldController.floatingPlaceholderNormalColor;
    fieldController.floatingPlaceholderNormalColor = fieldController.floatingPlaceholderNormalColor;
    fieldController.textInput.textInsetsMode = MDCTextInputTextInsetsModeIfContent;
    [_floatingTextFieldControllers addObject:fieldController];
    return resultCell;
}

- (NSString *)getGroupTitle
{
    return _isNewItemAdding && _editPointType == EOAEditPointTypeFavorite
        ? [OAFavoriteGroup getDisplayName:[[OAAppSettings sharedManager].lastFavCategoryEntered get]]
        : [_pointHandler getGroupTitle];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    NSDictionary *item = _data[section].firstObject;
    return ((NSString *) item[@"header"]).uppercaseString;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    
    if ([cellType isEqualToString:[OATextInputFloatingCell getCellIdentifier]])
    {
        return item[@"cell"];
    }
    else if ([cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        if (cell)
        {
            BOOL isCartegoryLabel = indexPath.row == _selectCategoryLabelRowIndex && indexPath.section == _selectCategorySectionIndex;
            [cell setCustomLeftSeparatorInset:isCartegoryLabel];
            if (isCartegoryLabel)
                cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);

            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = item[@"value"];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            [cell titleVisibility:NO];
            [cell leftIconVisibility:NO];
            [cell leftEditButtonVisibility:NO];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:YES];
            [cell hideTopSpace];
            cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.descriptionLabel.text = item[@"title"];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAIconsPaletteCell getCellIdentifier]])
    {
        OAIconsPaletteCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAIconsPaletteCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconsPaletteCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.useMultyLines = NO;
            cell.forceScrollOnStart = YES;
            cell.disableAnimationsOnStart = YES;
            cell.topLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.topLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
        }
        cell.hostVC = self;
        _poiIconCollectionHandler.selectedIconColor = [_selectedColorItem getColor];
        [_poiIconCollectionHandler setCollectionView:cell.collectionView];
        [cell setCollectionHandler:_poiIconCollectionHandler];
        [_poiIconCollectionHandler updateTopButtonName];
        cell.topLabel.text = item[@"title"];
        [cell topButtonVisibility:YES];
        [cell.bottomButton setTitle:item[@"descr"] forState:UIControlStateNormal];
        cell.collectionView.contentInset = UIEdgeInsetsMake(0, 20, 0, 20);
        [cell.collectionView reloadData];
        [cell layoutIfNeeded];
        return cell;
    }
    else if ([cellType isEqualToString:[OAShapesTableViewCell getCellIdentifier]])
    {
        OAShapesTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAShapesTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAShapesTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.delegate = self;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsZero;
        }
        if (cell)
        {
            int selectedIndex = [item[@"index"] intValue];
            cell.iconNames = item[@"icons"];
            cell.contourIconNames = item[@"contourIcons"];
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = item[@"value"];
            cell.valueLabel.hidden = NO;
            cell.currentColor = _selectedColorItem.value;
            cell.currentIcon = selectedIndex;
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.titleLabel.textColor = item[@"color"];
            cell.rightIconView.image = [UIImage templateImageNamed:item[@"img"]];
            cell.rightIconView.tintColor = item[@"color"];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAFolderCardsCell getCellIdentifier]])
    {
        OAFolderCardsCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAFolderCardsCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFolderCardsCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
            cell.cellIndex = indexPath;
            cell.state = _scrollCellsState;
            cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
        }
        if (cell)
        {
            [cell setValues:item[@"values"] sizes:item[@"sizes"] colors:item[@"colors"] hidden:item[@"hidden"] addButtonTitle:item[@"addButtonTitle"] withSelectedIndex:[item[@"selectedValue"] intValue]];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAColorsPaletteCell getCellIdentifier]])
    {
        OAColorsPaletteCell *cell = _colorsPaletteCell;
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAColorsPaletteCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.disableAnimationsOnStart = YES;
            [_colorCollectionHandler setCollectionView:cell.collectionView];
            [cell setCollectionHandler:_colorCollectionHandler];
            _colorCollectionHandler.hostVCOpenColorPickerButton = cell.rightActionButton;
            cell.hostVC = self;
            _colorsPaletteCell = cell;
        }
        if (cell)
        {
            cell.topLabel.text = item[@"title"];
            [cell.bottomButton setTitle:item[@"descr"] forState:UIControlStateNormal];
            [cell.rightActionButton setImage:[UIImage templateImageNamed:@"ic_custom_add"] forState:UIControlStateNormal];
            cell.rightActionButton.tag = indexPath.section << 10 | indexPath.row;
            NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:_selectedColorItem] inSection:0];
            if (selectedIndexPath.row == NSNotFound)
                selectedIndexPath = [NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:[_appearanceCollection getDefaultPointColorItem]] inSection:0];
            [_colorCollectionHandler setSelectedIndexPath:selectedIndexPath];
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
            
            if (_needToScrollToSelectedColor)
            {
                NSIndexPath *selectedIndexPath = [[cell getCollectionHandler] getSelectedIndexPath];
                if (selectedIndexPath.row != NSNotFound && ![cell.collectionView.indexPathsForVisibleItems containsObject:selectedIndexPath])
                {
                    [cell.collectionView scrollToItemAtIndexPath:selectedIndexPath
                                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                        animated:YES];
                }
                _needToScrollToSelectedColor = NO;
            }
        }
        return cell;
    }

    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
 {
     NSDictionary *item = _data[indexPath.section][indexPath.row];
     NSString *type = item[@"type"];
     if ([type isEqualToString:[OAFolderCardsCell getCellIdentifier]])
     {
         OAFolderCardsCell *folderCell = (OAFolderCardsCell *)cell;
         [folderCell updateContentOffset];
     }
 }

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    
    if ([key isEqualToString:kNameKey] || [key isEqualToString:kDescKey] || [key isEqualToString:kAddressKey])
    {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if ([cell canBecomeFirstResponder])
            [cell becomeFirstResponder];
    }
    else if ([key isEqualToString:kSelectGroupKey])
    {
        OASelectFavoriteGroupViewController *selectGroupController;
        if (_editPointType == EOAEditPointTypeFavorite)
            selectGroupController = [[OASelectFavoriteGroupViewController alloc] initWithSelectedGroupName:self.groupTitle];
        else if (_editPointType == EOAEditPointTypeWaypoint)
            selectGroupController = [[OASelectFavoriteGroupViewController alloc] initWithSelectedGroupName:self.groupTitle gpxWptGroups:[(OAGpxWptEditingHandler *)_pointHandler getGroups]];

        selectGroupController.delegate = self;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:selectGroupController];
        [self presentViewController:navigationController animated:YES completion:nil];
    }
    else if ([key isEqualToString:kReplaceKey])
    {
        OAReplaceFavoriteViewController *replaceScreen;
        if (_editPointType == EOAEditPointTypeFavorite)
        {
            if ([OAFavoritesHelper getFavoriteItems].count > 0)
                replaceScreen = [[OAReplaceFavoriteViewController alloc] initWithItemType:EOAReplacePointTypeFavorite gpxDocument:nil];
            else
                return [self showAlertNotFoundReplaceItem];
        }
        else if (_editPointType == EOAEditPointTypeWaypoint)
        {
            OASGpxFile *gpxDocument = [(OAGpxWptEditingHandler *)_pointHandler getGpxDocument];
            if (gpxDocument.getPointsList.count > 0)
                replaceScreen = [[OAReplaceFavoriteViewController alloc] initWithItemType:EOAReplacePointTypeWaypoint gpxDocument:gpxDocument];
            else
                return [self showAlertNotFoundReplaceItem];
        }

        replaceScreen.delegate = self;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:replaceScreen];
        [self presentViewController:navigationController animated:YES completion:nil];
    }
    else if ([key isEqualToString:kDeleteKey])
    {
        [self deleteItemWithAlertView];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OATextInputFloatingCell getCellIdentifier]])
    {
        OATextInputFloatingCell *cell = item[@"cell"];
        return MAX(cell.inputField.intrinsicContentSize.height, 60.0);
    }
    return UITableViewAutomaticDimension;
}

- (NSIndexPath *)indexPathForCellContainingView:(UIView *)view inTableView:(UITableView *)tableView
{
    CGPoint viewCenterRelativeToTableview = [tableView convertPoint:CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds)) fromView:view];
    NSIndexPath *cellIndexPath = [tableView indexPathForRowAtPoint:viewCenterRelativeToTableview];
    return cellIndexPath;
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (BOOL)presentationControllerShouldDismiss:(UIPresentationController *)presentationController
{
    return NO;
}

- (void)presentationControllerDidAttemptToDismiss:(UIPresentationController *)presentationController
{
    [self dismissViewController];
}

#pragma mark - Actions

- (void)dismissViewController
{
    if (_isUnsaved)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"shared_string_dismiss") message:OALocalizedString(@"exit_without_saving") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleDefault handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_exit") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (_isNewItemAdding)
                [_pointHandler deleteItem];
            [self doDismiss];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        if (_isNewItemAdding && _editPointType == EOAEditPointTypeFavorite)
            [[OARootViewController instance].mapPanel openTargetViewWithFavorite:((OAFavoriteEditingHandler *)_pointHandler).getFavoriteItem pushed:NO];
        [self doDismiss];
    }
}

- (void)doDismiss
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (_renamedPointAlertMessage)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"fav_point_dublicate") message:_renamedPointAlertMessage preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
            [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
        }
        if (_targetMenuState && [_targetMenuState isKindOfClass:OATrackMenuViewControllerState.class])
        {
            OATrackMenuViewControllerState *state = (OATrackMenuViewControllerState *) _targetMenuState;
            state.openedFromTrackMenu = NO;
            OAGPXDatabase *db = [OAGPXDatabase sharedDb];
            auto gpx = [db getGPXItem:[
                [db getFileDir:self.gpxFileName] stringByAppendingPathComponent:self.gpxFileName.lastPathComponent]];
            if (gpx)
            {
                auto trackItem = [[OASTrackItem alloc] initWithFile:gpx.file];
                trackItem.dataItem = gpx;
                [[OARootViewController instance].mapPanel openTargetViewWithGPX:trackItem
                                                                   trackHudMode:EOATrackMenuHudMode
                                                                          state:state];
            }
            else
            {
                auto currentTrack = [OASavingTrackHelper sharedInstance].currentTrack;
                if (currentTrack)
                {
                    auto trackItem = [[OASTrackItem alloc] initWithGpxFile:currentTrack];
                    if (trackItem)
                    {
                        [[OARootViewController instance].mapPanel openTargetViewWithGPX:trackItem
                                                                           trackHudMode:EOATrackMenuHudMode
                                                                                  state:state];
                    }
                }
            }
        }
    }];
}

#pragma mark - Selectors

- (void)onContentSizeChanged:(NSNotification *)notification
{
    _originalSubviewHeight = [OAUtilities calculateTextBounds:[self getTitle]
                                                        width:DeviceScreenWidth - (20. + [OAUtilities getLeftMargin]) * 2
                                                         font:[UIFont scaledSystemFontOfSize:17 weight:UIFontWeightSemibold]].height + kSubviewVerticalOffset;
    [self setupHeaderWithVerticalOffset:self.tableView.contentOffset.y];
}

- (void)onRightNavbarButtonPressed
{
    _isUnsaved = NO;
    if (_wasChanged || _isNewItemAdding)
    {
        OAPointEditingData *data = [[OAPointEditingData alloc] init];
        NSString *savingGroup = [[OAFavoriteGroup convertDisplayNameToGroupIdName:self.groupTitle] trim];
        
        data.descr = self.desc ? self.desc : @"";
        data.address = self.address ? self.address : @"";
        data.color = [_selectedColorItem getColor];
        data.backgroundIcon = _backgroundIconNames[_selectedBackgroundIndex];
        data.icon = _selectedIconName;
        [_poiIconCollectionHandler addIconToLastUsed:_selectedIconName];

        if (_editPointType == EOAEditPointTypeWaypoint)
        {
            if (!_pointHandler.gpxWptDelegate)
                _pointHandler.gpxWptDelegate = self.gpxWptDelegate;
            if ([savingGroup isEqualToString:OALocalizedString(@"shared_string_waypoints")])
                savingGroup = @"";
        }

        if (_isNewItemAdding || ![self.name isEqualToString:_initialName] || ([self.name isEqualToString:_initialName] && ![self.groupTitle isEqualToString:_initialGroupName]))
        {
            NSString *savingName = [self.name trim];
            NSDictionary *checkingResult = [_pointHandler checkDuplicates:savingName group:savingGroup];
            
            if (checkingResult && ![checkingResult[@"name"] isEqualToString:self.name])
            {
                savingName = checkingResult[@"name"];
                if ([checkingResult[@"status"] isEqualToString:@"duplicate"])
                    _renamedPointAlertMessage = [NSString stringWithFormat:OALocalizedString(@"fav_point_dublicate_message"), savingName];
            }

            data.name = savingName;
            data.category = savingGroup;

            [_pointHandler savePoint:data newPoint:_isNewItemAdding];
        }
        else
        {
            NSString *savingName = [_pointHandler isSpecialPoint] ? [_pointHandler getName] : self.name;
            savingName = [savingName trim];
            data.name = savingName;
            data.category = savingGroup;
            [_pointHandler savePoint:data newPoint:NO];
        }
        if (_editPointType == EOAEditPointTypeFavorite)
            [OAAppSettings.sharedManager.lastFavCategoryEntered set:savingGroup];
    }
    [self dismissViewController];
}

- (void)onScrollViewDidScroll:(UIScrollView *)scrollView
{
    [self setupHeaderWithVerticalOffset:scrollView.contentOffset.y];
}

- (void)clearButtonPressed:(UIButton *)sender
{
    NSIndexPath *indexPath = [self indexPathForCellContainingView:sender inTableView:self.tableView];
    OATextInputFloatingCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self.tableView beginUpdates];
    
    cell.inputField.text = @"";
    
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    if ([key isEqualToString:kNameKey])
        self.name = @"";
    else if ([key isEqualToString:kDescKey])
        self.desc = @"";
    else if ([key isEqualToString:kAddressKey])
        self.address = @"";
    
    [self applyLocalization];
    [self generateData];
    [self.tableView endUpdates];
}

#pragma mark - UITextViewDelegate

- (void)textChanged:(UITextView * _Nonnull)textView userInput:(BOOL)userInput
{
    _wasChanged = YES;
    NSIndexPath *indexPath = [self indexPathForCellContainingView:textView inTableView:self.tableView];
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    if ([key isEqualToString:kNameKey])
        self.name = textView.text;
    else if ([key isEqualToString:kDescKey])
        self.desc = textView.text;
    else if ([key isEqualToString:kAddressKey])
        self.address = textView.text;

    [self applyLocalization];
    [self generateData];
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self textChanged:textView userInput:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    return YES;
}

#pragma mark - MDCMultilineTextInputLayoutDelegate

- (void)multilineTextField:(id<MDCMultilineTextInput> _Nonnull)multilineTextField didChangeContentSize:(CGSize)size
{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)onPoiSelected:(NSString *)poiName;
{
    _wasChanged = YES;
    _selectedIconName = poiName;
    [self applyLocalization];
}

#pragma mark - OAShapesTableViewCellDelegate

- (void)iconChanged:(NSInteger)tag
{
    _wasChanged = YES;
    _selectedBackgroundIndex = (int)tag;
    [self applyLocalization];
    [self generateData];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_shapeRowIndex inSection:_appearenceSectionIndex]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - OAFolderCardsCellDelegate

- (void)onItemSelected:(NSInteger)index
{
    [self onGroupChanged:_groupNames[index]];
}

- (void)onAddFolderButtonPressed
{
    OAFavoriteGroupEditorViewController *groupEditor = [[OAFavoriteGroupEditorViewController alloc] initWithNew];
    groupEditor.delegate = self;
    [self showModalViewController:groupEditor];
}

#pragma mark - OASelectFavoriteGroupDelegate

- (void)onGroupSelected:(NSString *)selectedGroupName
{
    [self onGroupChanged:selectedGroupName];
    NSIndexPath *groupsIndexPath = [NSIndexPath indexPathForRow:_selectCategoryCardsRowIndex inSection:_selectCategorySectionIndex];
    OAFolderCardsCell *colorCell = [self.tableView cellForRowAtIndexPath:groupsIndexPath];
    NSInteger selectedIndex = [_groupNames indexOfObject:selectedGroupName];
    [colorCell setSelectedIndex:selectedIndex];

    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:selectedIndex inSection:0];
    if (selectedIndexPath.row != NSNotFound && ![colorCell.collectionView.indexPathsForVisibleItems containsObject:selectedIndexPath])
    {
        [colorCell.collectionView scrollToItemAtIndexPath:selectedIndexPath
                                    atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                            animated:NO];
    }
}

- (void)addNewGroupWithName:(NSString *)name
                   iconName:(NSString *)iconName
                      color:(UIColor *)color
         backgroundIconName:(NSString *)backgroundIconName
{
    [self addGroupWithName:name iconName:iconName color:color backgroundIconName:backgroundIconName];
}

- (void)addGroupWithName:(NSString *)name
                iconName:(NSString *)iconName
                   color:(UIColor *)color
      backgroundIconName:(NSString *)backgroundIconName
{
    _wasChanged = YES;
    NSString *editedGroupName = [name trim];

    if (_editPointType == EOAEditPointTypeFavorite)
    {
        [OAFavoritesHelper addFavoriteGroup:editedGroupName
                                      color:color
                                   iconName:iconName
                         backgroundIconName:backgroundIconName];
    }
    else if (_editPointType == EOAEditPointTypeWaypoint)
    {
        if (!_pointHandler.gpxWptDelegate)
            _pointHandler.gpxWptDelegate = self.gpxWptDelegate;
        [((OAGpxWptEditingHandler *) _pointHandler) setGroup:editedGroupName color:color save:YES];
    }
    _selectedColorItem = [_appearanceCollection getColorItemWithValue:[color toARGBNumber]];
    _selectedBackgroundIndex = [_backgroundIconNames indexOfObject:backgroundIconName];
    
    _selectedIconName = iconName;
    [_poiIconCollectionHandler setIconName:iconName];
    [self onPoiSelected:iconName];

    self.groupTitle = editedGroupName;
    _needToScrollToSelectedColor = YES;
    [self setupGroups];

    [self updateUIAnimated:^(BOOL finished) {
        NSIndexPath *groupsIndexPath = [NSIndexPath indexPathForRow:_selectCategoryCardsRowIndex inSection:_selectCategorySectionIndex];
        OAFolderCardsCell *groupCell = [self.tableView cellForRowAtIndexPath:groupsIndexPath];
        [UIView transitionWithView:groupCell.collectionView
                          duration:.2
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^(void)
                        {
                            [groupCell.collectionView reloadData];
                        }
                        completion:^(BOOL finished)
         {
            NSInteger selectedIndex = [_groupNames indexOfObject:editedGroupName];
            NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:selectedIndex inSection:0];
            if (selectedIndexPath.row != NSNotFound
                && ![groupCell.collectionView.indexPathsForVisibleItems containsObject:selectedIndexPath]
                && [groupCell.collectionView numberOfItemsInSection:selectedIndexPath.section] > selectedIndex)
            {
                [groupCell.collectionView scrollToItemAtIndexPath:selectedIndexPath
                                                 atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                         animated:NO];
            }
        }];
    }];
}

#pragma mark - OAReplacePointDelegate

- (void)onFavoriteReplaced:(OAFavoriteItem *)favoriteItem;
{
    NSString *message = [NSString stringWithFormat:OALocalizedString(@"replace_favorite_confirmation"), [favoriteItem getDisplayName]];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"update_existing") message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_no") style:UIAlertActionStyleDefault handler:nil]];
    
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        OAPointEditingData *data = [[OAPointEditingData alloc] init];
        
        data.descr = [favoriteItem getDescription];
        data.address = [favoriteItem getAddress];
        data.color = [favoriteItem getColor];
        data.backgroundIcon = [favoriteItem getBackgroundIcon];
        data.icon = [favoriteItem getIcon];
        data.category = [favoriteItem getCategory];
        data.name = [favoriteItem getName];

        [OAFavoritesHelper deleteNewFavoriteItem:favoriteItem];
        [_pointHandler savePoint:data newPoint:_isNewItemAdding];
        [self dismissViewController];
    }]];
    
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onWaypointReplaced:(OAGpxWptItem *)waypointItem
{
    NSString *message = [NSString stringWithFormat:OALocalizedString(@"replace_waypoint_confirmation"), waypointItem.point.name];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"update_existing") message:message preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_no") style:UIAlertActionStyleDefault handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

        OAPointEditingData *data = [[OAPointEditingData alloc] init];

        data.descr = waypointItem.point.desc;
        data.address = [waypointItem.point getAddress];
        data.color = waypointItem.color ? waypointItem.color : UIColorFromARGB([waypointItem.point getColor]);
        data.backgroundIcon = [waypointItem.point getBackgroundType];
        data.icon = [waypointItem.point getIconName];
        data.category = waypointItem.point.category;
        data.name = waypointItem.point.name;

        if (_editPointType == EOAEditPointTypeWaypoint && !_pointHandler.gpxWptDelegate)
            _pointHandler.gpxWptDelegate = self.gpxWptDelegate;

        if (self.gpxWptDelegate)
            [self.gpxWptDelegate deleteGpxWpt:waypointItem docPath:[(OAGpxWptEditingHandler *)_pointHandler getGpxDocument].path];

        [_pointHandler savePoint:data newPoint:_isNewItemAdding];
        [self dismissViewController];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
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
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardHeight, insets.right)];
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
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0., insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

#pragma mark - OACollectionCellDelegate

- (void)onCollectionItemSelected:(NSIndexPath *)indexPath selectedItem:(id)selectedItem collectionView:(UICollectionView *)collectionView shouldDismiss:(BOOL)shouldDismiss
{
    if (collectionView == [_poiIconCollectionHandler getCollectionView])
    {
        NSString *iconName = [_poiIconCollectionHandler getSelectedItem];
        if (iconName)
            _selectedIconName = iconName;
    }
    else if (collectionView == [_colorCollectionHandler getCollectionView])
    {
        _isNewColorSelected = YES;
        _needToScrollToSelectedColor = YES;
        _selectedColorItem = [_colorCollectionHandler getData][indexPath.section][indexPath.row];
    }
    
    _wasChanged = YES;
    [self applyLocalization];
    [self generateData];
    
    if (collectionView == [_colorCollectionHandler getCollectionView])
    {
        _poiIconCollectionHandler.selectedIconColor = [_selectedColorItem getColor];
        [[_poiIconCollectionHandler getCollectionView] reloadData];
        
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_shapeRowIndex inSection:_appearenceSectionIndex]] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)reloadCollectionData
{
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_allColorsRowIndex inSection:_appearenceSectionIndex]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Additions

- (void)setupHeaderWithVerticalOffset:(CGFloat)offset
{
    CGFloat y = offset + [self getOriginalNavbarHeight] + _originalSubviewHeight;
    CGFloat subviewHeight = 0.;
    CGFloat multiplier = 0;
    if ([self isModal])
        y -= [OAUtilities getTopMargin];

    if (y <= 0)
    {
        multiplier = 1;
        subviewHeight = _originalSubviewHeight;
    }
    else if (y > 0 && y < _originalSubviewHeight)
    {
        multiplier = y < 0 ? 0 : 1 - (y / _originalSubviewHeight);
        subviewHeight = _originalSubviewHeight * multiplier;
    }
    else
    {
        multiplier = 0;
        subviewHeight = 0;
    }
    _subtitle.font = [UIFont scaledSystemFontOfSize:17 * multiplier weight:UIFontWeightSemibold];
    _subtitle.alpha = multiplier;
    _subtitle.hidden = NO;

    [self updateSubviewHeight:subviewHeight];
}

- (NSString *)getPreselectedIconName
{
    return (!_pointHandler || !_isNewItemAdding) ? nil : [_pointHandler getIcon];
}

- (NSString *)getDefaultIconName
{
    NSString *preselectedIconName = [self getPreselectedIconName];
    if (preselectedIconName && preselectedIconName.length > 0)
        return preselectedIconName;
    else if (_poiIconCollectionHandler.lastUsedIcons && _poiIconCollectionHandler.lastUsedIcons.count > 0)
        return _poiIconCollectionHandler.lastUsedIcons[0];
    return DEFAULT_ICON_NAME_KEY;
}

- (void)deleteItemWithAlertView
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"fav_remove_q") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_no") style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (_editPointType == EOAEditPointTypeWaypoint && !_pointHandler.gpxWptDelegate)
            _pointHandler.gpxWptDelegate = self.gpxWptDelegate;
        [_pointHandler deleteItem:_isNewItemAdding];
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onGroupChanged:(NSString *)groupName
{
    _wasChanged = YES;
    self.groupTitle = groupName;

    NSInteger prevSelectCategoryDescriptionRowIndex = _selectCategoryDescriptionRowIndex;
    if (_editPointType == EOAEditPointTypeFavorite)
    {
        groupName = [OAFavoriteGroup convertDisplayNameToGroupIdName:self.groupTitle];
        OAFavoriteGroup *group = [OAFavoritesHelper getGroupByName:groupName];
        if (group)
        {
            _selectedColorItem = [_appearanceCollection getColorItemWithValue:[group.color toARGBNumber]];
            _selectedIconName = group.iconName;
            _selectedBackgroundIndex = [_backgroundIconNames indexOfObject:group.backgroundType];
        }
    }
    else if (_editPointType == EOAEditPointTypeWaypoint)
    {
        _selectedColorItem = [_appearanceCollection getColorItemWithValue:[UIColor toNumberFromString:[(OAGpxWptEditingHandler *) _pointHandler getGroupsWithColors][groupName]]];
    }

    if ([self.groupTitle isEqualToString:@""])
        self.groupTitle = OALocalizedString(@"favorites_item");
    [self applyLocalization];
    [self generateData];
    NSInteger selectCategoryDescriptionRowIndex = _selectCategoryDescriptionRowIndex;

    _needToScrollToSelectedColor = YES;
    [self.tableView beginUpdates];
    if (prevSelectCategoryDescriptionRowIndex != selectCategoryDescriptionRowIndex)
    {
        if (prevSelectCategoryDescriptionRowIndex == -1)
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:selectCategoryDescriptionRowIndex inSection:_selectCategorySectionIndex]] withRowAnimation:UITableViewRowAnimationNone];
        else
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:prevSelectCategoryDescriptionRowIndex inSection:_selectCategorySectionIndex]] withRowAnimation:UITableViewRowAnimationNone];
    }
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_selectCategoryLabelRowIndex inSection:_selectCategorySectionIndex],
                                             [NSIndexPath indexPathForRow:_poiIconRowIndex inSection:_appearenceSectionIndex],
                                             [NSIndexPath indexPathForRow:_allColorsRowIndex inSection:_appearenceSectionIndex],
                                             [NSIndexPath indexPathForRow:_shapeRowIndex inSection:_appearenceSectionIndex]]
                          withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)showAlertNotFoundReplaceItem
{
    NSString *message = @"";
    if (_editPointType == EOAEditPointTypeFavorite)
        message = OALocalizedString(@"fav_points_not_exist");
    else if (_editPointType == EOAEditPointTypeWaypoint)
        message = OALocalizedString(@"no_waypoints_found");

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];

    UIPopoverPresentationController *popPresenter = alert.popoverPresentationController;
    popPresenter.sourceView = self.view;
    popPresenter.sourceRect = [self.tableView rectForRowAtIndexPath:_replaceIndexPath];
    popPresenter.permittedArrowDirections = UIPopoverArrowDirectionUp;

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - OAEditorDelegate

- (void)addNewItemWithName:(NSString *)name
                  iconName:(NSString *)iconName
                     color:(UIColor *)color
        backgroundIconName:(NSString *)backgroundIconName;
{
    [self addGroupWithName:name
                  iconName:iconName
                     color:color
        backgroundIconName:backgroundIconName];
}

- (void)onEditorUpdated
{
}

@end
