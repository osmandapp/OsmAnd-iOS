//
//  OAEditPointViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 05.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAEditPointViewController.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OADefaultFavorite.h"
#import "OATitleRightIconCell.h"
#import "OATextInputFloatingCellWithIcon.h"
#import "OASettingsTableViewCell.h"
#import "OAColorsTableViewCell.h"
#import "OAShapesTableViewCell.h"
#import "OAPoiTableViewCell.h"
#import "OASelectFavoriteGroupViewController.h"
#import "OAAddFavoriteGroupViewController.h"
#import "OAReplaceFavoriteViewController.h"
#import "OAFolderCardsCell.h"
#import "OAFavoritesHelper.h"
#import "OAFavoriteItem.h"
#import "OAGpxWptItem.h"
#import "OAGPXDocumentPrimitives.h"
#import "OARootViewController.h"
#import "OATargetInfoViewController.h"
#import "OATargetPointsHelper.h"
#import "OATableViewCustomHeaderView.h"
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

#include "Localization.h"
#import "OAGPXDocument.h"
#import "OATargetMenuViewController.h"

#define kNameKey @"kNameKey"
#define kDescKey @"kDescKey"
#define kAddressKey @"kAddressKeyd"
#define kIconsKey @"kIconsKey"
#define kBackgroundsKey @"kBackgroundsKey"
#define kSelectGroupKey @"kSelectGroupKey"
#define kReplaceKey @"kReplaceKey"
#define kDeleteKey @"kDeleteKey"
#define kLastUsedIconsKey @"kLastUsedIconsKey"

#define kDefaultIcon @"special_star"
#define kVerticalMargin 8.
#define kSideMargin 20.
#define kEmptyTextCellHeight 48.
#define kTextCellTopMargin 18.
#define kTextCellBottomMargin 17.
#define kCategoryCellIndex 0
#define kPoiCellIndex 1
#define kFullHeaderHeight 100
#define kCompressedHeaderHeight 62
#define kLastUsedIconsLimit 20

@interface OAEditPointViewController() <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate, OAColorsTableViewCellDelegate, OAPoiTableViewCellDelegate, OAShapesTableViewCellDelegate, MDCMultilineTextInputLayoutDelegate, OAReplacePointDelegate, OAFolderCardsCellDelegate, OASelectFavoriteGroupDelegate, OAAddFavoriteGroupDelegate, UIGestureRecognizerDelegate, UIAdaptivePresentationControllerDelegate>

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
    NSArray<NSNumber *> *_colors;
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
    OAFavoriteColor *_selectedColor;
    NSString *_selectedIconCategoryName;
    NSString *_selectedIconName;
    NSInteger _selectedColorIndex;
    NSInteger _selectedBackgroundIndex;
    NSString *_editingTextFieldKey;
    
    NSInteger _selectCategorySectionIndex;
    NSInteger _selectCategoryLabelRowIndex;
    NSInteger _selectCategoryCardsRowIndex;
    NSInteger _appearenceSectionIndex;
    NSInteger _poiIconRowIndex;
    NSInteger _colorRowIndex;
    NSInteger _shapeRowIndex;
    
    OACollectionViewCellState *_scrollCellsState;
    NSString *_renamedPointAlertMessage;
    OATargetMenuViewControllerState *_targetMenuState;
}

- (instancetype)initWithFavorite:(OAFavoriteItem *)favorite
{
    self = [super initWithNibName:@"OAEditPointViewController" bundle:nil];
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
        self.groupColor = [favorite getColor];
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithGpxWpt:(OAGpxWptItem *)gpxWpt
{
    self = [super initWithNibName:@"OAEditPointViewController" bundle:nil];
    if (self)
    {
        _editPointType = EOAEditPointTypeWaypoint;
        _app = [OsmAndApp instance];
        _isNewItemAdding = NO;
        _isUnsaved = YES;
        _pointHandler = [[OAGpxWptEditingHandler alloc] initWithItem:gpxWpt];self.name = gpxWpt.point.name;
        _waypoint = gpxWpt;
        self.desc = gpxWpt.point.desc;
        self.address = [gpxWpt.point getExtensionByKey:ADDRESS_EXTENSION].value;
        self.groupTitle = [self getGroupTitle]/*gpxWpt.point.type*/;
        self.groupColor = gpxWpt.color ? gpxWpt.color : [UIColor colorFromString:gpxWpt.point.color];
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithLocation:(CLLocationCoordinate2D)location
                           title:(NSString *)formattedTitle
                     customParam:(NSString *)customParam
                       pointType:(EOAEditPointType)pointType
                 targetMenuState:(OATargetMenuViewControllerState *)targetMenuState
                             poi:(OAPOI *)poi
{
    self = [super initWithNibName:@"OAEditPointViewController" bundle:nil];
    if (self)
    {
        _editPointType = pointType;
        _isNewItemAdding = YES;
        _isUnsaved = YES;
        _app = [OsmAndApp instance];
        _targetMenuState = targetMenuState;

        if (_editPointType == EOAEditPointTypeFavorite)
        {
            _pointHandler = [[OAFavoriteEditingHandler alloc] initWithLocation:location title:formattedTitle address:customParam poi:poi];
            self.address = customParam ? customParam : @"";
        }
        else if (_editPointType == EOAEditPointTypeWaypoint)
        {
            _pointHandler = [[OAGpxWptEditingHandler alloc] initWithLocation:location title:formattedTitle gpxFileName:customParam poi:poi];
            self.gpxFileName = customParam ? customParam : @"";
            self.address = ((OAGpxWptEditingHandler *)_pointHandler).getAddress;
        }
        
        self.name = formattedTitle ? formattedTitle : @"";
        self.desc = @"";
        self.groupTitle = [self getGroupTitle];
        self.groupColor = [_pointHandler getColor];

        _selectedIconCategoryName = @"special";
        _selectedIconName = kDefaultIcon;
        _selectedColorIndex = 0;
        _selectedBackgroundIndex = 0;

        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _wasChanged = NO;
    _initialName = self.name;
    _initialGroupName = self.groupTitle;
    _editingTextFieldKey = @"";

    _selectCategorySectionIndex = -1;
    _selectCategoryLabelRowIndex = -1;
    _selectCategoryCardsRowIndex = -1;
    _appearenceSectionIndex = -1;
    _poiIconRowIndex = -1;
    _colorRowIndex = -1;
    _shapeRowIndex = -1;
    _scrollCellsState = [[OACollectionViewCellState alloc] init];

    [self initLastUsedIcons];
    [self setupGroups];
    [self setupColors];
    [self setupIcons];
    [self generateData];
}

- (void)setupHeaderName
{
    if (self.name.length > 0)
    {
        self.titleLabel.text = self.name;
    }
    else
    {
        if (_editPointType == EOAEditPointTypeFavorite)
            self.titleLabel.text = _isNewItemAdding ? OALocalizedString(@"add_favorite") : OALocalizedString(@"ctx_mnu_edit_fav");
        else if (_editPointType == EOAEditPointTypeWaypoint)
            self.titleLabel.text = _isNewItemAdding ? OALocalizedString(@"add_waypoint_short") : OALocalizedString(@"edit_waypoint_short");

    }
}

- (void) setupGroups
{
    NSMutableArray *names = [NSMutableArray new];
    NSMutableArray *sizes = [NSMutableArray new];
    NSMutableArray *colors = [NSMutableArray new];

    if (_editPointType == EOAEditPointTypeFavorite)
    {
        if (![OAFavoritesHelper isFavoritesLoaded])
            [OAFavoritesHelper loadFavorites];

        NSArray<OAFavoriteGroup *> *allGroups = [OAFavoritesHelper getFavoriteGroups];

        if (![[OAFavoritesHelper getGroups].allKeys containsObject:@""]) {
            [names addObject:OALocalizedString(@"favorites")];
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
            [colors addObject:group[@"color"] ? [UIColor colorFromString:group[@"color"]] : UIColorFromRGB(color_primary_purple)];
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

    if (!_selectedIconName || _selectedIconName.length == 0)
        _selectedIconName = kDefaultIcon;

    if (!_selectedIconCategoryName || _selectedIconCategoryName.length == 0)
        _selectedIconCategoryName = @"special";
    
    _backgroundIconNames = [OAFavoritesHelper getFlatBackgroundIconNamesList];
    _backgroundContourIconNames = [OAFavoritesHelper getFlatBackgroundContourIconNamesList];

    NSMutableArray * tempBackgroundIcons = [NSMutableArray new];
    for (NSString *iconName in _backgroundIconNames)
        [tempBackgroundIcons addObject:[NSString stringWithFormat:@"bg_point_%@", iconName]];

    _backgroundIcons = [NSArray arrayWithArray:tempBackgroundIcons];

    _selectedBackgroundIndex = [_backgroundIconNames indexOfObject:[_pointHandler getBackgroundIcon]];
    if (_selectedBackgroundIndex == -1)
        _selectedBackgroundIndex = 0;
}

- (NSString *)getPreselectedIconName
{
    return (!_pointHandler || !_isNewItemAdding) ? nil : [_pointHandler getIcon];;
}

- (NSString *)getInitCategory
{
    for (int j = 0; j < [_iconCategories allKeys].count; j ++)
    {
        NSArray<NSString *> *iconsArray = _iconCategories[ [_iconCategories allKeys][j] ];
        for (int i = 0; i < iconsArray.count; i ++)
        {
            if ([iconsArray[i] isEqualToString:[_pointHandler getIcon]])
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
            NSString *translatedName = OALocalizedString(name);
            _iconCategories[translatedName] = icons;
        }
    }
    
    _selectedIconCategoryName = [self getInitCategory];
    [self createIconForCategory];
}

- (void) initLastUsedIcons
{
    _lastUsedIcons = @[];
    NSArray<NSString *> *fromPref = [OAAppSettings.sharedManager.lastUsedFavIcons get];
    if (fromPref && fromPref.count > 0)
        _lastUsedIcons = fromPref;
}

- (NSString *)getDefaultIconName
{
    NSString *preselectedIconName = [self getPreselectedIconName];
    if (preselectedIconName && preselectedIconName.length > 0)
        return preselectedIconName;
    else if (_lastUsedIcons && _lastUsedIcons.count > 0)
        return _lastUsedIcons[0];
    return kDefaultIcon;
}

- (void) addLastUsedIcon:(NSString *)iconName save:(BOOL)save
{
    NSMutableArray<NSString *> *mutableLastUsedIcons = _lastUsedIcons.mutableCopy;
    [mutableLastUsedIcons removeObject:iconName];
    if (mutableLastUsedIcons.count >= kLastUsedIconsLimit)
        [mutableLastUsedIcons removeLastObject];
    
    [mutableLastUsedIcons insertObject:iconName atIndex:0];
    _lastUsedIcons = mutableLastUsedIcons.copy;
    if (save)
        [OAAppSettings.sharedManager.lastUsedFavIcons set:_lastUsedIcons];
}

- (void)createIconForCategory
{
    [self createIconList];
}

- (void)createIconList
{
    NSMutableArray *iconNameList = [NSMutableArray array];
    [iconNameList addObjectsFromArray:_iconCategories[_selectedIconCategoryName]];
    
    NSString *preselectedIconName = [self getPreselectedIconName];
    if (preselectedIconName && preselectedIconName.length > 0)
    {
        [iconNameList removeObject:preselectedIconName];
        [iconNameList insertObject:preselectedIconName atIndex:0];
    }
    
    _currentCategoryIcons = [NSArray arrayWithArray:iconNameList];
}

- (OrderedDictionary<NSString *, NSArray<NSString *> *> *) loadOrderedJSON
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

- (void)setupColors
{
    UIColor* loadedColor = [_pointHandler getColor];
    _selectedColor = [OADefaultFavorite nearestFavColor:loadedColor];
    _selectedColorIndex = [[OADefaultFavorite builtinColors] indexOfObject:_selectedColor];
    
    NSMutableArray *tempColors = [NSMutableArray new];
    for (OAFavoriteColor *favColor in [OADefaultFavorite builtinColors])
    {
        [tempColors addObject:@([OAUtilities colorToNumber:favColor.color])];
    }
    _colors = [NSArray arrayWithArray:tempColors];
}

- (void)updateHeaderIcon
{
    _headerIconBackground.image = [UIImage templateImageNamed:_backgroundIcons[_selectedBackgroundIndex]];
    _headerIconBackground.tintColor = _selectedColor.color;

    UIImage *poiIcon = [OATargetInfoViewController getIcon:[@"mx_" stringByAppendingString:_selectedIconName]];
    _headerIconPoi.image = [poiIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _headerIconPoi.tintColor = UIColor.whiteColor;
}

- (void)generateData
{
    [self setupHeaderName];

    NSMutableArray *data = [NSMutableArray new];

    if (self.groupTitle.length == 0)
        self.groupTitle = [self getGroupTitle];

    NSMutableArray *section = [NSMutableArray new];
    [section addObject:@{
        @"header" : OALocalizedString(@"name_and_descr"),
        @"type" : [OATextInputFloatingCellWithIcon getCellIdentifier],
        @"title" : self.name ? self.name : @"",
        @"hint" : OALocalizedString(@"fav_name"),
        @"isEditable" : @(![_pointHandler isSpecialPoint]),
        @"key" : kNameKey
    }];
    [section addObject:@{
        @"type" : [OATextInputFloatingCellWithIcon getCellIdentifier],
        @"title" : self.desc ? self.desc : @"",
        @"hint" : OALocalizedString(@"description"),
        @"isEditable" : @YES,
        @"key" : kDescKey
    }];
    [section addObject:@{
        @"type" : [OATextInputFloatingCellWithIcon getCellIdentifier],
        @"title" : self.address ? self.address : @"",
        @"hint" : OALocalizedString(@"shared_string_address"),
        @"isEditable" : @YES,
        @"key" : kAddressKey
    }];
    [data addObject:[NSArray arrayWithArray:section]];

    section = [NSMutableArray new];
    [section addObject:@{
        @"header" : OALocalizedString(@"fav_group"),
        @"type" : [OASettingsTableViewCell getCellIdentifier],
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
        @"addButtonTitle" : OALocalizedString(@"fav_add_group")
    }];
    _selectCategoryCardsRowIndex = section.count - 1;
    [data addObject:[NSArray arrayWithArray:section]];
    _selectCategorySectionIndex = data.count - 1;

    section = [NSMutableArray new];
    [section addObject:@{
        @"header" : OALocalizedString(@"map_settings_appearance"),
        @"type" : [OAPoiTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"icon"),
        @"value" : @"",
        @"selectedCategoryName" : _selectedIconCategoryName,
        @"categotyData" : _poiCategories,
        @"selectedIconName" : _selectedIconName,
        @"poiData" : _currentCategoryIcons,
        @"key" : kIconsKey
    }];
    _poiIconRowIndex = section.count - 1;

    [section addObject:@{
        @"type" : [OAColorsTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"fav_color"),
        @"value" : _selectedColor.name,
        @"index" : @(_selectedColorIndex),
    }];
    _colorRowIndex = section.count - 1;

    [section addObject:@{
        @"type" : [OAShapesTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"shape"),
        @"value" : OALocalizedString(_backgroundIconNames[_selectedBackgroundIndex]),
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
        @"header" : OALocalizedString(@"actions").upperCase,
        @"type" : [OATitleRightIconCell getCellIdentifier],
        @"title" : OALocalizedString(@"fav_replace"),
        @"img" : @"ic_custom_replace",
        @"color" : UIColorFromRGB(color_primary_purple),
        @"key" : kReplaceKey
    }];
    if (!_isNewItemAdding)
    {
        [section addObject:@{
            @"type" : [OATitleRightIconCell getCellIdentifier],
            @"title" : OALocalizedString(@"shared_string_delete"),
            @"img" : @"ic_custom_remove_outlined",
            @"color" : UIColorFromRGB(color_primary_red),
            @"key" : kDeleteKey
        }];
    }
    [data addObject:[NSArray arrayWithArray:section]];

    _data = [NSArray arrayWithArray:data];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.presentationController.delegate = self;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    self.doneButton.hidden = NO;

    [self updateHeaderIcon];
    [self setupHeaderName];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)applyLocalization
{
    [super applyLocalization];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

- (NSString *)getGroupTitle
{
    return [_pointHandler getGroupTitle];
}

- (void)viewDidLayoutSubviews
{
    [self setupHeaderWithVerticalOffset:self.tableView.contentOffset.y];
}

- (void)setupHeaderWithVerticalOffset:(CGFloat)offset
{
    CGFloat compressingHeight = kFullHeaderHeight - kCompressedHeaderHeight;
    if (![OAUtilities isLandscape])
    {
        CGFloat multiplier;

        if (offset <= 0)
        {
            multiplier = 1;
            _navBarHeightConstraint.constant = kFullHeaderHeight;
        }
        else if (offset > 0 && offset < compressingHeight)
        {
            multiplier = offset < 0 ? 0 : 1 - (offset / compressingHeight);
            _navBarHeightConstraint.constant = kCompressedHeaderHeight + compressingHeight * multiplier;
        }
        else
        {
            multiplier = 0;
            _navBarHeightConstraint.constant = kCompressedHeaderHeight;
        }

        self.titleLabel.font = [UIFont systemFontOfSize:17 * multiplier weight:UIFontWeightSemibold];
        self.titleLabel.alpha = multiplier;
        self.titleLabel.hidden = NO;
    }
    else
    {
        _navBarHeightConstraint.constant = kCompressedHeaderHeight;
        self.titleLabel.hidden = YES;
        self.titleLabel.alpha = 0;
    }
}

- (void) dismissViewController
{
    if (_isUnsaved)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"shared_string_dismiss") message:OALocalizedString(@"osm_editing_lost_changes_title") preferredStyle:UIAlertControllerStyleAlert];
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

- (void) doDismiss
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (_renamedPointAlertMessage)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"fav_point_dublicate") message:_renamedPointAlertMessage preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
            [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
        }
        if (!_isNewItemAdding && _targetMenuState && [_targetMenuState isKindOfClass:OATrackMenuViewControllerState.class])
        {
            OAGPXDatabase *db = [OAGPXDatabase sharedDb];
            [[OARootViewController instance].mapPanel openTargetViewWithGPX:[db getGPXItem:[
                    [db getFileDir:self.gpxFileName] stringByAppendingPathComponent:self.gpxFileName.lastPathComponent]]
                                                               trackHudMode:EOATrackMenuHudMode
                                                                      state:_targetMenuState];
        }
    }];
}

#pragma mark - Actions

- (void)onCancelButtonPressed
{
}

- (void)onDoneButtonPressed
{
    _isUnsaved = NO;
    if (_wasChanged || _isNewItemAdding)
    {
        OAPointEditingData *data = [[OAPointEditingData alloc] init];
        NSString *savingGroup = [[OAFavoriteGroup convertDisplayNameToGroupIdName:self.groupTitle] trim];
        
        data.descr = self.desc ? self.desc : @"";
        data.address = self.address ? self.address : @"";
        data.color = _selectedColor.color;
        data.backgroundIcon = _backgroundIconNames[_selectedBackgroundIndex];
        data.icon = _selectedIconName;
        [self addLastUsedIcon:_selectedIconName save:YES];

        if (_editPointType == EOAEditPointTypeWaypoint)
        {
            if (!_pointHandler.gpxWptDelegate)
                _pointHandler.gpxWptDelegate = self.gpxWptDelegate;
            if ([savingGroup isEqualToString:OALocalizedString(@"gpx_waypoints")])
                savingGroup = @"";
        }

        if (_isNewItemAdding || ![self.name isEqualToString:_initialName] || ([self.name isEqualToString:_initialName] && ![self.groupTitle isEqualToString:_initialGroupName]))
        {
            NSString *savingName = [self.name trim];
            NSDictionary *checkingResult = [_pointHandler checkDuplicates:savingName group:savingGroup];
            
            if (checkingResult && ![checkingResult[@"name"] isEqualToString:self.name])
            {
                savingName = checkingResult[@"name"];
                if ([checkingResult[@"status"] isEqualToString:@"emoji"])
                    _renamedPointAlertMessage = [NSString stringWithFormat:OALocalizedString(@"fav_point_emoticons_message"), savingName];
                else
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

        [[OARootViewController instance].mapPanel reopenContextMenu];
    }
}

- (void) editName:(id)sender
{
    _wasChanged = YES;
    self.name = [((UITextField*)sender) text];
}

- (void) editDescription:(id)sender
{
    _wasChanged = YES;
    self.desc = [((UITextField*)sender) text];
}

- (void) editAddress:(id)sender
{
    _wasChanged = YES;
    self.address = [((UITextField*)sender) text];
}

- (void) deleteItemWithAlertView
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"fav_remove_q") preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_no") style:UIAlertActionStyleDefault handler:nil]];
    
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (_editPointType == EOAEditPointTypeWaypoint && !_pointHandler.gpxWptDelegate)
            _pointHandler.gpxWptDelegate = self.gpxWptDelegate;

        [_pointHandler deleteItem];
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) deleteFavoriteItem:(OAFavoriteItem *)favoriteItem
{
    [OAFavoritesHelper deleteNewFavoriteItem:favoriteItem];
}

-(void) clearButtonPressed:(UIButton *)sender
{
    NSIndexPath *indexPath = [self indexPathForCellContainingView:sender inTableView:self.tableView];
    OATextInputFloatingCellWithIcon *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self.tableView beginUpdates];
    
    cell.textField.text = @"";
    
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    if ([key isEqualToString:kNameKey])
        self.name = @"";
    else if ([key isEqualToString:kDescKey])
        self.desc = @"";
    else if ([key isEqualToString:kAddressKey])
        self.address = @"";

    cell.fieldLabel.hidden = YES;
    cell.textFieldTopConstraint.constant = 0;
    cell.textFieldBottomConstraint.constant = 0;
    
    [self generateData];
    [self.tableView endUpdates];
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self setupHeaderWithVerticalOffset:scrollView.contentOffset.y];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    
    if ([cellType isEqualToString:[OATextInputFloatingCellWithIcon getCellIdentifier]])
    {
        OATextInputFloatingCellWithIcon *resultCell = [self.tableView dequeueReusableCellWithIdentifier:[OATextInputFloatingCellWithIcon getCellIdentifier]];
        if (resultCell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextInputFloatingCellWithIcon getCellIdentifier] owner:self options:nil];
            resultCell = nib[0];
            resultCell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
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
        
        textField.font = [UIFont systemFontOfSize:17.0];
        textField.clearButton.imageView.tintColor = UIColorFromRGB(color_icon_color);
        [textField.clearButton setImage:[UIImage templateImageNamed:@"ic_custom_clear_field"] forState:UIControlStateNormal];
        [textField.clearButton setImage:[UIImage templateImageNamed:@"ic_custom_clear_field"] forState:UIControlStateHighlighted];
        resultCell.buttonView.hidden = YES;
        resultCell.fieldLabelLeadingConstraint.constant = 0;
        resultCell.textFieldLeadingConstraint.constant = 0;
        
        textField.placeholder = item[@"hint"];
        resultCell.separatorInset = UIEdgeInsetsZero;
        
        if (((NSString *)item[@"title"]).length == 0)
        {
            resultCell.fieldLabel.hidden = YES;
            resultCell.textFieldTopConstraint.constant = 0;
            resultCell.textFieldBottomConstraint.constant = 0;
        }
        else
        {
            resultCell.fieldLabel.hidden = NO;
            resultCell.textFieldTopConstraint.constant = kTextCellTopMargin;
            resultCell.textFieldBottomConstraint.constant = kTextCellBottomMargin;
        }
        
        BOOL isEditable = [item[@"isEditable"] boolValue];
        textField.enabled = isEditable;
        textField.userInteractionEnabled = isEditable;
        textField.textColor = isEditable ? UIColor.blackColor : UIColor.darkGrayColor;
        
        return resultCell;
    }
    else if ([cellType isEqualToString:[OASettingsTableViewCell getCellIdentifier]])
    {
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.descriptionView.font = [UIFont systemFontOfSize:17.0];
            cell.descriptionView.numberOfLines = 1;
            cell.iconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
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
    else if ([cellType isEqualToString:[OAPoiTableViewCell getCellIdentifier]])
    {
        OAPoiTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAPoiTableViewCell getCellIdentifier]];
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
            cell.currentColor = _colors[_selectedColorIndex].intValue;
            cell.currentIcon = item[@"selectedIconName"];
            [cell.collectionView reloadData];
            [cell.categoriesCollectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAColorsTableViewCell getCellIdentifier]])
    {
        OAColorsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAColorsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAColorsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
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
    else if ([cellType isEqualToString:[OAShapesTableViewCell getCellIdentifier]])
    {
        OAShapesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAShapesTableViewCell getCellIdentifier]];
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
            cell.currentColor = _colors[_selectedColorIndex].intValue;
            cell.currentIcon = selectedIndex;
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OATitleRightIconCell getCellIdentifier]])
    {
        OATitleRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:[OATitleRightIconCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleRightIconCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.titleView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightSemibold];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.titleView.text = item[@"title"];
        cell.titleView.textColor = item[@"color"];
        cell.iconView.tintColor = item[@"color"];
        [cell.iconView setImage:[UIImage templateImageNamed:item[@"img"]]];
        return cell;
    }
    else if ([cellType isEqualToString:[OAFolderCardsCell getCellIdentifier]])
    {
        OAFolderCardsCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAFolderCardsCell getCellIdentifier]];
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
    
    return nil;
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *item = _data[section].firstObject;
    return item[@"header"];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    vw.label.textColor = UIColorFromRGB(color_text_footer);
    vw.label.text = [title upperCase];
    vw.label.userInteractionEnabled = NO;
 
    int offset = section == 0 ? 32 : 16;
    [vw setYOffset:offset];
    [vw setXOffset:20];
    return vw;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    
    if ([key isEqualToString:kNameKey] || [key isEqualToString:kDescKey] || [key isEqualToString:kAddressKey])
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
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
        [self presentViewController:selectGroupController animated:YES completion:nil];
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
            if (gpxDocument.locationMarks.count > 0)
                replaceScreen = [[OAReplaceFavoriteViewController alloc] initWithItemType:EOAReplacePointTypeWaypoint gpxDocument:gpxDocument];
            else
                return [self showAlertNotFoundReplaceItem];
        }

        replaceScreen.delegate = self;
        [self presentViewController:replaceScreen animated:YES completion:nil];
    }
    else if ([key isEqualToString:kDeleteKey])
    {
        [self deleteItemWithAlertView];
    }
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
    [self presentViewController:alert animated:YES completion:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OATextInputFloatingCellWithIcon getCellIdentifier]])
    {
        NSString *key = item[@"key"];
        NSString *text;
        if ([key isEqualToString:kNameKey])
            text = self.name;
        else if ([key isEqualToString:kDescKey])
            text = self.desc;
        else if ([key isEqualToString:kAddressKey])
            text = self.address;
        
        if (text.length == 0)
            return kEmptyTextCellHeight;
        else
        {
            CGFloat cellSideMargin = kSideMargin;
            CGFloat labelWidth = [OAUtilities calculateScreenWidth] - 2 * cellSideMargin - 2 * [OAUtilities getLeftMargin];
            if ([key isEqualToString:_editingTextFieldKey])
                labelWidth -= kSideMargin;
            
            CGSize textBounds = [OAUtilities calculateTextBounds:text width:labelWidth font:[UIFont systemFontOfSize:17]];
            return textBounds.height + kTextCellTopMargin + kTextCellBottomMargin + kVerticalMargin;
        }
    }
    return UITableViewAutomaticDimension;
}

- (NSIndexPath *)indexPathForCellContainingView:(UIView *)view inTableView:(UITableView *)tableView
{
    CGPoint viewCenterRelativeToTableview = [tableView convertPoint:CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds)) fromView:view];
    NSIndexPath *cellIndexPath = [tableView indexPathForRowAtPoint:viewCenterRelativeToTableview];
    return cellIndexPath;
}

#pragma mark - UITextViewDelegate

- (void) textChanged:(UITextView * _Nonnull)textView userInput:(BOOL)userInput
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
    
    [self.tableView beginUpdates];
    OATextInputFloatingCellWithIcon *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (textView.text.length == 0)
    {
        cell.fieldLabel.hidden = YES;
        cell.textFieldTopConstraint.constant = 0;
        cell.textFieldBottomConstraint.constant = 0;
    }
    else
    {
        cell.fieldLabel.hidden = NO;
        cell.textFieldTopConstraint.constant = kTextCellTopMargin;
        cell.textFieldBottomConstraint.constant = kTextCellBottomMargin;
    }
    [self generateData];
    [self.tableView endUpdates];
}

-(void)textViewDidChange:(UITextView *)textView
{
    [self textChanged:textView userInput:YES];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    NSIndexPath *indexPath = [self indexPathForCellContainingView:textView inTableView:self.tableView];
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    _editingTextFieldKey = key;
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    _editingTextFieldKey = @"";
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)sender
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

- (void) onPoiCategorySelected:(NSString *)category index:(NSInteger)index
{
    _selectedIconCategoryName = category;
    [self createIconList];
    [self generateData];
    OAPoiTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_poiIconRowIndex inSection:_appearenceSectionIndex]];
    [cell updateIconsList:_currentCategoryIcons];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void) onPoiSelected:(NSString *)poiName;
{
    _wasChanged = YES;
    _selectedIconName = poiName;
    [self updateHeaderIcon];
}

#pragma mark - OAShapesTableViewCellDelegate

- (void)iconChanged:(NSInteger)tag
{
    _wasChanged = YES;
    _selectedBackgroundIndex = (int)tag;
    [self updateHeaderIcon];
    [self generateData];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_shapeRowIndex inSection:_appearenceSectionIndex]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - OAColorsTableViewCellDelegate

- (void)colorChanged:(NSInteger)tag
{
    _wasChanged = YES;
    _selectedColorIndex = tag;
    _selectedColor = [OADefaultFavorite builtinColors][tag];
    [self updateHeaderIcon];
    [self generateData];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_poiIconRowIndex inSection:_appearenceSectionIndex], [NSIndexPath indexPathForRow:_colorRowIndex inSection:_appearenceSectionIndex], [NSIndexPath indexPathForRow:_shapeRowIndex inSection:_appearenceSectionIndex]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - OAFolderCardsCellDelegate

- (void) onItemSelected:(NSInteger)index
{
    _wasChanged = YES;
    self.groupTitle = _groupNames[index];

    UIColor *selectedColor;
    NSString *groupName;
    if (_editPointType == EOAEditPointTypeFavorite)
    {
        groupName = [OAFavoriteGroup convertDisplayNameToGroupIdName:_groupNames[index]];
        OAFavoriteGroup *group = [OAFavoritesHelper getGroupByName:[OAFavoriteGroup convertDisplayNameToGroupIdName:groupName]];
        if (group)
            selectedColor = group.color;
    }
    else if (_editPointType == EOAEditPointTypeWaypoint)
    {
        selectedColor = [UIColor colorFromString:[(OAGpxWptEditingHandler *) _pointHandler getGroupsWithColors][self.groupTitle]];
    }

    if (selectedColor)
        _selectedColor = [OADefaultFavorite nearestFavColor:selectedColor];
    else
        _selectedColor = [OADefaultFavorite builtinColors].firstObject;
    
    _selectedColorIndex = [[OADefaultFavorite builtinColors] indexOfObject:_selectedColor];
    [self updateHeaderIcon];
    
    if ([self.groupTitle isEqualToString:@""])
        self.groupTitle = OALocalizedString(@"favorites");
    [self generateData];
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_selectCategoryLabelRowIndex inSection:_selectCategorySectionIndex], [NSIndexPath indexPathForRow:_poiIconRowIndex inSection:_appearenceSectionIndex], [NSIndexPath indexPathForRow:_colorRowIndex inSection:_appearenceSectionIndex], [NSIndexPath indexPathForRow:_shapeRowIndex inSection:_appearenceSectionIndex]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) onAddFolderButtonPressed
{
    OAAddFavoriteGroupViewController * addGroupVC = [[OAAddFavoriteGroupViewController alloc] init];
    addGroupVC.delegate = self;
    [self presentViewController:addGroupVC animated:YES completion:nil];
}

#pragma mark - OASelectFavoriteGroupDelegate

- (void) onGroupSelected:(NSString *)selectedGroupName
{
    _wasChanged = YES;
    self.groupTitle = selectedGroupName;

    UIColor *selectedColor;
    if (_editPointType == EOAEditPointTypeFavorite)
    {
        OAFavoriteGroup *group = [OAFavoritesHelper getGroupByName:[OAFavoriteGroup convertDisplayNameToGroupIdName:selectedGroupName]];
        if (group)
            selectedColor = group.color;
    }
    else if (_editPointType == EOAEditPointTypeWaypoint)
    {
        selectedColor = [UIColor colorFromString:[(OAGpxWptEditingHandler *)_pointHandler getGroupsWithColors][selectedGroupName]];
    }

    if (selectedColor)
        _selectedColor = [OADefaultFavorite nearestFavColor:selectedColor];
    else
        _selectedColor = [OADefaultFavorite builtinColors].firstObject;

    _selectedColorIndex = [[OADefaultFavorite builtinColors] indexOfObject:_selectedColor];
    [self updateHeaderIcon];
    
    [self generateData];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_selectCategoryLabelRowIndex inSection:_selectCategorySectionIndex], [NSIndexPath indexPathForRow:_selectCategoryCardsRowIndex inSection:_selectCategorySectionIndex], [NSIndexPath indexPathForRow:_poiIconRowIndex inSection:_appearenceSectionIndex], [NSIndexPath indexPathForRow:_colorRowIndex inSection:_appearenceSectionIndex], [NSIndexPath indexPathForRow:_shapeRowIndex inSection:_appearenceSectionIndex]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) onNewGroupAdded:(NSString *)selectedGroupName  color:(UIColor *)color
{
    [self addGroup:selectedGroupName color:color];
}

- (void) addGroup:(NSString *)groupName color:(UIColor *)color
{
    _wasChanged = YES;
    NSString *editedGroupName = [[OAFavoritesHelper checkEmoticons:groupName] trim];

    if (_editPointType == EOAEditPointTypeFavorite)
    {
        [OAFavoritesHelper addEmptyCategory:editedGroupName color:color visible:YES];
    }
    else if (_editPointType == EOAEditPointTypeWaypoint)
    {
        if (!_pointHandler.gpxWptDelegate)
            _pointHandler.gpxWptDelegate = self.gpxWptDelegate;

        [((OAGpxWptEditingHandler *) _pointHandler) setGroup:editedGroupName color:color save:YES];
    }

    self.groupTitle = editedGroupName;
    _selectedColor = [OADefaultFavorite nearestFavColor:color];
    _selectedColorIndex = [[OADefaultFavorite builtinColors] indexOfObject:_selectedColor];
    
    [self setupGroups];
    [self generateData];
    [self updateHeaderIcon];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:_selectCategorySectionIndex] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_poiIconRowIndex inSection:_appearenceSectionIndex], [NSIndexPath indexPathForRow:_colorRowIndex inSection:_appearenceSectionIndex], [NSIndexPath indexPathForRow:_shapeRowIndex inSection:_appearenceSectionIndex]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - OAAddFavoriteGroupDelegate

- (void) onFavoriteGroupAdded:(NSString *)groupName color:(UIColor *)color
{
    [self addGroup:groupName color:color];
}

#pragma mark - OAReplacePointDelegate

- (void)onFavoriteReplaced:(OAFavoriteItem *)favoriteItem;
{
    NSString *message = [NSString stringWithFormat:OALocalizedString(@"replace_favorite_confirmation"), [favoriteItem getDisplayName]];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"fav_replace") message:message preferredStyle:UIAlertControllerStyleAlert];
    
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

        [self deleteFavoriteItem:favoriteItem];
        [_pointHandler savePoint:data newPoint:_isNewItemAdding];
        [self dismissViewController];
    }]];
    
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) onWaypointReplaced:(OAGpxWptItem *)waypointItem
{
    NSString *message = [NSString stringWithFormat:OALocalizedString(@"replace_waypoint_confirmation"), waypointItem.point.name];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"fav_replace") message:message preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_no") style:UIAlertActionStyleDefault handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

        OAPointEditingData *data = [[OAPointEditingData alloc] init];

        data.descr = waypointItem.point.desc;
        data.address = [waypointItem.point getAddress];
        data.color = waypointItem.color ? waypointItem.color : [UIColor colorFromString:waypointItem.point.color];
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

- (void) keyboardWillShow:(NSNotification *)notification;
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

- (void) keyboardWillHide:(NSNotification *)notification;
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

@end
