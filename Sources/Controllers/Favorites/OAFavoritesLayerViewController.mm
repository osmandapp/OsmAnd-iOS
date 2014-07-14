//
//  OAFavoritesLayerViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/14/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAFavoritesLayerViewController.h"

#import <QuickDialog.h>
#import <QEmptyListElement.h>

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OARootViewController.h"
#import "OANativeUtilities.h"
#import "OADefaultFavorite.h"
#include "Localization.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>

#define _(name) OAFavoritesLayerViewController__##name

#define GroupItemData _(GroupItemData)
@interface GroupItemData : NSObject
@property NSString* groupName;
@property QList< std::shared_ptr<OsmAnd::IFavoriteLocation> > favorites;
@end
@implementation GroupItemData
@end

#define FavoriteItemData _(FavoriteItemData)
@interface FavoriteItemData : NSObject
@property std::shared_ptr<OsmAnd::IFavoriteLocation> favorite;
@end
@implementation FavoriteItemData
@end

@interface OAFavoritesLayerViewController ()
@end

@implementation OAFavoritesLayerViewController
{
    OsmAndAppInstance _app;

    OAAutoObserverProxy* _layersConfigurationObserver;
    UISwitch* _layerVisibilitySwitch;
    NSString* _groupName;
}

- (instancetype)init
{
    OsmAndAppInstance app = [OsmAndApp instance];

    const auto allFavorites = app.favoritesCollection->getFavoriteLocations();
    QHash< QString, QList< std::shared_ptr<OsmAnd::IFavoriteLocation> > > groupedFavorites;
    QList< std::shared_ptr<OsmAnd::IFavoriteLocation> > ungroupedFavorites;
    QSet<QString> groupNames;
    for(const auto& favorite : allFavorites)
    {
        const auto& groupName = favorite->getGroup();
        if (groupName.isEmpty())
            ungroupedFavorites.push_back(favorite);
        else
        {
            groupNames.insert(groupName);
            groupedFavorites[groupName].push_back(favorite);
        }
    }

    QRootElement* rootElement = [[QRootElement alloc] init];
    rootElement.title = OALocalizedString(@"My favorites");
    rootElement.grouped = YES;
    rootElement.appearance.entryAlignment = NSTextAlignmentRight;

    if (!groupNames.isEmpty())
    {
        QSection* groupsSection = [[QSection alloc] initWithTitle:OALocalizedString(@"Groups")];
        [rootElement addSection:groupsSection];

        for (const auto& groupName : groupNames)
        {
            GroupItemData* itemData = [[GroupItemData alloc] init];
            itemData.groupName = groupName.toNSString();
            itemData.favorites = groupedFavorites[groupName];

            QLabelElement* groupElement = [[QLabelElement alloc] initWithTitle:itemData.groupName
                                                                         Value:nil];
            groupElement.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            groupElement.keepSelected = NO;
            groupElement.controllerAction = NSStringFromSelector(@selector(onViewGroup:));
            groupElement.object = itemData;
            [groupsSection addElement:groupElement];
        }

        // Sort by title
        [groupsSection.elements sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            QLabelElement* element1 = (QLabelElement*)obj1;
            QLabelElement* element2 = (QLabelElement*)obj2;

            return [element1.title localizedCaseInsensitiveCompare:element2.title];
        }];
    }

    if (!ungroupedFavorites.isEmpty())
    {
        QSection* ungroupedFavoritesSection = [[QSection alloc] initWithTitle:OALocalizedString(@"Favorites")];
        ungroupedFavoritesSection.canDeleteRows = YES;
        [rootElement addSection:ungroupedFavoritesSection];

        for (const auto& favorite : ungroupedFavorites)
        {
            FavoriteItemData* itemData = [[FavoriteItemData alloc] init];
            itemData.favorite = favorite;

            QLabelElement* favoriteElement = [[QLabelElement alloc] initWithTitle:favorite->getTitle().toNSString()
                                                                            Value:nil];
            favoriteElement.accessoryType = UITableViewCellAccessoryNone;
            favoriteElement.controllerAction = NSStringFromSelector(@selector(onGoToFavorite:));
            favoriteElement.object = itemData;
            [ungroupedFavoritesSection addElement:favoriteElement];
        }

        // Sort by title
        [ungroupedFavoritesSection.elements sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            QLabelElement* element1 = (QLabelElement*)obj1;
            QLabelElement* element2 = (QLabelElement*)obj2;

            return [element1.title localizedCaseInsensitiveCompare:element2.title];
        }];
    }

    if ([rootElement.sections count] == 0)
    {
        QSection* fakeSection = [[QSection alloc] init];
        [rootElement addSection:fakeSection];

        QEmptyListElement* emptyListElement = [[QEmptyListElement alloc] initWithTitle:OALocalizedString(@"You haven't saved any favorites yet")
                                                                                 Value:nil];
        [fakeSection addElement:emptyListElement];
    }

    self = [super initWithRoot:rootElement];
    if (self) {
        _app = app;

        _groupName = nil;

        _layersConfigurationObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                 withHandler:@selector(onLayersConfigurationChanged)
                                                                  andObserve:_app.data.mapLayersConfiguration.changeObservable];
    }
    return self;
}

- (instancetype)initWithGroupTitle:(NSString*)groupTitle andFavorites:(const QList< std::shared_ptr<OsmAnd::IFavoriteLocation> >&)favorites
{
    OsmAndAppInstance app = [OsmAndApp instance];

    QRootElement* rootElement = [[QRootElement alloc] init];
    rootElement.title = groupTitle;
    rootElement.grouped = YES;
    rootElement.appearance.entryAlignment = NSTextAlignmentRight;

    QSection* favoritesSection = [[QSection alloc] initWithTitle:OALocalizedString(@"Favorites")];
    favoritesSection.canDeleteRows = YES;
    [rootElement addSection:favoritesSection];

    for (const auto& favorite : favorites)
    {
        FavoriteItemData* itemData = [[FavoriteItemData alloc] init];
        itemData.favorite = favorite;

        QLabelElement* favoriteElement = [[QLabelElement alloc] initWithTitle:favorite->getTitle().toNSString()
                                                                        Value:nil];
        favoriteElement.accessoryType = UITableViewCellAccessoryNone;
        favoriteElement.controllerAction = NSStringFromSelector(@selector(onGoToFavorite:));
        favoriteElement.object = itemData;
        [favoritesSection addElement:favoriteElement];
    }

    // Sort by title
    [favoritesSection.elements sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        QLabelElement* element1 = (QLabelElement*)obj1;
        QLabelElement* element2 = (QLabelElement*)obj2;

        return [element1.title localizedCaseInsensitiveCompare:element2.title];
    }];

    self = [super initWithRoot:rootElement];
    if (self) {
        _app = app;

        _groupName = groupTitle;

        _layersConfigurationObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                 withHandler:@selector(onLayersConfigurationChanged)
                                                                  andObserve:_app.data.mapLayersConfiguration.changeObservable];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Create switch
    _layerVisibilitySwitch = [[UISwitch alloc] init];
    [_layerVisibilitySwitch addTarget:self
                               action:@selector(onToggleLayerVisibility:)
                     forControlEvents:UIControlEventValueChanged];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_layerVisibilitySwitch];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self onLayersConfigurationChanged];
}

- (void)onLayersConfigurationChanged
{
    [_layerVisibilitySwitch setOn:[_app.data.mapLayersConfiguration isLayerVisible:kFavoritesLayerId]
                         animated:NO];
}

- (void)onToggleLayerVisibility:(id)sender
{
    [_app.data.mapLayersConfiguration setLayer:kFavoritesLayerId
                                    Visibility:_layerVisibilitySwitch.on];
}

- (void)onViewGroup:(QElement*)sender
{
    if (self.quickDialogTableView.isEditing)
        return;

    GroupItemData* itemData = (GroupItemData*)sender.object;

    UIViewController* viewGroupVC = [[OAFavoritesLayerViewController alloc] initWithGroupTitle:itemData.groupName
                                                                                  andFavorites:itemData.favorites];
    [self.navigationController pushViewController:viewGroupVC
                                         animated:YES];
}

- (void)onGoToFavorite:(QElement*)sender
{
    OARootViewController* rootViewController = [OARootViewController instance];
    
    FavoriteItemData* itemData = (FavoriteItemData*)sender.object;

    // Close everything
    [rootViewController closeMenuAndPanelsAnimated:YES];

    // Ensure favorites layer is shown
    [_app.data.mapLayersConfiguration setLayer:kFavoritesLayerId
                                    Visibility:YES];

    // Go to favorite location
    [rootViewController.mapPanel.mapViewController goToPosition:[OANativeUtilities convertFromPointI:itemData.favorite->getPosition()]
                                                        andZoom:kDefaultFavoriteZoom
                                                       animated:YES];
}

@end
