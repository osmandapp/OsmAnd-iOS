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
#include "Localization.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

@interface OAEditFavoriteViewController ()
@end

@implementation OAEditFavoriteViewController
{
    OsmAndAppInstance _app;

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
        groups = @[OALocalizedString(@"My places")];
    else
        groups = [groups sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    QRadioElement* groupField = [[OAQStringPickerElement alloc] initWithItems:groups
                                                                     selected:[groups indexOfObject:favorite->getGroup().toNSString()]
                                                                        title:OALocalizedString(@"Group")
                                                                 newItemTitle:OALocalizedString(@"New group")
                                                           newItemPlaceholder:OALocalizedString(@"Name")];
    [mainSection addElement:groupField];

    // Color
    QColorPickerElement* colorField = [[OAQColorPickerElement alloc] initWithItems:@[
                                                                                     @[@"Black", [UIColor blackColor]],
                                                                                     @[@"White", [UIColor whiteColor]],
                                                                                     @[@"Gray", [UIColor grayColor]],
                                                                                     @[@"Blue",  [UIColor blueColor]],
                                                                                     @[@"Red",  [UIColor redColor]],
                                                                                     @[@"Green", [UIColor greenColor]],
                                                                                     @[@"Yellow", [UIColor yellowColor]],
                                                                                     @[@"Purple", [UIColor purpleColor]],
                                                                                     @[@"Magenta", [UIColor magentaColor]]
                                                                                     ]
                                                                          selected:0 //TODO:!!!!!
                                                                             title:OALocalizedString(@"Color")];
    [mainSection addElement:colorField];

    self = [super initWithRoot:rootElement];
    if (self) {
        _app = app;

        _titleField = titleField;
        _groupField = groupField;
        _colorField = colorField;
    }
    return self;
}

//TODO: save during backward navigation!

@end
