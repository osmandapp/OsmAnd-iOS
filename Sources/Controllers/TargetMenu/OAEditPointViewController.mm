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
#import "OAPoiTableViewCell.h"
#import "OASelectFavoriteGroupViewController.h"
#import "OAReplaceFavoriteViewController.h"
#import "OAFolderCardsCell.h"
#import "OAFavoritesHelper.h"
#import "OAFavoriteItem.h"
#import "OAGpxWptItem.h"
#import "OAGPXDocumentPrimitives.h"
#import "OARootViewController.h"
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
#import "OACollectionSingleLineTableViewCell.h"
#import "OAGPXAppearanceCollection.h"
#import "OAColorCollectionHandler.h"
#import "OAColorCollectionViewController.h"
#import "OAGPXDocument.h"
#import "OATargetMenuViewController.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#define kNameKey @"kNameKey"
#define kDescKey @"kDescKey"
#define kAddressKey @"kAddressKeyd"
#define kIconsKey @"kIconsKey"
#define kBackgroundsKey @"kBackgroundsKey"
#define kSelectGroupKey @"kSelectGroupKey"
#define kReplaceKey @"kReplaceKey"
#define kDeleteKey @"kDeleteKey"
#define kLastUsedIconsKey @"kLastUsedIconsKey"

#define kCategoryCellIndex 0
#define kPoiCellIndex 1
#define kLastUsedIconsLimit 20

#define kSubviewVerticalOffset 8.

@interface OAEditPointViewController() <UITextFieldDelegate, UITextViewDelegate, OAPoiTableViewCellDelegate, OAShapesTableViewCellDelegate, MDCMultilineTextInputLayoutDelegate, OAReplacePointDelegate, OAFolderCardsCellDelegate, OASelectFavoriteGroupDelegate, UIAdaptivePresentationControllerDelegate, UIColorPickerViewControllerDelegate, OAColorsCollectionCellDelegate, OAColorCollectionDelegate, OACollectionTableViewCellDelegate, OAEditorDelegate>

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
    MutableOrderedDictionary<NSString *, NSArray<NSString *> *> *_iconCategories;
    NSArray<NSString *> *_currentCategoryIcons;
    
    NSArray *_poiCategories;
    NSArray<NSString *> *_lastUsedIcons;
    NSArray<NSString *> *_backgroundIcons;
    NSArray<NSString *> *_backgroundIconNames;
    NSArray<NSString *> *_backgroundContourIconNames;
    
    NSArray<NSString *> *_groupNames;
    NSArray<NSNumber *> *_groupSizes;
    NSArray<UIColor *> *_groupColors;
    NSString *_selectedIconCategoryName;
    NSString *_selectedIconName;
    NSInteger _selectedBackgroundIndex;
    
    NSInteger _selectCategorySectionIndex;
    NSInteger _selectCategoryLabelRowIndex;
    NSInteger _selectCategoryCardsRowIndex;
    NSInteger _appearenceSectionIndex;
    NSInteger _poiIconRowIndex;
    NSInteger _colorLabelRowIndex;
    NSInteger _colorRowIndex;
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

    OAGPXAppearanceCollection *_appearanceCollection;
    NSMutableArray<OAColorItem *> *_sortedColorItems;
    OAColorItem *_selectedColorItem;
    NSIndexPath *_editColorIndexPath;
    BOOL _isNewColorSelected;
    BOOL _needToScrollToSelectedColor;

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
        self.address = [gpxWpt.point getExtensionByKey:ADDRESS_EXTENSION].value;
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

        _selectedIconCategoryName = @"special";
        _selectedIconName = DEFAULT_ICON_NAME;
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
    _appearenceSectionIndex = -1;
    _poiIconRowIndex = -1;
    _colorRowIndex = -1;
    _shapeRowIndex = -1;
    _scrollCellsState = [[OACollectionViewCellState alloc] init];
    _floatingTextFieldControllers = [NSMutableArray array];

    [self initLastUsedIcons];
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
    [self setupIcons];
}

- (void) initLastUsedIcons
{
    _lastUsedIcons = @[];
    NSArray<NSString *> *fromPref = [OAAppSettings.sharedManager.lastUsedFavIcons get];
    if (fromPref && fromPref.count > 0)
        _lastUsedIcons = fromPref;
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
    UIColor *selectedColor = _isNewItemAdding ? [OAFavoritesHelper getGroupByName:self.groupTitle].color : [_pointHandler getColor];
    _selectedColorItem = [_appearanceCollection getColorItemWithValue:[selectedColor toARGBNumber]];
    _sortedColorItems = [NSMutableArray arrayWithArray:[_appearanceCollection getAvailableColorsSortingByLastUsed]];
}

- (void) setupGroups
{
    NSMutableArray *names = [NSMutableArray new];
    NSMutableArray *sizes = [NSMutableArray new];
    NSMutableArray *colors = [NSMutableArray new];

    if (_editPointType == EOAEditPointTypeFavorite)
    {
        NSArray<OAFavoriteGroup *> *allGroups = [OAFavoritesHelper getFavoriteGroups];

        if (![[OAFavoritesHelper getGroups].allKeys containsObject:@""]) {
            [names addObject:OALocalizedString(@"favorites_item")];
            [sizes addObject:@0];
            [colors addObject:[OADefaultFavorite getDefaultColor]];
        }

        for (OAFavoriteGroup *group in allGroups) {
            [names addObject:[OAFavoriteGroup getDisplayName:group.name]];
            [sizes addObject:@(group.points.count)];
            [colors addObject:group.color];
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
}


- (void)setupIcons
{
    [self createIconSelector];
    NSString *preselectedIconName = [_pointHandler getIcon];
    if (!preselectedIconName)
        preselectedIconName = [self getDefaultIconName];
    _selectedIconName = preselectedIconName;
    
    NSMutableArray *categoriesData = [NSMutableArray new];
    for (NSString *category in _iconCategories)
    {
        if ([category isEqualToString:kLastUsedIconsKey])
        {
            [categoriesData addObject: @{
                @"title" : @"",
                @"categoryName" : kLastUsedIconsKey,
                @"img" : @"ic_custom_history",
            }];
        }
        else
        {
            [categoriesData addObject: @{
                @"title" : OALocalizedString(category),
                @"categoryName" : category,
                @"img" : @"",
            }];
        }
    }

    _poiCategories = categoriesData;

    OAFavoriteGroup *selectedGroup = [OAFavoritesHelper getGroupByName:self.groupTitle];
    if (_isNewItemAdding && selectedGroup)
        _selectedIconName = selectedGroup.iconName;
    else if (!_selectedIconName || _selectedIconName.length == 0)
        _selectedIconName = DEFAULT_ICON_NAME;

    if (_isNewItemAdding && selectedGroup)
        _selectedIconCategoryName = [self getInitCategory:_selectedIconName];
    else if (!_selectedIconCategoryName || _selectedIconCategoryName.length == 0)
        _selectedIconCategoryName = @"special";
    
    _backgroundIconNames = [OAFavoritesHelper getFlatBackgroundIconNamesList];
    _backgroundContourIconNames = [OAFavoritesHelper getFlatBackgroundContourIconNamesList];

    NSMutableArray * tempBackgroundIcons = [NSMutableArray new];
    for (NSString *iconName in _backgroundIconNames)
        [tempBackgroundIcons addObject:[NSString stringWithFormat:@"bg_point_%@", iconName]];

    _backgroundIcons = [NSArray arrayWithArray:tempBackgroundIcons];

    _selectedBackgroundIndex = [_backgroundIconNames indexOfObject:_isNewItemAdding && selectedGroup ? selectedGroup.backgroundType : [_pointHandler getBackgroundIcon]];
    if (_selectedBackgroundIndex == -1)
        _selectedBackgroundIndex = 0;
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
        @"addButtonTitle" : OALocalizedString(@"add_group")
    }];
    _selectCategoryCardsRowIndex = section.count - 1;
    [data addObject:[NSArray arrayWithArray:section]];
    _selectCategorySectionIndex = data.count - 1;

    section = [NSMutableArray new];
    [section addObject:@{
        @"header" : OALocalizedString(@"shared_string_appearance"),
        @"type" : [OAPoiTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"shared_string_icon"),
        @"value" : @"",
        @"selectedCategoryName" : _selectedIconCategoryName,
        @"categotyData" : _poiCategories,
        @"selectedIconName" : _selectedIconName,
        @"poiData" : _currentCategoryIcons,
        @"key" : kIconsKey
    }];
    _poiIconRowIndex = section.count - 1;

    [section addObject:@{
        @"key" : @"color_title",
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"shared_string_coloring")
    }];
    _colorLabelRowIndex = section.count - 1;

    [section addObject:@{
        @"key" : @"color_grid",
        @"type" : [OACollectionSingleLineTableViewCell getCellIdentifier]
    }];
    _colorRowIndex = section.count - 1;

    [section addObject:@{
        @"key" : @"all_colors",
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"shared_string_all_colors"),
        @"titleTintColor" :[UIColor colorNamed:ACColorNameTextColorActive]
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
    else if ([cellType isEqualToString:[OAPoiTableViewCell getCellIdentifier]])
    {
        OAPoiTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAPoiTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPoiTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.delegate = self;
            cell.cellIndex = indexPath;
            cell.state = _scrollCellsState;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsZero;
        }
        if (cell)
        {
            cell.categoriesCollectionView.tag = kCategoryCellIndex;
            cell.currentCategory = item[@"selectedCategoryName"];
            cell.categoryDataArray = item[@"categotyData"];
            cell.collectionView.tag = kPoiCellIndex;
            cell.poiData = item[@"poiData"];
            cell.titleLabel.text = item[@"title"];
            cell.currentColor = _selectedColorItem.value;
            cell.currentIcon = item[@"selectedIconName"];
            [cell.collectionView reloadData];
            [cell.categoriesCollectionView reloadData];
            [cell layoutIfNeeded];
        }
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
        }
        if (cell)
        {
            [cell setValues:item[@"values"] sizes:item[@"sizes"] colors:item[@"colors"] addButtonTitle:item[@"addButtonTitle"] withSelectedIndex:[item[@"selectedValue"] intValue]];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OACollectionSingleLineTableViewCell getCellIdentifier]])
    {
        OACollectionSingleLineTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OACollectionSingleLineTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACollectionSingleLineTableViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = nib[0];
            OAColorCollectionHandler *colorHandler = [[OAColorCollectionHandler alloc] initWithData:@[_sortedColorItems] collectionView:cell.collectionView];
            colorHandler.delegate = self;
            NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:_selectedColorItem] inSection:0];
            if (selectedIndexPath.row == NSNotFound)
                selectedIndexPath = [NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:[_appearanceCollection getDefaultPointColorItem]] inSection:0];
            [colorHandler setSelectedIndexPath:selectedIndexPath];
            [cell setCollectionHandler:colorHandler];
            cell.separatorInset = UIEdgeInsetsZero;
            cell.rightActionButton.accessibilityLabel = OALocalizedString(@"shared_string_add_color");
            cell.delegate = self;
        }
        if (cell)
        {
            [cell.rightActionButton setImage:[UIImage templateImageNamed:@"ic_custom_add"] forState:UIControlStateNormal];
            cell.rightActionButton.tag = indexPath.section << 10 | indexPath.row;
            [cell.rightActionButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
            [cell.rightActionButton addTarget:self action:@selector(onCellButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
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
    else if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            BOOL isColorLabel = indexPath.row == _colorLabelRowIndex && indexPath.section == _appearenceSectionIndex;
            BOOL isAllColors = indexPath.row == _allColorsRowIndex && indexPath.section == _appearenceSectionIndex;
            [cell setCustomLeftSeparatorInset:isColorLabel || isAllColors];
            if (isColorLabel || isAllColors)
                cell.separatorInset = UIEdgeInsetsMake(0., isAllColors ? 0. : CGFLOAT_MAX, 0., 0.);
            cell.selectionStyle = isColorLabel ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;

            UIColor *tintColor = item[@"titleTintColor"];
            cell.titleLabel.text = item[@"title"];
            cell.titleLabel.textColor = tintColor ?: [UIColor colorNamed:ACColorNameTextColorPrimary];
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
     else if ([type isEqualToString:[OAPoiTableViewCell getCellIdentifier]])
     {
         OAPoiTableViewCell *poiCell = (OAPoiTableViewCell *)cell;
         [poiCell updateContentOffsetForce:NO];
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
            OAGPXDocument *gpxDocument = [(OAGpxWptEditingHandler *)_pointHandler getGpxDocument];
            if (gpxDocument.points.count > 0)
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
    else if ([key isEqualToString:@"all_colors"])
    {
        OAColorCollectionViewController *colorCollectionViewController =
            [[OAColorCollectionViewController alloc] initWithColorItems:[_appearanceCollection getAvailableColorsSortingByKey]
                                                      selectedColorItem:_selectedColorItem];
        colorCollectionViewController.delegate = self;
        [self showViewController:colorCollectionViewController];
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
            [[OARootViewController instance].mapPanel openTargetViewWithGPX:[db getGPXItem:[
                    [db getFileDir:self.gpxFileName] stringByAppendingPathComponent:self.gpxFileName.lastPathComponent]]
                                                               trackHudMode:EOATrackMenuHudMode
                                                                      state:state];
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
        [self addLastUsedIcon:_selectedIconName];

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

- (void)onCellButtonPressed:(UIButton *)sender
{
    [self onRightActionButtonPressed:sender.tag];
}

#pragma mark - OACollectionTableViewCellDelegate

- (void)onRightActionButtonPressed:(NSInteger)tag
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:tag & 0x3FF inSection:tag >> 10];
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"key"] isEqualToString:@"color_grid"])
        [self openColorPickerWithColor:_selectedColorItem];
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

#pragma mark - OAPoiTableViewCellDelegate

- (void)onPoiCategorySelected:(NSString *)category index:(NSInteger)index
{
    _selectedIconCategoryName = category;
    [self createIconList];
    [self applyLocalization];
    [self generateData];
    OAPoiTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_poiIconRowIndex inSection:_appearenceSectionIndex]];
    [cell updateIconsList:_currentCategoryIcons];
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
    [self onPoiSelected:iconName];
    NSString *selectedIconCategoryName = [self getInitCategory:_selectedIconName];
    if (![_selectedIconCategoryName isEqualToString:selectedIconCategoryName])
        [self onPoiCategorySelected:selectedIconCategoryName index:0];

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
        data.color = waypointItem.color ? waypointItem.color : [waypointItem.point getColor];
        data.backgroundIcon = [waypointItem.point getBackgroundIcon];
        data.icon = [waypointItem.point getIcon];
        data.category = waypointItem.point.type;
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

#pragma mark - OAColorCollectionDelegate

- (void)selectColorItem:(OAColorItem *)colorItem
{
    _needToScrollToSelectedColor = YES;
    [self onCollectionItemSelected:[NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:colorItem] inSection:0]];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_colorRowIndex inSection:_appearenceSectionIndex]]
                          withRowAnimation:UITableViewRowAnimationNone];
}

- (OAColorItem *)addAndGetNewColorItem:(UIColor *)color
{
    NSIndexPath *colorIndexPath = [NSIndexPath indexPathForRow:_colorRowIndex inSection:_appearenceSectionIndex];
    OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:colorIndexPath];
    OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];

    OAColorItem *newColorItem = [_appearanceCollection addNewSelectedColor:color];
    [_sortedColorItems insertObject:newColorItem atIndex:0];
    [colorHandler addAndSelectColor:[NSIndexPath indexPathForRow:0 inSection:0] newItem:newColorItem];
    return newColorItem;
}

- (void)changeColorItem:(OAColorItem *)colorItem withColor:(UIColor *)color
{
    NSIndexPath *colorIndexPath = [NSIndexPath indexPathForRow:_colorRowIndex inSection:_appearenceSectionIndex];
    OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:colorIndexPath];
    OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:colorItem] inSection:0];
    [_appearanceCollection changeColor:colorItem newColor:color];
    [colorHandler replaceOldColor:indexPath];
}

- (OAColorItem *)duplicateColorItem:(OAColorItem *)colorItem
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:colorItem] inSection:0];
    OAColorItem *duplicatedColorItem = [_appearanceCollection duplicateColor:colorItem];
    [_sortedColorItems insertObject:duplicatedColorItem atIndex:indexPath.row + 1];

    NSIndexPath *colorIndexPath = [NSIndexPath indexPathForRow:_colorRowIndex inSection:_appearenceSectionIndex];
    OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:colorIndexPath];
    OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
    [colorHandler addColor:newIndexPath newItem:duplicatedColorItem];
    return duplicatedColorItem;
}

- (void)deleteColorItem:(OAColorItem *)colorItem
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:colorItem] inSection:0];
    [_appearanceCollection deleteColor:colorItem];
    [_sortedColorItems removeObjectAtIndex:indexPath.row];

    NSIndexPath *colorIndexPath = [NSIndexPath indexPathForRow:_colorRowIndex inSection:_appearenceSectionIndex];
    OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:colorIndexPath];
    OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
    [colorHandler removeColor:indexPath];
}

#pragma mark - OACollectionCellDelegate

- (void)onCollectionItemSelected:(NSIndexPath *)indexPath
{
    _isNewColorSelected = YES;
    _selectedColorItem = _sortedColorItems[indexPath.row];
    _wasChanged = YES;
    [self applyLocalization];
    [self generateData];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_poiIconRowIndex inSection:_appearenceSectionIndex],
                                             [NSIndexPath indexPathForRow:_shapeRowIndex inSection:_appearenceSectionIndex]]
                          withRowAnimation:UITableViewRowAnimationNone];
}

- (void)reloadCollectionData
{
}

#pragma mark - OAColorsCollectionCellDelegate

- (void)onContextMenuItemEdit:(NSIndexPath *)indexPath
{
    _editColorIndexPath = indexPath;
    [self openColorPickerWithColor:_sortedColorItems[indexPath.row]];
}

- (void)duplicateItemFromContextMenu:(NSIndexPath *)indexPath
{
    [self duplicateColorItem:_sortedColorItems[indexPath.row]];
}

- (void)deleteItemFromContextMenu:(NSIndexPath *)indexPath
{
    [self deleteColorItem:_sortedColorItems[indexPath.row]];
}

#pragma mark - UIColorPickerViewControllerDelegate

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController
{
    if (_editColorIndexPath)
    {
        if (![[_sortedColorItems[_editColorIndexPath.row] getHexColor] isEqualToString:[viewController.selectedColor toHexARGBString]])
        {
            [self changeColorItem:_sortedColorItems[_editColorIndexPath.row]
                        withColor:viewController.selectedColor];
        }
        _editColorIndexPath = nil;
    }
    else
    {
        [self addAndGetNewColorItem:viewController.selectedColor];
    }
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

- (NSString *)getInitCategory:(NSString *)selectedIconName
{
    for (int j = 0; j < [_iconCategories allKeys].count; j ++)
    {
        NSArray<NSString *> *iconsArray = _iconCategories[ [_iconCategories allKeys][j] ];
        for (int i = 0; i < iconsArray.count; i ++)
        {
            if ([iconsArray[i] isEqualToString:selectedIconName ? selectedIconName : [_pointHandler getIcon]])
                return [_iconCategories allKeys][j];
        }
    }
    return [_iconCategories allKeys][0];
}

- (void) createIconSelector
{
    _iconCategories = [MutableOrderedDictionary dictionary];

    // update last used icons
    if (_lastUsedIcons && _lastUsedIcons.count > 0)
    {
        _iconCategories[kLastUsedIconsKey] = _lastUsedIcons;
    }

    OrderedDictionary<NSString *, NSArray<NSString *> *> *categories = [self loadOrderedJSON];
    if (categories)
    {
        for (int i = 0; i < [categories allKeys].count; i++)
        {
            NSString *name = [categories allKeys][i];
            NSArray *icons = categories[name];
            NSString *translatedName = OALocalizedString([NSString stringWithFormat:@"icon_group_%@", name]);
            _iconCategories[translatedName] = icons;
        }
    }
    _selectedIconCategoryName = [self getInitCategory:nil];
    [self createIconList];
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
    else if (_lastUsedIcons && _lastUsedIcons.count > 0)
        return _lastUsedIcons[0];
    return DEFAULT_ICON_NAME;
}

- (void)addLastUsedIcon:(NSString *)iconName
{
    NSMutableArray<NSString *> *mutableLastUsedIcons = _lastUsedIcons.mutableCopy;
    [mutableLastUsedIcons removeObject:iconName];
    if (mutableLastUsedIcons.count >= kLastUsedIconsLimit)
        [mutableLastUsedIcons removeLastObject];
    [mutableLastUsedIcons insertObject:iconName atIndex:0];
    _lastUsedIcons = mutableLastUsedIcons.copy;
    [OAAppSettings.sharedManager.lastUsedFavIcons set:_lastUsedIcons];
}

- (void)createIconList
{
    NSMutableArray *iconNameList = [NSMutableArray array];
    [iconNameList addObjectsFromArray:_iconCategories[_selectedIconCategoryName]];
    NSString *preselectedIconName = [self getPreselectedIconName];
    if (preselectedIconName && preselectedIconName.length > 0 && [_selectedIconCategoryName isEqualToString:kLastUsedIconsKey])
    {
        [iconNameList removeObject:preselectedIconName];
        [iconNameList insertObject:preselectedIconName atIndex:0];
    }
    _currentCategoryIcons = [NSArray arrayWithArray:iconNameList];
}

- (OrderedDictionary<NSString *, NSArray<NSString *> *> *)loadOrderedJSON
{
    NSString* path = [[NSBundle mainBundle] pathForResource:@"poi_categories" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSString* jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *unorderedJson = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    if (unorderedJson)
    {
        NSMutableDictionary<NSString *, NSNumber *> *categoriesOrder = [NSMutableDictionary dictionary];
        NSDictionary *unorderedCategories = unorderedJson[@"categories"];
        NSArray *unorderedCategoryNames = unorderedCategories.allKeys;
        if (unorderedCategories)
        {
            for (NSString *categoryName in unorderedCategoryNames)
            {
                NSNumber *indexInJsonSrting = [NSNumber numberWithInt:[jsonString indexOf:[NSString stringWithFormat:@"\"%@\"", categoryName]]];
                categoriesOrder[categoryName] = indexInJsonSrting;
            }
            NSArray *orderedCategoryNames = [categoriesOrder keysSortedByValueUsingSelector:@selector(compare:)];
            MutableOrderedDictionary *orderedJson = [MutableOrderedDictionary new];
            for (NSString *categoryName in orderedCategoryNames)
            {
                NSDictionary *iconsDictionary = unorderedCategories[categoryName];
                if (iconsDictionary)
                {
                    NSArray *iconsArray = iconsDictionary[@"icons"];
                    if (iconsArray)
                    {
                        orderedJson[categoryName] = iconsArray;
                    }
                }
            }
            return orderedJson;
        }
    }
    return nil;
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

- (void)openColorPickerWithColor:(OAColorItem *)colorItem
{
    UIColorPickerViewController *colorViewController = [[UIColorPickerViewController alloc] init];
    colorViewController.delegate = self;
    colorViewController.selectedColor = [colorItem getColor];
    [self presentViewController:colorViewController animated:YES completion:nil];
}

- (void)onGroupChanged:(NSString *)groupName
{
    _wasChanged = YES;
    self.groupTitle = groupName;

    if (_editPointType == EOAEditPointTypeFavorite)
    {
        groupName = [OAFavoriteGroup convertDisplayNameToGroupIdName:self.groupTitle];
        OAFavoriteGroup *group = [OAFavoritesHelper getGroupByName:groupName];
        if (group)
        {
            _selectedColorItem = [_appearanceCollection getColorItemWithValue:[group.color toARGBNumber]];
            _selectedIconName = group.iconName;
            _selectedIconCategoryName = [self getInitCategory:_selectedIconName];
            _selectedBackgroundIndex = [_backgroundIconNames indexOfObject:group.backgroundType];
            [self createIconList];
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

    _needToScrollToSelectedColor = YES;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_selectCategoryLabelRowIndex inSection:_selectCategorySectionIndex],
                                             [NSIndexPath indexPathForRow:_poiIconRowIndex inSection:_appearenceSectionIndex],
                                             [NSIndexPath indexPathForRow:_colorRowIndex inSection:_appearenceSectionIndex],
                                             [NSIndexPath indexPathForRow:_shapeRowIndex inSection:_appearenceSectionIndex]]
                          withRowAnimation:UITableViewRowAnimationNone];
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
