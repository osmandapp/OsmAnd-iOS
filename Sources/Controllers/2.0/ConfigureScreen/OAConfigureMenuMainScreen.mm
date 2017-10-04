//
//  OAConfigureMenuMainScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAConfigureMenuMainScreen.h"
#import "OAConfigureMenuViewController.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAAppModeCell.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAMapWidgetRegInfo.h"
#import "OAMapWidgetRegistry.h"
#import "OARootViewController.h"
#import "OAUtilities.h"

@interface OAConfigureMenuMainScreen () <OAAppModeCellDelegate>

@end

@implementation OAConfigureMenuMainScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAMapWidgetRegistry *_mapWidgetRegistry;
    
    OAAppModeCell *_appModeCell;
}

@synthesize configureMenuScreen, tableData, vwController, tblView, title;

- (id) initWithTable:(UITableView *)tableView viewController:(OAConfigureMenuViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _mapWidgetRegistry = [OARootViewController instance].mapPanel.mapWidgetRegistry;
        
        title = OALocalizedString(@"layer_map_appearance");
        configureMenuScreen = EConfigureMenuScreenMain;
        
        vwController = viewController;
        tblView = tableView;
        [self initData];
    }
    return self;
}

- (void) initData
{
}

- (void) setupView
{
    NSMutableDictionary *sectionMapStyle = [NSMutableDictionary dictionary];
    [sectionMapStyle setObject:@"OAAppModeCell" forKey:@"type"];
    
    NSMutableArray *arr = [NSMutableArray array];
    
    NSDictionary *mapStyles = @{ @"groupName" : @"",
                                 @"cells" : @[sectionMapStyle]
                                 };
    [arr addObject:mapStyles];
    
    // Right panel
    NSMutableArray *controlsList = [NSMutableArray array];
    NSArray *controls = @[ @{ @"groupName" : OALocalizedString(@"map_widget_right"),
                              @"cells" : controlsList,
                              } ];
    
    [self addControls:controlsList widgets:[_mapWidgetRegistry getRightWidgetSet] mode:_settings.applicationMode];
    
    [arr addObjectsFromArray:controls];

    // Left panel
    controlsList = [NSMutableArray array];
    controls = @[ @{ @"groupName" : OALocalizedString(@"map_widget_left"),
                     @"cells" : controlsList,
                     } ];
    
    [self addControls:controlsList widgets:[_mapWidgetRegistry getLeftWidgetSet] mode:_settings.applicationMode];
    
    [arr addObjectsFromArray:controls];
    
    tableData = [NSArray arrayWithArray:arr];
}

- (void) addControls:(NSMutableArray *)controlsList widgets:(NSSet<OAMapWidgetRegInfo *> *)widgets mode:(OAApplicationMode *)mode
{
    for (OAMapWidgetRegInfo *r in widgets)
    {
        if (![mode isWidgetAvailable:r.key])
            continue;
        
        BOOL selected = [r visibleCollapsed:mode] || [r visible:mode];
        NSString *desc = OALocalizedString(@"shared_string_collapse");
        
        [controlsList addObject:@{ @"title" : [r getMessage],
                                   @"img" : [r getImageId],
                                   @"selected" : @(selected),
                                   @"color" : selected ? UIColorFromRGB(0xff8f00) : [NSNull null],
                                   @"secondaryImg" : r.widget ? @"ic_action_additional_option" : [NSNull null],
                                   @"description" : [r visibleCollapsed:mode] ? desc : [NSNull null],
                                   
                                   @"type" : @"OASettingSwitchCell"} ];

        /*
        ContextMenuItem.ItemBuilder itemBuilder = new ContextMenuItem.ItemBuilder()
        .setIcon(r.getDrawableMenu())
        .setSelected(selected)
        .setColor(selected ? R.color.osmand_orange : ContextMenuItem.INVALID_ID)
        .setSecondaryIcon(r.widget != null ? R.drawable.ic_action_additional_option : ContextMenuItem.INVALID_ID)
        .setDescription(r.visibleCollapsed(mode) ? desc : null)
        .setListener(new ContextMenuAdapter.OnRowItemClick() {
            @Override
            public boolean onRowItemClick(final ArrayAdapter<ContextMenuItem> adapter,
                                          final View view,
                                          final int itemId,
                                          final int pos) {
                if (r.widget == null) {
                    setVisibility(adapter, pos, !r.visible(mode), false);
                    return false;
                }
                View textWrapper = view.findViewById(R.id.text_wrapper);
                IconPopupMenu popup = new IconPopupMenu(view.getContext(), textWrapper);
                MenuInflater inflater = popup.getMenuInflater();
                final Menu menu = popup.getMenu();
                inflater.inflate(R.menu.widget_visibility_menu, menu);
                IconsCache ic = mapActivity.getMyApplication().getIconsCache();
                menu.findItem(R.id.action_show).setIcon(ic.getThemedIcon(R.drawable.ic_action_view));
                menu.findItem(R.id.action_hide).setIcon(ic.getThemedIcon(R.drawable.ic_action_hide));
                menu.findItem(R.id.action_collapse).setIcon(ic.getThemedIcon(R.drawable.ic_action_widget_collapse));
                
                final int[] menuIconIds = r.getDrawableMenuIds();
                final int[] menuTitleIds = r.getMessageIds();
                final int[] menuItemIds = r.getItemIds();
                int checkedId = r.getItemId();
                boolean selected = r.visibleCollapsed(mode) || r.visible(mode);
                if (menuIconIds != null && menuTitleIds != null && menuItemIds != null
                    && menuIconIds.length == menuTitleIds.length && menuIconIds.length == menuItemIds.length) {
                    for (int i = 0; i < menuIconIds.length; i++) {
                        int iconId = menuIconIds[i];
                        int titleId = menuTitleIds[i];
                        int id = menuItemIds[i];
                        MenuItem menuItem = menu.add(R.id.single_selection_group, id, i, titleId)
                        .setChecked(id == checkedId);
                        menuItem.setIcon(menuItem.isChecked() && selected
                                         ? ic.getIcon(iconId, R.color.osmand_orange) : ic.getThemedIcon(iconId));
                    }
                    menu.setGroupCheckable(R.id.single_selection_group, true, true);
                    menu.setGroupVisible(R.id.single_selection_group, true);
                }
                
                popup.setOnMenuItemClickListener(
                                                 new IconPopupMenu.OnMenuItemClickListener() {
                                                     @Override
                                                     public boolean onMenuItemClick(MenuItem menuItem) {
                                                         
                                                         switch (menuItem.getItemId()) {
                                                             case R.id.action_show:
                                                                 setVisibility(adapter, pos, true, false);
                                                                 return true;
                                                             case R.id.action_hide:
                                                                 setVisibility(adapter, pos, false, false);
                                                                 return true;
                                                             case R.id.action_collapse:
                                                                 setVisibility(adapter, pos, true, true);
                                                                 return true;
                                                             default:
                                                                 if (menuItemIds != null) {
                                                                     for (int menuItemId : menuItemIds) {
                                                                         if (menuItem.getItemId() == menuItemId) {
                                                                             r.changeState(menuItemId);
                                                                             MapInfoLayer mil = mapActivity.getMapLayers().getMapInfoLayer();
                                                                             if (mil != null) {
                                                                                 mil.recreateControls();
                                                                             }
                                                                             ContextMenuItem item = adapter.getItem(pos);
                                                                             item.setIcon(r.getDrawableMenu());
                                                                             if (r.getMessage() != null) {
                                                                                 item.setTitle(r.getMessage());
                                                                             } else {
                                                                                 item.setTitle(mapActivity.getResources().getString(r.getMessageId()));
                                                                             }
                                                                             adapter.notifyDataSetChanged();
                                                                             return true;
                                                                         }
                                                                     }
                                                                 }
                                                         }
                                                         return false;
                                                     }
                                                 });
                popup.show();
                return false;
            }
            
            @Override
            public boolean onContextMenuClick(ArrayAdapter<ContextMenuItem> a,
                                              int itemId, int pos, boolean isChecked) {
                setVisibility(a, pos, isChecked, false);
                return false;
            }
            
            private void setVisibility(ArrayAdapter<ContextMenuItem> adapter,
                                       int position,
                                       boolean visible,
                                       boolean collapsed) {
                MapWidgetRegistry.this.setVisibility(r, visible, collapsed);
                MapInfoLayer mil = mapActivity.getMapLayers().getMapInfoLayer();
                if (mil != null) {
                    mil.recreateControls();
                }
                ContextMenuItem item = adapter.getItem(position);
                item.setSelected(visible);
                item.setColorRes(visible ? R.color.osmand_orange : ContextMenuItem.INVALID_ID);
                item.setDescription(visible && collapsed ? desc : null);
                adapter.notifyDataSetChanged();
            }
        });
        if (r.getMessage() != null) {
            itemBuilder.setTitle(r.getMessage());
        } else {
            itemBuilder.setTitleId(r.getMessageId(), mapActivity);
        }
        contextMenuAdapter.addItem(itemBuilder.createItem());
         */
    }
}

#pragma mark - OAAppModeCellDelegate

- (void) appModeChanged:(OAApplicationMode *)mode
{
    [vwController waitForIdle];
    _settings.applicationMode = mode;
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [tableData count];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [((NSDictionary*)tableData[section]) objectForKey:@"groupName"];
}


- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [((NSArray*)[((NSDictionary*)tableData[section]) objectForKey:@"cells"]) count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* data = (NSDictionary*)[((NSArray*)[((NSDictionary*)tableData[indexPath.section]) objectForKey:@"cells"]) objectAtIndex:indexPath.row];
    if ([[data objectForKey:@"type"] isEqualToString:@"OAAppModeCell"])
    {
        return 44.0;
    }
    else if ([[data objectForKey:@"type"] isEqualToString:@"OASettingsCell"])
    {
        return [OASettingsTableViewCell getHeight:[data objectForKey:@"name"] value:[data objectForKey:@"value"] cellWidth:tableView.bounds.size.width];
    }
    else if ([[data objectForKey:@"type"] isEqualToString:@"OASwitchCell"])
    {
        return [OASwitchTableViewCell getHeight:[data objectForKey:@"name"] cellWidth:tableView.bounds.size.width];
    }
    else
    {
        return 44.0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* data = (NSDictionary*)[((NSArray*)[((NSDictionary*)tableData[indexPath.section]) objectForKey:@"cells"]) objectAtIndex:indexPath.row];
    
    UITableViewCell* outCell = nil;
    if ([[data objectForKey:@"type"] isEqualToString:@"OAAppModeCell"])
    {
        if (!_appModeCell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAAppModeCell" owner:self options:nil];
            _appModeCell = (OAAppModeCell *)[nib objectAtIndex:0];
            _appModeCell.showDefault = YES;
            _appModeCell.selectedMode = [OAAppSettings sharedManager].applicationMode;
            _appModeCell.delegate = self;
        }
        
        outCell = _appModeCell;
    }
    else if ([[data objectForKey:@"type"] isEqualToString:@"OASettingsCell"])
    {
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText:[data objectForKey:@"name"]];
            [cell.descriptionView setText:[data objectForKey:@"value"]];
        }
        outCell = cell;
    }
    else if ([[data objectForKey:@"type"] isEqualToString:@"OASwitchCell"])
    {
        static NSString* const identifierCell = @"OASwitchTableViewCell";
        OASwitchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText: [data objectForKey:@"name"]];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            
            //[cell.switchView setOn:_settings.mapSettingShowFavorites];
            //[cell.switchView addTarget:self action:@selector(showFavoriteChanged:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    
    return outCell;
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSDictionary* data = (NSDictionary*)[((NSArray*)[((NSDictionary*)tableData[section]) objectForKey:@"cells"]) objectAtIndex:0];
    if ([[data objectForKey:@"type"] isEqualToString:@"OAAppModeCell"])
        return 0.01;
    else
        return 34.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAConfigureMenuViewController *configureMenuViewController;
    /*
    NSInteger section = indexPath.section;
    if (mapStyleCellPresent)
        section--;
    
    switch (section)
    {
        case 0:
        {
            if (indexPath.row == 1) {
                mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenGpx];
            }
            
            break;
        }
            
        case 1: // Map Type
        {
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenMapType];
            
            break;
        }
            
        case 2: // Map Style
        {
            if (mapStyleCellPresent)
            {
                NSArray *categories = [styleSettings getAllCategories];
                NSArray *topLevelParams = [styleSettings getParameters:@""];
                
                if (indexPath.row == 0)
                {
                    mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenSetting param:settingAppModeKey];
                }
                else if (indexPath.row <= categories.count)
                {
                    mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenCategory param:categories[indexPath.row - 1]];
                }
                else
                {
                    OAMapStyleParameter *p = topLevelParams[indexPath.row - categories.count - 1];
                    if (p.dataType != OABoolean)
                    {
                        OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenParameter param:p.name];
                        
                        [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
                    }
                }
                break;
            }
        }
        case 3:
        {
            NSInteger index = 0;
            if ([[OAIAPHelper sharedInstance] productPurchased:kInAppId_Addon_Srtm])
                index++;
            
            if (indexPath.row == index)
                mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenOverlay];
            else if (indexPath.row == index + 1)
                mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenUnderlay];
            
            break;
        }
        case 4:
        {
            mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenLanguage];
            break;
        }
            
        default:
            break;
    }
    */
    
    if (configureMenuViewController)
        [configureMenuViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
