//
//  OAExportItemsSelectionViewController.m
//  OsmAnd
//
//  Created by Paul on 31.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAExportItemsSelectionViewController.h"
#import "OAExportSettingsType.h"
#import "OACustomSelectionButtonCell.h"
#import "OAApplicationMode.h"
#import "OAMenuSimpleCell.h"
#import "Localization.h"
#import "OAProfileDataObject.h"
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

#include <OsmAndCore/ArchiveReader.h>

#define titleWithDescrCellHeight 60.0
#define kHeaderId @"TableViewSectionHeader"

@interface OAExportItemsSelectionViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
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
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    [self.tableView setEditing:YES];
    self.tableView.tintColor = UIColorFromRGB(color_primary_purple);
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:kHeaderId];

    self.cancelButton.layer.cornerRadius = 9.0;
    self.saveButton.layer.cornerRadius = 9.0;
    
    [self generateData];
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
    self.titleView.text = _type.title;
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.saveButton setTitle:OALocalizedString(@"shared_string_apply") forState:UIControlStateNormal];
}

- (void)generateData
{
    NSMutableArray<NSDictionary *> *data = [NSMutableArray new];
    [data addObject:@{
        @"type" : [OACustomSelectionButtonCell getCellIdentifier]
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
    item[@"type"] = [OAMenuSimpleCell getCellIdentifier];
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
            routingProfile = [OARoutingProfileDataObject getLocalizedName:[OARoutingProfileDataObject getValueOf:[routingProfileValue upperCase]]];
            routingProfile = routingProfile.length > 0 ? [routingProfile capitalizedString] : routingProfileValue.capitalizedString;
        }
        if (routingProfile.length > 0)
            item[@"descr"] = [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"nav_type_title"), routingProfile];
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
        item[@"title"] = globalSettingsItem.publicName;
        item[@"icon"] = [UIImage templateImageNamed:@"ic_custom_settings"];
    }
    else if ([object isKindOfClass:OADestination.class])
    {
        OADestination *marker = object;
        item[@"title"] = marker.desc ? marker.desc : @"";
        item[@"icon"] = [UIImage templateImageNamed:@"ic_custom_marker"];
        item[@"color"] = marker.color;
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

- (NSString *) getFormattedSize:(NSString *)filePath
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
    if ([filePath hasSuffix:GPX_FILE_EXT])
    {
        [self setupItemFromGpx:item filePath:filePath appearanceInfo:nil];
    }
    else if ([OAFileSettingsItemFileSubtype isMap:fileSubtype])
    {
        NSString *fileName = filePath.lastPathComponent;
        NSString *formattedSize = [self getFormattedSize:filePath];
        item[@"title"] = [OAFileNameTranslationHelper getMapName:[fileName stringByDeletingPathExtension]];
        NSString *mapDescr = [self getMapDescription:filePath];
        
        if (mapDescr.length > 0)
            item[@"descr"] = [NSString stringWithFormat:@"%@ • %@", mapDescr, formattedSize];
        else
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
    NSArray<NSString *> *pathComponents = filePath.pathComponents;
    NSString *parent = pathComponents.count > 1 ? pathComponents[pathComponents.count - 2] : @"";
    if (parent.length > 0)
        folder = parent.capitalizedString;
    
//    if (exportMode) {
//        GpxDataItem dataItem = getDataItem(file, gpxDataItemCallback);
//        if (dataItem != null) {
//            return getTrackDescrForDataItem(dataItem);
//        }
//    } else
    OsmAndAppInstance app = OsmAndApp.instance;
    if (appearanceInfo)
    {
        NSString *dist = [app getFormattedDistance:appearanceInfo.totalDistance];
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
        return OALocalizedString(@"res_roads");
    else if ([filePath hasSuffix:BINARY_WIKI_MAP_INDEX_EXT])
        return OALocalizedString(@"res_wiki");
    else if ([filePath hasSuffix:BINARY_SRTM_MAP_INDEX_EXT])
        return OALocalizedString(@"res_srtm");
    else if ([filePath hasSuffix:BINARY_MAP_INDEX_EXT])
        return OALocalizedString(@"res_standard");
    return @"";
}

- (NSString *)getTitleForSection
{
    return [[NSString stringWithFormat:OALocalizedString(@"selected_of"), (int)_selectedItems.count, (int)_items.count] upperCase];
}

- (void)selectDeselectGroup:(id)sender
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

- (void)selectDeselectItem:(NSIndexPath *)indexPath
{
    if (indexPath.row < 1)
        return;
    [self.tableView beginUpdates];
    id item = _items[indexPath.row - 1];
    if ([_selectedItems containsObject:item])
        [_selectedItems removeObject:item];
    else
        [_selectedItems addObject:item];
    [self.tableView endUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
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
        OATableViewCustomHeaderView *customHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kHeaderId];
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
    if ([item[@"type"] isEqualToString:[OACustomSelectionButtonCell getCellIdentifier]])
    {
        OACustomSelectionButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:[OACustomSelectionButtonCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACustomSelectionButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OACustomSelectionButtonCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 65., 0., 0.);
        }
        if (cell)
        {
            NSString *selectionText = _selectedItems.count > 0 ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"select_all");
            [cell.selectDeselectButton setTitle:selectionText forState:UIControlStateNormal];
            [cell.selectDeselectButton addTarget:self action:@selector(selectDeselectGroup:) forControlEvents:UIControlEventTouchUpInside];
            [cell.selectionButton addTarget:self action:@selector(selectDeselectGroup:) forControlEvents:UIControlEventTouchUpInside];
            
            NSInteger selectedAmount = _selectedItems.count;
            if (selectedAmount > 0)
            {
                UIImage *selectionImage = selectedAmount < _items.count ? [UIImage imageNamed:@"ic_system_checkbox_indeterminate"] : [UIImage imageNamed:@"ic_system_checkbox_selected"];
                [cell.selectionButton setImage:selectionImage forState:UIControlStateNormal];
            }
            else
            {
                [cell.selectionButton setImage:nil forState:UIControlStateNormal];
            }
            return cell;
        }
    }
    else if ([item[@"type"] isEqualToString:[OAMenuSimpleCell getCellIdentifier]])
    {
        OAMenuSimpleCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCell getCellIdentifier] owner:self options:nil];
            cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 65., 0., 0.);
            cell.tintColor = UIColorFromRGB(color_primary_purple);
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:.05];
            [cell setSelectedBackgroundView:bgColorView];
        }
        if (cell)
        {
            cell.imgView.image = item[@"icon"];
            cell.textView.text = item[@"title"];
            BOOL selected = [_selectedItems containsObject:item[@"object"]];
            UIColor *selectedColor = item[@"color"];
            selectedColor = selectedColor ? selectedColor : UIColorFromRGB(color_primary_purple);
            cell.imgView.tintColor = selected ? selectedColor : UIColorFromRGB(color_tint_gray);
            cell.descriptionView.text = item[@"descr"];
            cell.descriptionView.hidden = !cell.descriptionView.text || cell.descriptionView.text.length == 0;
            if ([cell needsUpdateConstraints])
                [cell updateConstraints];
        }
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if (item[@"descr"])
        return titleWithDescrCellHeight;
    else
        return kEstimatedRowHeight;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if (item[@"descr"])
        return titleWithDescrCellHeight;
    else
        return kEstimatedRowHeight;
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
    if (indexPath.row > 0)
        [self selectDeselectItem:indexPath];
    else
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0)
        [self selectDeselectItem:indexPath];
}

@end
