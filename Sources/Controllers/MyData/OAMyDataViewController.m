//
//  OAMyDataViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/9/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMyDataViewController.h"

#import <QuickDialog.h>

#import "OsmAndApp.h"
#import "OAManageFavoritesViewController.h"
#import "OALog.h"
#include "Localization.h"

@interface OAMyDataViewController () <UIDocumentInteractionControllerDelegate>

@end

@implementation OAMyDataViewController
{
    OsmAndAppInstance _app;

    UIDocumentInteractionController* _exportController;
}

- (instancetype)init
{
    OsmAndAppInstance app = [OsmAndApp instance];

    QRootElement* rootElement = [[QRootElement alloc] init];

    rootElement.title = OALocalizedString(@"My data");
    rootElement.grouped = YES;
    rootElement.appearance.entryAlignment = NSTextAlignmentRight;

    // Favorites section:
    QSection* favoritesSection = [[QSection alloc] initWithTitle:OALocalizedString(@"Favorites")];
    [rootElement addSection:favoritesSection];

    QLabelElement* manageFavoritesElement = [[QLabelElement alloc] initWithTitle:OALocalizedString(@"Manage my favorites")
                                                                           Value:nil];
    manageFavoritesElement.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    manageFavoritesElement.controllerAction = NSStringFromSelector(@selector(onManageFavorites:));
    manageFavoritesElement.keepSelected = NO;
    [favoritesSection addElement:manageFavoritesElement];
    
    QLabelElement* importFavoritesElement = [[QLabelElement alloc] initWithTitle:OALocalizedString(@"Import Favorites")
                                                                           Value:nil];
    importFavoritesElement.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    importFavoritesElement.controllerAction = NSStringFromSelector(@selector(onImportFavorites:));
    importFavoritesElement.keepSelected = NO;
    [favoritesSection addElement:importFavoritesElement];
    
    QLabelElement* exportFavoritesElement = [[QLabelElement alloc] initWithTitle:OALocalizedString(@"Export my favorites")
                                                                           Value:nil];
    exportFavoritesElement.controllerAction = NSStringFromSelector(@selector(onExportFavorites:));
    exportFavoritesElement.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    exportFavoritesElement.keepSelected = NO;
    [favoritesSection addElement:exportFavoritesElement];

    self = [super initWithRoot:rootElement];
    if (self) {
        _app = app;
    }
    return self;
}

- (void)onManageFavorites:(QElement*)sender
{
    OAManageFavoritesViewController* favoriteManageViewController = [[OAManageFavoritesViewController alloc] initWithAction:kManageFavoriteActionTypeManage];
    [self.navigationController pushViewController:favoriteManageViewController animated:YES];
}

- (void)onImportFavorites:(QElement*)sender
{
    
    NSString* favoritesImportText = OALocalizedString(@"You can import your favorites as waypoints in GPX file (standard format for storing map information supported by PC, iOS, Android)\n\nTo share the favorites.gpx file you can open file from Dropbox, Email, or any other source - Use Open In function.");
    UIAlertView* importHelpAlert = [[UIAlertView alloc] initWithTitle:@"" message:favoritesImportText delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [importHelpAlert show];

}

- (void)onExportFavorites:(QElement*)sender
{
    OAManageFavoritesViewController* favoriteManageViewController = [[OAManageFavoritesViewController alloc] initWithAction:kManageFavoriteActionTypeShare];
    [self.navigationController pushViewController:favoriteManageViewController animated:YES];

     return;
    
    // Share all favorites
    NSURL* favoritesUrl = [NSURL fileURLWithPath:_app.favoritesStorageFilename];
    _exportController = [UIDocumentInteractionController interactionControllerWithURL:favoritesUrl];
    _exportController.UTI = @"net.osmand.gpx";
    _exportController.delegate = self;
    _exportController.name = OALocalizedString(@"OsmAnd Favorites.gpx");
    [_exportController presentOptionsMenuFromRect:CGRectZero
                                           inView:self.view
                                         animated:YES];
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}

#pragma mark -

@end
