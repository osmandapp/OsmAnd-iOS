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
    NSMutableArray<NSString *> *_ignoredNames;
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
    _ignoredNames = [NSMutableArray array];
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
                                                                 color: UIColorFromRGBA([wptPt getColor])];

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
        // IOS-214
        if (![self isFavoritesValid])
            return;

        [OAFavoritesHelper importFavoritesFromGpx:_gpxFile];

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
    for (OAFavoriteItem *localItem in favoriteItems)
    {
        for (NSString *key in _gpxFile.pointsGroups.allKeys)
        {
            OASGpxUtilitiesPointsGroup *pointGroup = _gpxFile.pointsGroups[key];
            for (OASWptPt *item in pointGroup.points)
            {
                NSString *importItemName = item.name;
                NSString *importItemFolder = item.category;
                NSString *localItemName = [localItem getName];
                NSString *localItemFolder = [localItem getCategory];
                
                if ([importItemName isEqualToString:localItemName] &&
                    [importItemFolder isEqualToString:localItemFolder] &&
                    ![_ignoredNames containsObject:importItemName])
                {
                    _conflictedItem = item;

                    UIAlertController *alert =
                            [UIAlertController alertControllerWithTitle:nil
                                                                message:[NSString stringWithFormat:OALocalizedString(@"fav_exists"), importItemName]
                                                         preferredStyle:UIAlertControllerStyleAlert];

                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction * _Nonnull action)
                        {
                            [_ignoredNames removeAllObjects];
                            _conflictedItem = nil;
                        }
                    ];

                    UIAlertAction *ignoreAction =
                        [UIAlertAction actionWithTitle:OALocalizedString(@"fav_ignore")
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * _Nonnull action)
                        {
                            [_ignoredNames addObject:_conflictedItem.name];
                            [self onRightNavbarButtonPressed];
                        }
                    ];

                    UIAlertAction *renameAction =
                        [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_rename")
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * _Nonnull action)
                        {
                            UIAlertController *alertRename =
                                    [UIAlertController alertControllerWithTitle:OALocalizedString(@"fav_rename_q")
                                                                        message:OALocalizedString(@"fav_enter_new_name \"%@\"", _conflictedItem.name)
                                                                 preferredStyle:UIAlertControllerStyleAlert];

                            [alertRename addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                                textField.text = _conflictedItem.name;
                            }];

                            UIAlertAction *cancelRenameAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                                                   style:UIAlertActionStyleDefault
                                                                                 handler:nil
                            ];

                            UIAlertAction *okAction =
                                [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok")
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action)
                                {
                                    
                                    NSString *newFavoriteName = alertRename.textFields[0].text;
                                    _conflictedItem.name = newFavoriteName;
                                    [self onRightNavbarButtonPressed];
                                }
                            ];

                            [alertRename addAction:cancelRenameAction];
                            [alertRename addAction:okAction];

                            [self presentViewController:alertRename animated:YES completion:nil];
                        }
                    ];

                    UIAlertAction *updateAction =
                        [UIAlertAction actionWithTitle:OALocalizedString(@"update_existing")
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * _Nonnull action)
                        {
                            for (OAFavoriteItem *localFavortite in favoriteItems)
                            {
                                if ([[localFavortite getName] isEqualToString:_conflictedItem.name])
                                {
                                    [OAFavoritesHelper deleteFavoriteGroups:nil
                                                          andFavoritesItems:@[localFavortite]];
                                    break;
                                }
                            }
                            [self onRightNavbarButtonPressed];
                        }
                    ];

                    UIAlertAction *replaceAction =
                        [UIAlertAction actionWithTitle:OALocalizedString(@"replace_all")
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * _Nonnull action)
                        {
                            for (NSString *keyGroup in _gpxFile.pointsGroups.allKeys)
                            {
                                OASGpxUtilitiesPointsGroup *group = _gpxFile.pointsGroups[keyGroup];
                                for (OASWptPt *wptPt in group.points)
                                {
                                    for (OAFavoriteItem *localFavortite in favoriteItems)
                                    {
                                        if ([[localFavortite getName] isEqualToString:wptPt.name])
                                        {
                                            [OAFavoritesHelper deleteFavoriteGroups:nil
                                                                  andFavoritesItems:@[localFavortite]];
                                        }
                                    }
                                }
                            }
                            [self onRightNavbarButtonPressed];
                        }
                    ];

                    [alert addAction:cancelAction];
                    [alert addAction:ignoreAction];
                    [alert addAction:renameAction];
                    [alert addAction:updateAction];
                    [alert addAction:replaceAction];

                    [self presentViewController:alert animated:YES completion:nil];
                    return NO;
                }
            }
        }
    }
    return YES;
}

@end
