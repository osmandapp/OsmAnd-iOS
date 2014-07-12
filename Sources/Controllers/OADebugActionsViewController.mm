//
//  OADebugActionsViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADebugActionsViewController.h"

#import "OATableViewCellWithSwitch.h"
#import "OAMapRendererView.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"

#define _(name) OADebugActionsViewController__##name
#define ctor _(ctor)
#define dtor _(dtor)

@interface OADebugActionsViewController () <UITableViewDelegate, UITableViewDataSource, OATableViewWithSwitchDelegate>

@end

@implementation OADebugActionsViewController
{
    OAMapRendererView* __weak _mapRendererView;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self ctor];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self ctor];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
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

    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    if ([mapVC isViewLoaded])
        _mapRendererView= (OAMapRendererView*)mapVC.view;
}

#define kRenderingSection 0
#define kRenderingSection_ForcedRendering 0

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case kRenderingSection:
            return 1;
        /*case kOnlineSourcesSection:
            return [_onlineMapSourcesIds count];*/

        default:
            return 0;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case kRenderingSection:
            return @"Rendering";
        /*case kOnlineSourcesSection:
            return OALocalizedString(@"Online maps");*/

        default:
            return nil;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const submenuCell = @"submenuCell";
    static NSString* const switchCell = @"switchCell";

    NSString* cellTypeId = nil;
    UIImage* icon = nil;
    NSString* caption = nil;
    BOOL boolValue = NO;
    switch (indexPath.section)
    {
        case kRenderingSection:
            switch(indexPath.row)
            {
                case kRenderingSection_ForcedRendering:
                    caption = @"Forced rendering";
                    cellTypeId = switchCell;
                    boolValue = _mapRendererView.forcedRenderingOnEachFrame;
                    break;
            }
            break;
    }

    // Obtain reusable cell or create one
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellTypeId];
    if (cell == nil)
    {
        if ([cellTypeId isEqualToString:switchCell])
            cell = [[OATableViewCellWithSwitch alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellTypeId];
        else
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellTypeId];
    }

    // Fill cell content
    cell.imageView.image = icon;
    cell.textLabel.text = caption;
    if ([cellTypeId isEqualToString:switchCell])
    {
        OATableViewCellWithSwitch* switchCell = (OATableViewCellWithSwitch*)cell;
        [switchCell.switchView setOn:boolValue];
    }

    return cell;
}

#pragma mark - OATableViewWithSwitchDelegate

- (void)tableView:(UITableView *)tableView accessorySwitchChangedStateForRowWithIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case kRenderingSection:
            switch(indexPath.row)
            {
                case kRenderingSection_ForcedRendering:
                    {
                        OATableViewCellWithSwitch* cell = (OATableViewCellWithSwitch*)[tableView cellForRowAtIndexPath:indexPath];
                        _mapRendererView.forcedRenderingOnEachFrame = cell.switchView.on;
                    }
                    break;
            }
            break;
    }
}

#pragma mark - UITableViewDelegate

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*// Deselect any currently selected (if not the same)
    NSIndexPath* currentlySelected = [tableView indexPathForSelectedRow];
    if (currentlySelected != nil)
    {
        if ([currentlySelected isEqual:indexPath])
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
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        [self.navigationController popViewControllerAnimated:YES];*/
}

- (NSIndexPath*)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Disallow manual deselection of any map source
    return nil;
}

#pragma mark -

@end
