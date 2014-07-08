//
//  OAFavoritesLayerViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/8/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAFavoritesLayerViewController.h"

#import <QuickDialog.h>
#import <QEmptyListElement.h>

#import "OsmAndApp.h"
#import "OANativeUtilities.h"
#include "Localization.h"

#include <OsmAndCore/IFavoriteLocation.h>

@interface OAFavoritesLayerViewController ()
@end

#define _(name) OAFavoritesLayerViewController__##name
#define ctor _(ctor)
#define dtor _(dtor)

#define Group _(Group)
@interface Group : NSObject
@property NSString* name;
@end
@implementation Group
- (NSString*)description
{
    return _name;
}
@end

#define Favorite _(Favorite)
@interface Favorite : NSObject
@property NSString* name;
@property std::shared_ptr<const OsmAnd::IFavoriteLocation> favoriteLocation;
@end
@implementation Favorite
- (NSString*)description
{
    return _name;
}
@end

@implementation OAFavoritesLayerViewController
{
    OsmAndAppInstance _app;

    NSArray* _items;
}

- (instancetype)init
{
    OsmAndAppInstance app = [OsmAndApp instance];

    // Collect items
    NSMutableArray* groups = [NSMutableArray array];
    NSMutableArray* rawGroups = [OANativeUtilities QListOfStringsToNSMutableArray:app.favoritesCollection->getGroups().toList()];
    [rawGroups sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    for (NSString* groupName in rawGroups)
    {
        Group* group = [[Group alloc] init];
        group.name = groupName;

        [groups addObject:group];
    }
    NSMutableArray* favorites = [NSMutableArray array];
    for (const auto& favoriteLocation : app.favoritesCollection->getFavoriteLocations())
    {
        if (!favoriteLocation->getGroup().isEmpty())
            continue;

        Favorite* favorite = [[Favorite alloc] init];
        favorite.name = favoriteLocation->getTitle().toNSString();
        favorite.favoriteLocation = favoriteLocation;

        [favorites addObject:favorite];
    }
    [favorites sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Favorite* favorite1 = (Favorite*)obj1;
        Favorite* favorite2 = (Favorite*)obj2;

        return [favorite1.name localizedCaseInsensitiveCompare:favorite2.name];
    }];

    QRootElement* rootElement = [[QRootElement alloc] init];

    rootElement.title = OALocalizedString(@"Favorites");
    rootElement.grouped = YES;
    rootElement.appearance.entryAlignment = NSTextAlignmentRight;

    if ([groups count] == 0 && [favorites count] == 0)
    {
        QSection* mainSection = [[QSection alloc] init];
        [rootElement addSection:mainSection];

        QEmptyListElement* emptyListElement = [[QEmptyListElement alloc] init];
        emptyListElement.title = OALocalizedString(@"You have no favorites yet");

        [mainSection addElement:emptyListElement];
    }
    else
    {
        if ([groups count] != 0)
        {
            QSection* groupsSection = [[QSection alloc] init];
            groupsSection.title = OALocalizedString(@"Groups");
            [rootElement addSection:groupsSection];
        }

        if ([favorites count] != 0)
        {
            QSelectSection* favoritesSection = [[QSelectSection alloc] initWithItems:favorites selected:0];
            favoritesSection.title = OALocalizedString(@"Favorites");
            [rootElement addSection:favoritesSection];
        }
    }

    self = [super initWithRoot:rootElement];
    if (self) {
        _app = app;
    }
    return self;
}

@end
