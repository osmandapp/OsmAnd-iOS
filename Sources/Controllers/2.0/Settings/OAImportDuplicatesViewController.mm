//
//  OAImportDuplicatesViewControllers.m
//  OsmAnd Maps
//
//  Created by nnngrach on 15.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAImportDuplicatesViewController.h"
#import "OAImportCompleteViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAResourcesUIHelper.h"
#import "OASettingsHelper.h"
#import "OASettingsImporter.h"
#import "OAApplicationMode.h"
#import "OAQuickActionRegistry.h"
#import "OAQuickActionType.h"
#import "OAQuickAction.h"
#import "OAMapSource.h"
#import "OASQLiteTileSource.h"
#import "OAPOIUIFilter.h"
#import "OAAvoidRoadInfo.h"
#import "OAProfileDataObject.h"
#import "OAMenuSimpleCell.h"
#import "OAMenuSimpleCellNoIcon.h"
#import "OATitleTwoIconsRoundCell.h"
#import "OAActivityViewWithTitleCell.h"

#define kMenuSimpleCell @"OAMenuSimpleCell"
#define kMenuSimpleCellNoIcon @"OAMenuSimpleCellNoIcon"
#define kTitleTwoIconsRoundCell @"OATitleTwoIconsRoundCell"
#define kCellTypeWithActivity @"OAActivityViewWithTitleCell"
#define RENDERERS_DIR @"rendering/"
#define ROUTING_PROFILES_DIR @"routing/"

@interface OAImportDuplicatesViewController () <UITableViewDelegate, UITableViewDataSource, OASettingsImportExportDelegate>

@end

@implementation OAImportDuplicatesViewController
{
    OsmAndAppInstance _app;
    NSArray<id> *_duplicatesList;
    NSArray<OASettingsItem *> * _settingsItems;
    NSString *_file;
    OASettingsHelper *_settingsHelper;
    
    NSString *_title;
    NSString *_description;
    
    NSMutableArray<NSMutableArray<NSDictionary *> *> *_data;
}

//- (instancetype) init
//{
//    self = [super init];
//    if (self)
//    {
//        [self commonInit];
//    }
//    return self;
//}

- (instancetype) initWithDuplicatesList:(NSArray<id> *)duplicatesList settingsItems:(NSArray<OASettingsItem *> *)settingsItems file:(NSString *)file
{
    self = [super init];
    if (self)
    {
        _duplicatesList = duplicatesList;
        _settingsItems = settingsItems;
        _file = file;
        [self commonInit];
    }
    return self;
}

//onCreate
- (void) commonInit
{
    _app = [OsmAndApp instance];
    _settingsHelper = [OASettingsHelper sharedInstance];
    
    [self generateFakeData]; //TODO: delete this
    
    OAImportAsyncTask *importTask = _settingsHelper.importTask;
    if (!importTask)
        _settingsItems = [importTask getSelectedItems];
    if (!_duplicatesList)
        _duplicatesList = [importTask getDuplicates];
    if (!_file)
        _file = [importTask getFile];
    
    importTask.delegate = self;
}

//onActivityCreated
- (void) viewDidLoad
{
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsSelection = NO;
    self.additionalNavBarButton.hidden = YES;
    [self setupBottomViewMultyLabelButtons];
    [super viewDidLoad];
    
    if (_duplicatesList)
        [self prepareData: [self prepareDuplicates:_duplicatesList]];
    if ([_settingsHelper.importTask getImportType] == EOAImportTypeImport)
        [self setupImportingUI];
    else
        _title = OALocalizedString(@"import_duplicates_title");
    _title = OALocalizedString(@"import_duplicates_title");
}

- (void) setupImportingUI
{
    _title = OALocalizedString(@"shared_string_importing");
    _description = [NSString stringWithFormat:OALocalizedString(@"importing_from"), _file];
    
    [self turnOnLoadingIndicator];
    self.bottomBarView.hidden = YES;
    [self.tableView reloadData];
}

- (void) turnOnLoadingIndicator
{
    _data = @[ @[ @{
        @"cellType": kCellTypeWithActivity,
        @"label": @"",
    }]];
}

- (void) generateFakeData
{
    //TODO: for now here is generating fake data, just for demo
    //old version
    
    _duplicatesList = [NSMutableArray new];
    //_data = [NSMutableArray new];
    
    /*
    NSArray<OAApplicationMode *> *profiles = [NSArray arrayWithObject:OAApplicationMode.CAR];
    
    NSArray<OAQuickActionType *> *allQuickActions = [[OAQuickActionRegistry sharedInstance] produceTypeActionsListWithHeaders];
    NSArray<OAQuickActionType *> *quickActions = [allQuickActions subarrayWithRange:NSMakeRange(3,2)];
    
    NSArray<OAResourceItem *> *mapSources = [OAResourcesUIHelper getSortedRasterMapSources:NO];
    NSArray<OAMapSource * > *renderStyles = @[_app.data.lastMapSource];
    
    NSArray<NSString * > *routingFiles = @[@"Desert.xml", @"moon.xml", @"pt.xml"];
     */
}



- (NSMutableArray<id> *) prepareDuplicates:(NSArray<id> *)duplicatesList
{
    NSMutableArray<id> *duplicates = [NSMutableArray new];
    NSMutableArray<OAApplicationModeBean *> *profiles = [NSMutableArray new];
    NSMutableArray<OAQuickAction *> *actions = [NSMutableArray new];
    NSMutableArray<OAPOIUIFilter *> *filters = [NSMutableArray new];
    NSMutableArray<OASQLiteTileSource *> *tileSources = [NSMutableArray new]; //ITileSource ???
    NSMutableArray<NSString *> *renderFilesList = [NSMutableArray new];
    NSMutableArray<NSString *> *routingFilesList = [NSMutableArray new];
    NSMutableArray<OAAvoidRoadInfo *> *avoidRoads = [NSMutableArray new];
    
    for (id object in duplicates)
    {
        if ([object isKindOfClass:OAApplicationModeBean.class])
            [profiles addObject: (OAApplicationModeBean *)object];
        else if ([object isKindOfClass:OAQuickAction.class])
            [actions addObject: (OAQuickAction *)object];
        if ([object isKindOfClass:OAPOIUIFilter.class])
            [filters addObject: (OAPOIUIFilter *)object];
        else if ([object isKindOfClass:OASQLiteTileSource.class])
            [tileSources addObject: (OASQLiteTileSource *)object];
        else if ([object isKindOfClass:NSString.class])
        {
            NSString *file = (NSString *)object;
            if ([file containsString:RENDERERS_DIR])
                [renderFilesList addObject: file];
            if ([file containsString:ROUTING_PROFILES_DIR])
                [routingFilesList addObject: file];
        }
        else if ([object isKindOfClass:OAAvoidRoadInfo.class])
            [avoidRoads addObject: (OAAvoidRoadInfo *)object];
    }
    if (profiles.count > 0)
    {
        [duplicates addObject:OALocalizedString(@"shared_string_profiles")];
        [duplicates addObjectsFromArray:profiles];
        
        //??? variant of separating cell list by sections.
        /*
        NSMutableArray *profilesToDisplay = [NSMutableArray new];
        [profilesToDisplay addObject:OALocalizedString(@"shared_string_profiles")];
        [profilesToDisplay addObjectsFromArray:profiles];
        [duplicates addObject:profilesToDisplay];
        */
    }
    if (actions.count > 0)
    {
        [duplicates addObject:OALocalizedString(@"shared_string_quick_actions")];
        [duplicates addObjectsFromArray:actions];
    }
    if (filters.count > 0)
    {
        [duplicates addObject:OALocalizedString(@"shared_string_poi_types")];
        [duplicates addObjectsFromArray:filters];
    }
    if (tileSources.count > 0)
    {
        [duplicates addObject:OALocalizedString(@"quick_action_map_source_title")];
        [duplicates addObjectsFromArray:tileSources];
    }
    if (routingFilesList.count > 0)
    {
        [duplicates addObject:OALocalizedString(@"shared_string_routing")];
        [duplicates addObjectsFromArray:routingFilesList];
    }
    if (renderFilesList.count > 0)
    {
        [duplicates addObject:OALocalizedString(@"shared_string_rendering_style")];
        [duplicates addObjectsFromArray:renderFilesList];
    }
    if (avoidRoads.count > 0)
    {
        [duplicates addObject:OALocalizedString(@"avoid_road")];
        [duplicates addObjectsFromArray:avoidRoads];
    }
    return duplicates;
    
    //------------------------
    //TODO: Check tableView correctly work and delete this old code
    /*
    if (_profiles.count > 0)
    {
        NSMutableArray<NSDictionary *> *profileItems = [NSMutableArray new];
        [profileItems addObject: @{
            @"cellType": kMenuSimpleCellNoIcon,
            @"label": OALocalizedString(@"shared_string_profiles"),
            @"description": [NSString stringWithFormat:OALocalizedString(@"listed_exist"), [OALocalizedString(@"shared_string_profiles") lowerCase]]
        }];
        for (OAApplicationMode *profile in _profiles)
        {
            [profileItems addObject: @{
                @"cellType": kMenuSimpleCell,
                @"label": profile.toHumanString,
                @"description": profile.getProfileDescription,
                @"icon": profile.getIcon,
                //@"iconColor": UIColorFromRGB(profile.getIconColor)
                @"iconColor": UIColorFromRGB(color_chart_orange)
            }];
        }
        [_data addObject:profileItems];
    }
    
    if (_quickActions.count > 0)
    {
        NSMutableArray<NSDictionary *> *quickActionsItems = [NSMutableArray new];
        [quickActionsItems addObject: @{
            @"cellType": kMenuSimpleCellNoIcon,
            @"label": OALocalizedString(@"shared_string_quick_actions"),
            @"description": [NSString stringWithFormat:OALocalizedString(@"listed_exist"), [OALocalizedString(@"shared_string_quick_actions") lowerCase]]
        }];
        for (OAQuickActionType *action in _quickActions)
        {
            [quickActionsItems addObject: @{
                @"cellType": kTitleTwoIconsRoundCell,
                @"label": action.name,
                @"icon": [UIImage imageNamed:action.iconName],
                @"iconColor": UIColorFromRGB(color_chart_orange)
            }];
        }
        [_data addObject:quickActionsItems];
    }
    
    if (_mapSources.count > 0)
    {
        NSMutableArray<NSDictionary *> *mapSourcesItems = [NSMutableArray new];
        [mapSourcesItems addObject: @{
            @"cellType": kMenuSimpleCellNoIcon,
            @"label": OALocalizedString(@"map_sources"),
            @"description": [NSString stringWithFormat:OALocalizedString(@"listed_exist"), [OALocalizedString(@"map_sources") lowerCase]]
        }];
        for (OAResourceItem *mapSource in _mapSources)
        {
            [mapSourcesItems addObject: @{
                @"cellType": kTitleTwoIconsRoundCell,
                @"label": ((OAOnlineTilesResourceItem *) mapSource).mapSource.name,
                @"icon": [UIImage imageNamed:@"ic_custom_map_style"],
                @"iconColor": UIColorFromRGB(color_chart_orange)
            }];
        }
        [_data addObject:mapSourcesItems];
    }
    
    if (_renderStyles.count > 0)
    {
        NSMutableArray<NSDictionary *> *mapSourcesItems = [NSMutableArray new];
        [mapSourcesItems addObject: @{
            @"cellType": kMenuSimpleCellNoIcon,
            @"label": OALocalizedString(@"shared_string_rendering_styles"),
            @"description": [NSString stringWithFormat:OALocalizedString(@"listed_exist"), [OALocalizedString(@"shared_string_rendering_styles") lowerCase]]
        }];
        for (OAMapSource *style in _renderStyles)
        {
            UIImage *icon;
            NSString *iconName = [NSString stringWithFormat:@"img_mapstyle_%@", [style.resourceId stringByReplacingOccurrencesOfString:@".render.xml" withString:@""]];
            if (iconName)
                icon = [UIImage imageNamed:iconName];
            
            [mapSourcesItems addObject: @{
                @"cellType": kTitleTwoIconsRoundCell,
                @"label": style.name,
                @"icon": icon
            }];
        }
        [_data addObject:mapSourcesItems];
    }
    
    if (_routingFiles.count > 0)
    {
        NSMutableArray<NSDictionary *> *routingItems = [NSMutableArray new];
        [routingItems addObject: @{
            @"cellType": kMenuSimpleCellNoIcon,
            @"label": OALocalizedString(@"shared_string_routing"),
            @"description": [NSString stringWithFormat:OALocalizedString(@"listed_exist"), [OALocalizedString(@"shared_string_routing") lowerCase]]
        }];
        for (NSString *routingFileName in _routingFiles)
        {
            [routingItems addObject: @{
                @"cellType": kTitleTwoIconsRoundCell,
                @"label": routingFileName,
                @"icon": [UIImage imageNamed:@"ic_custom_navigation"],
                @"iconColor": UIColorFromRGB(color_tint_gray)
            }];
        }
        [_data addObject:routingItems];
    }
     */
}


// from DuplicatesSettingsAdapter.java : onBindViewHolder()
- (void) prepareData:(NSArray<id> *)duplicates
{
    _data = [NSMutableArray new];
    for (id currentItem in duplicates)
    {
        NSMutableDictionary *item = [NSMutableDictionary new];
        if ([currentItem isKindOfClass:OAApplicationModeBean.class])
        {
            OAApplicationModeBean *modeBean = (OAApplicationModeBean *)currentItem;
            NSString *profileName = modeBean.userProfileName;
            if (!profileName || profileName.length == 0)
            {
                OAApplicationMode* appMode = [OAApplicationMode valueOfStringKey:modeBean.stringKey def:nil];
                profileName = appMode.name; //?
            }
            item[@"label"] = profileName;
            NSString *routingProfile = @"";
            NSString *routingProfileValue = modeBean.routingProfile;
            if (routingProfileValue && routingProfileValue.length > 0)
            {
                try
                {
                    routingProfile = [OARoutingProfileDataObject getLocalizedName: [OARoutingProfileDataObject getValueOf: [routingProfileValue upperCase]]];
                    routingProfile = [routingProfile capitalizedString];

                } catch (NSException *e)
                {
                    routingProfile = [routingProfileValue capitalizedString];
                    NSLog(@"Error trying to get routing resource for %@ \n %@ %@", routingProfileValue, e.name, e.reason);
                }
            }
            if (!routingProfile || routingProfile.length == 0)
            {
                item[@"label"] = @""; //TODO: hide cell label if text == "" ??
            }
            else
            {
                item[@"label"] = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), OALocalizedString(@"nav_type_hint"), routingProfile];
            }
            item[@"icon"] = [UIImage imageNamed:modeBean.iconName];
            item[@"iconColor"] = UIColorFromRGB(modeBean.iconColor);
        }
        else if ([currentItem isKindOfClass:OAQuickAction.class])
        {
            OAQuickAction *action = (OAQuickAction *)currentItem;
            item[@"label"] = [action getName];
            item[@"icon"] = [UIImage imageNamed:[action getIconResName]];
            item[@"description"] = @"";
        }
        else if ([currentItem isKindOfClass:OAPOIUIFilter.class])
        {
            OAPOIUIFilter *filter = (OAPOIUIFilter *)currentItem;
            item[@"label"] = [filter getName];
            NSString *iconRes = [filter getIconId];
            item[@"icon"] = [UIImage imageNamed: (![iconRes isEqualToString:@"0"] ? iconRes : @"ic_action_user")]; // ?
            item[@"description"] = @"";
        }
        else if ([currentItem isKindOfClass:OASQLiteTileSource.class]) //ITileSource ???
        {
            item[@"label"] = ((OASQLiteTileSource *)currentItem).name;
            item[@"icon"] = [UIImage imageNamed:@"ic_map"];
            item[@"description"] = @"";
        }
        else if ([currentItem isKindOfClass:NSString.class])
        {
            NSString *file = (NSString *)currentItem;
            item[@"label"] = [[file lastPathComponent] stringByDeletingPathExtension];
            if ([file containsString:RENDERERS_DIR])
            {
                item[@"icon"] = [UIImage imageNamed:@"ic_action_map_style"];
            }
            else if ([file containsString:ROUTING_PROFILES_DIR])
            {
                item[@"icon"] = [UIImage imageNamed:@"ic_action_route_distance"];
            }
            item[@"description"] = @"";
        }
        else if ([currentItem isKindOfClass:OAAvoidRoadInfo.class])
        {
            item[@"label"] = ((OAAvoidRoadInfo *)currentItem).name;
            item[@"icon"] = [UIImage imageNamed:@"ic_action_alert"];
            item[@"description"] = @"";
        }
        [data addObject:item];
        //itemHolder.divider.setVisibility(shouldShowDivider(position) ? View.VISIBLE : View.GONE);
    }
}




- (void) applyLocalization
{
    [self.backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (NSString *) getTableHeaderTitle
{
    return OALocalizedString(@"import_duplicates_title");
}



- (void) setupBottomViewMultyLabelButtons
{
    self.primaryBottomButton.hidden = NO;
    self.secondaryBottomButton.hidden = NO;
    
    [self setToButton: self.secondaryBottomButton firstLabelText:OALocalizedString(@"keep_both") firstLabelFont:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold] firstLabelColor:UIColorFromRGB(color_primary_purple) secondLabelText:OALocalizedString(@"keep_both_desc") secondLabelFont:[UIFont systemFontOfSize:13] secondLabelColor:UIColorFromRGB(color_icon_inactive)];
    
    [self setToButton: self.primaryBottomButton firstLabelText:OALocalizedString(@"replace_all") firstLabelFont:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold] firstLabelColor:[UIColor whiteColor] secondLabelText:OALocalizedString(@"replace_all_desc") secondLabelFont:[UIFont systemFontOfSize:13] secondLabelColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5]];
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [self generateHeaderForTableView:tableView withFirstSessionText:OALocalizedString(@"import_duplicates_description") forSection:section];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self generateHeightForHeaderWithFirstHeaderText:OALocalizedString(@"import_duplicates_description") inSection:section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *type = item[@"cellType"];

    if ([type isEqualToString:kMenuSimpleCellNoIcon])
    {
        static NSString* const identifierCell = kMenuSimpleCellNoIcon;
        OAMenuSimpleCellNoIcon* cell;
        cell = (OAMenuSimpleCellNoIcon *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kMenuSimpleCellNoIcon owner:self options:nil];
            cell = (OAMenuSimpleCellNoIcon *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 20.0, 0.0, 0.0);
        }
        cell.descriptionView.hidden = NO;
        cell.textView.text = item[@"label"];
        cell.descriptionView.text = item[@"description"];
        return cell;
    }
    else if ([type isEqualToString:kMenuSimpleCell])
    {
        static NSString* const identifierCell = kMenuSimpleCell;
        OAMenuSimpleCell* cell;
        cell = (OAMenuSimpleCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kMenuSimpleCell owner:self options:nil];
            cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 62., 0.0, 0.0);
        }
        cell.textView.text = item[@"label"];
        cell.descriptionView.hidden = NO;
        cell.descriptionView.text = item[@"description"];

        cell.imgView.hidden = NO;
        if (item[@"icon"] && item[@"iconColor"])
        {
            cell.imgView.image = [item[@"icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imgView.tintColor = item[@"iconColor"];
        }
        else if (item[@"icon"])
        {
            cell.imgView.image = item[@"icon"];
        }
        return cell;
    }
    
    else if ([type isEqualToString:kTitleTwoIconsRoundCell])
    {
        static NSString* const identifierCell = kTitleTwoIconsRoundCell;
        OATitleTwoIconsRoundCell* cell;
        cell = (OATitleTwoIconsRoundCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kTitleTwoIconsRoundCell owner:self options:nil];
            cell = (OATitleTwoIconsRoundCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 62., 0.0, 0.0);
        }
        cell.rightIconView.hidden = YES;
        cell.leftIconView.hidden = NO;
        cell.titleView.text = item[@"label"];
        
        cell.leftIconView.hidden = NO;
        if (item[@"icon"] && item[@"iconColor"])
        {
            cell.leftIconView.image = [item[@"icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.leftIconView.tintColor = item[@"iconColor"];
        }
        else if (item[@"icon"])
        {
            cell.leftIconView.image = item[@"icon"];
        }
        return cell;
    }
    else if ([type isEqualToString:kTitleTwoIconsRoundCell])
    {
        static NSString* const identifierCell = kCellTypeWithActivity;
        OAActivityViewWithTitleCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAActivityViewWithTitleCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            //cell.titleView.text = OALocalizedString(@"checking_for_duplicates");
            
            BOOL inProgress = YES; // to change
            if (inProgress)
            {
                cell.activityIndicatorView.hidden = NO;
                [cell.activityIndicatorView startAnimating];
            }
            else
            {
                cell.activityIndicatorView.hidden = YES;
                [cell.activityIndicatorView startAnimating];
            }
        }
        return cell;
    }
    return nil;
}

- (void) importItems:(BOOL)shouldReplace
{
    if (_settingsItems && _file)
    {
        [self setupImportingUI];
        for (OASettingsItem *item in _settingsItems)
        {
            [item setShouldReplace:shouldReplace];
        }
        [_settingsHelper importSettings:_file items:_settingsItems latestChanges:@"" version:1 delegate:self];
    }
}

- (IBAction)primaryButtonPressed:(id)sender
{
    [self importItems: YES];
    
    //OAImportCompleteViewController* importComplete = [[OAImportCompleteViewController alloc] init];
    //[self.navigationController pushViewController:importComplete animated:YES];
}

- (IBAction)secondaryButtonPressed:(id)sender
{
    [self importItems: NO];
}

#pragma mark - OASettingsImportExportDelegate

- (void)onSettingsImportFinished:(BOOL)succeed items:(nonnull NSArray<OASettingsItem *> *)items {
    if (succeed)
    {
        //app.getRendererRegistry().updateExternalRenderers();
        //AppInitializer.loadRoutingFiles(app, null);
        
        OAImportCompleteViewController* importCompleteVC = [[OAImportCompleteViewController alloc] init];
        [self.navigationController pushViewController:importCompleteVC animated:YES];
    }
}

@end
