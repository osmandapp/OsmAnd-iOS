//
//  OAAddFavoriteViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/7/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAAddFavoriteViewController.h"

#import <QuickDialog.h>

#import "OsmAndApp.h"
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
}

- (instancetype)initWithLocation:(CLLocationCoordinate2D)location andTitle:(NSString*)title
{
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

    self = [super initWithRoot:rootElement];
    if (self) {
        _app = [OsmAndApp instance];
        _location = location;

        _titleField = titleField;
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
    OsmAnd::PointI location;
    location.x = OsmAnd::Utilities::get31TileNumberX(_location.longitude);
    location.y = OsmAnd::Utilities::get31TileNumberY(_location.latitude);

    _app.favoritesCollection->createFavoriteLocation(location, QString::fromNSString(_titleField.textValue));
    [_app saveFavoritesToPermamentStorage];

    [self.navigationController popViewControllerAnimated:YES];
}

@end
