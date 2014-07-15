//
//  OAIncomingURLViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/9/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAIncomingURLViewController.h"

#import <QuickDialog.h>
#import <QPickerElement.h>
#import <UIAlertView+Blocks.h>

#import "OsmAndApp.h"
#include "Localization.h"

#include <OsmAndCore.h>
#include <OsmAndCore/FavoriteLocationsGpxCollection.h>

@interface OAIncomingURLViewController ()

@end

@implementation OAIncomingURLViewController
{
    OsmAndAppInstance _app;

    std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> _favoritesCollection;
}

- (instancetype)initFor:(NSURL*)url
{
    OsmAndAppInstance app = [OsmAndApp instance];

    BOOL handled = NO;

    QRootElement* rootElement = [[QRootElement alloc] init];

    rootElement.title = [url isFileURL] ? OALocalizedString(@"Open file") : OALocalizedString(@"Open URL");
    rootElement.grouped = YES;
    rootElement.appearance.entryAlignment = NSTextAlignmentRight;

    // Try to process as favorites
    std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> favoritesCollection;
    if ([url isFileURL])
    {
        favoritesCollection = OsmAnd::FavoriteLocationsGpxCollection::tryLoadFrom(QString::fromNSString(url.path));
        if (favoritesCollection)
        {
            handled = YES;

            QSection* favoritesSection = [[QSection alloc] initWithTitle:OALocalizedString(@"Import as favorites")];
            [rootElement addSection:favoritesSection];

            // Import all and replace
            QLabelElement* importAllAndReplace = [[QLabelElement alloc] initWithTitle:OALocalizedString(@"All and replace mine")
                                                                                Value:nil];
            importAllAndReplace.controllerAction = NSStringFromSelector(@selector(onImportAllAsFavoritesAndReplace:));
            importAllAndReplace.accessoryType = UITableViewCellAccessoryNone;
            [favoritesSection addElement:importAllAndReplace];

            // Import all and merge
            QLabelElement* importAllAndMerge = [[QLabelElement alloc] initWithTitle:OALocalizedString(@"All and merge with mine")
                                                                              Value:nil];
            importAllAndMerge.controllerAction = NSStringFromSelector(@selector(onImportAllAsFavoritesAndMerge:));
            importAllAndMerge.accessoryType = UITableViewCellAccessoryNone;
            [favoritesSection addElement:importAllAndMerge];

/*
            // Import selected and replace
            QLabelElement* importSelectedAndReplace = [[QLabelElement alloc] initWithTitle:OALocalizedString(@"Selected and replace mine")
                                                                                     Value:nil];
            importSelectedAndReplace.controllerAction = NSStringFromSelector(@selector(onImportSelectedAsFavoritesAndReplace:));
            importSelectedAndReplace.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [favoritesSection addElement:importSelectedAndReplace];

            // Import selected and merge
            QLabelElement* importSelectedAndMerge = [[QLabelElement alloc] initWithTitle:OALocalizedString(@"Selected and merge with mine")
                                                                                   Value:nil];
            importSelectedAndMerge.controllerAction = NSStringFromSelector(@selector(onImportSelectedAsFavoritesAndMerge:));
            importSelectedAndMerge.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [favoritesSection addElement:importSelectedAndMerge];
 */
        }
    }

    // Seems that this URL can not be handled
    if (!handled)
        return nil;

    self = [super initWithRoot:rootElement];
    if (self) {
        _app = app;

        _favoritesCollection = favoritesCollection;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem.title = OALocalizedString(@"Cancel");
}

- (void)onImportAllAsFavoritesAndReplace:(QElement*)sender
{
    [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"Confirmation")
                                message:OALocalizedString(@"Do you want to lose your previous favorites and replace them with imported ones?")
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"No")
                                                             action:^{
                                                             }]
                       otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"Yes")
                                                             action:^{
                                                                 _app.favoritesCollection->copyFrom(_favoritesCollection);
                                                                 [_app saveFavoritesToPermamentStorage];
                                                                 
                                                                 [self.navigationController popViewControllerAnimated:YES];
                                                             }], nil] show];
}

- (void)onImportAllAsFavoritesAndMerge:(QElement*)sender
{
    _app.favoritesCollection->mergeFrom(_favoritesCollection);
    [_app saveFavoritesToPermamentStorage];

    [self.navigationController popViewControllerAnimated:YES];
}

/*
- (void)onImportSelectedAsFavoritesAndReplace:(QElement*)sender
{

}

- (void)onImportSelectedAsFavoritesAndMerge:(QElement*)sender
{

}
*/

@end
