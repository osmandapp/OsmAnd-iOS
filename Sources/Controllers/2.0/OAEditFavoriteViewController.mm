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
#import "OAEditGroupViewController.h"
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

#define kIconsKey @"kIconsKey"
#define kBackgroundsKey @"kBackgroundsKey"
#define kSelectGroupKey @"kSelectGroupKey"
#define kReplaceKey @"kReplaceKey"
#define kDeleteKey @"kDeleteKey"

@interface OAEditFavoriteViewController() <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate, OAColorsTableViewCellDelegate, OAPoiTableViewCellDelegate, OAIconsTableViewCellDelegate, OAEditGroupViewControllerDelegate>

@end

@implementation OAEditFavoriteViewController
{
    OsmAndAppInstance _app;
    OAEditGroupViewController *_groupController;
    BOOL _isNewItemAdding;
    BOOL _wasChanged;
    
    NSArray<NSArray<NSDictionary *> *> *_data;
    NSArray<NSNumber *> *_colors;
    NSMutableDictionary *_poiIcons;
    NSArray *_poiCategories;
    NSArray<NSString *> *_backgroundIcons;
    NSArray<NSString *> *_backgroundIconNames;
    
    OAFavoriteColor *_selectedColor;
    NSString *_selectedIconCategoryName;
    int _selectedIconIndex;
    int _selectedColorIndex;
    int _selectedBackgroundIndex;
}

- (id) initWithItem:(OAFavoriteItem *)favorite
{
    self = [super initWithNibName:@"OAEditFavoriteViewController" bundle:nil];
    if (self)
    {
        _app = [OsmAndApp instance];
        _isNewItemAdding = NO;
        self.favorite = favorite;
        self.name = [self getItemName];
        self.desc = [self getItemDesc];
        self.address = [self getItemAddress];
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
        _selectedIconIndex = 0;
        _selectedColorIndex = 0;
        _selectedBackgroundIndex = 0;
        
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    _wasChanged = NO;
    [self setupColors];
    [self setupIcons];
    [self generateData];
}

- (void) setupIcons
{
    NSString *loadedPoiIconName = [self getItemIcon];
    
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
                        _selectedIconIndex = index;
                        _selectedIconCategoryName = categoryName;
                    }
                }
            }
        }
    }
    
    _poiCategories = [_poiIcons.allKeys sortedArrayUsingSelector:@selector(compare:)];
    
    if (_selectedIconIndex == -1)
        _selectedIconIndex = 0;
    if (!_selectedIconCategoryName)
        _selectedIconCategoryName = @"special";
        
    _backgroundIcons = @[@"bg_point_circle",
                         @"bg_point_octagon",
                         @"bg_point_square"];
    
    _backgroundIconNames = @[@"circle",
                         @"octagon",
                         @"square"];
    
    
    _selectedBackgroundIndex = [_backgroundIconNames indexOfObject:[self getItemBackground]];
    if (_selectedBackgroundIndex == -1)
        _selectedBackgroundIndex = 0;
}

- (void) setupColors
{
    UIColor* loadedColor = [self getItemColor];
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

    NSString *poiIconName = [NSString stringWithFormat:@"mm_%@", _poiIcons[_selectedIconCategoryName][_selectedIconIndex]];
    UIImage *poiIcon = [OAUtilities applyScaleFactorToImage:[UIImage imageNamed:[OAUtilities drawablePath:poiIconName]]];
    _headerIconPoi.image = [poiIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _headerIconPoi.tintColor = UIColor.whiteColor;
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    
    NSMutableArray *section = [NSMutableArray new];
    [section addObject:@{
        @"header" : OALocalizedString(@"name_and_descr").upperCase,
        @"type" : kTextFieldCell,
        @"title" : self.name,
        @"placeholder" : OALocalizedString(@"fav_name"),
        @"selector" : @"editName:"
    }];
    [section addObject:@{
        @"type" : kTextFieldCell,
        @"title" : self.desc,
        @"placeholder" : OALocalizedString(@"description"),
        @"selector" : @"editDescription:"
    }];
    [section addObject:@{
        @"type" : kTextFieldCell,
        @"title" : self.address,
        @"placeholder" : OALocalizedString(@"shared_string_address"),
        @"selector" : @"editAddress:"
    }];
    [data addObject:[NSArray arrayWithArray:section]];
    
    section = [NSMutableArray new];
    [section addObject:@{
        @"header" : OALocalizedString(@"group"),
        @"type" : kCellTypeTitle,
        @"title" : OALocalizedString(@"select_group"),
        @"value" : [self getGroupTitle],
        @"key" : kSelectGroupKey
    }];
    [data addObject:[NSArray arrayWithArray:section]];
    
    section = [NSMutableArray new];
    [section addObject:@{
        @"header" : OALocalizedString(@"map_settings_appearance"),
        @"type" : kCellTypePoiCollection,
        @"title" : OALocalizedString(@"icon"),
        @"value" : @"",
        @"index" : [NSNumber numberWithInt:_selectedIconIndex],
        @"data" : _poiIcons[_selectedIconCategoryName],
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

#pragma mark - Getters and setters

- (NSString *) getItemName
{
    if (!self.favorite.favorite->getTitle().isNull())
    {
        return self.favorite.favorite->getTitle().toNSString();
    }
    else
    {
        return @"";
    }
}

- (void) setItemName:(NSString *)name
{
    self.favorite.favorite->setTitle(QString::fromNSString(name));
}

- (NSString *) getItemDesc
{
    if (!self.favorite.favorite->getDescription().isNull())
    {
        return self.favorite.favorite->getDescription().toNSString();
    }
    else
    {
        return @"";
    }
}

- (void) setItemDesc:(NSString *)desc
{
    self.favorite.favorite->setDescription(QString::fromNSString(desc));
}

- (NSString *) getItemAddress
{
    if (!self.favorite.favorite->getAddress().isNull())
    {
        return self.favorite.favorite->getAddress().toNSString();
    }
    else
    {
        return @"";
    }
}

- (void) setItemAddress:(NSString *)address
{
    self.favorite.favorite->setAddress(QString::fromNSString(address));
}

- (NSString *) getItemIcon
{
    if (!self.favorite.favorite->getIcon().isNull())
    {
        return self.favorite.favorite->getIcon().toNSString();
    }
    else
    {
        return @"";
    }
}

- (void) setItemIcon:(NSString *)icon
{
    self.favorite.favorite->setIcon(QString::fromNSString(icon));
}

- (NSString *) getItemBackground
{
    if (!self.favorite.favorite->getBackground().isNull())
    {
        return self.favorite.favorite->getBackground().toNSString();
    }
    else
    {
        return @"";
    }
}

- (void) setItemBackground:(NSString *)background
{
    self.favorite.favorite->setBackground(QString::fromNSString(background));
}

- (UIColor *) getItemColor
{
    return [UIColor colorWithRed:self.favorite.favorite->getColor().r/255.0 green:self.favorite.favorite->getColor().g/255.0 blue:self.favorite.favorite->getColor().b/255.0 alpha:1.0];
}

- (void) setItemColor:(UIColor *)color
{
    CGFloat r,g,b,a;
    [color getRed:&r
            green:&g
             blue:&b
            alpha:&a];
    
    self.favorite.favorite->setColor(OsmAnd::FColorRGB(r,g,b));
}

- (NSString *) getItemGroup
{
    if (!self.favorite.favorite->getGroup().isNull())
    {
        return self.favorite.favorite->getGroup().toNSString();
    }
    else
    {
        return @"";
    }
}

- (void) setItemGroup:(NSString *)groupName
{
    self.favorite.favorite->setGroup(QString::fromNSString(groupName));
}

- (NSString *) getGroupTitle
{
    NSString *groupName = self.favorite.favorite->getGroup().toNSString();
    return groupName.length == 0 ? OALocalizedString(@"favorite") : groupName;
}

- (NSArray *) getItemGroups
{
    return [[OANativeUtilities QListOfStringsToNSMutableArray:_app.favoritesCollection->getGroups().toList()] copy];
}


#pragma mark - Actions

- (void)onCancelButtonPressed
{
    if (_isNewItemAdding)
        [self deleteItemSilent];
}

- (void)onDoneButtonPressed
{
    if (_wasChanged)
    {
        [self setItemName:self.name];
        [self setItemDesc:self.desc ? self.desc : @""];
        [self setItemAddress:self.address ? self.address : @""];
        [self setItemIcon:_poiIcons[_selectedIconCategoryName][_selectedIconIndex]];
        [self setItemColor:_selectedColor.color];
        [self setItemBackground:_backgroundIconNames[_selectedBackgroundIndex]];
        [self saveItemToStorage];
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
                                            [self deleteItemSilent];
                                            [self dismissViewControllerAnimated:YES completion:nil];
                                        }],
      nil] show];
}

- (void) deleteItemSilent
{
    _app.favoritesCollection->removeFavoriteLocation(self.favorite.favorite);
    [_app saveFavoritesToPermamentStorage];
}

- (void) saveItemToStorage
{
    [[OsmAndApp instance] saveFavoritesToPermamentStorage];
}

- (void) removeExistingItemFromCollection
{
    NSString *favoriteTitle = self.favorite.favorite->getTitle().toNSString();
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
    
    if ([item[@"type"] isEqualToString:kTextFieldCell])
    {
        OATextViewTableViewCell* cell;
        cell = (OATextViewTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kTextFieldCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextViewCell" owner:self options:nil];
            cell = (OATextViewTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsZero;
        }
        if (cell)
        {
            [cell.textView setText:item[@"title"]];
            [cell.textView setPlaceholder:item[@"placeholder"]];
            [cell.textView removeTarget:self action:NULL forControlEvents:UIControlEventEditingChanged];
            [cell.textView addTarget:self action:NSSelectorFromString(item[@"selector"]) forControlEvents:UIControlEventEditingChanged];
            [cell.textView setDelegate:self];
            
            cell.textView.backgroundColor = UIColorFromRGB(0xffffff);
            cell.backgroundColor = UIColorFromRGB(0xffffff);
            return cell;
        }
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
            int selectedIndex = [item[@"index"] intValue];
            cell.dataArray = item[@"data"];
            cell.titleLabel.text = item[@"title"];
            cell.currentColor = _colors[_selectedColorIndex].intValue;
            cell.currentIcon = selectedIndex;
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
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
    
    if ([key isEqualToString:kSelectGroupKey])
    {
        _groupController = [[OAEditGroupViewController alloc] initWithGroupName:[self getItemGroup] groups:[self getItemGroups]];
        _groupController.delegate = self;
        [self presentViewController:_groupController animated:YES completion:nil];
    }
    else if ([key isEqualToString:kReplaceKey])
    {
        
    }
    else if ([key isEqualToString:kDeleteKey])
    {
        [self deleteItemWithAlertView];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    return YES;
}

#pragma mark - OAPoiTableViewCellDelegate

- (void)poiChanged:(NSInteger)tag
{
    _wasChanged = YES;
    _selectedIconIndex = tag;
    [self updateHeaderIcon];
    [self generateData];
    [self.tableView reloadData];
}

#pragma mark - OAColorsTableViewCellDelegate

- (void)colorChanged:(NSInteger)tag
{
    _wasChanged = YES;
    _selectedColorIndex = tag;
    _selectedColor =  [OADefaultFavorite builtinColors][tag];
    [self updateHeaderIcon];
    [self generateData];
    [self.tableView reloadData];
}

#pragma mark - OAIconsTableViewCellDelegate

- (void)iconChanged:(NSInteger)tag
{
    _wasChanged = YES;
    _selectedBackgroundIndex = tag;
    [self updateHeaderIcon];
    [self generateData];
    [self.tableView reloadData];
}

#pragma mark - OAEditGroupViewControllerDelegate

- (void) groupChanged
{
    [self setItemGroup:_groupController.groupName];
    [self generateData];
    [self.tableView reloadData];
}

@end
