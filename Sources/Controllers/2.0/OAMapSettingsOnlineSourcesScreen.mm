//
//  OAMapSettingsOnlineSourcesScreen.m
//  OsmAnd
//
//  Created by Paul on 28/11/19.
//  Copyright (c) 2019 OsmAnd. All rights reserved.
//

#import "OAMapSettingsOnlineSourcesScreen.h"
#import "OAMapSettingsViewController.h"
#import "Localization.h"
#import "OASliderCell.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapCreatorHelper.h"

#include <QSet>

#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

#define kMaxDoneWidth 70

@implementation OAMapSettingsOnlineSourcesScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    UIButton *_btnDone;

    QList<std::shared_ptr<const OsmAnd::OnlineTileSources::Source>> _onlineMapSources;
    QList<std::shared_ptr<const OsmAnd::OnlineTileSources::Source>> _selectedSources;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;


- (id) initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        
        
        title = OALocalizedString(@"map_settings_install_maps");
        settingsScreen = EMapSettingsScreenOnlineSources;
        
        vwController = viewController;
        tblView = tableView;
        
        _btnDone = [UIButton buttonWithType:UIButtonTypeSystem];
        UIFont *font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
        CGRect f = vwController.navbarView.frame;
        CGSize btnSize = [OAUtilities calculateTextBounds:OALocalizedString(@"shared_string_done") width:kMaxDoneWidth font:font];
        _btnDone.frame = CGRectMake(f.size.width - 16. - btnSize.width, f.size.height / 2 - btnSize.height / 2 + OAUtilities.getStatusBarHeight / 2, btnSize.width, btnSize.height);
        _btnDone.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_btnDone setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
        [_btnDone setTintColor:UIColor.whiteColor];
        [_btnDone.titleLabel setFont:font];
        [_btnDone addTarget:self action:@selector(donePressed) forControlEvents:UIControlEventTouchUpInside];
        [vwController.navbarView addSubview:_btnDone];
        
        [self commonInit];
        [self initData];
    }
    return self;
}

- (void)dealloc
{
    [self deinit];
}

- (void)commonInit
{
}

- (void)deinit
{
}

-(void) initData
{
}

- (void)setupView
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        _onlineMapSources = _app.resourcesManager->downloadOnlineTileSources()->getCollection().values();
        std::sort(_onlineMapSources, [](
                                        const std::shared_ptr<const OsmAnd::OnlineTileSources::Source> s1,
                                        const std::shared_ptr<const OsmAnd::OnlineTileSources::Source> s2)
                                        {
                                            return s1->name.toLower() < s2->name.toLower();
                                        });
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [tblView reloadData];
        });
    });
}

- (void) donePressed
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (const auto& item : _selectedSources)
    {
        NSString *cachePath = [_app.cachePath stringByAppendingPathComponent:item->name.toNSString()];
        if ([fileManager fileExistsAtPath:cachePath])
        {
            _app.resourcesManager->uninstallTilesResource(item->name);
        }
        OsmAnd::OnlineTileSources::installTileSource(item, QString::fromNSString(_app.cachePath));
        _app.resourcesManager->installTilesResource(item);
    }
    [self.vwController.parentVC setupView];
    [self.vwController.parentVC.tableView reloadData];
    [self.vwController hide:NO animated:YES];
}


#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _onlineMapSources.count();
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString* const mapSourceItemCell = @"mapSourceItemCell";
    
    // Get content for cell and it's type id
    NSString* caption = nil;
    NSString* description = nil;
    
    const auto& item = _onlineMapSources[(int) indexPath.row];
    caption = item->name.toNSString();
    
    // Obtain reusable cell or create one
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:mapSourceItemCell];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:mapSourceItemCell];
    
    // Fill cell content
    cell.textLabel.text = caption;
    cell.detailTextLabel.text = description;
    
    if (_selectedSources.contains(item))
    {
        cell.accessoryView.hidden = NO;
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
    }
    else
    {
        cell.accessoryView.hidden = YES;
    }
    
    return cell;
    
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    return 0.0001;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0001;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    const auto& item = _onlineMapSources[(int) indexPath.row];
    _selectedSources.append(item);
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadData];
}

@end
