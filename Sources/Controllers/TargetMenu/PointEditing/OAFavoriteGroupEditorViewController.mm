//
//  OAFavoriteGroupEditorViewController.m
//  OsmAnd
//
//  Created by SKalii on 17.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAFavoriteGroupEditorViewController.h"
#import "OAFavoritesHelper.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAUtilities.h"
#import "OsmAnd_Maps-Swift.h"

#import "Localization.h"

@implementation OAFavoriteGroupEditorViewController
{
    OAFavoriteGroup *_favoriteGroup;
    BOOL _isSaving;
}

#pragma mark - Initialization

- (void)postInit
{
    [super postInit];
    
    if (self.isNewItem)
    {
        _favoriteGroup = [[OAFavoriteGroup alloc] init];
        _favoriteGroup.name = self.editName;
        _favoriteGroup.color = self.editColor;
        _favoriteGroup.isVisible = YES;
        _favoriteGroup.iconName = self.editIconName;
        _favoriteGroup.backgroundType = self.editBackgroundIconName;
    }
    else
    {
        _favoriteGroup = [OAFavoritesHelper groupByName:self.editName];
    }
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return self.isNewItem ? [super getNavbarColorScheme] : EOABaseNavbarColorSchemeOrange;
}

- (OAFavoriteGroup *)existingGroupFor:(NSString *)name
{
    NSString *groupName = [self targetGroupNameForName:name];
    OAFavoriteGroup *group = [OAFavoritesHelper groupByTrimmedName:groupName];
    if (group || !self.isNewItem)
        return group;

    NSString *languageCode = [OAUtilities currentLang];
    NSLocale *locale = languageCode.length > 0 ? [NSLocale localeWithLocaleIdentifier:languageCode] : NSLocale.currentLocale;
    NSString *lowercaseGroupName = [groupName lowercaseStringWithLocale:locale];
    for (OAFavoriteGroup *favoriteGroup in [OAFavoritesHelper favoriteGroups])
    {
        if ([[[favoriteGroup.name trim] lowercaseStringWithLocale:locale] isEqualToString:lowercaseGroupName]
            || [[OAFavoriteGroup getDisplayName:favoriteGroup.name] isEqualToString:groupName])
            return favoriteGroup;
    }
    return nil;
}

- (BOOL)allowsValidationForGroupName
{
    return !self.isNewItem;
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    if (_isSaving)
        return;

    if (self.isNewItem)
    {
        [self addPointsGroup];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"shared_string_save")
                                                                       message:OALocalizedString(@"save_favorite_default_appearance")
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        NSString *titleApplyExisting = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_space"),
                                        OALocalizedString(@"apply_to_existing"),
                                        [NSString stringWithFormat:@"(%lu)", _favoriteGroup.points.count]];

        [alert addAction:[UIAlertAction actionWithTitle:titleApplyExisting
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
            [self editPointsGroup:YES updateGroupValues:NO];
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"apply_only_to_new_points")
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
            [self editPointsGroup:NO updateGroupValues:YES];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"apply_to_all_points")
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
            [self editPointsGroup:YES updateGroupValues:YES];
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        
        UIPopoverPresentationController *popover = alert.popoverPresentationController;
        popover.barButtonItem = self.navigationItem.rightBarButtonItem;
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;

        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)onLeftNavbarButtonPressed
{
    if (_isSaving)
        return;

    if (self.isNewItem || ![self isAppearanceChanged])
    {
        [super onLeftNavbarButtonPressed];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"exit_without_saving") message:OALocalizedString(@"unsaved_changes_will_be_lost") preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_exit") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [super onLeftNavbarButtonPressed];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (BOOL)onGestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return !_isSaving && [super onGestureRecognizerShouldBegin:gestureRecognizer];
}

- (void)dismissViewController
{
    if (!_isSaving)
        [super dismissViewController];
}

#pragma mark - Additions

- (NSString *)targetGroupNameForName:(NSString *)name
{
    NSString *trimmedName = [(name ?: @"") stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *parentGroupName = self.parentGroupName ?: @"";
    if (parentGroupName.length > 0 && trimmedName.length > 0)
        return [NSString stringWithFormat:@"%@/%@", parentGroupName, trimmedName];
    else if (trimmedName.length > 0)
        return trimmedName;
    else
        return parentGroupName;
}

- (void)addPointsGroup
{
    [self dismissViewController];
    if (self.delegate)
    {
        [self.delegate addNewItemWithName:self.editName
                                 iconName:self.editIconName
                                    color:self.editColor
                       backgroundIconName:self.editBackgroundIconName];
    }
}

- (void)editPointsGroup:(BOOL)updatePoints updateGroupValues:(BOOL)updateGroupValues
{
    if (_isSaving)
        return;

    [self beginSaving];
    if (![self.editIconName isEqual:_favoriteGroup.iconName] || (updatePoints && self.editIconName.length == 0))
    {
        [OAFavoritesHelper updateGroup:_favoriteGroup
                              iconName:self.editIconName
                          updatePoints:updatePoints
                       updateGroupIcon:updateGroupValues
                       saveImmediately:NO
                            completion:^{
            [self finishEditingPointsGroup:updatePoints updateGroupValues:updateGroupValues];
        }];
    }
    else
    {
        [self finishEditingPointsGroup:updatePoints updateGroupValues:updateGroupValues];
    }
}

- (void)beginSaving
{
    _isSaving = YES;
    [self.view endEditing:YES];
    self.modalInPresentation = YES;
    self.view.userInteractionEnabled = NO;
}

- (void)finishEditingPointsGroup:(BOOL)updatePoints updateGroupValues:(BOOL)updateGroupValues
{
    [[self getPoiIconCollectionHandler] addIconToLastUsed:self.editIconName];

    if (![self.editColor isEqual:_favoriteGroup.color])
        [OAFavoritesHelper updateGroup:_favoriteGroup
                                 color:self.editColor
                          updatePoints:updatePoints
                      updateGroupColor:updateGroupValues
                       saveImmediately:NO];

    if (![self.editBackgroundIconName isEqualToString:_favoriteGroup.backgroundType])
        [OAFavoritesHelper updateGroup:_favoriteGroup
                    backgroundIconName:self.editBackgroundIconName
                          updatePoints:updatePoints
                      updateGroupShape:updateGroupValues
                       saveImmediately:NO];

    [OAFavoritesHelper updateGroup:_favoriteGroup
                           newName:self.editName
                   saveImmediately:NO];

    [OAFavoritesHelper notifyFavoritesStorageChanged];
    [OAFavoritesHelper saveCurrentPointsIntoFile];

    self.view.userInteractionEnabled = YES;
    self.modalInPresentation = NO;
    _isSaving = NO;

    if ([self.delegate respondsToSelector:@selector(onEditorUpdated)])
        [self.delegate onEditorUpdated];
    [self dismissViewController];
}

@end
