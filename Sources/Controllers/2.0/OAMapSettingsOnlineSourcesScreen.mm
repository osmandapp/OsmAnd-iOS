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
#import "OABottomSheetActionCell.h"

#include <QSet>

#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

#define kMaxDoneWidth 70

typedef enum
{
    EMapSettingOverlay = 0,
    EMapSettingUnderlay,
    
} EMapSettingType;

@implementation OAMapSettingsOnlineSourcesScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    UIButton *_btnDone;
    EMapSettingType _mapSettingType;

    QList<std::shared_ptr<const OsmAnd::OnlineTileSources::Source>> _onlineMapSources;
    QList<std::shared_ptr<const OsmAnd::OnlineTileSources::Source>> _selectedSources;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;


- (id) initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController param:(id)param
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
        
        vwController.okButton.hidden = false;
        [vwController.okButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
        CGSize btnSize = [OAUtilities calculateTextBounds:OALocalizedString(@"shared_string_done") width:kMaxDoneWidth font:vwController.okButton.titleLabel.font];
        [vwController.okButton setConstant:@"buttonWidth" constant:btnSize.width + 32.];
        
        if ([param isEqualToString:@"overlay"] || self.vwController.parentVC.screenType == EMapSettingsScreenOverlay)
            _mapSettingType = EMapSettingOverlay;
        else if ([param isEqualToString:@"underlay"] || self.vwController.parentVC.screenType == EMapSettingsScreenUnderlay)
            _mapSettingType = EMapSettingUnderlay;
        
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
        const auto& onlineSourcesCollection = _app.resourcesManager->downloadOnlineTileSources();
        if (onlineSourcesCollection != nullptr)
        {
            _onlineMapSources = _app.resourcesManager->downloadOnlineTileSources()->getCollection().values();
            std::sort(_onlineMapSources, [](
                                            const std::shared_ptr<const OsmAnd::OnlineTileSources::Source> s1,
                                            const std::shared_ptr<const OsmAnd::OnlineTileSources::Source> s2)
                                            {
                                                return s1->priority < s2->priority;
                                            });
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                tblView.allowsMultipleSelectionDuringEditing = YES;
                [tblView setEditing:YES];
                [tblView reloadData];
            });
        }
        else
        {
            NSLog(@"Failed to download online tile resources list.");
        }
    });
}

- (BOOL) okButtonPressed
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
    if (_selectedSources.size() == 1)
    {
        const auto& src = _selectedSources[0];
        OAMapSource *mapSource = [[OAMapSource alloc] initWithResource:@"online_tiles"
                                                    andVariant:src->name.toNSString() name:src->name.toNSString()];

        switch (self.vwController.parentVC.screenType) // Drop this switch and use _mapSettingType only
        {
            case EMapSettingsScreenMapType:
                _app.data.lastMapSource = mapSource;
                break;
            case EMapSettingsScreenOverlay:
                _app.data.overlayMapSource = mapSource;
                break;
            case EMapSettingsScreenUnderlay:
                _app.data.underlayMapSource = mapSource;
                break;
            case EMapSettingsScreenMain:
                if (_mapSettingType == EMapSettingOverlay)
                    _app.data.overlayMapSource = mapSource;
                else
                    _app.data.underlayMapSource = mapSource;
                break;
        }
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
    const auto& item = _onlineMapSources[(int) indexPath.row];
    NSString* caption = item->name.toNSString();
    
    static NSString* const identifierCell = @"OABottomSheetActionCell";
    OABottomSheetActionCell* cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
        cell = (OABottomSheetActionCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        UIImage *img = nil;
        img = [UIImage imageNamed:@"ic_custom_map_style"];
        
        cell.textView.text = caption;
        cell.descView.hidden = YES;
        cell.iconView.image = img;
        cell.separatorInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    const auto& item = _onlineMapSources[(int) indexPath.row];
    return [OABottomSheetActionCell getHeight:item->name.toNSString() value:nil cellWidth:tableView.bounds.size.width];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    const auto& item = _onlineMapSources[(int) indexPath.row];
    _selectedSources.append(item);
}

@end
