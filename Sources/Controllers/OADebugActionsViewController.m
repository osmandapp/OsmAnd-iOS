//
//  OADebugActionsViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADebugActionsViewController.h"

@interface OADebugActionsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OADebugActionsViewController

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
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        /*case kOfflineSourcesSection:
            return [_offlineMapSourcesIds count];
        case kOnlineSourcesSection:
            return [_onlineMapSourcesIds count];*/

        default:
            return 0;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        /*case kOfflineSourcesSection:
            return OALocalizedString(@"Offline maps");
        case kOnlineSourcesSection:
            return OALocalizedString(@"Online maps");*/

        default:
            return nil;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*static NSString* const mapSourceItemCell = @"mapSourceItemCell";

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

    return cell;*/
}

#pragma mark - UITableViewDelegate

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*// Deselect any currently selected (if not the same)
    NSIndexPath* currentlySelected = [tableView indexPathForSelectedRow];
    if(currentlySelected != nil)
    {
        if([currentlySelected isEqual:indexPath])
            return indexPath;
        [tableView deselectRowAtIndexPath:currentlySelected animated:YES];
    }
*/
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*NSMutableArray* collection = (indexPath.section == kOfflineSourcesSection) ? _offlineMapSourcesIds : _onlineMapSourcesIds;
    NSUUID* newActiveMapSourceId = [collection objectAtIndex:indexPath.row];

    _app.data.activeMapSourceId = newActiveMapSourceId;

    // For iPhone/iPod, since this menu wasn't opened in popover, return
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        [self.navigationController popViewControllerAnimated:YES];*/
}

- (NSIndexPath*)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Disallow manual deselection of any map source
    return nil;
}

#pragma mark -

@end
