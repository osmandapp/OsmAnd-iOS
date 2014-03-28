//
//  OAMapSourcesListViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/28/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapSourcesListViewController.h"

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#include "Localization.h"

@interface OAMapSourcesListViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAMapSourcesListViewController
{
    OsmAndAppInstance _app;

    OAAutoObserverProxy* _activeMapSourceIdObserver;
    OAAutoObserverProxy* _mapSourcesCollectionObserver;

    NSMutableArray* _offlineMapSourcesIds;
    NSMutableArray* _onlineMapSourcesIds;
}

#define kOfflineSourcesSection 0
#define kOnlineSourcesSection 1

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self ctor];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self ctor];
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)ctor
{
    _app = [OsmAndApp instance];

    _activeMapSourceIdObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onActiveMapSourceIdChanged)
                                                            andObserve:_app.data.activeMapSourceIdChangeObservable];
    _mapSourcesCollectionObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                              withHandler:@selector(onMapSourcesCollectionChanged)
                                                               andObserve:_app.data.mapSources.collectionChangeObservable];

    _offlineMapSourcesIds = [[NSMutableArray alloc] init];
    _onlineMapSourcesIds = [[NSMutableArray alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Obtain initial map sources list
    [self obtainMapSourcesList];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Perform selection of proper preset
    [self selectActiveMapSource:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)obtainMapSourcesList
{
    [_offlineMapSourcesIds removeAllObjects];
    [_onlineMapSourcesIds removeAllObjects];

    [_app.data.mapSources enumerateMapSourcesUsingBlock:^(OAMapSource *mapSource, BOOL *stop) {
        if(mapSource.type == OAMapSourceTypeOffline)
            [_offlineMapSourcesIds addObject:mapSource.uniqueId];
        else //if(mapSource.type == OAMapSourceTypeOnline)
            [_onlineMapSourcesIds addObject:mapSource.uniqueId];
    }];
}

- (void)selectActiveMapSource:(BOOL)animated
{
    OAMapSource* activeMapSource = [_app.data.mapSources mapSourceWithId:_app.data.activeMapSourceId];
    NSUInteger activeMapSourceIndex;
    if(activeMapSource.type == OAMapSourceTypeOffline)
        activeMapSourceIndex = [_offlineMapSourcesIds indexOfObject:_app.data.activeMapSourceId];
    else //if(mapSource.type == OAMapSourceTypeOnline)
        activeMapSourceIndex = [_onlineMapSourcesIds indexOfObject:_app.data.activeMapSourceId];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:activeMapSourceIndex
                                                            inSection:kOfflineSourcesSection]
                                animated:animated
                          scrollPosition:UITableViewScrollPositionNone];
}

- (void)onActiveMapSourceIdChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow]
                                      animated:YES];
        [self selectActiveMapSource:YES];
    });
}

- (void)onMapSourcesCollectionChanged
{
    [self obtainMapSourcesList];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2 /* Offline section, Online section */;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case kOfflineSourcesSection:
            return [_offlineMapSourcesIds count];
        case kOnlineSourcesSection:
            return [_onlineMapSourcesIds count];

        default:
            return 0;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case kOfflineSourcesSection:
            return OALocalizedString(@"Offline maps");
        case kOnlineSourcesSection:
            return OALocalizedString(@"Online maps");

        default:
            return nil;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const mapSourceItemCell = @"mapSourceItemCell";

    // Get content for cell and it's type id
    NSMutableArray* collection = (indexPath.section == kOfflineSourcesSection) ? _offlineMapSourcesIds : _onlineMapSourcesIds;
    OAMapSource* mapSource = [_app.data.mapSources mapSourceWithId:[collection objectAtIndex:indexPath.row]];
    NSString* caption = mapSource.name;
    NSString* description = nil;

    // Obtain reusable cell or create one
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:mapSourceItemCell];
    if(cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:mapSourceItemCell];

    // Fill cell content
    cell.textLabel.text = caption;
    cell.detailTextLabel.text = description;

    return cell;
}

#pragma mark - UITableViewDelegate

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Everything is selectable
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //TODO: perform change of active map source
}

- (NSIndexPath*)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Disallow deselection completely
    return nil;
}

#pragma mark -

@end
