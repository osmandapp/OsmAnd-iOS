//
//  OABaseEditorViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 11.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseEditorViewController.h"
#import "OAColorsPaletteCell.h"
#import "OATextInputFloatingCell.h"
#import "OAShapesTableViewCell.h"
#import "OAColorCollectionHandler.h"
#import "OAGPXDocumentPrimitives.h"
#import "MaterialTextFields.h"
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
#import "OAFavoriteItem.h"

static NSString * const kInputNameKey = @"kInputNameKey";
static NSString * const kLastUsedIconsKey = @"kLastUsedIconsKey";
static NSString * const kIconsKey = @"kIconsKey";
static NSString * const kBackgroundsKey = @"kBackgroundsKey";

@interface OABaseEditorViewController () <UITextViewDelegate, MDCMultilineTextInputLayoutDelegate, OAShapesTableViewCellDelegate, OACollectionCellDelegate, OABaseCollectionHandlerDelegate>

@property(nonatomic) NSString *originalName;
@property(nonatomic) NSString *editName;
@property(nonatomic) UIColor *editColor;
@property(nonatomic) NSString *editIconName;
@property(nonatomic) NSString *editBackgroundIconName;
@property(nonatomic) BOOL isNewItem;
@property(nonatomic) BOOL wasChanged;
@property(nonatomic) BOOL isTextViewNameValid;

@property(nonatomic) OAGPXAppearanceCollection *appearanceCollection;

@end

@implementation OABaseEditorViewController
{
    NSMutableArray<MDCTextInputControllerUnderline *> *_floatingTextFieldControllers;
   
    PoiIconCollectionHandler *_poiIconCollectionHandler;
    NSString *_selectedIconName;

    OAColorCollectionHandler *_colorCollectionHandler;
    NSMutableArray<OAColorItem *> *_sortedColorItems;
    OAColorItem *_selectedColorItem;
    BOOL _needToScrollToSelectedColor;

    ShapesCollectionHandler *_shapesCollectionHandler;
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
    _floatingTextFieldControllers = [NSMutableArray array];
}

- (void)postInit
{
    [self setupIconHandler];
    [self setupBackgroundIcons];
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
    return _isNewItem ? OALocalizedString(@"fav_add_new_group") : OALocalizedString(@"default_appearance");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    _saveBarButton = [self createRightNavbarButton:OALocalizedString(@"shared_string_done")
                                          iconName:nil
                                            action:@selector(onRightNavbarButtonPressed)
                                              menu:nil];
    [self changeButtonAvailability:_saveBarButton isEnabled:NO];
    return @[_saveBarButton];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}

- (UIColor *)blurBackgroundColor
{
    return [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
}

#pragma mark - Table data

- (void)generateData
{
    if (self.isNewItem)
        [self generateDescriptionSection];
    [self generateGroupSection];
    if (self.isNewItem)
    {
        [self generateIconSection];
        [self generateColorSection];
    }
    else
    {
        [self generateColorSection];
        [self generateIconSection];
    }
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
    OATableRowData *iconRow = [iconSection createNewRow];
    iconRow.key = kIconsKey;
    iconRow.cellType = [OAIconsPaletteCell getCellIdentifier];
    iconRow.title = OALocalizedString(@"shared_string_icon");
    iconRow.descr = OALocalizedString(@"shared_string_all_icons");
    [iconRow setObj:@"" forKey:@"value"];
    _iconIndexPath = [NSIndexPath indexPathForRow:[iconSection rowCount] - 1
                                        inSection:[self.tableData sectionCount] - 1];
}

- (void)generateColorSection
{
    OATableSectionData *colorSection = [self.tableData createNewSection];
    NSInteger appearenceSectionIndex = [self.tableData sectionCount] - 1;
    OATableRowData *colorTitleRow = [colorSection createNewRow];
    colorTitleRow.key = @"color_cell";
    colorTitleRow.cellType = [OAColorsPaletteCell getCellIdentifier];
    colorTitleRow.title = OALocalizedString(@"shared_string_coloring");
    colorTitleRow.descr = OALocalizedString(@"shared_string_all_colors");
    _colorGridIndexPath = [NSIndexPath indexPathForRow:0
                                                 inSection:appearenceSectionIndex];
}

- (void)generateShapeSection
{
    OATableSectionData *shapeSection = [self.tableData createNewSection];
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
    else if ([item.cellType isEqualToString:[OAColorsPaletteCell getCellIdentifier]])
    {
        OAColorsPaletteCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAColorsPaletteCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAColorsPaletteCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.disableAnimationsOnStart = YES;
        }
        if (cell)
        {
            [_colorCollectionHandler setCollectionView:cell.collectionView];
            [cell setCollectionHandler:_colorCollectionHandler];
            _colorCollectionHandler.hostVCOpenColorPickerButton = cell.rightActionButton;
            cell.hostVC = self;
            NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:_selectedColorItem] inSection:0];
            if (selectedIndexPath.row == NSNotFound)
                selectedIndexPath = [NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:[_appearanceCollection getDefaultPointColorItem]] inSection:0];
            [_colorCollectionHandler setSelectedIndexPath:selectedIndexPath];
            [_colorCollectionHandler updateHostCellIfNeeded];
            cell.topLabel.text = item.title;
            [cell topButtonVisibility:!_isNewItem];
            cell.descriptionLabel.text = OALocalizedString(@"original_color_description");
            [cell.bottomButton setTitle:item.descr forState:UIControlStateNormal];
            [cell.rightActionButton setImage:[UIImage templateImageNamed:@"ic_custom_add"] forState:UIControlStateNormal];
            cell.rightActionButton.tag = indexPath.section << 10 | indexPath.row;
            [cell.collectionView reloadData];
            
            if (_needToScrollToSelectedColor)
            {
                NSIndexPath *selectedIndexPath = [[cell getCollectionHandler] getSelectedIndexPath];
                if (selectedIndexPath.row != NSNotFound
                    && indexPath.section < [cell.collectionView numberOfSections]
                    && selectedIndexPath.row < [cell.collectionView numberOfItemsInSection:indexPath.section]
                    && ![cell.collectionView.indexPathsForVisibleItems containsObject:selectedIndexPath])
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
    else if ([item.cellType isEqualToString:[OAIconsPaletteCell getCellIdentifier]])
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
        [_poiIconCollectionHandler updateHostCellIfNeeded];
        cell.topLabel.text = item.title;
        cell.descriptionLabel.text = OALocalizedString(@"original_icon_description");
        [cell topButtonVisibility:YES];
        [cell.bottomButton setTitle:item.descr forState:UIControlStateNormal];
        [cell.collectionView reloadData];
        [cell layoutIfNeeded];
        return cell;
    }
    else if ([item.cellType isEqualToString:[OAShapesTableViewCell getCellIdentifier]])
    {
        OAShapesTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAShapesTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAShapesTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.shapesDelegate = self;
            cell.disableAnimationsOnStart = YES;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsZero;
            cell.valueLabel.hidden = NO;
        }
        if (cell)
        {
            [_shapesCollectionHandler setCollectionView:cell.collectionView];
            [cell setCollectionHandler:_shapesCollectionHandler];
            [_shapesCollectionHandler updateHostCellIfNeeded];
            cell.iconNames = [item objForKey:@"icons"];
            cell.contourIconNames = [item objForKey:@"contourIcons"];
            cell.titleLabel.text = item.title;
            cell.descriptionLabel.text = OALocalizedString(@"original_shape_description");
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
    _colorCollectionHandler = [[OAColorCollectionHandler alloc] initWithData:@[_sortedColorItems] isFavoriteList:!_isNewItem];
    _colorCollectionHandler.delegate = self;
    _colorCollectionHandler.handlerDelegate = self;
    _colorCollectionHandler.hostVC = self;
    
    OAFavoriteGroup *group = [OAFavoritesHelper getGroupByName:self.editName];
    if (group)
    {
        NSMutableArray *colors = [NSMutableArray array];
        for (OAFavoriteItem *item in group.points)
        {
            [colors addObject:[item getColor]];
        }
        _colorCollectionHandler.groupColors = [colors copy];
    }
    [_colorCollectionHandler setupDefaultCategory];
}

- (void) setupIconHandler
{
    _poiIconCollectionHandler = [[PoiIconCollectionHandler alloc] initWithIsFavoriteList:!self.isNewItem];
    _poiIconCollectionHandler.delegate = self;
    _poiIconCollectionHandler.handlerDelegate = self;
    _poiIconCollectionHandler.hostVC = self;
    _poiIconCollectionHandler.customTitle = OALocalizedString(@"profile_icon");
    _poiIconCollectionHandler.regularIconColor = [UIColor colorNamed:ACColorNameIconColorSecondary];
    _poiIconCollectionHandler.selectedIconColor = [_selectedColorItem getColor];
    
    OAFavoriteGroup *group = [OAFavoritesHelper getGroupByName:self.editName];
    if (group)
    {
        NSMutableArray *iconNames = [NSMutableArray array];
        for (OAFavoriteItem *item in group.points)
        {
            [iconNames addObject:[item getIcon]];
        }
        _poiIconCollectionHandler.groupIcons = [iconNames copy];
    }
    
    [_poiIconCollectionHandler setItemSizeWithSize:48];
    [_poiIconCollectionHandler setIconBackgroundSizeWithSize:36];
    [_poiIconCollectionHandler setIconSizeWithSize:24];
    [_poiIconCollectionHandler setSpacingWithSpacing:9];
    
    if (!_isNewItem && self.editIconName)
        _selectedIconName = self.editIconName;
    else
    {
        _selectedIconName = [self getDefaultIconName];
        self.editIconName = _selectedIconName;
    }
    [_poiIconCollectionHandler setIconName:_selectedIconName];
}

- (void)setupBackgroundIcons
{
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
    _shapesCollectionHandler = [[ShapesCollectionHandler alloc] initWithBackgroundIconNames:_backgroundIconNames isFavoriteList:!self.isNewItem];
    _shapesCollectionHandler.handlerDelegate = self;
    _shapesCollectionHandler.hostVC = self;
    
    OAFavoriteGroup *group = [OAFavoritesHelper getGroupByName:self.editName];
    if (group)
    {
        NSMutableArray *backgroundIconNames = [NSMutableArray array];
        for (OAFavoriteItem *item in group.points)
        {
            [backgroundIconNames addObject:[item getBackgroundIcon]];
        }
        _shapesCollectionHandler.groupShapes = [backgroundIconNames copy];
    }
    
    _shapesCollectionHandler.selectedCatagoryKey = _backgroundIconNames[_selectedBackgroundIndex];
    [_shapesCollectionHandler setupDefaultCategory];
}

- (NSString *)getPreselectedIconName
{
    return (!_isNewItem) ? nil : self.editIconName;
}

- (NSString *)getDefaultIconName
{
    NSString *preselectedIconName = [self getPreselectedIconName];
    if (preselectedIconName && preselectedIconName.length > 0)
        return preselectedIconName;
    else if (self.editIconName && self.editIconName.length > 0)
        return self.editIconName;
    else if (_poiIconCollectionHandler.lastUsedIcons && _poiIconCollectionHandler.lastUsedIcons.count > 0)
        return _poiIconCollectionHandler.lastUsedIcons[0];
    return DEFAULT_ICON_NAME_KEY;
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

- (BOOL)isValidText
{
    return !_isNewItem || _isTextViewNameValid;
}

- (BOOL)isAppearanceChanged
{
    OAFavoriteGroup *groupExist = [OAFavoritesHelper getGroupByName:self.editName];
    return !groupExist
            || ![self.editBackgroundIconName isEqualToString:groupExist.backgroundType]
            || ![self.editIconName isEqual:groupExist.iconName]
            || ![self.editColor isEqual:groupExist.color];
}

- (void)changeSaveButtonAvailabilityWithGroup
{
    [self changeButtonAvailability:_saveBarButton
                         isEnabled:[self isValidText] && [self isAppearanceChanged]];
}

- (PoiIconCollectionHandler *) getPoiIconCollectionHandler
{
    return _poiIconCollectionHandler;
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

    [self changeSaveButtonAvailabilityWithGroup];
}

#pragma mark - OACollectionCellDelegate

- (void)onCollectionItemSelected:(NSIndexPath *)indexPath selectedItem:(id)selectedItem collectionView:(UICollectionView *)collectionView shouldDismiss:(BOOL)shouldDismiss
{
    _wasChanged = YES;
    if (collectionView == [_poiIconCollectionHandler getCollectionView])
    {
        NSString *iconName = [_poiIconCollectionHandler getSelectedItem];
        if (iconName)
            _selectedIconName = iconName;
        self.editIconName = _selectedIconName;
    }
    else if (collectionView == [_colorCollectionHandler getCollectionView])
    {
        NSArray *data = [_colorCollectionHandler getData];
        if (indexPath.section >= data.count || indexPath.row >= [data[indexPath.section] count])
            return;
        
        _selectedColorItem = data[indexPath.section][indexPath.row];
        self.editColor = [_selectedColorItem getColor];
        _needToScrollToSelectedColor = YES;
        if (_iconIndexPath && _shapeIndexPath && _iconIndexPath.section < self.tableView.numberOfSections && _shapeIndexPath.section < self.tableView.numberOfSections)
            [self.tableView reloadRowsAtIndexPaths:@[_iconIndexPath, _shapeIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    [self applyLocalization];
    [self changeSaveButtonAvailabilityWithGroup];
}

- (void)reloadCollectionData
{
    [self.tableView reloadRowsAtIndexPaths:@[_colorGridIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - OABaseCollectionHandlerDelegate

- (void)onCategorySelected:(NSString *)category with:(OAIconsPaletteCell *)cell
{
    if (_isNewItem)
        return;
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (indexPath)
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    if ([category isEqualToString: @"original"])
    {
        OAFavoriteGroup *groupExist = [OAFavoritesHelper getGroupByName:self.editName];
        if (groupExist)
        {
            _selectedIconName = groupExist.iconName;
            self.editIconName = _selectedIconName;
        }
    }
    [self changeSaveButtonAvailabilityWithGroup];
}

- (void)onCategorySelectedWith:(OACollectionSingleLineTableViewCell *)cell
{
    if (_isNewItem)
        return;
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (indexPath)
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self changeSaveButtonAvailabilityWithGroup];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    _isTextViewNameValid = YES;
    _wasChanged = YES;
    NSIndexPath *indexPath = [self indexPathForCellContainingView:textView inTableView:self.tableView];
    OATableRowData *item = [self.tableData itemForIndexPath:indexPath];
    if ([item.key isEqualToString:kInputNameKey])
    {
        OAFavoriteGroup *groupExist = [OAFavoritesHelper getGroupByName:textView.text];
        _isTextViewNameValid = [OAFavoritesHelper isGroupNameValidWithText:textView.text] && !groupExist;
        if (!_isTextViewNameValid && groupExist)
        {
            _isTextViewNameValid = textView.text.length > 0
                && (![groupExist.iconName isEqualToString:self.editIconName]
                || ![groupExist.backgroundType isEqualToString:self.editBackgroundIconName]
                || ![groupExist.color isEqual:self.editColor]);
        }
        self.editName = textView.text;
    }

    [self applyLocalization];
    [self changeButtonAvailability:_saveBarButton isEnabled:_isTextViewNameValid];
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
