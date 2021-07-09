//
//  OAPluginInstalledViewController.m
//  OsmAnd Maps
//
//  Created by Paul on 22.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAPluginInstalledViewController.h"
#import "OATextViewSimpleCell.h"
#import "OAPlugin.h"
#import "OAColors.h"
#import "Localization.h"
#import "OAResourcesUIHelper.h"
#import "OAIAPHelper.h"
#import "OAAutoObserverProxy.h"
#import "OAIconTextDescSwitchCell.h"

#define kSidePadding 20.0
#define kTopPadding 6
#define kBottomPadding 32
#define kIconWidth 48

#define kSectionTypeDescription 0
#define kSectionTypeSuggestedMaps 1
#define kSectionTypeSuggestedProfiles 2

#define kCellTypeMap @"MapCell"

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

@interface OAPluginInstalledViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *disableButton;
@property (weak, nonatomic) IBOutlet UIButton *enableButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@end

@implementation OAPluginInstalledViewController
{
    OsmAndAppInstance _app;
    NSString *_pluginId;
    OAPlugin *_plugin;
    
    NSArray<NSArray<NSMutableDictionary *> *> *_data;
    NSArray<OAResourceItem *> *_suggestedMaps;
    NSArray<OAApplicationMode *> *_addedAppModes;
    
    OAIAPHelper *_iapHelper;
    
    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
    OAAutoObserverProxy* _localResourcesChangedObserver;
    NSObject *_dataLock;
}

- (instancetype) initWithPluginId:(NSString *)pluginId
{
    self = [super init];
    if (self) {
        _pluginId = pluginId;
        _plugin = [OAPlugin getPluginById:_pluginId];
        _iapHelper = [OAIAPHelper sharedInstance];
        _app = OsmAndApp.instance;
        _dataLock = [[NSObject alloc] init];
        _suggestedMaps = @[];
        _addedAppModes = @[];
    }
    return self;
}

- (void)applyLocalization
{
    [self.closeButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
    [self.enableButton setTitle:OALocalizedString(@"shared_string_ok") forState:UIControlStateNormal];
    [self.disableButton setTitle:OALocalizedString(@"shared_string_turn_off") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.enableButton.layer.cornerRadius = 9.;
    self.disableButton.layer.cornerRadius = 9.;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.tableView.tableHeaderView = [self getHeaderForTableView:self.tableView withFirstSectionText:self.descriptionText boldFragment:self.descriptionBoldText];
    
    [self setupView];
}

- (NSString *)descriptionText
{
    return OALocalizedString(@"new_plugin_added");
}

- (NSString *)descriptionBoldText
{
    return _plugin.getName;
}

- (void) setupView
{
    _downloadTaskProgressObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                              withHandler:@selector(onDownloadTaskProgressChanged:withKey:andValue:)
                                                               andObserve:_app.downloadsManager.progressCompletedObservable];
    _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onDownloadTaskFinished:withKey:andValue:)
                                                                andObserve:_app.downloadsManager.completedObservable];
    _localResourcesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onLocalResourcesChanged:withKey:)
                                                                andObserve:_app.localResourcesChangedObservable];
    
    [self updateAvailableMaps];
    [self generateData];
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    
    NSMutableArray *descriptionSection = [NSMutableArray new];
    [descriptionSection addObject: [NSMutableDictionary dictionaryWithDictionary:@{
        @"sectionType" : [NSNumber numberWithInt:kSectionTypeDescription],
        @"type" : [OATextViewSimpleCell getCellIdentifier],
        @"text" : _plugin.getDescription
    }]];
    [data addObject:descriptionSection];
    
    NSMutableArray *suggestedMapsSection = [NSMutableArray new];
    for (OARepositoryResourceItem* item in _suggestedMaps)
    {
        [suggestedMapsSection addObject: [NSMutableDictionary dictionaryWithDictionary:@{
            @"sectionType" : [NSNumber numberWithInt:kSectionTypeSuggestedMaps],
            @"type" : kCellTypeMap
        }]];
    }
    if (suggestedMapsSection.count > 0)
        [data addObject:suggestedMapsSection];
    
    _addedAppModes = [_plugin getAddedAppModes];
    NSMutableArray *addedAppModesSection = [NSMutableArray new];
    for (OAApplicationMode* mode in _addedAppModes)
    {
        [OAApplicationMode changeProfileAvailability:mode isSelected:YES];
        [addedAppModesSection addObject: [NSMutableDictionary dictionaryWithDictionary:@{
            @"sectionType" : [NSNumber numberWithInt:kSectionTypeSuggestedProfiles],
            @"type" : [OAIconTextDescSwitchCell getCellIdentifier],
            @"mode" : mode
        }]];
    }
    if (addedAppModesSection.count > 0)
        [data addObject:addedAppModesSection];
    
    _data = [NSArray arrayWithArray:data];
}

- (void) updateAvailableMaps
{
    _suggestedMaps = [_plugin getSuggestedMaps];
    [self generateData];
    [self.tableView reloadData];
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.tableView.tableHeaderView = [self getHeaderForTableView:self.tableView withFirstSectionText:self.descriptionText boldFragment:self.descriptionBoldText];
        [self.tableView reloadData];
    } completion:nil];
}

- (NSString *) getProfileDescription:(OAApplicationMode *)am
{
    return am.isCustomProfile ? OALocalizedString(@"profile_type_custom_string") : OALocalizedString(@"profile_type_base_string");
}

- (void) onAppModeSwitchChanged:(UISwitch *)sender
{
    OAApplicationMode *am = _addedAppModes[sender.tag];
    [OAApplicationMode changeProfileAvailability:am isSelected:sender.isOn];
}

- (IBAction)onDisablePressed:(UIButton *)sender
{
    if (_plugin)
        [OAPlugin enablePlugin:_plugin enable:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onEnablePressed:(id)sender
{
    if (_plugin)
        [OAPlugin enablePlugin:_plugin enable:YES];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

// MARK: UITableViewDataSource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[OATextViewSimpleCell getCellIdentifier]])
    {
        OATextViewSimpleCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextViewSimpleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextViewSimpleCell getCellIdentifier] owner:self options:nil];
            cell = (OATextViewSimpleCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsZero;
        }
        if (cell)
        {
            cell.textView.attributedText = [OAUtilities attributedStringFromHtmlString:item[@"text"] fontSize:17];
            cell.textView.linkTextAttributes = @{NSForegroundColorAttributeName: UIColorFromRGB(color_primary_purple)};
            [cell.textView sizeToFit];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeMap])
    {
        static NSString* const repositoryResourceCell = @"repositoryResourceCell";
        static NSString* const downloadingResourceCell = @"downloadingResourceCell";
        OAResourceItem *mapItem = _suggestedMaps[indexPath.row];
        NSString* cellTypeId = mapItem.downloadTask ? downloadingResourceCell : repositoryResourceCell;
        
        uint64_t _sizePkg = mapItem.sizePkg;
        if ((mapItem.resourceType == OsmAndResourceType::SrtmMapRegion || mapItem.resourceType == OsmAndResourceType::HillshadeRegion || mapItem.resourceType == OsmAndResourceType::SlopeRegion)
            && ![_iapHelper.srtm isActive])
        {
            mapItem.disabled = YES;
        }
        NSString *title = mapItem.title;
        NSString *subtitle = [NSString stringWithFormat:@"%@ • %@", [OAResourcesUIHelper resourceTypeLocalized:mapItem.resourceType], [NSByteCountFormatter stringFromByteCount:_sizePkg countStyle:NSByteCountFormatterCountStyleFile]];

        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellTypeId];
        if (cell == nil)
        {
            if ([cellTypeId isEqualToString:repositoryResourceCell])
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                              reuseIdentifier:cellTypeId];

                cell.textLabel.font = [UIFont systemFontOfSize:17.0];
                cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
                cell.detailTextLabel.textColor = UIColorFromRGB(0x929292);

                UIImage* iconImage = [UIImage imageNamed:@"menu_item_install_icon.png"];
                UIButton *btnAcc = [UIButton buttonWithType:UIButtonTypeSystem];
                [btnAcc addTarget:self action: @selector(accessoryButtonTapped:withEvent:) forControlEvents: UIControlEventTouchUpInside];
                [btnAcc setImage:iconImage forState:UIControlStateNormal];
                btnAcc.frame = CGRectMake(0.0, 0.0, 30.0, 50.0);
                [cell setAccessoryView:btnAcc];
            }
            else if ([cellTypeId isEqualToString:downloadingResourceCell])
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                              reuseIdentifier:cellTypeId];

                cell.textLabel.font = [UIFont systemFontOfSize:17.0];
                cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
                cell.detailTextLabel.textColor = UIColorFromRGB(0x929292);

                FFCircularProgressView* progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
                progressView.iconView = [[UIView alloc] init];

                cell.accessoryView = progressView;
            }
        }
        
        if ([cellTypeId isEqualToString:repositoryResourceCell])
        {
            if (!mapItem.disabled)
            {
                cell.textLabel.textColor = [UIColor blackColor];
                UIImage* iconImage = [UIImage imageNamed:@"menu_item_install_icon.png"];
                UIButton *btnAcc = [UIButton buttonWithType:UIButtonTypeSystem];
                [btnAcc addTarget:self action: @selector(accessoryButtonTapped:withEvent:) forControlEvents: UIControlEventTouchUpInside];
                [btnAcc setImage:iconImage forState:UIControlStateNormal];
                btnAcc.frame = CGRectMake(0.0, 0.0, 30.0, 50.0);
                [cell setAccessoryView:btnAcc];
            }
            else
            {
                cell.textLabel.textColor = [UIColor lightGrayColor];
                cell.accessoryView = nil;
            }
        }
        
        cell.imageView.image = [UIImage templateImageNamed: [OAResourcesUIHelper iconNameByResourseType:mapItem.resourceType]];
        cell.imageView.tintColor = UIColorFromRGB(color_tint_gray);
        cell.textLabel.text = title;
        if (cell.detailTextLabel != nil)
            cell.detailTextLabel.text = subtitle;
        
        if ([cellTypeId isEqualToString:downloadingResourceCell])
            [self updateDownloadingCell:cell indexPath:indexPath];

        return cell;
    }
    
    else if ([item[@"type"] isEqualToString:[OAIconTextDescSwitchCell getCellIdentifier]])
    {
        OAIconTextDescSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTextDescSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextDescSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTextDescSwitchCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        OAApplicationMode *am = item[@"mode"];
        BOOL isEnabled = [OAApplicationMode.values containsObject:am];
        cell.separatorInset = UIEdgeInsetsMake(0.0, indexPath.row < OAApplicationMode.allPossibleValues.count - 1 ? 62.0 : 0.0, 0.0, 0.0);
        UIImage *img = am.getIcon;
        cell.leftIconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.leftIconView.tintColor = isEnabled ? UIColorFromRGB(am.getIconColor) : UIColorFromRGB(color_tint_gray);
        cell.titleLabel.text = am.toHumanString;
        cell.descLabel.text = [self getProfileDescription:am];
        cell.switchView.tag = indexPath.row;
        BOOL isDefault = am == OAApplicationMode.DEFAULT;
        [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        if (!isDefault)
        {
            [cell.switchView setOn:isEnabled];
            [cell.switchView addTarget:self action:@selector(onAppModeSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        cell.switchView.hidden = isDefault;
        cell.dividerView.hidden = isDefault;
        return cell;
    }
     
    return nil;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (UIView *) getHeaderForTableView:(UITableView *)tableView withFirstSectionText:(NSString *)text boldFragment:(NSString *)boldFragment
{
    NSString *descriptionText;
    if (boldFragment && boldFragment.length > 0)
        descriptionText = [NSString stringWithFormat:@"%@\n\n%@", text, boldFragment];
    else
        descriptionText = text;
    NSAttributedString *attrString;
    if (boldFragment && boldFragment.length > 0)
    {
        attrString = [OAUtilities getStringWithBoldPart:descriptionText mainString:text boldString:boldFragment lineSpacing:0. fontSize:17. boldFontSize:34. boldColor:UIColor.blackColor mainColor:UIColorFromRGB(color_text_footer)];
    }
    else
    {
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:6];
        attrString = [[NSAttributedString alloc] initWithString:descriptionText attributes:@{NSParagraphStyleAttributeName : style}];
    }
    return [OAUtilities setupTableHeaderViewWithText:attrString tintColor:UIColor.whiteColor icon:_plugin.getLogoResource iconFrameSize:48. iconBackgroundColor:UIColorFromRGB(color_primary_purple) iconContentMode:UIViewContentModeScaleAspectFit iconYOffset:48.];
}

- (NSInteger) getTypeForSection:(NSInteger)section
{
    if (_data[section])
    {
        NSDictionary *item = _data[section].firstObject;
        if (item)
        {
            return [item[@"type"] integerValue];
        }
    }
    return -1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSInteger type = [self getTypeForSection:section];
    
    if (type == kSectionTypeSuggestedMaps)
        return OALocalizedString(@"suggested_maps");
    else if (type == kSectionTypeSuggestedProfiles)
        return OALocalizedString(@"added_profiles");
        
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSInteger type = [self getTypeForSection:section];
    
    if (type == kSectionTypeSuggestedMaps)
        return OALocalizedString(@"suggested_maps_descr");
    else if (type == kSectionTypeSuggestedProfiles)
        return OALocalizedString(@"added_profiles_descr");
    
    return @"";
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *type = _data[indexPath.section][indexPath.row][@"type"];
    if ([type isEqualToString:kCellTypeMap])
        [self onItemClicked:indexPath];

    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Selectors

- (void) accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:self.tableView]];
    if (!indexPath)
        return;
    
    [self.tableView.delegate tableView: self.tableView accessoryButtonTappedForRowWithIndexPath: indexPath];
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self onItemClicked:indexPath];
}

- (OARepositoryResourceItem *) getMapItem:(NSIndexPath *)indexPath
{
    return (OARepositoryResourceItem *)_suggestedMaps[indexPath.row];
}

- (void) onItemClicked:(NSIndexPath *)indexPath
{
    OARepositoryResourceItem *mapItem = [self getMapItem:indexPath];
        if (mapItem.downloadTask != nil)
        {
            [OAResourcesUIHelper offerCancelDownloadOf:mapItem onTaskStop:nil completionHandler:^(UIAlertController *alert) {
                [self presentViewController:alert animated:YES completion:nil];
            }];
        }
        else if ([mapItem isKindOfClass:[OARepositoryResourceItem class]])
        {
            OARepositoryResourceItem* item = (OARepositoryResourceItem*)mapItem;
            
            [OAResourcesUIHelper offerDownloadAndInstallOf:item onTaskCreated:^(id<OADownloadTask> task) {
                [self updateAvailableMaps];
            } onTaskResumed:nil completionHandler:^(UIAlertController *alert) {
                [self presentViewController:alert animated:YES completion:nil];
            }];
        }
}

- (void) updateDownloadingCellAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self updateDownloadingCell:cell indexPath:indexPath];
}

- (void) updateDownloadingCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    OARepositoryResourceItem *mapItem = [self getMapItem:indexPath];
    
    if (mapItem.downloadTask)
    {
        FFCircularProgressView* progressView = (FFCircularProgressView*)cell.accessoryView;
        
        float progressCompleted = mapItem.downloadTask.progressCompleted;
        if (progressCompleted >= 0.001f && mapItem.downloadTask.state == OADownloadTaskStateRunning)
        {
            progressView.iconPath = nil;
            if (progressView.isSpinning)
                [progressView stopSpinProgressBackgroundLayer];
            progressView.progress = progressCompleted - 0.001;
        }
        else if (mapItem.downloadTask.state == OADownloadTaskStateFinished)
        {
            progressView.iconPath = [OAResourcesUIHelper tickPath:progressView];
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
            progressView.progress = 0.0f;
        }
        else
        {
            progressView.iconPath = [UIBezierPath bezierPath];
            progressView.progress = 0.0;
            progressView.iconPath = [OAResourcesUIHelper tickPath:progressView];
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
        }
    }
}

- (void) onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;

    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;
 
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshDownloadingContent:task.key];
    });
}

- (void) refreshDownloadingContent:(NSString *)downloadTaskKey
{
    for (int i = 0; i < _suggestedMaps.count; i++)
    {
        OAResourceItem *item = (OAResourceItem *)_suggestedMaps[i];
        if (item && [[item.downloadTask key] isEqualToString:downloadTaskKey])
            [self updateDownloadingCellAtIndexPath:[NSIndexPath indexPathForRow:i inSection:1]];
    }
}

- (void) onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;

    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (task.progressCompleted < 1.0)
        {
            if ([OsmAndApp.instance.downloadsManager.keysOfDownloadTasks count] > 0) {
                id<OADownloadTask> nextTask =  [OsmAndApp.instance.downloadsManager firstDownloadTasksWithKey:[OsmAndApp.instance.downloadsManager.keysOfDownloadTasks objectAtIndex:0]];
                [nextTask resume];
            }
            [self updateAvailableMaps];
        }
        else
        {
            [self refreshDownloadingContent:task.key];
        }
    });
}

- (void) onLocalResourcesChanged:(id<OAObservableProtocol>)observer withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateAvailableMaps];
        [self.tableView reloadData];
    });
}

@end
