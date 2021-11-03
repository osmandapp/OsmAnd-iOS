//
//  OASelectMapSourceViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 26.05.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASelectMapSourceViewController.h"
#import "OAMapSource.h"
#import "OsmAndApp.h"
#import "OAMenuSimpleCell.h"
#import "OAMapCreatorHelper.h"
#import "OASQLiteTileSource.h"
#import "OAResourcesUIHelper.h"

#include "Localization.h"
#include "OASizes.h"
#include <QSet>

#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

@interface OASelectMapSourceViewController() <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation OASelectMapSourceViewController
{
    OsmAndAppInstance _app;
    NSArray *_onlineMapSources;
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleView.text = OALocalizedString(@"select_online_source");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _app = [OsmAndApp instance];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0, 0., 0.);
    self.tableView.contentInset = UIEdgeInsetsMake(10., 0., 0., 0.);
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    [self setupView];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (UIView *) getTopView
{
    return _navBarView;
}

- (UIView *) getMiddleView
{
    return _tableView;
}

- (CGFloat) getNavBarHeight
{
    return defaultNavBarHeight;
}

- (void) adjustViews
{
    CGRect buttonFrame = _cancelButton.frame;
    CGRect titleFrame = _titleView.frame;
    CGFloat statusBarHeight = [OAUtilities getStatusBarHeight];
    buttonFrame.origin.y = statusBarHeight;
    titleFrame.origin.y = statusBarHeight;
    _cancelButton.frame = buttonFrame;
    _titleView.frame = titleFrame;
}

- (void) setupView
{
    _onlineMapSources = [OAResourcesUIHelper getSortedRasterMapSources:NO];
}

- (IBAction) onCancelButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return OALocalizedString(@"online_sources");
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _onlineMapSources.count;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSString* caption = nil;
    OAResourceItem *item = _onlineMapSources[indexPath.row];
    OAMapSource *itemMapSource = nil;
    if ([item isKindOfClass:OASqliteDbResourceItem.class])
    {
        itemMapSource = ((OASqliteDbResourceItem *) item).mapSource;
        caption = itemMapSource.name;
    }
    else if ([item isKindOfClass:OAOnlineTilesResourceItem.class])
    {
        itemMapSource = ((OAOnlineTilesResourceItem *) item).mapSource;
        caption = itemMapSource.name;
    }
    OAMenuSimpleCell* cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCell getCellIdentifier] owner:self options:nil];
        cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
        cell.descriptionView.hidden = YES;
        cell.separatorInset = UIEdgeInsetsMake(0.0, 61.0, 0.0, 0.0);
    }
    if (cell)
    {
        UIImage *img = nil;
        img = [UIImage imageNamed:@"ic_custom_map_online"];
        cell.textView.text = caption;
        cell.imgView.image = img;
        if ([_app.data.lastMapSource isEqual:itemMapSource])
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_checkmark_default.png"]];
        else
            cell.accessoryView = nil;
    }
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAResourceItem* item = [_onlineMapSources objectAtIndex:indexPath.row];
    OAMapSource *itemMapSource = nil;
    if ([item isKindOfClass:OASqliteDbResourceItem.class])
        itemMapSource = ((OASqliteDbResourceItem *) item).mapSource;
    else if ([item isKindOfClass:OAOnlineTilesResourceItem.class])
        itemMapSource = ((OAOnlineTilesResourceItem *) item).mapSource;
    
    _app.data.lastMapSource = itemMapSource;
    if (self.delegate)
        [self.delegate onNewSourceSelected];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

