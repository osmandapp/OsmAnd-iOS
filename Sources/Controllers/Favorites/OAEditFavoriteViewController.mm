//
//  OAEditFavoriteViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/10/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAEditFavoriteViewController.h"

#import <QuickDialog.h>
#import <QPickerElement.h>

#import "OsmAndApp.h"
#import "OAQColorPickerElement.h"
#import "OAQStringPickerElement.h"
#import "OANativeUtilities.h"
#import "OADefaultFavorite.h"
#include "Localization.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

@interface OAEditFavoriteViewController ()
@end

@implementation OAEditFavoriteViewController
{
    OsmAndAppInstance _app;

    std::shared_ptr< OsmAnd::IFavoriteLocation > _favorite;

    QEntryElement* _titleField;
    QRadioElement* _groupField;
    QColorPickerElement* _colorField;
}

- (instancetype)initWithFavorite:(const std::shared_ptr< OsmAnd::IFavoriteLocation >&)favorite
{
    OsmAndAppInstance app = [OsmAndApp instance];

    QRootElement* rootElement = [[QRootElement alloc] init];

    rootElement.title = OALocalizedString(@"Edit favorite");
    rootElement.grouped = YES;
    rootElement.appearance.entryAlignment = NSTextAlignmentRight;

    QSection* mainSection = [[QSection alloc] init];
    [rootElement addSection:mainSection];

    // Title
    QEntryElement* titleField = [[QEntryElement alloc] initWithTitle:OALocalizedString(@"Title")
                                                               Value:favorite->getTitle().toNSString()
                                                         Placeholder:nil];
    titleField.enablesReturnKeyAutomatically = YES;
    [mainSection addElement:titleField];

    // Group
    NSArray* groups = [[OANativeUtilities QListOfStringsToNSMutableArray:app.favoritesCollection->getGroups().toList()] copy];
    if (groups == nil || [groups count] == 0)
        groups = [OADefaultFavorite builtinGroupNames];
    else
        groups = [groups sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    QRadioElement* groupField = [[OAQStringPickerElement alloc] initWithItems:groups
                                                                     selected:[groups indexOfObject:favorite->getGroup().toNSString()]
                                                                        title:OALocalizedString(@"Group")
                                                                 newItemTitle:OALocalizedString(@"New group")
                                                           newItemPlaceholder:OALocalizedString(@"Name")];
    [mainSection addElement:groupField];

    // Color
    NSArray* availableColors = [OADefaultFavorite builtinColors];
    NSUInteger selectedColor = [availableColors indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        UIColor* uiColor = (UIColor*)[obj objectAtIndex:1];
        OsmAnd::FColorARGB fcolor;
        [uiColor getRed:&fcolor.r
                  green:&fcolor.g
                   blue:&fcolor.b
                  alpha:&fcolor.a];
        OsmAnd::ColorRGB color = OsmAnd::FColorRGB(fcolor);

        if (color == favorite->getColor())
            return YES;

        return NO;
    }];
    QColorPickerElement* colorField = [[OAQColorPickerElement alloc] initWithItems:availableColors
                                                                          selected:selectedColor
                                                                             title:OALocalizedString(@"Color")];
    [mainSection addElement:colorField];

    self = [super initWithRoot:rootElement];
    if (self) {
        _app = app;

        _favorite = favorite;

        _titleField = titleField;
        _groupField = groupField;
        _colorField = colorField;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"Save")
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(onSaveFavoriteAndClose)];

    self.toolbarItems = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                        target:nil
                                                                        action:nil],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                        target:self
                                                                        action:@selector(onGoTo)],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                        target:nil
                                                                        action:nil],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                        target:self
                                                                        action:@selector(onShare)],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                        target:nil
                                                                        action:nil],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                        target:self
                                                                        action:@selector(onDelete)],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                        target:nil
                                                                        action:nil]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:NO
                                       animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES
                                       animated:animated];
}

- (void)onSaveFavoriteAndClose
{
    QString title = QString::fromNSString(_titleField.textValue);

    QString group = QString::fromNSString((NSString*)_groupField.selectedValue);

    UIColor* color_ = (UIColor*)[_colorField.selectedItem objectAtIndex:1];
    OsmAnd::FColorARGB color;
    [color_ getRed:&color.r
             green:&color.g
              blue:&color.b
             alpha:&color.a];

    _favorite->setTitle(title);
    _favorite->setGroup(group);
    _favorite->setColor(OsmAnd::FColorRGB(color));
    [_app saveFavoritesToPermamentStorage];

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onGoTo
{

}

- (void)onShare
{
/*    NSArray* selectedCells = [self.quickDialogTableView indexPathsForSelectedRows];
    if ([selectedCells count] == 0)
        return;

    NSArray* selectedElements = [self.quickDialogTableView elementsForIndexPaths:selectedCells];
    if ([selectedElements count] == 0)
        return;

    std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> exportCollection(new OsmAnd::FavoriteLocationsGpxCollection());
    for (QElement* element in selectedElements)
    {
        if ([element.object isKindOfClass:[FavoriteItemData class]])
        {
            FavoriteItemData* favoriteItemData = (FavoriteItemData*)element.object;

            exportCollection->copyFavoriteLocation(favoriteItemData.favorite);
        }
        else if ([element.object isKindOfClass:[GroupItemData class]])
        {
            GroupItemData* groupItemData = (GroupItemData*)element.object;

            exportCollection->mergeFrom(groupItemData.favorites);
        }
    }
    if (exportCollection->getFavoriteLocationsCount() == 0)
        return;

    NSString* tempFilename = [NSTemporaryDirectory() stringByAppendingString:@"exported_favorites.gpx"];
    if (!exportCollection->saveTo(QString::fromNSString(tempFilename)))
        return;

    NSURL* favoritesUrl = [NSURL fileURLWithPath:tempFilename];
    _exportController = [UIDocumentInteractionController interactionControllerWithURL:favoritesUrl];
    _exportController.UTI = @"net.osmand.gpx";
    _exportController.delegate = self;
    _exportController.name = OALocalizedString(@"Exported favorites.gpx");
    [_exportController presentOptionsMenuFromRect:CGRectZero
                                           inView:self.view
                                         animated:YES];*/
}

- (void)onDelete
{
/*    NSArray* selectedCells = [self.quickDialogTableView indexPathsForSelectedRows];
    if ([selectedCells count] == 0)
        return;

    NSArray* selectedElements = [self.quickDialogTableView elementsForIndexPaths:selectedCells];
    if ([selectedElements count] == 0)
        return;

    QList< std::shared_ptr<OsmAnd::IFavoriteLocation> > toBeRemoved;
    for (QElement* element in selectedElements)
    {
        if ([element.object isKindOfClass:[FavoriteItemData class]])
        {
            FavoriteItemData* favoriteItemData = (FavoriteItemData*)element.object;

            toBeRemoved.push_back(favoriteItemData.favorite);
        }
        else if ([element.object isKindOfClass:[GroupItemData class]])
        {
            GroupItemData* groupItemData = (GroupItemData*)element.object;

            toBeRemoved.append(groupItemData.favorites);
        }
    }
    if (toBeRemoved.isEmpty())
        return;

    [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"Confirmation")
                                message:OALocalizedString(@"Do you want to delete selected favorites?")
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"No")
                                                             action:^{
                                                             }]
                       otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"Yes")
                                                             action:^{
                                                                 _app.favoritesCollection->removeFavoriteLocations(toBeRemoved);
                                                                 [_app saveFavoritesToPermamentStorage];
                                                             }], nil] show];*/
}

@end
