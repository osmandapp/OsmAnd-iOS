//
//  OAExportItemsSelectionViewController.m
//  OsmAnd
//
//  Created by Paul on 31.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAExportItemsSelectionViewController.h"
#import "OAExportSettingsType.h"
#import "OASimpleTableViewCell.h"
#import "OAApplicationMode.h"
#import "OARightIconTableViewCell.h"
#import "Localization.h"
#import "OAProfileDataObject.h"
#import "OARoutingDataObject.h"
#import "OAQuickAction.h"
#import "OAPOIUIFilter.h"
#import "OATileSource.h"
#import "OAFileSettingsItem.h"
#import "OAColors.h"
#import "OAIndexConstants.h"
#import "OAFileNameTranslationHelper.h"
#import "OAGpxAppearanceInfo.h"
#import "OAGpxSettingsItem.h"
#import "OAAvoidRoadInfo.h"
#import "OASettingsImporter.h"
#import "OASettingsHelper.h"
#import "OsmAndApp.h"
#import "OAOsmNotePoint.h"
#import "OAOpenStreetMapPoint.h"
#import "OAOsmEditingPlugin.h"
#import "OAFavoritesHelper.h"
#import "OAGlobalSettingsItem.h"
#import "OADestination.h"
#import "OAPOIHelper.h"
#import "OATableViewCustomHeaderView.h"
#import "OAOsmAndFormatter.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#include <OsmAndCore/ArchiveReader.h>

#define titleWithDescrCellHeight 60.0

@interface OAExportItemsSelectionViewController () <UITableViewDelegate, UITableViewDataSource, OATableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@end

@implementation OAExportItemsSelectionViewController
{
    NSArray *_items;
    NSMutableArray *_selectedItems;
    NSArray<NSDictionary *> *_data;
    OAExportSettingsType *_type;
    
    QList<OsmAnd::ArchiveReader::Item> _archiveItems;
}

- (instancetype) initWithItems:(NSArray *)items type:(OAExportSettingsType *)type selectedItems:(NSArray *)selectedItems
{
    self = [super init];
    if (self)
    {
        _items = items;
        _selectedItems = selectedItems ? [NSMutableArray arrayWithArray:selectedItems] : [NSMutableArray new];
        _type = type;
        
        OASettingsHelper *settingsHelper = OASettingsHelper.sharedInstance;
        if (settingsHelper.importTask)
            _archiveItems = OsmAnd::ArchiveReader(QString::fromNSString(settingsHelper.importTask.getFile)).getItems();
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = _type.title;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    [self.tableView setEditing:YES];
    self.tableView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];

    self.cancelButton.layer.cornerRadius = 9.0;
    self.saveButton.layer.cornerRadius = 9.0;
    
    self.cancelButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
    self.saveButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = titleWithDescrCellHeight;

    [self generateData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = self.tableView.backgroundColor;
    appearance.shadowColor = [UIColor colorNamed:ACColorNameCustomSeparator];
    appearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorPrimary]
    };
    UINavigationBarAppearance *blurAppearance = [[UINavigationBarAppearance alloc] init];

    self.navigationController.navigationBar.standardAppearance = blurAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationController.navigationBar.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    self.navigationController.navigationBar.prefersLargeTitles = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    for (id item in _selectedItems)
    {
        NSInteger index = [_items indexOfObject:item];
        if (index != NSNotFound)
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index + 1 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.saveButton setTitle:OALocalizedString(@"shared_string_apply") forState:UIControlStateNormal];
}

- (void)generateData
{
    NSMutableArray<NSDictionary *> *data = [NSMutableArray new];
    [data addObject:@{
        @"key" : @"selectDeselectAll",
        @"type" : [OASimpleTableViewCell getCellIdentifier]
    }];
    
    for (id obj in _items)
    {
        [data addObject:[self setupCellDataFromObject:obj]];
    }
    _data = data;
}

- (NSDictionary *)setupCellDataFromObject:(id)object
{
    if (!object)
        return nil;
    
    NSMutableDictionary *item = [NSMutableDictionary new];
    item[@"type"] = [OARightIconTableViewCell getCellIdentifier];
    item[@"object"] = object;
    if ([object isKindOfClass:OAApplicationModeBean.class])
    {
        OAApplicationModeBean *modeBean = (OAApplicationModeBean *) object;
        NSString *profileName = modeBean.userProfileName;
        if (profileName.length == 0)
        {
            OAApplicationMode *appMode = [OAApplicationMode valueOfStringKey:modeBean.stringKey def:nil];
            if (appMode)
                profileName = appMode.toHumanString;
            else
                profileName = modeBean.stringKey.capitalizedString;
        }
        item[@"title"] = profileName;
        
        NSString *routingProfile = @"";
        NSString *routingProfileValue = modeBean.routingProfile;
        if (routingProfileValue.length > 0)
        {
            routingProfile = [OARoutingDataObject getLocalizedName:[OARoutingDataObject getValueOf:[routingProfileValue upperCase]]];
            routingProfile = routingProfile.length > 0 ? [routingProfile capitalizedString] : routingProfileValue.capitalizedString;
        }
        if (routingProfile.length > 0)
            item[@"descr"] = [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"nav_type_hint"), routingProfile];
        else
            item[@"descr"] = OALocalizedString(@"profile_type_osmand_string");
        
        UIImage *profileIcon = [UIImage templateImageNamed:modeBean.iconName];
        if (profileIcon)
            item[@"icon"] = profileIcon;
        
        item[@"color"] = UIColorFromRGB(modeBean.iconColor);
    }
    else if ([object isKindOfClass:OAQuickAction.class])
    {
        OAQuickAction *quickAction = object;
        item[@"title"] = quickAction.getName;
        UIImage *icon = [UIImage templateImageNamed:[quickAction getIconResName]];
        if (icon)
            item[@"icon"] = icon;
    }
    else if ([object isKindOfClass:OAPOIUIFilter.class])
    {
        OAPOIUIFilter *poiUIFilter = object;
        item[@"title"] = poiUIFilter.getName ? poiUIFilter.getName : @"";
        UIImage *poiIcon = [OAPOIHelper getCustomFilterIcon:poiUIFilter];
        item[@"icon"] = poiIcon;
    }
    else if ([object isKindOfClass:OATileSource.class])
    {
        OATileSource *tileSource = object;
        item[@"title"] = tileSource.name;
        item[@"icon"] = [UIImage templateImageNamed:@"ic_custom_map"];
    }
    else if ([object isKindOfClass:NSString.class])
    {
        [self setupItemFromFile:item filePath:object];
    }
    else if ([object isKindOfClass:OAGpxSettingsItem.class])
    {
        OAGpxSettingsItem *settingsItem = object;
        [self setupItemFromGpx:item filePath:settingsItem.filePath appearanceInfo:settingsItem.getAppearanceInfo];
    }
    else if ([object isKindOfClass:OAFileSettingsItem.class])
    {
        OAFileSettingsItem *settingsItem = object;
        [self setupItemFromFile:item filePath:settingsItem.filePath];
    }
    else if ([object isKindOfClass:OAAvoidRoadInfo.class])
    {
        OAAvoidRoadInfo *avoidRoadInfo = object;
        item[@"title"] = avoidRoadInfo.name ? avoidRoadInfo.name : @"";
        item[@"icon"] = [UIImage templateImageNamed:@"ic_custom_alert"];
    }
    else if ([object isKindOfClass:OAOsmNotePoint.class])
    {
        OAOsmNotePoint *osmNotePoint = object;
        item[@"title"] = osmNotePoint.getText;
        item[@"icon"] = [UIImage templateImageNamed:@"ic_action_add_osm_note"];
    }
    else if ([object isKindOfClass:OAOpenStreetMapPoint.class])
    {
        OAOpenStreetMapPoint *openstreetmapPoint = object;
        item[@"title"] = [OAOsmEditingPlugin getTitle:openstreetmapPoint];
        item[@"icon"] = [UIImage templateImageNamed:@"ic_action_create_poi"];
    }
    else if ([object isKindOfClass:OAFavoriteGroup.class])
    {
        OAFavoriteGroup *group = object;
        item[@"title"] = [OAFavoriteGroup getDisplayName:group.name];
        item[@"icon"] = [UIImage templateImageNamed:@"ic_custom_folder"];
        NSInteger points = group.points.count;
        NSString *itemsDescr = [NSString stringWithFormat:@"%@ %ld", OALocalizedString(@"points_count"), points];
        item[@"descr"] = itemsDescr;
    }
    else if ([object isKindOfClass:OAGlobalSettingsItem.class])
    {
        OAGlobalSettingsItem *globalSettingsItem = object;
        item[@"title"] = globalSettingsItem.getPublicName;
        item[@"icon"] = [UIImage templateImageNamed:@"ic_custom_settings"];
    }
    else if ([object isKindOfClass:OADestination.class])
    {
        OADestination *marker = object;
        item[@"title"] = marker.desc ? marker.desc : @"";
        item[@"icon"] = [UIImage templateImageNamed:@"ic_custom_marker"];
        item[@"color"] = marker.color;
    }
    else if ([object isKindOfClass:OAQuickActionButtonState.class])
    {
        OAQuickActionButtonState *quickActionButtonState = object;
        item[@"title"] = [quickActionButtonState getName];
        item[@"icon"] = [quickActionButtonState getIcon];
    }
//        if (ExportSettingsType.ACTIVE_MARKERS.name().equals(markersGroup.getId())) {
//            item.setTitle(getString(R.string.map_markers));
//            item.setIcon(uiUtilities.getIcon(R.drawable.ic_action_flag, getItemIconColor(object)));
//        } else if (ExportSettingsType.HISTORY_MARKERS.name().equals(markersGroup.getId())) {
//            item.setTitle(getString(R.string.markers_history));
//            item.setIcon(uiUtilities.getIcon(R.drawable.ic_action_history, getItemIconColor(object)));
//        }
//        int selectedMarkers = markersGroup.getMarkers().size();
//        String itemsDescr = getString(R.string.shared_string_items);
//        item.setDescription(getString(R.string.ltr_or_rtl_combine_via_colon, itemsDescr, selectedMarkers));
//    } else if (object instanceof HistoryEntry) {
//        HistoryEntry historyEntry = (HistoryEntry) object;
//        item.setTitle(historyEntry.getName().getName());
//        item.setIcon(uiUtilities.getIcon(R.drawable.ic_action_history, getItemIconColor(object)));
//    }
//    else if (object instanceof OnlineRoutingEngine) {
//        OnlineRoutingEngine onlineRoutingEngine = (OnlineRoutingEngine) object;
//        item.setTitle(onlineRoutingEngine.getName(app));
//        item.setIcon(uiUtilities.getIcon(R.drawable.ic_world_globe_dark, getItemIconColor(object)));
//    }
    return item;
}

- (NSString *) getFormattedSize:(NSString *)filePath
{
    NSString *formattedSize = @"";
    if (_archiveItems.size() > 0)
    {
        NSString *fileName = filePath.lastPathComponent;
        const auto fileNameStr = QString::fromNSString(fileName);
        for (const auto& item : constOf(_archiveItems))
        {
            if (item.name.endsWith(fileNameStr))
                formattedSize = [NSByteCountFormatter stringFromByteCount:item.size countStyle:NSByteCountFormatterCountStyleFile];
        }
    }
    
    if (formattedSize.length == 0)
    {
        NSFileManager *fileManager = NSFileManager.defaultManager;
        NSDictionary *attrs = [fileManager attributesOfItemAtPath:filePath error:nil];
        formattedSize = [NSByteCountFormatter stringFromByteCount:attrs.fileSize countStyle:NSByteCountFormatterCountStyleFile];
    }
    return formattedSize;
}

- (void)setupItemFromFile:(NSMutableDictionary *)item filePath:(NSString *)filePath
{
    EOASettingsItemFileSubtype fileSubtype = [OAFileSettingsItemFileSubtype getSubtypeByFileName:filePath.lastPathComponent];
    item[@"title"] = [filePath.lastPathComponent stringByDeletingPathExtension];
    item[@"icon"] = [UIImage templateImageNamed:[OAFileSettingsItemFileSubtype getIcon:fileSubtype]];
    if ([filePath.lowercaseString hasSuffix:GPX_FILE_EXT])
    {
        [self setupItemFromGpx:item filePath:filePath appearanceInfo:nil];
    }
    else if ([OAFileSettingsItemFileSubtype isMap:fileSubtype])
    {
        BOOL fileExists = [NSFileManager.defaultManager fileExistsAtPath:filePath];
        NSString *fileName = filePath.lastPathComponent;
        NSString *formattedSize = [self getFormattedSize:filePath];
        item[@"title"] = [OAFileNameTranslationHelper getMapName:[fileName stringByDeletingPathExtension]];
        NSString *mapDescr = [self getMapDescription:filePath];
        
        if (!fileExists && mapDescr)
            item[@"descr"] = mapDescr;
        else if (mapDescr.length > 0)
            item[@"descr"] = [NSString stringWithFormat:@"%@ • %@", mapDescr, formattedSize];
        else if (fileExists)
            item[@"descr"] = formattedSize;
    }
}

- (void)setupItemFromGpx:(NSMutableDictionary *)item filePath:(NSString *)filePath appearanceInfo:(OAGpxAppearanceInfo *)appearanceInfo
{
    item[@"title"] = [filePath.lastPathComponent.stringByDeletingPathExtension stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    item[@"descr"] = [self getTrackDescr:filePath appearanceInfo:appearanceInfo];
    item[@"icon"] = [UIImage templateImageNamed:@"ic_custom_trip"];
}

- (NSString *) getTrackDescr:(NSString *)filePath appearanceInfo:(OAGpxAppearanceInfo *)appearanceInfo
{
    NSString *folder = @"";
    NSString *shortPath = [filePath stringByReplacingOccurrencesOfString:OsmAndApp.instance.gpxPath withString:@""];
    shortPath = [shortPath stringByDeletingLastPathComponent];
    if ([shortPath hasPrefix:@"/"])
        shortPath = [shortPath substringFromIndex:1];
    folder = shortPath.length == 0 ? OALocalizedString(@"shared_string_gpx_tracks") : shortPath;

    NSArray<NSString *> *components = [shortPath pathComponents];
    if (components.count == 1)
    {
        folder = [OAUtilities capitalizeFirstLetter:components[0]];
    }
    else
    {
        for (NSString *component in components)
        {
            folder = [folder stringByAppendingPathComponent:[OAUtilities capitalizeFirstLetter:component]];
        }
    }
    
//    if (exportMode) {
//        GpxDataItem dataItem = getDataItem(file, gpxDataItemCallback);
//        if (dataItem != null) {
//            return getTrackDescrForDataItem(dataItem);
//        }
//    } else
    if (appearanceInfo)
    {
        NSString *dist = [OAOsmAndFormatter getFormattedDistance:appearanceInfo.totalDistance];
        NSString *points = [NSString stringWithFormat:@"%ld %@", appearanceInfo.wptPoints, OALocalizedString(@"shared_string_gpx_points").lowerCase];
        NSString *descr = [NSString stringWithFormat:@"%@ • %@", folder, dist];
        return [NSString stringWithFormat:@"%@, %@", descr, points];
    }
    else
    {
        NSDictionary *fileAttributes = [NSFileManager.defaultManager attributesOfItemAtPath:filePath error:nil];
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        formater.dateStyle = NSDateFormatterShortStyle;
        formater.timeStyle = NSDateFormatterMediumStyle;
        NSString *date = [formater stringFromDate:fileAttributes.fileModificationDate];
        NSString *formattedSize = [NSByteCountFormatter stringFromByteCount:fileAttributes.fileSize countStyle:NSByteCountFormatterCountStyleFile];
        NSString *descr = [NSString stringWithFormat:@"%@ • %@", folder, date];
        return [NSString stringWithFormat:@"%@, %@", descr, formattedSize];
    }
    return @"";
}

- (NSString *)getMapDescription:(NSString *)filePath
{
    BOOL isDir = NO;
    [NSFileManager.defaultManager fileExistsAtPath:filePath isDirectory:&isDir];
    if (isDir /*|| file.getName().endsWith(IndexConstants.BINARY_WIKIVOYAGE_MAP_INDEX_EXT)*/)
        return OALocalizedString(@"online_map");
    if ([filePath hasSuffix:BINARY_ROAD_MAP_INDEX_EXT])
        return OALocalizedString(@"roads");
    else if ([filePath hasSuffix:BINARY_WIKI_MAP_INDEX_EXT])
        return OALocalizedString(@"download_wikipedia_maps");
    else if ([filePath hasSuffix:BINARY_SRTM_MAP_INDEX_EXT])
        return OALocalizedString(@"srtm_plugin_name");
    else if ([filePath hasSuffix:BINARY_MAP_INDEX_EXT])
        return OALocalizedString(@"download_regular_maps");
    return @"";
}

- (NSString *)getTitleForSection
{
    return [[NSString stringWithFormat:OALocalizedString(@"selected_of"), (int)_selectedItems.count, (int)_items.count] upperCase];
}

- (void)selectDeselectItem:(NSIndexPath *)indexPath
{
    if (indexPath.row < 1)
        return;
    [UIView setAnimationsEnabled:NO];
    [self.tableView beginUpdates];
    id item = _items[indexPath.row - 1];
    if ([_selectedItems containsObject:item])
        [_selectedItems removeObject:item];
    else
        [_selectedItems addObject:item];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:indexPath.section], indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
    [UIView setAnimationsEnabled:YES];

    OATableViewCustomHeaderView *headerView = (OATableViewCustomHeaderView *) [self.tableView headerViewForSection:0];
    headerView.label.text = [self getTitleForSection];
}

- (IBAction)onCancelPressed:(id)sender
{
    [self dismissViewController];
}

- (IBAction)onSavePressed:(id)sender
{
    if (self.delegate)
        [self.delegate onItemsSelected:_selectedItems type:_type];
    [self dismissViewController];
}

// MARK: UITableViewDataSource

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0)
    {
        NSDictionary *item = _data[indexPath.row];
        BOOL selected = [_selectedItems containsObject:item[@"object"]];
        [cell setSelected:selected animated:NO];
        if (selected)
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        else
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        OATableViewCustomHeaderView *customHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
        [customHeader setYOffset:32];
        customHeader.label.text = [self getTitleForSection];
        return customHeader;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        NSString *title = [self getTitleForSection];
        return [OATableViewCustomHeaderView getHeight:title width:tableView.bounds.size.width] + 18;
    }
    return UITableViewAutomaticDimension;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            [cell leftEditButtonVisibility:YES];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];

            UIButtonConfiguration *conf = [UIButtonConfiguration plainButtonConfiguration];
            conf.contentInsets = NSDirectionalEdgeInsetsMake(0., -6.5, 0., 0.);
            cell.leftEditButton.configuration = conf;
            cell.leftEditButton.layer.shadowColor = [UIColor colorNamed:ACColorNameIconColorDefault].CGColor;
            cell.leftEditButton.layer.shadowOffset = CGSizeMake(0., 0.);
            cell.leftEditButton.layer.shadowOpacity = 1.;
            cell.leftEditButton.layer.shadowRadius = 1.;
        }
        if (cell)
        {
            NSUInteger selectedAmount = _selectedItems.count;
            cell.titleLabel.text = selectedAmount > 0 ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"shared_string_select_all");

            UIImage *selectionImage = nil;
            if (selectedAmount > 0)
                selectionImage = [UIImage imageNamed:selectedAmount < _items.count ? @"ic_system_checkbox_indeterminate" : @"ic_system_checkbox_selected"];
            else
                selectionImage = [UIImage imageNamed:@"ic_custom_checkbox_unselected"];
            [cell.leftEditButton setImage:selectionImage forState:UIControlStateNormal];
            [cell.leftEditButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.leftEditButton addTarget:self action:@selector(selectDeselectGroup:) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *)[nib objectAtIndex:0];
            [cell rightIconVisibility:NO];
            cell.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [[UIColor colorNamed:ACColorNameIconColorActive] colorWithAlphaComponent:.05];
            [cell setSelectedBackgroundView:bgColorView];
        }
        if (cell)
        {
            cell.leftIconView.image = item[@"icon"];
            cell.titleLabel.text = item[@"title"];
            BOOL selected = [_selectedItems containsObject:item[@"object"]];
            UIColor *selectedColor = item[@"color"];
            selectedColor = selectedColor ? selectedColor : [UIColor colorNamed:ACColorNameIconColorActive];
            cell.leftIconView.tintColor = selected ? selectedColor : [UIColor colorNamed:ACColorNameIconColorDisabled];
            cell.descriptionLabel.text = item[@"descr"];
            [cell descriptionVisibility:cell.descriptionLabel.text || cell.descriptionLabel.text.length != 0];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row != 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_data[indexPath.row][@"key"] isEqualToString:@"selectDeselectAll"])
        [self selectDeselectGroup:nil];
    else if (indexPath.row > 0)
        [self selectDeselectItem:indexPath];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0)
        [self selectDeselectItem:indexPath];
}

#pragma mark - Selectors

- (void)selectDeselectGroup:(UIButton *)sender
{
    [self onLeftEditButtonPressed:sender.tag];
}

#pragma mark - OATableViewCellDelegate

- (void)onLeftEditButtonPressed:(NSInteger)tag
{
    [self.tableView beginUpdates];
    BOOL shouldSelect = _selectedItems.count == 0;
    if (!shouldSelect)
        [_selectedItems removeAllObjects];
    else
        [_selectedItems addObjectsFromArray:_items];

    for (NSInteger i = 0; i < _items.count; i++)
    {
        if (shouldSelect)
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i + 1 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        else
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i + 1 inSection:0] animated:NO];
    }
    [self.tableView endUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

@end
