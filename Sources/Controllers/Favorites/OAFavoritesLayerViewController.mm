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

    OAAutoObserverProxy* _favoritesCollectionChangeObserver;
    OAAutoObserverProxy* _favoriteChangeObserver;
    OAAutoObserverProxy* _layersConfigurationObserver;

    BOOL _contentIsInvalidated;

    UISwitch* _layerVisibilitySwitch;

    NSString* _groupName;
}

- (instancetype)init
{
    self = [super initWithRoot:[OAFavoritesLayerViewController inflateRoot]];
    if (self) {
        _app = [OsmAndApp instance];

        _favoritesCollectionChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                       withHandler:@selector(onFavoritesCollectionChanged)
                                                                        andObserve:_app.favoritesCollectionChangedObservable];
        _favoriteChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                            withHandler:@selector(onFavoriteChanged)
                                                             andObserve:_app.favoriteChangedObservable];
        _layersConfigurationObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                 withHandler:@selector(onLayersConfigurationChanged)
                                                                  andObserve:_app.data.mapLayersConfiguration.changeObservable];
        _contentIsInvalidated = NO;
        _groupName = nil;
    }
    return self;
}

- (instancetype)initWithGroupTitle:(NSString*)groupTitle andFavorites:(const QList< std::shared_ptr<OsmAnd::IFavoriteLocation> >&)favorites
{
    self = [super initWithRoot:[OAFavoritesLayerViewController inflateGroup:groupTitle withFavorites:favorites]];
    if (self) {
        _app = [OsmAndApp instance];
        _favoritesCollectionChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                       withHandler:@selector(onFavoritesCollectionChanged)
                                                                        andObserve:_app.favoritesCollectionChangedObservable];
        _favoriteChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                            withHandler:@selector(onFavoriteChanged)
                                                             andObserve:_app.favoriteChangedObservable];
        _layersConfigurationObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                 withHandler:@selector(onLayersConfigurationChanged)
                                                                  andObserve:_app.data.mapLayersConfiguration.changeObservable];
        _contentIsInvalidated = NO;
        _groupName = groupTitle;
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

    [self updateLayerVisibilitySwitch];

    // If content was invalidated while view was in background, update it's content right now
    if (_contentIsInvalidated)
    {
        [self updateContent];

        _contentIsInvalidated = NO;
    }
}

- (void)updateContent
{
    if (_groupName == nil)
        [self setRoot:[OAFavoritesLayerViewController inflateRoot]];
    else
    {
        const auto allFavorites = _app.favoritesCollection->getFavoriteLocations();
        QList< std::shared_ptr<OsmAnd::IFavoriteLocation> > favorites;
        for(const auto& favorite : allFavorites)
        {
            const auto& groupName = favorite->getGroup();
            if (![_groupName isEqualToString:groupName.toNSString()])
                continue;

            favorites.push_back(favorite);
        }

        // In case this group no longer exist, go back
        if (favorites.isEmpty())
        {
            [self.navigationController popViewControllerAnimated:YES];
            return;
        }

        [self setRoot:[OAFavoritesLayerViewController inflateGroup:_groupName
                                                     withFavorites:favorites]];
    }
}

- (void)onFavoritesCollectionChanged
{
    if (!self.isViewLoaded || self.view.window == nil)
    {
        _contentIsInvalidated = YES;
        return;
    }

    [self updateContent];
}

- (void)onFavoriteChanged
{
    if (!self.isViewLoaded || self.view.window == nil)
    {
        _contentIsInvalidated = YES;
        return;
    }

    [self updateContent];
}

- (void)onLayersConfigurationChanged
{
    [self updateLayerVisibilitySwitch];
}

- (void)updateLayerVisibilitySwitch
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

+ (QRootElement*)inflateRoot
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

    return rootElement;
}

+ (QRootElement*)inflateGroup:(NSString*)groupTitle withFavorites:(const QList< std::shared_ptr<OsmAnd::IFavoriteLocation> >&)favorites
{
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
    
    return rootElement;
}

@end
