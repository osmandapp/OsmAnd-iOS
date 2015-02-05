//
//  OAIncomingURLViewController.mm
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
#include <OsmAndCore/IFavoriteLocation.h>

#include <OsmAndCore.h>
#include <OsmAndCore/FavoriteLocationsGpxCollection.h>
#include <OsmAndCore/GpxDocument.h>

#define kAlertConflictWarning -2
#define kAlertConflictRename -4

@interface OAIncomingURLViewController ()

@end

@implementation OAIncomingURLViewController
{
    OsmAndAppInstance _app;

    std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> _favoritesCollection;
    std::shared_ptr<OsmAnd::GpxDocument> gpxCollection;
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
        // Try to import favorites
        favoritesCollection = OsmAnd::FavoriteLocationsGpxCollection::tryLoadFrom(QString::fromNSString(url.path));
        if (favoritesCollection)
        {
            // handled
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


        } else {
            // Try to import GPX
            gpxCollection = OsmAnd::GpxDocument::loadFrom(QString::fromNSString(url.path));
            if (gpxCollection) {
                handled = YES;
                
                QSection* favoritesSection = [[QSection alloc] initWithTitle:OALocalizedString(@"Import as GPX")];
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
            } else
                gpxCollection = nullptr;
        }
        
        self = [super initWithRoot:rootElement];
        if (self) {
            _app = app;
            _favoritesCollection = favoritesCollection;
        }
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem.title = OALocalizedString(@"Cancel");
    self.ignoredNames = [[NSMutableArray alloc] init];
    
}

- (void)onImportAllAsFavoritesAndReplace:(QElement*)sender
{
    if (_favoritesCollection) {
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
    } else if (gpxCollection) {
        [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"Confirmation")
                                    message:OALocalizedString(@"Do you want to lose your previous GPX and replace them with imported ones?")
                           cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"No")
                                                                 action:^{
                                                                 }]
                           otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"Yes")
                                                                 action:^{
                                                                     
                                                                     _app.gpxCollection = gpxCollection;
                                                                     [_app saveGPXToPermamentStorage];
                                                                     
                                                                     [self.navigationController popViewControllerAnimated:YES];
                                                                 }], nil] show];
    }
}

-(BOOL)isFavoritesValid {
    for(const auto& favorite : _favoritesCollection->getFavoriteLocations())
    {
        NSString* favoriteTitle = favorite->getTitle().toNSString();
        for(const auto& localFavorite : _app.favoritesCollection->getFavoriteLocations())
        {
            if ([favoriteTitle isEqualToString:localFavorite->getTitle().toNSString()] && ![self.ignoredNames containsObject:favoriteTitle] ) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:@"Favorite with name \"%@\" already exists.", favoriteTitle] delegate:self cancelButtonTitle:@"Ignore" otherButtonTitles:@"Rename", @"Replace", nil];
                alert.tag = kAlertConflictWarning;
                [alert show];
                self.conflictedName = favoriteTitle;
                return NO;
            }
        }
    }
    return YES;
}

- (void)onImportAllAsFavoritesAndMerge:(QElement*)sender
{
    if (_favoritesCollection) {
        // IOS-214
        if (![self isFavoritesValid])
            return;
    
        _app.favoritesCollection->mergeFrom(_favoritesCollection);
        [_app saveFavoritesToPermamentStorage];
        [self.ignoredNames removeAllObjects];
        self.conflictedName = @"";

        [self.navigationController popViewControllerAnimated:YES];
    } else {
        //TODO: Change
        _app.gpxCollection = gpxCollection;
        [_app saveGPXToPermamentStorage];
        [self.navigationController popViewControllerAnimated:YES];
    }
}


#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kAlertConflictWarning) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            [self.ignoredNames addObject:self.conflictedName];
            [self onImportAllAsFavoritesAndMerge:nil];
        } else if (buttonIndex == 1) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Remane favorite" message:[NSString stringWithFormat:@"Please enter new name for favorite \"%@\"", self.conflictedName] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            alert.tag = kAlertConflictRename;
            [alert show];

        } else if (buttonIndex == 2) {
            for(const auto& localFavorite : _app.favoritesCollection->getFavoriteLocations()) {
                NSString* favoriteTitle = localFavorite->getTitle().toNSString();
                if ([favoriteTitle isEqualToString:self.conflictedName]) {
                    _app.favoritesCollection->removeFavoriteLocation(localFavorite);
                    break;
                }
            }
            [self onImportAllAsFavoritesAndMerge:nil];
        }
    } else if (alertView.tag == kAlertConflictRename) {
        NSString* newFavoriteName = [alertView textFieldAtIndex:0].text;
        
        for(const auto& favorite : _favoritesCollection->getFavoriteLocations()) {
            NSString* favoriteTitle = favorite->getTitle().toNSString();
            if ([favoriteTitle isEqualToString:self.conflictedName]) {
                favorite->setTitle(QString::fromNSString(newFavoriteName));
                break;
            }
        }
        [self onImportAllAsFavoritesAndMerge:nil];
    }

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
