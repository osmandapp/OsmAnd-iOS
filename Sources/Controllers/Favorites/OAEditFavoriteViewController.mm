//
//  OAEditFavoriteViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/10/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAEditFavoriteViewController.h"

#import <QuickDialog.h>
#import <QPickerElement.h>
#import <UIAlertView+Blocks.h>
#import <RegexKitLite.h>

#import "OsmAndApp.h"
#import "OAQColorPickerElement.h"
#import "OAQStringPickerElement.h"
#import "OANativeUtilities.h"
#import "OADefaultFavorite.h"
#import "OARootViewController.h"
#include "Localization.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>

@interface OAEditFavoriteViewController () <UIDocumentInteractionControllerDelegate>
@end

@implementation OAEditFavoriteViewController
{
    OsmAndAppInstance _app;

    std::shared_ptr<OsmAnd::IFavoriteLocation> _favorite;

    QEntryElement* _titleField;
    QRadioElement* _groupField;
    QColorPickerElement* _colorField;

    UIDocumentInteractionController* _exportController;
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
    [super viewWillAppear:animated];

    [self.navigationController setToolbarHidden:NO
                                       animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.navigationController setToolbarHidden:YES
                                       animated:animated];
}

- (void)collectData
{
    QString title = QString::fromNSString(_titleField.textValue);

    QString group = QString::fromNSString((NSString*)_groupField.selectedItem);

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
}

- (void)onSaveFavoriteAndClose
{
    [self collectData];

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onGoTo
{
    OARootViewController* rootViewController = [OARootViewController instance];

    // Close everything
    [rootViewController closeMenuAndPanelsAnimated:YES];

    // Ensure favorites layer is shown
    [_app.data.mapLayersConfiguration setLayer:kFavoritesLayerId
                                    Visibility:YES];

    // Go to favorite location
    [rootViewController.mapPanel.mapViewController goToPosition:[OANativeUtilities convertFromPointI:_favorite->getPosition()]
                                                        andZoom:kDefaultFavoriteZoom
                                                       animated:YES];
}

- (void)onShare
{
    [self collectData];

    std::shared_ptr<OsmAnd::FavoriteLocationsGpxCollection> exportCollection(new OsmAnd::FavoriteLocationsGpxCollection());
    exportCollection->copyFavoriteLocation(_favorite);

    NSString* name = _favorite->getTitle().toNSString();
    name = [name stringByReplacingOccurrencesOfRegex:@"([^\\w-\\.]+)" withString:@"_"];
    NSString* filename = [name stringByAppendingString:@".gpx"];
    NSString* fullFilename = [NSTemporaryDirectory() stringByAppendingString:filename];
    if (!exportCollection->saveTo(QString::fromNSString(fullFilename)))
        return;

    NSURL* favoritesUrl = [NSURL fileURLWithPath:fullFilename];
    _exportController = [UIDocumentInteractionController interactionControllerWithURL:favoritesUrl];
    _exportController.UTI = @"net.osmand.gpx";
    _exportController.delegate = self;
    _exportController.name = filename;
    [_exportController presentOptionsMenuFromRect:CGRectZero
                                           inView:self.view
                                         animated:YES];
}

- (void)onDelete
{
    [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"Confirmation")
                                message:OALocalizedString(@"Do you want to delete this favorites?")
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"No")
                                                             action:^{
                                                             }]
                       otherButtonItems:[RIButtonItem itemWithLabel:OALocalizedString(@"Yes")
                                                             action:^{
                                                                 _app.favoritesCollection->removeFavoriteLocation(_favorite);
                                                                 [_app saveFavoritesToPermamentStorage];

                                                                 [self.navigationController popViewControllerAnimated:YES];
                                                             }], nil] show];
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
