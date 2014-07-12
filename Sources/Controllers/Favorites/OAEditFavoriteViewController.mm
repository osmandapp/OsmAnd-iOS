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
                                                                             action:@selector(saveFavoriteAndClose)];
}

- (void)saveFavoriteAndClose
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

@end
