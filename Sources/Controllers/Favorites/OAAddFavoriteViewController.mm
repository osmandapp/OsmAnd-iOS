//
//  OAAddFavoriteViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/7/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAAddFavoriteViewController.h"

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

@interface OAAddFavoriteViewController ()
@end

@implementation OAAddFavoriteViewController
{
    OsmAndAppInstance _app;

    CLLocationCoordinate2D _location;

    QEntryElement* _titleField;
    QRadioElement* _groupField;
    QColorPickerElement* _colorField;
}

- (instancetype)initWithLocation:(CLLocationCoordinate2D)location andTitle:(NSString*)title
{
    OsmAndAppInstance app = [OsmAndApp instance];

    QRootElement* rootElement = [[QRootElement alloc] init];

    rootElement.title = OALocalizedString(@"Add favorite");
    rootElement.grouped = YES;
    rootElement.appearance.entryAlignment = NSTextAlignmentRight;

    QSection* mainSection = [[QSection alloc] init];
    [rootElement addSection:mainSection];

    // Title
    QEntryElement* titleField = [[QEntryElement alloc] initWithTitle:OALocalizedString(@"Title")
                                                               Value:title
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
                                                                     selected:0
                                                                        title:OALocalizedString(@"Group")
                                                                 newItemTitle:OALocalizedString(@"New group")
                                                           newItemPlaceholder:OALocalizedString(@"Name")];
    [mainSection addElement:groupField];

    // Color
    QColorPickerElement* colorField = [[OAQColorPickerElement alloc] initWithItems:[OADefaultFavorite builtinColors]
                                                                          selected:0
                                                                             title:OALocalizedString(@"Color")];
    [mainSection addElement:colorField];

    self = [super initWithRoot:rootElement];
    if (self) {
        _app = app;
        _location = location;

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
}

- (void)onSaveFavoriteAndClose
{
    OsmAnd::PointI location;
    location.x = OsmAnd::Utilities::get31TileNumberX(_location.longitude);
    location.y = OsmAnd::Utilities::get31TileNumberY(_location.latitude);

    QString title = QString::fromNSString(_titleField.textValue);

    QString group = QString::fromNSString((NSString*)_groupField.selectedItem);

    UIColor* color_ = (UIColor*)[_colorField.selectedItem objectAtIndex:1];
    OsmAnd::FColorARGB color;
    [color_ getRed:&color.r
             green:&color.g
              blue:&color.b
             alpha:&color.a];

    _app.favoritesCollection->createFavoriteLocation(location,
                                                     title,
                                                     group,
                                                     OsmAnd::FColorRGB(color));
    [_app saveFavoritesToPermamentStorage];

    [self.navigationController popViewControllerAnimated:YES];
}

@end
