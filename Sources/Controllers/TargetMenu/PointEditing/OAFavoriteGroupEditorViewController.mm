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
#import "Localization.h"

@implementation OAFavoriteGroupEditorViewController
{
    OAFavoriteGroup *_favoriteGroup;
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
        _favoriteGroup = [OAFavoritesHelper getGroupByName:self.editName];
    }
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    if (self.isNewItem)
    {
        [self addPointsGroup];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"shared_string_save")
                                                                       message:OALocalizedString(@"apply_to_existing_favorites_descr")
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        NSString *titleApplyExisting = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_space"),
                                        OALocalizedString(@"apply_to_existing"),
                                        [NSString stringWithFormat:@"(%lu)", _favoriteGroup.points.count]];

        [alert addAction:[UIAlertAction actionWithTitle:titleApplyExisting
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
            [self editPointsGroup:YES];
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"apply_only_to_new_points")
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
            [self editPointsGroup:NO];
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

#pragma mark - Additions

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

- (void)editPointsGroup:(BOOL)updatePoints
{
    [OAFavoritesHelper updateGroup:_favoriteGroup
                          iconName:self.editIconName
                      updatePoints:updatePoints
                   saveImmediately:NO];

    [OAFavoritesHelper updateGroup:_favoriteGroup
                             color:self.editColor
                      updatePoints:updatePoints
                   saveImmediately:NO];

    [OAFavoritesHelper updateGroup:_favoriteGroup
                backgroundIconName:self.editBackgroundIconName
                      updatePoints:updatePoints
                   saveImmediately:NO];

    [OAFavoritesHelper updateGroup:_favoriteGroup
                           newName:self.editName
                   saveImmediately:NO];

    [OAFavoritesHelper saveCurrentPointsIntoFile];
    if (self.delegate)
        [self.delegate onEditorUpdated];
    [self dismissViewController];
}

@end
