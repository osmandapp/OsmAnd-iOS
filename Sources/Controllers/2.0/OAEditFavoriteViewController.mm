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
#import "OANativeUtilities.h"
#import "OATitleRightIconCell.h"
#import "OATextViewTableViewCell.h"
#import "OATextInputFloatingCellWithIcon.h"
#import "OASettingsTableViewCell.h"
#import "OAColorsTableViewCell.h"
#import "OAIconsTableViewCell.h"
#import "OAPoiTableViewCell.h"
#import "OASelectFavoriteGroupViewController.h"
#import "OAAddFavoriteGroupViewController.h"
#import "OAReplaceFavoriteViewController.h"
#import "OAFolderCardsCell.h"
#import "OAFavoritesHelper.h"
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

@interface OAEditFavoriteViewController() <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate, OAColorsTableViewCellDelegate, OAPoiTableViewCellDelegate, OAIconsTableViewCellDelegate, MDCMultilineTextInputLayoutDelegate, OAReplaceFavoriteDelegate, OAFolderCardsCellDelegate, OASelectFavoriteGroupDelegate, OAAddFavoriteGroupDelegate>

@end

@implementation OAEditFavoriteViewController
{
    OsmAndAppInstance _app;
    BOOL _isNewItemAdding;
    BOOL _wasChanged;
    
    NSArray<NSArray<NSDictionary *> *> *_data;
    NSArray<NSNumber *> *_colors;
    NSMutableDictionary *_poiIcons;
    NSArray *_poiCategories;
    NSArray<NSString *> *_backgroundIcons;
    NSArray<NSString *> *_backgroundIconNames;
    
    NSArray<NSString *> *_groupNames;
    NSArray<NSNumber *> *_groupSizes;
    OAFavoriteColor *_selectedColor;
    NSString *_selectedIconCategoryName;
    NSString *_selectedIconName;
    int _selectedColorIndex;
    int _selectedBackgroundIndex;
    NSString *_editingTextFieldKey;;
}

- (id) initWithItem:(OAFavoriteItem *)favorite
{
    self = [super initWithNibName:@"OAEditFavoriteViewController" bundle:nil];
    if (self)
    {
        _app = [OsmAndApp instance];
        _isNewItemAdding = NO;
        self.favorite = favorite;
        self.name = [self.favorite getFavoriteName];
        self.desc = [self.favorite getFavoriteDesc];
        self.address = [self.favorite getFavoriteAddress];
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
        _app = [OsmAndApp instance];
        
        // Create favorite
        OsmAnd::PointI locationPoint;
        locationPoint.x = OsmAnd::Utilities::get31TileNumberX(location.longitude);
        locationPoint.y = OsmAnd::Utilities::get31TileNumberY(location.latitude);
        
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

        OAFavoriteItem* fav = [[OAFavoriteItem alloc] init];
        
        fav.favorite = _app.favoritesCollection->createFavoriteLocation(locationPoint,
                                                                        title,
                                                                        description,
                                                                        address,
                                                                        group,
                                                                        icon,
                                                                        background,
                                                                        OsmAnd::FColorRGB(r,g,b));
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
    _editingTextFieldKey = @"";
    [self setupGroups];
    [self setupColors];
    [self setupIcons];
    [self generateData];
}

- (void) setupGroups
{
    if (![OAFavoritesHelper isFavoritesLoaded])
        [OAFavoritesHelper loadFavorites];
    
    NSMutableArray *names = [NSMutableArray new];
    NSMutableArray *sizes = [NSMutableArray new];
    NSArray<OAFavoriteGroup *> *allGroups = [OAFavoritesHelper getFavoriteGroups];
    
    for (OAFavoriteGroup *group in allGroups)
    {
        NSString *name = group.name;
        if ([name isEqualToString:@""])
            name = OALocalizedString(@"favorites");
        
        [names addObject:name];
        [sizes addObject:[NSNumber numberWithInt:group.points.count]];
    }
    _groupNames = [NSArray arrayWithArray:names];
    _groupSizes = [NSArray arrayWithArray:sizes];
}

- (void) setupIcons
{
    NSString *loadedPoiIconName = [self.favorite getFavoriteIcon];
    
    NSString* path = [[NSBundle mainBundle] pathForResource:@"poi_categories" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    NSMutableDictionary *parsedJson = [NSMutableDictionary new];
    _poiIcons = [NSMutableDictionary new];
    
    if (json)
    {
        NSDictionary *categories = json[@"categories"];
        if (categories)
        {
            for (NSString *categoryName in categories.allKeys)
            {
                NSArray<NSString *> *icons = categories[categoryName][@"icons"];
                if (icons)
                {
                    _poiIcons[categoryName] = icons;
                    int index = (int)[icons indexOfObject:loadedPoiIconName];
                    if (index != -1)
                    {
                        _selectedIconName = loadedPoiIconName;
                        _selectedIconCategoryName = categoryName;
                    }
                }
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
        
    _backgroundIcons = @[@"bg_point_circle",
                         @"bg_point_octagon",
                         @"bg_point_square"];
    
    _backgroundIconNames = @[@"circle",
                         @"octagon",
                         @"square"];
    
    _selectedBackgroundIndex = [_backgroundIconNames indexOfObject:[self.favorite getFavoriteBackground]];
    if (_selectedBackgroundIndex == -1)
        _selectedBackgroundIndex = 0;
}

- (void) setupColors
{
    UIColor* loadedColor = [self.favorite getFavoriteColor];
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

    NSString *poiIconName = [NSString stringWithFormat:@"mm_%@", _selectedIconName];
    UIImage *poiIcon = [OAUtilities applyScaleFactorToImage:[UIImage imageNamed:[OAUtilities drawablePath:poiIconName]]];
    _headerIconPoi.image = [poiIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _headerIconPoi.tintColor = UIColor.whiteColor;
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    
    NSMutableArray *section = [NSMutableArray new];
    [section addObject:@{
        @"header" : OALocalizedString(@"name_and_descr"),
        @"type" : kTextInputFloatingCellWithIcon,
        @"title" : self.name,
        @"hint" : OALocalizedString(@"fav_name"),
        @"key" : kNameKey
    }];
    [section addObject:@{
        @"type" : kTextInputFloatingCellWithIcon,
        @"title" : self.desc,
        @"hint" : OALocalizedString(@"description"),
        @"key" : kDescKey
    }];
    [section addObject:@{
        @"type" : kTextInputFloatingCellWithIcon,
        @"title" : self.address,
        @"hint" : OALocalizedString(@"shared_string_address"),
        @"key" : kAddressKey
    }];
    
    [data addObject:[NSArray arrayWithArray:section]];
    
    section = [NSMutableArray new];
    [section addObject:@{
        @"header" : OALocalizedString(@"group"),
        @"type" : kCellTypeTitle,
        @"title" : OALocalizedString(@"select_group"),
        @"value" : self.groupTitle,
        @"key" : kSelectGroupKey
    }];
    
    int selectedGroupIndex = [_groupNames indexOfObject:self.groupTitle];
    if (selectedGroupIndex < 0)
        selectedGroupIndex = 0;
    [section addObject:@{
        @"type" : kFolderCardsCell,
        @"selectedValue" : [NSNumber numberWithInt:selectedGroupIndex],
        @"values" : _groupNames,
        @"sizes" : _groupSizes,
        @"addButtonTitle" : OALocalizedString(@"fav_add_group")
    }];
    
    [data addObject:[NSArray arrayWithArray:section]];
    
    section = [NSMutableArray new];
    [section addObject:@{
        @"header" : OALocalizedString(@"map_settings_appearance"),
        @"type" : kCellTypePoiCollection,
        @"title" : OALocalizedString(@"icon"),
        @"value" : @"",
        @"selectedCategoryName" : _selectedIconCategoryName,
        @"categotyData" : _poiCategories,
        @"selectedIconName" : _selectedIconName,
        @"poiData" : _poiIcons[_selectedIconCategoryName],
        @"key" : kIconsKey
    }];
    [section addObject:@{
        @"type" : kCellTypeColorCollection,
        @"title" : OALocalizedString(@"fav_color"),
        @"value" : _selectedColor.name,
        @"index" : [NSNumber numberWithInt:_selectedColorIndex],
    }];
    [section addObject:@{
        @"type" : kCellTypeIconCollection,
        @"title" : OALocalizedString(@"shape"),
        @"value" : OALocalizedString(_backgroundIconNames[_selectedBackgroundIndex]),
        @"index" : [NSNumber numberWithInt:_selectedBackgroundIndex],
        @"data" : _backgroundIcons,
        @"key" : kBackgroundsKey
    }];
    [data addObject:[NSArray arrayWithArray:section]];
    
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
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
    self.doneButton.hidden = NO;
    [self updateHeaderIcon];
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"add_favorite");
    [self.doneButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

- (NSString *) getGroupTitle
{
    NSString *groupName = [self.favorite getFavoriteGroup];
    return groupName.length == 0 ? OALocalizedString(@"favorites") : groupName;
}


#pragma mark - Actions

- (void)onCancelButtonPressed
{
    if (_isNewItemAdding)
        [self deleteFavoriteItem:self.favorite];
}

- (void)onDoneButtonPressed
{
    if (_wasChanged)
    {
        NSString *savingGroup = [self.groupTitle isEqualToString:OALocalizedString(@"favorites")] ? @"" : self.groupTitle;
        [OAFavoritesHelper editFavorite:self.favorite name:self.name group:savingGroup];
        
        [self.favorite setFavoriteDesc:self.desc ? self.desc : @""];
        [self.favorite setFavoriteAddress:self.address ? self.address : @""];
        [self.favorite setFavoriteIcon:_selectedIconName];
        [self.favorite setFavoriteColor:_selectedColor.color];
        [self.favorite setFavoriteBackground:_backgroundIconNames[_selectedBackgroundIndex]];
                
        [[OsmAndApp instance] saveFavoritesToPermamentStorage];
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
    [[[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"fav_remove_q")
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_no")]
                       otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_yes")
                                                             action:^{
                                            [self deleteFavoriteItem:self.favorite];
                                            [self dismissViewControllerAnimated:YES completion:nil];
                                        }],
      nil] show];
}

- (void) deleteFavoriteItem:(OAFavoriteItem *)favoriteItem
{
    [OAFavoritesHelper deleteFavoriteGroups:nil andFavoritesItems:@[favoriteItem]];
}

- (void) removeExistingItemFromCollection
{
    NSString *favoriteTitle = [self.favorite getFavoriteName];
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

- (NSIndexPath *)indexPathForCellContainingView:(UIView *)view inTableView:(UITableView *)tableView
{
    CGPoint viewCenterRelativeToTableview = [tableView convertPoint:CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds)) fromView:view];
    NSIndexPath *cellIndexPath = [tableView indexPathForRowAtPoint:viewCenterRelativeToTableview];
    return cellIndexPath;
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
        static NSString* const identifierCell = @"OAPoiTableViewCell";
        OAPoiTableViewCell *cell = nil;
        cell = (OAPoiTableViewCell*)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPoiTableViewCell" owner:self options:nil];
            cell = (OAPoiTableViewCell *)[nib objectAtIndex:0];
            cell.delegate = self;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsZero;
        }
        if (cell)
        {
            cell.categoriesCollectionView.tag = kCategoryCellIndex;
            cell.currentCategory = item[@"selectedCategoryName"];
            cell.catagoryDataArray = item[@"categotyData"];
            
            cell.collectionView.tag = kPoiCellIndex;
            cell.poiDataArray = item[@"poiData"];
            cell.titleLabel.text = item[@"title"];
            cell.currentColor = _colors[_selectedColorIndex].intValue;
            cell.currentIcon = item[@"selectedIconName"];
            [cell.collectionView reloadData];
            [cell.categoriesCollectionView reloadData];
        }
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypeColorCollection])
    {
        static NSString* const identifierCell = @"OAColorsTableViewCell";
        OAColorsTableViewCell *cell = nil;
        cell = (OAColorsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAColorsTableViewCell" owner:self options:nil];
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
        static NSString* const identifierCell = @"OAIconsTableViewCell";
        OAIconsTableViewCell *cell = nil;
        cell = (OAIconsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconsTableViewCell" owner:self options:nil];
            cell = (OAIconsTableViewCell *)[nib objectAtIndex:0];
            cell.delegate = self;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsZero;
        }
        if (cell)
        {
            int selectedIndex = [item[@"index"] intValue];
            cell.dataArray = item[@"data"];
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
        }
        if (cell)
        {
            cell.delegate = self;
            [cell setValues:item[@"values"] sizes:item[@"sizes"] addButtonTitle:item[@"addButtonTitle"] withSelectedIndex:(int)[item[@"selectedValue"] intValue]];
        }
        return cell;
    }
    
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *item = ((NSArray *)_data[section]).firstObject;
    return item[@"header"];
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
        OAReplaceFavoriteViewController *replaceScreen = [[OAReplaceFavoriteViewController alloc] init];
        replaceScreen.delegate = self;
        [self presentViewController:replaceScreen animated:YES completion:nil];
    }
    else if ([key isEqualToString:kDeleteKey])
    {
        [self deleteItemWithAlertView];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableView:self.tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:OATextInputFloatingCellWithIcon.class])
    {
        NSDictionary *item = _data[indexPath.section][indexPath.row];
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

- (void) onPoiCategorySelected:(NSString *)category
{
    _selectedIconCategoryName = category;
    [self generateData];
    [self.tableView reloadData];
    [self.tableView layoutSubviews];
}

- (void) onPoiSelected:(NSString *)poiName;
{
    _wasChanged = YES;
    _selectedIconName = poiName;
    [self updateHeaderIcon];
    [self generateData];
    [self.tableView reloadData];
}

#pragma mark - OAIconsTableViewCellDelegate

- (void)iconChanged:(NSInteger)tag
{
    _wasChanged = YES;
    _selectedBackgroundIndex = (int)tag;
    [self updateHeaderIcon];
    [self generateData];
    [self.tableView reloadData];
}

#pragma mark - OAColorsTableViewCellDelegate

- (void)colorChanged:(NSInteger)tag
{
    _wasChanged = YES;
    _selectedColorIndex = tag;
    _selectedColor = [OADefaultFavorite builtinColors][tag];
    [self updateHeaderIcon];
    [self generateData];
    [self.tableView reloadData];
}

#pragma mark - OAFolderCardsCellDelegate

- (void) onItemSelected:(int)index
{
    _wasChanged = YES;
    self.groupTitle = _groupNames[index];
    if ([self.groupTitle isEqualToString:@""])
        self.groupTitle = OALocalizedString(@"favorites");
    [self generateData];
    [self.tableView reloadData];
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
    [self generateData];
    [self.tableView reloadData];
}

- (void) onNewGroupAdded:(NSString *)selectedGroupName
{
    [self addGroup:selectedGroupName];
}

- (void) addGroup:(NSString *)groupName
{
    _wasChanged = YES;
    UIColor *defaultColor = ((OAFavoriteColor *)[OADefaultFavorite builtinColors][0]).color;
    [OAFavoritesHelper addEmptyCategory:groupName color:defaultColor visible:YES];
    self.groupTitle = groupName;
    
    [self setupGroups];
    [self generateData];
    [self.tableView reloadData];
}

#pragma mark - OAAddFavoriteGroupDelegate

- (void) onFavoriteGroupAdded:(NSString *)groupName
{
    [self addGroup:groupName];
}

#pragma mark - OAReplaceFavoriteDelegate

- (void) onReplaced:(OAFavoriteItem *)favoriteItem;
{
    _wasChanged = YES;
    [self deleteFavoriteItem:favoriteItem];
    [self onDoneButtonPressed];
    [self dismissViewController];
}

@end
