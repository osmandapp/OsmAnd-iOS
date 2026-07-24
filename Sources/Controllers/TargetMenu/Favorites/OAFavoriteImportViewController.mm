//
//  OAFavoriteImportViewController.m
//  OsmAnd
//
//  Created by Alexey on 2/6/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAFavoriteImportViewController.h"
#import "OAPointTableViewCell.h"
#import "OAFavoriteItem.h"
#import "OAFavoritesBridgeHelper.h"
#import "OAFavoritesHelper.h"
#import "OAGPXDocumentPrimitives.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAColors.h"
#import "Localization.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"

NSNotificationName const OAFavoriteImportViewControllerDidDismissNotification = @"OAFavoriteImportViewControllerDidDismissNotification";

@implementation OAFavoriteImportViewController
{
    NSURL *_url;
    NSMutableSet<NSString *> *_ignoredNames;
    OASGpxFile *_gpxFile;
    OASWptPt *_conflictedItem;
}

#pragma mark - Initialization

- (instancetype)initFor:(NSURL *)url
{
    self = [super init];
    if (self)
    {
        _url = url;
        [self postInit];
    }
    return self;
}

- (void)commonInit
{
    _ignoredNames = [NSMutableSet set];
}

- (void)postInit
{
    if ([_url isFileURL])
    {
        _gpxFile = [OAFavoritesHelper loadGpxFile:_url.path];
        _handled = YES;
    }
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"fav_import_title");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    UIBarButtonItem *rightButton = [self createRightNavbarButton:OALocalizedString(@"shared_string_import")
                                                        iconName:nil
                                                          action:@selector(onRightNavbarButtonPressed)
                                                            menu:nil];
    rightButton.accessibilityLabel = OALocalizedString(@"shared_string_import");
    return @[rightButton];
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

#pragma mark - Table Data

- (void)generateData
{
    if (_gpxFile)
    {
        for (NSString *key in _gpxFile.pointsGroups.allKeys)
        {
            OASGpxUtilitiesPointsGroup *pointsGroup = _gpxFile.pointsGroups[key];
            OATableSectionData *section = [self.tableData createNewSection];
            section.headerText = [OAFavoriteGroup getDisplayName:pointsGroup.name];
            
            for (OASWptPt *wptPt in pointsGroup.points)
            {
                OATableRowData *row = [section createNewRow];
                row.cellType = [OAPointTableViewCell getCellIdentifier];
                [row setObj:wptPt forKey:@"wptPt"];
            }
        }
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [self.tableData itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OAPointTableViewCell getCellIdentifier]])
    {
        OAPointTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAPointTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            OASWptPt *wptPt = [item objForKey:@"wptPt"];

            cell.titleView.text = wptPt.name;
            cell.rightArrow.image = nil;
            cell.directionImageView.image = nil;
            cell.distanceView.hidden = YES;

            CGRect titleFrame = CGRectMake(cell.titleView.frame.origin.x, 15.0, cell.titleView.frame.size.width + 20.0, cell.titleView.frame.size.height);
            cell.titleView.frame = titleFrame;

            cell.distanceView.text = @(wptPt.distance).stringValue;
            cell.directionImageView.image = [UIImage templateImageNamed:@"ic_small_direction"];
            cell.directionImageView.tintColor = UIColorFromRGB(color_elevation_chart);
//            cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
            
           
            cell.titleIcon.image = [OAFavoritesHelper getCompositeIcon:[wptPt getIconName]
                                                        backgroundIcon:[wptPt getBackgroundType]
                                                                 color: UIColorFromARGB([wptPt getColor])];

        }
        return cell;
    }
    return nil;
}

#pragma mark - Selectors

- (void)onLeftNavbarButtonPressed
{
    [OAUtilities denyAccessToFile:_url.path removeFromInbox:YES];
    [self dismissViewController];
}

- (void)onRightNavbarButtonPressed
{
    if (_gpxFile && _gpxFile.pointsGroups.count > 0)
    {
        if (![self isFavoritesValid])
            return;

        [OAFavoritesHelper importFavoritesFromGpx:_gpxFile];
        [OAFavoritesBridgeHelper invalidateFavoriteFoldersCache];

        [_ignoredNames removeAllObjects];
        _conflictedItem = nil;
        
        [OAUtilities denyAccessToFile:_url.path removeFromInbox:YES];
        [self dismissViewController];
    }
}

- (void)dismissViewController
{
    [self dismissViewControllerWithAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:
         OAFavoriteImportViewControllerDidDismissNotification object:nil userInfo:nil];
    }];
}

#pragma mark - Additions

- (BOOL)isFavoritesValid
{
    if (!_gpxFile)
        return NO;

    NSArray<OAFavoriteItem *> *favoriteItems = [OAFavoritesHelper getFavoriteItems];
    if (favoriteItems.count == 0)
        return YES;

    NSMutableDictionary<NSString *, OAFavoriteItem *> *localIndex =
        [NSMutableDictionary dictionaryWithCapacity:favoriteItems.count];

    for (OAFavoriteItem *item in favoriteItems)
    {
        NSString *name = [item getName];
        if (!name)
            continue;

        NSString *cat = [item getCategory] ?: @"";
        NSString *key = [[cat stringByAppendingString:@"|"] stringByAppendingString:name];

        localIndex[key] = item;
    }

    NSMutableSet<NSString *> *ignoredSet = [_ignoredNames mutableCopy];

    __weak __typeof(self) weakSelf = self;

    for (NSString *groupKey in _gpxFile.pointsGroups)
    {
        OASGpxUtilitiesPointsGroup *group = _gpxFile.pointsGroups[groupKey];

        for (OASWptPt *wpt in group.points)
        {
            NSString *name = wpt.name;
            if (!name)
                continue;

            if ([ignoredSet containsObject:name])
                continue;

            NSString *cat = wpt.category ?: @"";
            NSString *key = [[cat stringByAppendingString:@"|"] stringByAppendingString:name];

            OAFavoriteItem *match = localIndex[key];
            if (!match)
                continue;

            _conflictedItem = wpt;

            UIAlertController *alert =
                [UIAlertController alertControllerWithTitle:nil
                                                    message:[NSString stringWithFormat:OALocalizedString(@"fav_exists"), name]
                                             preferredStyle:UIAlertControllerStyleAlert];

            // CANCEL
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                      style:UIAlertActionStyleCancel
                                                    handler:^(UIAlertAction *action) {

                __strong __typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf)
                    return;

                [strongSelf->_ignoredNames removeAllObjects];
                strongSelf->_conflictedItem = nil;
            }]];

            // IGNORE
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"fav_ignore")
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {

                __strong __typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf)
                    return;

                if (strongSelf->_conflictedItem.name)
                {
                    [strongSelf->_ignoredNames addObject:strongSelf->_conflictedItem.name];
                    [ignoredSet addObject:strongSelf->_conflictedItem.name];
                }

                [strongSelf onRightNavbarButtonPressed];
            }]];

            // RENAME
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_rename")
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {

                __strong __typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf)
                    return;

                [strongSelf showRenameAlertForConflict:strongSelf->_conflictedItem];
            }]];

            // UPDATE
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"update_existing")
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {

                __strong __typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf)
                    return;

                OAFavoriteItem *toDelete = match;

                [OAFavoritesHelper deleteFavoriteGroups:nil
                                      andFavoritesItems:@[toDelete]];

                [strongSelf onRightNavbarButtonPressed];
            }]];

            // REPLACE ALL
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"replace_all")
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {

                __strong __typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf)
                    return;

                NSMutableArray<OAFavoriteItem *> *toDelete =
                    [NSMutableArray array];

                for (NSString *gKey in strongSelf->_gpxFile.pointsGroups)
                {
                    OASGpxUtilitiesPointsGroup *group = strongSelf->_gpxFile.pointsGroups[gKey];

                    for (OASWptPt *pt in group.points)
                    {
                        NSString *ptName = pt.name;
                        if (!ptName)
                            continue;

                        NSString *ptCat = pt.category ?: @"";
                        NSString *ptKey = [[ptCat stringByAppendingString:@"|"] stringByAppendingString:ptName];

                        OAFavoriteItem *fav = localIndex[ptKey];
                        if (fav)
                        {
                            [toDelete addObject:fav];
                        }
                    }
                }

                if (toDelete.count > 0)
                {
                    [OAFavoritesHelper deleteFavoriteGroups:nil
                                          andFavoritesItems:toDelete];
                }

                [strongSelf onRightNavbarButtonPressed];
            }]];

            [self presentViewController:alert animated:YES completion:nil];
            return NO;
        }
    }

    return YES;
}

- (void)showRenameAlertForConflict:(OASWptPt *)conflictedItem
{
    if (!conflictedItem)
        return;

    __weak __typeof(self) weakSelf = self;
    
    NSString *alertRenameMessage = [NSString stringWithFormat:@"%@ \"%@\"",
        OALocalizedString(@"fav_enter_new_name"),
        conflictedItem.name ?: @""];

    UIAlertController *alertRename =
        [UIAlertController alertControllerWithTitle:OALocalizedString(@"fav_rename_q")
                                            message:alertRenameMessage
                                     preferredStyle:UIAlertControllerStyleAlert];

    [alertRename addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = conflictedItem.name;
    }];

    // CANCEL
    [alertRename addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                    style:UIAlertActionStyleCancel
                                                  handler:nil]];

    // OK
    [alertRename addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok")
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction * _Nonnull action)
    {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf)
            return;

        NSString *newName = alertRename.textFields.firstObject.text;
        if (newName.length == 0)
            return;

        conflictedItem.name = newName;

        [strongSelf onRightNavbarButtonPressed];
    }]];

    [self presentViewController:alertRename animated:YES completion:nil];
}

@end
