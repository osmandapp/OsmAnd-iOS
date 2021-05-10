//
//  OAEditFavoriteViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 05.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAEditFavoriteViewController.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OADefaultFavorite.h"
#import "OATitleRightIconCell.h"
#import "OATextViewTableViewCell.h"
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
#import "OARootViewController.h"
#import "OATargetInfoViewController.h"
#import "OATargetPointsHelper.h"
#import "OATableViewCustomHeaderView.h"
#import "OACollectionViewCellState.h"
#import <UIAlertView+Blocks.h>
#import <UIAlertView-Blocks/RIButtonItem.h>

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"

#define kTextFieldCell @"OATextViewTableViewCell"
#define kCellTypeAction @"OATitleRightIconCell"
#define kTextInputFloatingCellWithIcon @"OATextInputFloatingCellWithIcon"
#define kCellTypeTitle @"OASettingsCell"
#define kCellTypeColorCollection @"colorCollectionCell"
#define kCellTypeIconCollection @"iconCollectionCell"
#define kCellTypePoiCollection @"poiCollectionCell"
#define kFolderCardsCell @"OAFolderCardsCell"
#define kHeaderId @"TableViewSectionHeader"
#define kPoiTableViewCell @"OAPoiTableViewCell"

#define kNameKey @"kNameKey"
#define kDescKey @"kDescKey"
#define kAddressKey @"kAddressKeyd"
#define kIconsKey @"kIconsKey"
#define kBackgroundsKey @"kBackgroundsKey"
#define kSelectGroupKey @"kSelectGroupKey"
#define kReplaceKey @"kReplaceKey"
#define kDeleteKey @"kDeleteKey"

#define kVerticalMargin 8.
#define kSideMargin 20.
#define kEmptyTextCellHeight 48.
#define kTextCellTopMargin 18.
#define kTextCellBottomMargin 17.
#define kCategoryCellIndex 0
#define kPoiCellIndex 1
#define kFullHeaderHeight 100
#define kCompressedHeaderHeight 62

@interface OAEditFavoriteViewController() <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate, OAColorsTableViewCellDelegate, OAPoiTableViewCellDelegate, OAShapesTableViewCellDelegate, MDCMultilineTextInputLayoutDelegate, OAReplaceFavoriteDelegate, OAFolderCardsCellDelegate, OASelectFavoriteGroupDelegate, OAAddFavoriteGroupDelegate, UIGestureRecognizerDelegate, UIAdaptivePresentationControllerDelegate>

@end

@implementation OAEditFavoriteViewController
{
    OsmAndAppInstance _app;
    BOOL _isNewItemAdding;
    BOOL _wasChanged;
    BOOL _isUnsaved;
    NSString *_ininialName;
    NSString *_ininialGroupName;
    
    NSArray<NSArray<NSDictionary *> *> *_data;
    NSArray<NSNumber *> *_colors;
    NSDictionary<NSString *, NSArray<NSString *> *> *_poiIcons;
    NSArray *_poiCategories;
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
}

- (id) initWithItem:(OAFavoriteItem *)favorite
{
    self = [super initWithNibName:@"OAEditFavoriteViewController" bundle:nil];
    if (self)
    {
        _app = [OsmAndApp instance];
        _isNewItemAdding = NO;
        _isUnsaved = YES;
        self.favorite = favorite;
        self.name = [self.favorite getDisplayName];
        self.desc = [self.favorite getDescription];
        self.address = [self.favorite getAddress];
        self.groupTitle = [self getGroupTitle];
        self.groupColor = [self.favorite getColor];
        [self commonInit];
    }
    return self;
}

- (id) initWithLocation:(CLLocationCoordinate2D)location title:(NSString*)formattedTitle address:(NSString*)formattedLocation
{
    self = [super initWithNibName:@"OAEditFavoriteViewController" bundle:nil];
    if (self)
    {
        _isNewItemAdding = YES;
        _isUnsaved = YES;
        _app = [OsmAndApp instance];
        
        // Create favorite
        OsmAnd::PointI locationPoint;
        locationPoint.x = OsmAnd::Utilities::get31TileNumberX(location.longitude);
        locationPoint.y = OsmAnd::Utilities::get31TileNumberY(location.latitude);
        
        QString elevation = QString::null;
        QString time = QString::fromNSString([OAFavoriteItem toStringDate:[NSDate date]]);
        
        QString title = QString::fromNSString(formattedTitle);
        QString address = QString::fromNSString(formattedLocation);
        QString description = QString::null;
        QString icon = QString::null;
        QString background = QString::null;
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *groupName;
        if ([userDefaults objectForKey:kFavoriteDefaultGroupKey])
            groupName = [userDefaults stringForKey:kFavoriteDefaultGroupKey];
        
        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors].firstObject;
        
        UIColor* color_ = favCol.color;
        CGFloat r,g,b,a;
        [color_ getRed:&r
                 green:&g
                  blue:&b
                 alpha:&a];
        
        QString group;
        if (groupName)
            group = QString::fromNSString(groupName);
        else
            group = QString::null;
        
        auto favorite = _app.favoritesCollection->createFavoriteLocation(locationPoint,
                                                                        elevation,
                                                                        time,
                                                                        title,
                                                                        description,
                                                                        address,
                                                                        group,
                                                                        icon,
                                                                        background,
                                                                        OsmAnd::FColorRGB(r,g,b));
        
        OAFavoriteItem* fav = [[OAFavoriteItem alloc] initWithFavorite:favorite];
        
        self.favorite = fav;
        [_app saveFavoritesToPermamentStorage];
        
        self.name = formattedTitle ? formattedTitle : @"";
        self.desc = @"";
        self.address = formattedLocation ? formattedLocation : @"";
        self.groupTitle = [self getGroupTitle];
        self.groupColor = [self.favorite getColor];
        
        _selectedIconCategoryName = @"special";
        _selectedIconName = @"special_star";
        _selectedColorIndex = 0;
        _selectedBackgroundIndex = 0;
        
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    _wasChanged = NO;
    _ininialName = self.name;
    _ininialGroupName = self.groupTitle;
    _editingTextFieldKey = @"";
    
    _selectCategorySectionIndex = -1;
    _selectCategoryLabelRowIndex = -1;
    _selectCategoryCardsRowIndex = -1;
    _appearenceSectionIndex = -1;
    _poiIconRowIndex = -1;
    _colorRowIndex = -1;
    _shapeRowIndex = -1;
    _scrollCellsState = [[OACollectionViewCellState alloc] init];
    
    [self setupGroups];
    [self setupColors];
    [self setupIcons];
    [self generateData];
}

- (void) setupHeaderName
{
    if (self.name.length > 0)
        self.titleLabel.text = self.name;
    else
        self.titleLabel.text = _isNewItemAdding ? OALocalizedString(@"add_favorite") : OALocalizedString(@"ctx_mnu_edit_fav");
}

- (void) setupGroups
{
    if (![OAFavoritesHelper isFavoritesLoaded])
        [OAFavoritesHelper loadFavorites];
    
    NSMutableArray *names = [NSMutableArray new];
    NSMutableArray *sizes = [NSMutableArray new];
    NSMutableArray *colors = [NSMutableArray new];
    NSArray<OAFavoriteGroup *> *allGroups = [OAFavoritesHelper getFavoriteGroups];
    
    if (![[OAFavoritesHelper getGroups].allKeys containsObject:@""])
    {
        [names addObject:OALocalizedString(@"favorites")];
        [sizes addObject:@0];
        [colors addObject:[OADefaultFavorite getDefaultColor]];
    }
    
    for (OAFavoriteGroup *group in allGroups)
    {
        [names addObject:[OAFavoriteGroup getDisplayName:group.name]];
        [sizes addObject:[NSNumber numberWithInteger:group.points.count]];
        [colors addObject:group.color];
    }
    _groupNames = [NSArray arrayWithArray:names];
    _groupSizes = [NSArray arrayWithArray:sizes];
    _groupColors = [NSArray arrayWithArray:colors];
}

- (void) setupIcons
{
    NSString *loadedPoiIconName = [self.favorite getIcon];
    _poiIcons = [OAFavoritesHelper getCategirizedIconNames];
    
    for (NSString *categoryName in _poiIcons.allKeys)
    {
        NSArray<NSString *> *icons = _poiIcons[categoryName];
        if (icons)
        {
            int index = (int)[icons indexOfObject:loadedPoiIconName];
            if (index != -1)
            {
                _selectedIconName = loadedPoiIconName;
                _selectedIconCategoryName = categoryName;
            }
        }
    }
    
    NSArray *categories = [_poiIcons.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray *categoriesData = [NSMutableArray new];
    for (NSString *category in categories)
    {
        [categoriesData addObject: @{
            @"title" : OALocalizedString(category),
            @"categoryName" : category,
            @"img" : @"",
        }];
    }
    _poiCategories = [NSArray arrayWithArray:categoriesData];
    
    if (!_selectedIconName || _selectedIconName.length == 0)
        _selectedIconName = @"special_star";
    
    if (!_selectedIconCategoryName || _selectedIconCategoryName.length == 0)
        _selectedIconCategoryName = @"special";
        
    _backgroundIconNames = [OAFavoritesHelper getFlatBackgroundIconNamesList];
    _backgroundContourIconNames = [OAFavoritesHelper getFlatBackgroundContourIconNamesList];
    
    NSMutableArray * tempBackgroundIcons = [NSMutableArray new];
    for (NSString *iconName in _backgroundIconNames)
        [tempBackgroundIcons addObject:[NSString stringWithFormat:@"bg_point_%@", iconName]];

    _backgroundIcons = [NSArray arrayWithArray:tempBackgroundIcons];
    
    _selectedBackgroundIndex = [_backgroundIconNames indexOfObject:[self.favorite getBackgroundIcon]];
    if (_selectedBackgroundIndex == -1)
        _selectedBackgroundIndex = 0;
}

- (void) setupColors
{
    UIColor* loadedColor = [self.favorite getColor];
    _selectedColor = [OADefaultFavorite nearestFavColor:loadedColor];
    _selectedColorIndex = [[OADefaultFavorite builtinColors] indexOfObject:_selectedColor];
    
    NSMutableArray *tempColors = [NSMutableArray new];
    for (OAFavoriteColor *favColor in [OADefaultFavorite builtinColors])
    {
        [tempColors addObject:[NSNumber numberWithInt:[OAUtilities colorToNumber:favColor.color]]];
    }
    _colors = [NSArray arrayWithArray:tempColors];
}

- (void) updateHeaderIcon
{
    UIImage *backroundImage = [UIImage imageNamed:_backgroundIcons[_selectedBackgroundIndex]];
    _headerIconBackground.image = [backroundImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _headerIconBackground.tintColor = _selectedColor.color;

    UIImage *poiIcon = [OATargetInfoViewController getIcon:[@"mx_" stringByAppendingString:_selectedIconName]];
    _headerIconPoi.image = [poiIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _headerIconPoi.tintColor = UIColor.whiteColor;
}

- (void) generateData
{
    [self setupHeaderName];
    
    NSMutableArray *data = [NSMutableArray new];
    
    NSMutableArray *section = [NSMutableArray new];
    [section addObject:@{
        @"header" : OALocalizedString(@"name_and_descr"),
        @"type" : kTextInputFloatingCellWithIcon,
        @"title" : self.name,
        @"hint" : OALocalizedString(@"fav_name"),
        @"isEditable" : [NSNumber numberWithBool:![self.favorite isSpecialPoint]],
        @"key" : kNameKey
    }];
    [section addObject:@{
        @"type" : kTextInputFloatingCellWithIcon,
        @"title" : self.desc,
        @"hint" : OALocalizedString(@"description"),
        @"isEditable" : @YES,
        @"key" : kDescKey
    }];
    [section addObject:@{
        @"type" : kTextInputFloatingCellWithIcon,
        @"title" : self.address,
        @"hint" : OALocalizedString(@"shared_string_address"),
        @"isEditable" : @YES,
        @"key" : kAddressKey
    }];
    [data addObject:[NSArray arrayWithArray:section]];
    
    section = [NSMutableArray new];
    [section addObject:@{
        @"header" : OALocalizedString(@"fav_group"),
        @"type" : kCellTypeTitle,
        @"title" : OALocalizedString(@"select_group"),
        @"value" : self.groupTitle,
        @"key" : kSelectGroupKey
    }];
    _selectCategoryLabelRowIndex = section.count -1;

    NSUInteger selectedGroupIndex = [_groupNames indexOfObject:self.groupTitle];
    if (selectedGroupIndex < 0)
        selectedGroupIndex = 0;
    [section addObject:@{
        @"type" : kFolderCardsCell,
        @"selectedValue" : [NSNumber numberWithInteger:selectedGroupIndex],
        @"values" : _groupNames,
        @"sizes" : _groupSizes,
        @"colors" : _groupColors,
        @"addButtonTitle" : OALocalizedString(@"fav_add_group")
    }];
    _selectCategoryCardsRowIndex = section.count -1;
    [data addObject:[NSArray arrayWithArray:section]];
    _selectCategorySectionIndex = data.count - 1;
    
    section = [NSMutableArray new];
    [section addObject:@{
        @"header" : OALocalizedString(@"map_settings_appearance"),
        @"type" : kCellTypePoiCollection,
        @"title" : OALocalizedString(@"icon"),
        @"value" : @"",
        @"selectedCategoryName" : _selectedIconCategoryName,
        @"categotyData" : _poiCategories,
        @"selectedIconName" : _selectedIconName,
        @"poiData" : _poiIcons,
        @"key" : kIconsKey
    }];
    _poiIconRowIndex = section.count - 1;
    
    [section addObject:@{
        @"type" : kCellTypeColorCollection,
        @"title" : OALocalizedString(@"fav_color"),
        @"value" : _selectedColor.name,
        @"index" : [NSNumber numberWithInteger:_selectedColorIndex],
    }];
    _colorRowIndex = section.count - 1;
    
    [section addObject:@{
        @"type" : kCellTypeIconCollection,
        @"title" : OALocalizedString(@"shape"),
        @"value" : OALocalizedString(_backgroundIconNames[_selectedBackgroundIndex]),
        @"index" : [NSNumber numberWithInteger:_selectedBackgroundIndex],
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
        @"type" : kCellTypeAction,
        @"title" : OALocalizedString(@"fav_replace"),
        @"img" : @"ic_custom_replace",
        @"color" : UIColorFromRGB(color_primary_purple),
        @"key" : kReplaceKey
    }];
    if (!_isNewItemAdding)
    {
        [section addObject:@{
            @"type" : kCellTypeAction,
            @"title" : OALocalizedString(@"shared_string_delete"),
            @"img" : @"ic_custom_remove_outlined",
            @"color" : UIColorFromRGB(color_primary_red),
            @"key" : kDeleteKey
        }];
    }
    [data addObject:[NSArray arrayWithArray:section]];
    
    _data = [NSArray arrayWithArray:data];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.presentationController.delegate = self;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:kHeaderId];
    self.doneButton.hidden = NO;
    
    [self updateHeaderIcon];
    [self setupHeaderName];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void) applyLocalization
{
    [super applyLocalization];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

- (NSString *) getGroupTitle
{
    return [self.favorite getCategoryDisplayName];
}

- (void)viewDidLayoutSubviews
{
    [self setupHeaderWithVerticalOffset:self.tableView.contentOffset.y];
}

- (void) setupHeaderWithVerticalOffset:(CGFloat)offset
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
            
            if (_isNewItemAdding )
                [self deleteFavoriteItem:self.favorite];
            [self doDismiss];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
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
        
        NSString *savingGroup = [[OAFavoriteGroup convertDisplayNameToGroupIdName:self.groupTitle] trim];
        
        [self.favorite setDescription:self.desc ? self.desc : @""];
        [self.favorite setAddress:self.address ? self.address : @""];
        [self.favorite setColor:_selectedColor.color];
        [self.favorite setBackgroundIcon:_backgroundIconNames[_selectedBackgroundIndex]];
        [self.favorite setIcon:_selectedIconName];
        
        if (_isNewItemAdding || ![self.name isEqualToString:_ininialName] || ![self.groupTitle isEqualToString:_ininialGroupName])
        {
            NSString *savingName = [self.name trim];
            NSDictionary *checkingResult = [OAFavoritesHelper checkDuplicates:self.favorite newName:savingName newCategory:savingGroup];
            
            
            if (checkingResult && ![checkingResult[@"name"] isEqualToString:self.name])
            {
                savingName = checkingResult[@"name"];
                if ([checkingResult[@"status"] isEqualToString:@"emoji"])
                    _renamedPointAlertMessage = [NSString stringWithFormat:OALocalizedString(@"fav_point_emoticons_message"), savingName];
                else
                    _renamedPointAlertMessage = [NSString stringWithFormat:OALocalizedString(@"fav_point_dublicate_message"), savingName];
            }
            
            if (_isNewItemAdding)
            {
                [self.favorite setName:savingName];
                [self.favorite setCategory:savingGroup];
                [OAFavoritesHelper addFavorite:self.favorite];
            }
            else
            {
                [OAFavoritesHelper editFavoriteName:self.favorite newName:savingName group:savingGroup descr:[self.favorite getDescription] address:[self.favorite getAddress]];
            }
        }
        else
        {
            NSString *savingName = [self.favorite isSpecialPoint] ? [self.favorite getName] : self.name;
            savingName = [savingName trim];
            [OAFavoritesHelper editFavoriteName:self.favorite newName:savingName group:savingGroup descr:[self.favorite getDescription] address:[self.favorite getAddress]];
        }
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
        [self deleteFavoriteItem:self.favorite];
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) deleteFavoriteItem:(OAFavoriteItem *)favoriteItem
{
    [OAFavoritesHelper deleteFavoriteGroups:nil andFavoritesItems:@[favoriteItem]];
}

- (void) removeExistingItemFromCollection
{
    NSString *favoriteTitle = [self.favorite getName];
    for(const auto& localFavorite : [OsmAndApp instance].favoritesCollection->getFavoriteLocations())
    {
        if ((localFavorite != self.favorite.favorite) &&
            [favoriteTitle isEqualToString:localFavorite->getTitle().toNSString()])
        {
            [OsmAndApp instance].favoritesCollection->removeFavoriteLocation(localFavorite);
            break;
        }
    }
}

- (void) removeNewItemFromCollection
{
    _app.favoritesCollection->removeFavoriteLocation(self.favorite.favorite);
    [_app saveFavoritesToPermamentStorage];
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
    
    if ([cellType isEqualToString:kTextInputFloatingCellWithIcon])
    {
        OATextInputFloatingCellWithIcon *resultCell = nil;
        resultCell = [self.tableView dequeueReusableCellWithIdentifier:kTextInputFloatingCellWithIcon];
        if (resultCell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kTextInputFloatingCellWithIcon owner:self options:nil];
            resultCell = (OATextInputFloatingCellWithIcon *)[nib objectAtIndex:0];
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
        [textField.clearButton addTarget:self action:@selector(clearButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        textField.font = [UIFont systemFontOfSize:17.0];
        textField.clearButton.imageView.tintColor = UIColorFromRGB(color_icon_color);
        [textField.clearButton setImage:[[UIImage imageNamed:@"ic_custom_clear_field"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [textField.clearButton setImage:[[UIImage imageNamed:@"ic_custom_clear_field"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateHighlighted];
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
    else if ([cellType isEqualToString:kCellTypePoiCollection])
    {
        static NSString* const identifierCell = kPoiTableViewCell;
        OAPoiTableViewCell *cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kPoiTableViewCell owner:self options:nil];
            cell = (OAPoiTableViewCell *)[nib objectAtIndex:0];
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
    else if ([cellType isEqualToString:kCellTypeColorCollection])
    {
        static NSString* const identifierCell = [OAColorsTableViewCell getCellIdentifier];
        OAColorsTableViewCell *cell = nil;
        cell = (OAColorsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAColorsTableViewCell *)[nib objectAtIndex:0];
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
    else if ([cellType isEqualToString:kCellTypeIconCollection])
    {
        static NSString* const identifierCell = @"OAShapesTableViewCell";
        OAShapesTableViewCell *cell = nil;
        cell = (OAShapesTableViewCell*)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAShapesTableViewCell" owner:self options:nil];
            cell = (OAShapesTableViewCell *)[nib objectAtIndex:0];
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
    else if ([cellType isEqualToString:kCellTypeAction])
    {
        static NSString* const identifierCell = kCellTypeAction;
        OATitleRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kCellTypeAction owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            cell.titleView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightSemibold];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.titleView.text = item[@"title"];
        cell.titleView.textColor = item[@"color"];
        cell.iconView.tintColor = item[@"color"];
        [cell.iconView setImage:[[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
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
            cell.delegate = self;
            cell.cellIndex = indexPath;
            cell.state = _scrollCellsState;
        }
        if (cell)
        {
            [cell setValues:item[@"values"] sizes:item[@"sizes"] colors:item[@"colors"] addButtonTitle:item[@"addButtonTitle"] withSelectedIndex:(int)[item[@"selectedValue"] intValue]];
        }
        return cell;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
 {
     NSDictionary *item = _data[indexPath.section][indexPath.row];
     NSString *type = item[@"type"];
     if ([type isEqualToString:kFolderCardsCell])
     {
         OAFolderCardsCell *folderCell = (OAFolderCardsCell *)cell;
         [folderCell updateContentOffset];
     }
     else if ([type isEqualToString:kCellTypePoiCollection])
     {
         OAPoiTableViewCell *poiCell = (OAPoiTableViewCell *)cell;
         [poiCell updateContentOffset];
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
    OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kHeaderId];
    vw.label.textColor = UIColorFromRGB(color_text_footer);
    vw.label.text = [title upperCase];
    vw.label.userInteractionEnabled = NO;
 
    int offset = section == 0 ? 32 : 16;
    [vw setYOffset:offset];
    
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
        OASelectFavoriteGroupViewController *selectGroupConroller = [[OASelectFavoriteGroupViewController alloc] initWithSelectedGroupName:self.groupTitle];
        selectGroupConroller.delegate = self;
        [self presentViewController:selectGroupConroller animated:YES completion:nil];
    }
    else if ([key isEqualToString:kReplaceKey])
    {
        if ([OAFavoritesHelper getFavoriteItems].count > 0)
        {
            OAReplaceFavoriteViewController *replaceScreen = [[OAReplaceFavoriteViewController alloc] init];
            replaceScreen.delegate = self;
            [self presentViewController:replaceScreen animated:YES completion:nil];
        }
        else
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"fav_points_not_exist") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
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
    if ([cellType isEqualToString:kTextInputFloatingCellWithIcon])
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
    [self generateData];
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
    
    NSString *groupName = [OAFavoriteGroup convertDisplayNameToGroupIdName:_groupNames[index]];
    OAFavoriteGroup *group = [OAFavoritesHelper getGroupByName:groupName];
    if (group)
        _selectedColor = [OADefaultFavorite nearestFavColor:group.color];
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
    
    OAFavoriteGroup *group = [OAFavoritesHelper getGroupByName:[OAFavoriteGroup convertDisplayNameToGroupIdName:selectedGroupName]];
    if (group)
        _selectedColor = [OADefaultFavorite nearestFavColor:group.color];
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
    
    [OAFavoritesHelper addEmptyCategory:editedGroupName color:color visible:YES];
    self.groupTitle = editedGroupName;
    _selectedColor = [OADefaultFavorite nearestFavColor:color];
    _selectedColorIndex = [[OADefaultFavorite builtinColors] indexOfObject:_selectedColor];
    
    [self setupGroups];
    [self generateData];
    [self updateHeaderIcon];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_selectCategoryLabelRowIndex inSection:_selectCategorySectionIndex], [NSIndexPath indexPathForRow:_selectCategoryCardsRowIndex inSection:_selectCategorySectionIndex], [NSIndexPath indexPathForRow:_poiIconRowIndex inSection:_appearenceSectionIndex], [NSIndexPath indexPathForRow:_colorRowIndex inSection:_appearenceSectionIndex], [NSIndexPath indexPathForRow:_shapeRowIndex inSection:_appearenceSectionIndex]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - OAAddFavoriteGroupDelegate

- (void) onFavoriteGroupAdded:(NSString *)groupName color:(UIColor *)color
{
    [self addGroup:groupName color:color];
}

#pragma mark - OAReplaceFavoriteDelegate

- (void) onReplaced:(OAFavoriteItem *)favoriteItem;
{
    NSString *message = [NSString stringWithFormat:OALocalizedString(@"replace_favorite_confirmation"), [favoriteItem getDisplayName]];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"fav_replace") message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_no") style:UIAlertActionStyleDefault handler:nil]];
    
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        NSString *description = [favoriteItem getDescription];
        NSString *address = [favoriteItem getAddress];
        UIColor *color = [favoriteItem getColor];
        NSString *backgroundIcon = [favoriteItem getBackgroundIcon];
        NSString *icon = [favoriteItem getIcon];
        NSString *category = [favoriteItem getCategory];
        NSString *name = [favoriteItem getName];
        
        [self.favorite setDescription:description];
        [self.favorite setAddress:address];
        [self.favorite setColor:color];
        [self.favorite setBackgroundIcon:backgroundIcon];
        [self.favorite setIcon:icon];
        
        [self deleteFavoriteItem:favoriteItem];

        if (_isNewItemAdding)
        {
            [self.favorite setCategory:category];
            [self.favorite setName:name];
            [OAFavoritesHelper addFavorite:self.favorite];
        }
        else
        {
            [OAFavoritesHelper editFavoriteName:self.favorite newName:name group:category descr:description address:address];
        }
        
        [self dismissViewController];
    }]];
    
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Keyboard Notifications

- (void) keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = [keyboardBoundsValue CGRectValue].size.height;

    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardHeight, insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0., insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

@end
