//
//  OABaseEditorViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 11.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseEditorViewController.h"
#import "OACollectionSingleLineTableViewCell.h"
#import "OAColorCollectionViewController.h"
#import "OATextInputFloatingCell.h"
#import "OAPoiTableViewCell.h"
#import "OAShapesTableViewCell.h"
#import "OAColorCollectionHandler.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXAppearanceCollection.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OrderedDictionary.h"
#import "OAFavoritesHelper.h"
#import "OAColors.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#define kIllegalFileNameCharacters [NSCharacterSet characterSetWithCharactersInString:@"\\?%*|\"<>:;.,"]

#define kInputNameKey @"kInputNameKey"
#define kLastUsedIconsKey @"kLastUsedIconsKey"
#define kIconsKey @"kIconsKey"
#define kBackgroundsKey @"kBackgroundsKey"

#define kCategoryCellIndex 0
#define kPoiCellIndex 1

@interface OABaseEditorViewController () <UIColorPickerViewControllerDelegate, UITextViewDelegate, MDCMultilineTextInputLayoutDelegate, OAColorCollectionDelegate, OAColorsCollectionCellDelegate, OACollectionTableViewCellDelegate, OAPoiTableViewCellDelegate, OAShapesTableViewCellDelegate>

@property(nonatomic) NSString *originalName;
@property(nonatomic) NSString *editName;
@property(nonatomic) UIColor *editColor;
@property(nonatomic) NSString *editIconName;
@property(nonatomic) NSString *editBackgroundIconName;
@property(nonatomic) BOOL isNewItem;
@property(nonatomic) BOOL wasChanged;
@property(nonatomic) OAGPXAppearanceCollection *appearanceCollection;

@end

@implementation OABaseEditorViewController
{
    MutableOrderedDictionary<NSString *, NSArray<NSString *> *> *_iconCategories;
    NSArray<NSString *> *_currentCategoryIcons;
    NSArray<NSString *> *_lastUsedIcons;
    NSArray<NSDictionary<NSString *, NSString *> *> *_poiCategories;
    NSString *_selectedIconCategoryName;
    NSString *_selectedIconName;
    OACollectionViewCellState *_scrollCellsState;
    NSMutableArray<MDCTextInputControllerUnderline *> *_floatingTextFieldControllers;

    NSMutableArray<OAColorItem *> *_sortedColorItems;
    OAColorItem *_selectedColorItem;
    BOOL _needToScrollToSelectedColor;

    NSArray<NSString *> *_backgroundIcons;
    NSArray<NSString *> *_backgroundIconNames;
    NSArray<NSString *> *_backgroundContourIconNames;
    NSInteger _selectedBackgroundIndex;

    NSIndexPath *_iconIndexPath;
    NSIndexPath *_editColorIndexPath;
    NSIndexPath *_colorGridIndexPath;
    NSIndexPath *_allColorsIndexPath;
    NSIndexPath *_shapeIndexPath;

    UIBarButtonItem *_saveBarButton;
}

@synthesize appearanceCollection = _appearanceCollection, editName = _editName, originalName = _originalName, editColor = _editColor, editIconName = _editIconName, editBackgroundIconName = _editBackgroundIconName;

#pragma mark - Initialization

- (instancetype)initWithNew
{
    self = [super init];
    if (self)
    {
        _isNewItem = YES;
        [self postInit];
    }
    return self;
}

- (void)commonInit
{
    _appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
    self.editName = @"";
    self.editIconName = @"";
    self.editColor = [[_appearanceCollection getDefaultPointColorItem] getColor];
    self.editBackgroundIconName = @"";
    _wasChanged = NO;
    _needToScrollToSelectedColor = YES;
    _scrollCellsState = [[OACollectionViewCellState alloc] init];
    _floatingTextFieldControllers = [NSMutableArray array];
}

- (void)postInit
{
    [self setupIcons];
    [self setupColors];
}

- (void)registerNotifications
{
    [self addNotification:UIKeyboardWillShowNotification selector:@selector(keyboardWillShow:)];
    [self addNotification:UIKeyboardWillHideNotification selector:@selector(keyboardWillHide:)];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _isNewItem ? OALocalizedString(@"fav_add_new_group") : OALocalizedString(@"change_appearance");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    _saveBarButton = [self createRightNavbarButton:OALocalizedString(@"shared_string_save")
                                          iconName:nil
                                            action:@selector(onRightNavbarButtonPressed)
                                              menu:nil];
    [self changeButtonAvailability:_saveBarButton isEnabled:NO];
    return @[_saveBarButton];
}

#pragma mark - Table data

- (void)generateData
{
    [self generateDescriptionSection];
    [self generateGroupSection];
    [self generateIconSection];
    [self generateColorSection];
    [self generateShapeSection];
    [self generateActionSection];
}

- (void)generateDescriptionSection
{
}

- (void)generateGroupSection
{
}

- (void)generateIconSection
{
    OATableSectionData *iconSection = [self.tableData createNewSection];
    iconSection.headerText = OALocalizedString(@"shared_string_appearance");

    OATableRowData *iconRow = [iconSection createNewRow];
    iconRow.key = kIconsKey;
    iconRow.cellType = [OAPoiTableViewCell getCellIdentifier];
    iconRow.title = OALocalizedString(@"shared_string_icon");
    [iconRow setObj:@"" forKey:@"value"];
    [iconRow setObj:_selectedIconCategoryName forKey:@"selectedCategoryName"];
    [iconRow setObj:_poiCategories forKey:@"categotyData"];
    [iconRow setObj:_selectedIconName forKey:@"selectedIconName"];
    [iconRow setObj:_currentCategoryIcons forKey:@"poiData"];
    _iconIndexPath = [NSIndexPath indexPathForRow:[iconSection rowCount] - 1
                                        inSection:[self.tableData sectionCount] - 1];
}

- (void)generateColorSection
{
    OATableSectionData *colorSection = [self.tableData createNewSection];
    NSInteger appearenceSectionIndex = [self.tableData sectionCount] - 1;

    OATableRowData *colorTitleRow = [colorSection createNewRow];
    colorTitleRow.key = @"colorTitle";
    colorTitleRow.cellType = [OASimpleTableViewCell getCellIdentifier];
    colorTitleRow.title = OALocalizedString(@"shared_string_coloring");

    OATableRowData *gridRow = [colorSection createNewRow];
    gridRow.key = @"colorGrid";
    gridRow.cellType = [OACollectionSingleLineTableViewCell getCellIdentifier];
    _colorGridIndexPath = [NSIndexPath indexPathForRow:[colorSection rowCount] - 1
                                             inSection:appearenceSectionIndex];

    OATableRowData *allColorsRow = [colorSection createNewRow];
    allColorsRow.key = @"allColors";
    allColorsRow.cellType = [OASimpleTableViewCell getCellIdentifier];
    allColorsRow.title = OALocalizedString(@"shared_string_all_colors");
    [allColorsRow setObj:[UIColor colorNamed:ACColorNameTextColorActive] forKey:@"titleTintColor"];
    _allColorsIndexPath = [NSIndexPath indexPathForRow:[colorSection rowCount] - 1
                                             inSection:appearenceSectionIndex];
}

- (void)generateShapeSection
{
    OATableSectionData *shapeSection = [self.tableData createNewSection];
    shapeSection.headerText = OALocalizedString(@"shared_string_appearance");

    OATableRowData *shapeRow = [shapeSection createNewRow];
    shapeRow.key = kBackgroundsKey;
    shapeRow.cellType = [OAShapesTableViewCell getCellIdentifier];
    shapeRow.title = OALocalizedString(@"shared_string_shape");
    [shapeRow setObj:OALocalizedString([NSString stringWithFormat:@"shared_string_%@",
                                        _backgroundIconNames[_selectedBackgroundIndex]])
              forKey:@"value"];
    [shapeRow setObj:@(_selectedBackgroundIndex) forKey:@"index"];
    [shapeRow setObj:_backgroundIcons forKey:@"icons"];
    [shapeRow setObj:_backgroundContourIconNames forKey:@"contourIcons"];
    _shapeIndexPath = [NSIndexPath indexPathForRow:[shapeSection rowCount] - 1
                                         inSection:[self.tableData sectionCount] - 1];
}

- (void)generateActionSection
{
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [self.tableData itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
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
            BOOL isColorLabel = [item.key isEqualToString:@"colorTitle"];
            BOOL isAllColors = [item.key isEqualToString:@"allColors"];
            [cell setCustomLeftSeparatorInset:isColorLabel || isAllColors];
            if (isColorLabel || isAllColors)
                cell.separatorInset = UIEdgeInsetsMake(0., isAllColors ? 0. : CGFLOAT_MAX, 0., 0.);
            cell.selectionStyle = isColorLabel ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;

            UIColor *tintColor = [item objForKey:@"titleTintColor"];
            cell.titleLabel.text = item.title;
            cell.titleLabel.textColor = tintColor ?: [UIColor colorNamed:ACColorNameTextColorPrimary];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OACollectionSingleLineTableViewCell getCellIdentifier]])
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
            [cell.rightActionButton setImage:[UIImage templateImageNamed:@"ic_custom_add"]
                                    forState:UIControlStateNormal];
            cell.delegate = self;
        }
        if (cell)
        {
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
    else if ([item.cellType isEqualToString:[OATextInputFloatingCell getCellIdentifier]])
    {
        return [item objForKey:@"cell"];
    }
    else if ([item.cellType isEqualToString:[OAPoiTableViewCell getCellIdentifier]])
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
            cell.currentCategory = [item objForKey:@"selectedCategoryName"];
            cell.categoryDataArray = [item objForKey:@"categotyData"];
            cell.collectionView.tag = kPoiCellIndex;
            cell.poiData = [item objForKey:@"poiData"];
            cell.titleLabel.text = [item objForKey:@"title"];
            cell.currentColor = _selectedColorItem.value;
            cell.currentIcon = [item objForKey:@"selectedIconName"];
            [cell.collectionView reloadData];
            [cell.categoriesCollectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OAShapesTableViewCell getCellIdentifier]])
    {
        OAShapesTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAShapesTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAShapesTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.delegate = self;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsZero;
            cell.valueLabel.hidden = NO;
        }
        if (cell)
        {
            cell.iconNames = [item objForKey:@"icons"];
            cell.contourIconNames = [item objForKey:@"contourIcons"];
            cell.titleLabel.text = item.title;
            cell.valueLabel.text = [item objForKey:@"value"];
            cell.currentColor = _selectedColorItem.value;
            cell.currentIcon = [item integerForKey:@"index"];
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }

    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
 {
     OATableRowData *item = [self.tableData itemForIndexPath:indexPath];
     if ([item.cellType isEqualToString:[OAPoiTableViewCell getCellIdentifier]])
     {
         OAPoiTableViewCell *poiCell = (OAPoiTableViewCell *) cell;
         [poiCell updateContentOffsetForce:NO];
     }
 }

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OATableRowData *item = [self.tableData itemForIndexPath:indexPath];
    if ([item.key isEqualToString:@"allColors"])
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
    OATableRowData *item = [self.tableData itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OATextInputFloatingCell getCellIdentifier]])
    {
        OATextInputFloatingCell *cell = [item objForKey:@"cell"];
        return cell ? MAX(cell.inputField.intrinsicContentSize.height, 60.) : 60.;
    }
    return UITableViewAutomaticDimension;
}

#pragma mark - Selecors

- (void)onCellButtonPressed:(UIButton *)sender
{
    [self onRightActionButtonPressed:sender.tag];
}

- (void)clearButtonPressed:(UIButton *)sender
{
    NSIndexPath *indexPath = [self indexPathForCellContainingView:sender inTableView:self.tableView];
    OATextInputFloatingCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self.tableView beginUpdates];
    cell.inputField.text = @"";
    OATableRowData *item = [self.tableData itemForIndexPath:indexPath];
    if ([item.key isEqualToString:kInputNameKey])
        self.editName = @"";
    [self.tableView endUpdates];
}

- (NSIndexPath *)indexPathForCellContainingView:(UIView *)view inTableView:(UITableView *)tableView
{
    CGPoint viewCenterRelativeToTableview = [tableView convertPoint:CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds)) fromView:view];
    NSIndexPath *cellIndexPath = [tableView indexPathForRowAtPoint:viewCenterRelativeToTableview];
    return cellIndexPath;
}

#pragma mark - Additions

- (void)setupColors
{
    _selectedColorItem = [_appearanceCollection getColorItemWithValue:[self.editColor toARGBNumber]];
    _sortedColorItems = [NSMutableArray arrayWithArray:[_appearanceCollection getAvailableColorsSortingByLastUsed]];
}

- (void)setupIcons
{
    [self createIconSelector];
    NSString *preselectedIconName = self.editIconName;
    if (!preselectedIconName)
        preselectedIconName = [self getDefaultIconName];
    _selectedIconName = preselectedIconName;

    NSMutableArray<NSDictionary<NSString *, NSString *> *> *categoriesData = [NSMutableArray array];
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

    if (!_selectedIconName || _selectedIconName.length == 0)
    {
        _selectedIconName = DEFAULT_ICON_NAME;
        self.editIconName = _selectedIconName;
    }

    if (!_selectedIconCategoryName || _selectedIconCategoryName.length == 0)
        _selectedIconCategoryName = @"special";

    _backgroundIconNames = [OAFavoritesHelper getFlatBackgroundIconNamesList];
    _backgroundContourIconNames = [OAFavoritesHelper getFlatBackgroundContourIconNamesList];

    NSMutableArray * tempBackgroundIcons = [NSMutableArray array];
    for (NSString *iconName in _backgroundIconNames)
        [tempBackgroundIcons addObject:[NSString stringWithFormat:@"bg_point_%@", iconName]];

    _backgroundIcons = tempBackgroundIcons;

    _selectedBackgroundIndex = [_backgroundIconNames indexOfObject:self.editBackgroundIconName];
    if (_selectedBackgroundIndex == NSNotFound)
    {
        _selectedBackgroundIndex = 0;
        self.editBackgroundIconName = _backgroundIconNames.firstObject;
    }
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

- (void)createIconSelector
{
    _iconCategories = [MutableOrderedDictionary dictionary];
    // update last used icons
    if (_lastUsedIcons && _lastUsedIcons.count > 0)
        _iconCategories[kLastUsedIconsKey] = _lastUsedIcons;

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
    _selectedIconCategoryName = [self getInitCategory];
    [self createIconList];
}

- (OrderedDictionary<NSString *, NSArray<NSString *> *> *)loadOrderedJSON
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"poi_categories" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *unorderedJson = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    if (unorderedJson)
    {
        NSMutableDictionary<NSString *, NSNumber *> *categoriesOrder = [NSMutableDictionary dictionary];
        NSDictionary<NSString *, NSDictionary<NSString *, NSArray<NSString *> *> *> *unorderedCategories = unorderedJson[@"categories"];
        NSArray<NSString *> *unorderedCategoryNames = unorderedCategories.allKeys;
        if (unorderedCategories)
        {
            for (NSString *categoryName in unorderedCategoryNames)
            {
                NSNumber *indexInJsonSrting = [NSNumber numberWithInt:[jsonString indexOf:[NSString stringWithFormat:@"\"%@\"", categoryName]]];
                categoriesOrder[categoryName] = indexInJsonSrting;
            }
            NSArray<NSString *> *orderedCategoryNames = [categoriesOrder keysSortedByValueUsingSelector:@selector(compare:)];
            MutableOrderedDictionary *orderedJson = [MutableOrderedDictionary dictionary];
            for (NSString *categoryName in orderedCategoryNames)
            {
                NSDictionary<NSString *, NSArray<NSString *> *> *iconsDictionary = unorderedCategories[categoryName];
                if (iconsDictionary)
                {
                    NSArray<NSString *> *iconsArray = iconsDictionary[@"icons"];
                    if (iconsArray)
                        orderedJson[categoryName] = iconsArray;
                }
            }
            return orderedJson;
        }
    }
    return nil;
}

- (NSString *)getInitCategory
{
    for (int j = 0; j < _iconCategories.allKeys.count; j ++)
    {
        NSArray<NSString *> *iconsArray = _iconCategories[[_iconCategories allKeys][j]];
        for (int i = 0; i < iconsArray.count; i ++)
        {
            if ([iconsArray[i] isEqualToString:self.editIconName])
                return [_iconCategories allKeys][j];
        }
    }
    return [_iconCategories allKeys][0];
}

- (void)createIconList
{
    NSMutableArray<NSString *> *iconNameList = [NSMutableArray array];
    [iconNameList addObjectsFromArray:_iconCategories[_selectedIconCategoryName]];
    NSString *preselectedIconName = [self getPreselectedIconName];
    if (preselectedIconName && preselectedIconName.length > 0 && [_selectedIconCategoryName isEqualToString:kLastUsedIconsKey])
    {
        [iconNameList removeObject:preselectedIconName];
        [iconNameList insertObject:preselectedIconName atIndex:0];
    }
    _currentCategoryIcons = iconNameList;
}

- (NSString *)getPreselectedIconName
{
    return (!_isNewItem) ? nil : self.editIconName;
}

- (void)openColorPickerWithColor:(OAColorItem *)colorItem
{
    UIColorPickerViewController *colorViewController = [[UIColorPickerViewController alloc] init];
    colorViewController.delegate = self;
    colorViewController.selectedColor = [colorItem getColor];
    [self presentViewController:colorViewController animated:YES completion:nil];
}

- (OATextInputFloatingCell *) getInputCellWithHint:(NSString *)hint
                                              text:(NSString *)text
                                               tag:(NSInteger)tag
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextInputFloatingCell getCellIdentifier]
                                                 owner:self
                                               options:nil];
    OATextInputFloatingCell *resultCell = nib[0];
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
    [textField.clearButton setImage:[UIImage templateImageNamed:@"ic_custom_clear_field"] forState:UIControlStateNormal];
    [textField.clearButton setImage:[UIImage templateImageNamed:@"ic_custom_clear_field"] forState:UIControlStateHighlighted];

    if (!_floatingTextFieldControllers)
        _floatingTextFieldControllers = [NSMutableArray array];
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

#pragma mark - OAPoiTableViewCellDelegate

- (void)onPoiCategorySelected:(NSString *)category index:(NSInteger)index
{
    _selectedIconCategoryName = category;
    [self createIconList];
    [self applyLocalization];
    OATableRowData *iconRow = [self.tableData itemForIndexPath:_iconIndexPath];
    [iconRow setObj:_selectedIconCategoryName forKey:@"selectedCategoryName"];
    [iconRow setObj:_currentCategoryIcons forKey:@"poiData"];
    OAPoiTableViewCell *cell = [self.tableView cellForRowAtIndexPath:_iconIndexPath];
    [cell updateIconsList:_currentCategoryIcons];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)onPoiSelected:(NSString *)poiName;
{
    _wasChanged = YES;
    _selectedIconName = poiName;
    self.editIconName = _selectedIconName;
    [self applyLocalization];
    OATableRowData *iconRow = [self.tableData itemForIndexPath:_iconIndexPath];
    [iconRow setObj:_selectedIconName forKey:@"selectedIconName"];

    OAFavoriteGroup *groupExist = [OAFavoritesHelper getGroupByName:self.editName];
    [self changeButtonAvailability:_saveBarButton
                         isEnabled:!groupExist
     || ![self.editIconName isEqual:groupExist.iconName]
     || ![self.editBackgroundIconName isEqualToString:groupExist.backgroundType]
     || ![self.editColor isEqual:groupExist.color]];
}

#pragma mark - OAShapesTableViewCellDelegate

- (void)iconChanged:(NSInteger)tag
{
    _wasChanged = YES;
    _selectedBackgroundIndex = (int) tag;
    self.editBackgroundIconName = _backgroundIconNames[_selectedBackgroundIndex];
    [self applyLocalization];
    OATableRowData *shapeRow = [self.tableData itemForIndexPath:_shapeIndexPath];
    [shapeRow setObj:OALocalizedString([NSString stringWithFormat:@"shared_string_%@",
                                        _backgroundIconNames[_selectedBackgroundIndex]])
              forKey:@"value"];
    [shapeRow setObj:@(_selectedBackgroundIndex) forKey:@"index"];
    [self.tableView reloadRowsAtIndexPaths:@[_shapeIndexPath]
                          withRowAnimation:UITableViewRowAnimationNone];

    OAFavoriteGroup *groupExist = [OAFavoritesHelper getGroupByName:self.editName];
    [self changeButtonAvailability:_saveBarButton
                         isEnabled:!groupExist
        || ![self.editBackgroundIconName isEqualToString:groupExist.backgroundType]
        || ![self.editIconName isEqual:groupExist.iconName]
        || ![self.editColor isEqual:groupExist.color]];
}

#pragma mark - OACollectionTableViewCellDelegate

- (void)onRightActionButtonPressed:(NSInteger)tag
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:tag & 0x3FF inSection:tag >> 10];
    OATableRowData *item = [self.tableData itemForIndexPath:indexPath];
    if ([item.key isEqualToString:@"colorGrid"])
        [self openColorPickerWithColor:_selectedColorItem];
}

#pragma mark - OAColorCollectionDelegate

- (void)selectColorItem:(OAColorItem *)colorItem
{
    _needToScrollToSelectedColor = YES;
    [self onCollectionItemSelected:[NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:colorItem] inSection:0]];
    [self.tableView reloadRowsAtIndexPaths:@[_colorGridIndexPath, _shapeIndexPath]
                          withRowAnimation:UITableViewRowAnimationNone];
}

- (OAColorItem *)addAndGetNewColorItem:(UIColor *)color
{
    if (self.delegate)
    {
        OAColorItem *newColorItem = [self.delegate addAndGetNewColorItem:color];
        [_sortedColorItems insertObject:newColorItem atIndex:0];
        return newColorItem;
    }
    return nil;
}

- (void)changeColorItem:(OAColorItem *)colorItem withColor:(UIColor *)color
{
    if (self.delegate)
        [self.delegate changeColorItem:colorItem withColor:color];
}

- (OAColorItem *)duplicateColorItem:(OAColorItem *)colorItem
{
    if (self.delegate && _colorGridIndexPath)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:colorItem] inSection:0];
        OAColorItem *duplicatedColorItem = [self.delegate duplicateColorItem:colorItem];
        [_sortedColorItems insertObject:duplicatedColorItem atIndex:indexPath.row + 1];
        OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorGridIndexPath];
        OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        [colorHandler addColor:newIndexPath newItem:duplicatedColorItem];
        return duplicatedColorItem;
    }
    return nil;
}

- (void)deleteColorItem:(OAColorItem *)colorItem
{
    if (self.delegate && _colorGridIndexPath)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:colorItem] inSection:0];
        OAColorItem *colorItem = _sortedColorItems[indexPath.row];
        [_sortedColorItems removeObjectAtIndex:indexPath.row];
        [self.delegate deleteColorItem:colorItem];
        OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorGridIndexPath];
        OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
        [colorHandler removeColor:indexPath];
    }
}

#pragma mark - OACollectionCellDelegate

- (void)onCollectionItemSelected:(NSIndexPath *)indexPath
{
    _selectedColorItem = _sortedColorItems[indexPath.row];
    self.editColor = [_selectedColorItem getColor];
    _wasChanged = YES;
    [self applyLocalization];
    [self.tableView reloadRowsAtIndexPaths:@[_iconIndexPath, _shapeIndexPath]
                          withRowAnimation:UITableViewRowAnimationNone];

    OAFavoriteGroup *groupExist = [OAFavoritesHelper getGroupByName:self.editName];
    [self changeButtonAvailability:_saveBarButton
                         isEnabled:!groupExist
     || ![self.editColor isEqual:groupExist.color]
     || ![self.editIconName isEqual:groupExist.iconName]
     || ![self.editBackgroundIconName isEqualToString:groupExist.backgroundType]];
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
    OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorGridIndexPath];
    OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
    if (_editColorIndexPath)
    {
        if (![[_sortedColorItems[_editColorIndexPath.row] getHexColor] isEqualToString:[viewController.selectedColor toHexARGBString]])
        {
            [self changeColorItem:_sortedColorItems[_editColorIndexPath.row] withColor:viewController.selectedColor];
            [colorHandler replaceOldColor:_editColorIndexPath];
        }
        _editColorIndexPath = nil;
    }
    else
    {
        OAColorItem *newColorItem = [self addAndGetNewColorItem:viewController.selectedColor];
        [colorHandler addAndSelectColor:[NSIndexPath indexPathForRow:0 inSection:0] newItem:newColorItem];
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    BOOL isEnabled = YES;
    _wasChanged = YES;
    NSIndexPath *indexPath = [self indexPathForCellContainingView:textView inTableView:self.tableView];
    OATableRowData *item = [self.tableData itemForIndexPath:indexPath];
    if ([item.key isEqualToString:kInputNameKey])
    {
        OAFavoriteGroup *groupExist = [OAFavoritesHelper getGroupByName:textView.text];
        isEnabled = textView.text.length > 0
            && [textView.text rangeOfCharacterFromSet:kIllegalFileNameCharacters].length == 0
            && ![textView.text isEqualToString:OALocalizedString(@"favorites_item")]
            && ![textView.text isEqualToString:OALocalizedString(@"personal_category_name")]
            && ![textView.text isEqualToString:kPersonalCategory]
            && !groupExist;
        if (!isEnabled && groupExist)
        {
            isEnabled = textView.text.length > 0
                && (![groupExist.iconName isEqualToString:self.editIconName]
                || ![groupExist.backgroundType isEqualToString:self.editBackgroundIconName]
                || ![groupExist.color isEqual:self.editColor]);
        }
        self.editName = textView.text;
    }

    [self applyLocalization];
    [self changeButtonAvailability:_saveBarButton isEnabled:isEnabled];
}

#pragma mark - MDCMultilineTextInputLayoutDelegate

- (void)multilineTextField:(id<MDCMultilineTextInput> _Nonnull)multilineTextField
      didChangeContentSize:(CGSize)size
{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    NSValue *keyboardBoundsValue = userInfo[UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = [keyboardBoundsValue CGRectValue].size.height;
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [self.tableView contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [self.tableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardHeight, insets.right)];
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [self.tableView contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [self.tableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0., insets.right)];
        [self.view layoutIfNeeded];
    } completion:nil];
}

@end
