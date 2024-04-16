//
//  OAMapSettingsTerrainScreen.m
//  OsmAnd Maps
//
//  Created by igor on 20.11.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapSettingsTerrainScreen.h"
#import "OAMapSettingsTerrainParametersViewController.h"
#import "OAMapSettingsViewController.h"
#import "OAMapStyleSettings.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OARightIconTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OATextLineViewCell.h"
#import "OAButtonTableViewCell.h"
#import "OAImageTextViewCell.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAResourcesUIHelper.h"
#import "OAChoosePlanHelper.h"
#import "OAIAPHelper.h"
#import "OAPluginPopupViewController.h"
#import "OASRTMPlugin.h"
#import "OAManageResourcesViewController.h"
#import "OAAutoObserverProxy.h"
#import "OALinks.h"
#import "OASizes.h"
#import <SafariServices/SafariServices.h>
#import "GeneratedAssetSymbols.h"
#import "OAPluginsHelper.h"

#define kRelief3DCellRowHeight 48.3

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

@interface OAMapSettingsTerrainScreen() <SFSafariViewControllerDelegate, UITextViewDelegate, OATerrainParametersDelegate>

@end

@implementation OAMapSettingsTerrainScreen
{
    OsmAndAppInstance _app;
    OAIAPHelper *_iapHelper;
    OASRTMPlugin *_plugin;
    OATableDataModel *_data;
    NSInteger _availableMapsSection;
    NSInteger _minZoom;
    NSInteger _maxZoom;

    NSObject *_dataLock;
    NSArray<OAResourceItem *> *_mapItems;

    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
    OAAutoObserverProxy* _localResourcesChangedObserver;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;

-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _iapHelper = [OAIAPHelper sharedInstance];
        _plugin = (OASRTMPlugin *) [OAPluginsHelper getPlugin:OASRTMPlugin.class];
        settingsScreen = EMapSettingsScreenTerrain;

        vwController = viewController;
        tblView = tableView;
        tblView.sectionHeaderHeight = UITableViewAutomaticDimension;
        tblView.sectionFooterHeight = UITableViewAutomaticDimension;
        _dataLock = [[NSObject alloc] init];

        [self setupView];
        [self initData];
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_downloadTaskProgressObserver)
    {
        [_downloadTaskProgressObserver detach];
        _downloadTaskProgressObserver = nil;
    }
    if (_downloadTaskCompletedObserver)
    {
        [_downloadTaskCompletedObserver detach];
        _downloadTaskCompletedObserver = nil;
    }
    if (_localResourcesChangedObserver)
    {
        [_localResourcesChangedObserver detach];
        _localResourcesChangedObserver = nil;
    }
}

- (void) initData
{
    _data = [OATableDataModel model];

    EOATerrainType type = _app.data.terrainType;

    double alphaValue = type == EOATerrainTypeSlope ? _app.data.slopeAlpha : _app.data.hillshadeAlpha;
    NSString *alphaValueString = [NSString stringWithFormat:@"%.0f%@", alphaValue * 100, @"%"];

    _minZoom = type == EOATerrainTypeHillshade ? _app.data.hillshadeMinZoom : _app.data.slopeMinZoom;
    _maxZoom = type == EOATerrainTypeHillshade ? _app.data.hillshadeMaxZoom : _app.data.slopeMaxZoom;
    NSString *zoomRangeString = [NSString stringWithFormat:@"%ld-%ld", (long)_minZoom, (long)_maxZoom];

    BOOL isRelief3D = [OAIAPHelper isOsmAndProAvailable];

    OATableSectionData *switchSection = [_data createNewSection];
    [switchSection addRowFromDictionary:@{
        kCellKeyKey : @"terrainStatus",
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellTitleKey : type != EOATerrainTypeDisabled ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name"),
        kCellIconNameKey : type != EOATerrainTypeDisabled ? @"ic_custom_show.png" : @"ic_custom_hide.png",
        kCellIconTintColor : type != EOATerrainTypeDisabled ? [UIColor colorNamed:ACColorNameIconColorSelected] : [UIColor colorNamed:ACColorNameIconColorDisabled],
        @"value" : @(type != EOATerrainTypeDisabled)
    }];

    if (type == EOATerrainTypeDisabled)
    {
        OATableSectionData *disabledSection = [_data createNewSection];
        [disabledSection addRowFromDictionary:@{
            kCellKeyKey : @"disabledImage",
            kCellTypeKey : [OAImageTextViewCell getCellIdentifier],
            kCellDescrKey : OALocalizedString(@"enable_hillshade"),
            kCellIconNameKey : @"img_empty_state_terrain"
        }];
        [disabledSection addRowFromDictionary:@{
            kCellKeyKey : @"readMore",
            kCellTypeKey : [OARightIconTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(@"shared_string_read_more"),
            kCellIconNameKey : @"ic_custom_safari",
            @"link" : kOsmAndFeaturesContourLinesPlugin
        }];
    }
    else
    {
        OATableSectionData *titleSection = [_data createNewSection];
        [titleSection addRowFromDictionary:@{
            kCellKeyKey : @"terrainType",
            kCellTypeKey : [OAButtonTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(@"srtm_color_scheme")
        }];
        [titleSection addRowFromDictionary:@{
            kCellKeyKey : @"terrainTypeDesc",
            kCellTypeKey : [OATextLineViewCell getCellIdentifier],
            kCellDescrKey : type == EOATerrainTypeHillshade ? OALocalizedString(@"map_settings_hillshade_description") : OALocalizedString(@"map_settings_slopes_description"),

        }];
        if (_app.data.terrainType == EOATerrainTypeSlope)
        {
            [titleSection addRowFromDictionary:@{
                kCellTypeKey : [OAImageTextViewCell getCellIdentifier],
                kCellDescrKey : OALocalizedString(@"map_settings_slopes_legend"),
                kCellIconNameKey : @"img_legend_slope",
                @"link" : kUrlWikipediaSlope
            }];
        }
        [titleSection addRowFromDictionary:@{
            kCellKeyKey : @"visibility",
            kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(@"visibility"),
            kCellIconNameKey : @"ic_custom_visibility",
            kCellIconTintColor : [UIColor colorNamed:ACColorNameIconColorDefault],
            @"value" : alphaValueString
        }];
        [titleSection addRowFromDictionary:@{
            kCellKeyKey : @"zoomLevels",
            kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(@"shared_string_zoom_levels"),
            kCellIconNameKey : @"ic_custom_overlay_map",
            kCellIconTintColor : [UIColor colorNamed:ACColorNameIconColorDefault],
            @"value" : zoomRangeString
        }];
        OATableSectionData *relief3DSection = [_data createNewSection];
        [relief3DSection addRowFromDictionary:@{
            kCellKeyKey : @"relief3D",
            kCellTypeKey : isRelief3D ? [OASwitchTableViewCell getCellIdentifier] : [OAButtonTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(@"shared_string_relief_3d"),
            kCellIconNameKey : @"ic_custom_3d_relief",
            kCellIconTintColor : ![_plugin.enable3DMaps get] || !isRelief3D ? [UIColor colorNamed:ACColorNameIconColorDisabled] : [UIColor colorNamed:ACColorNameIconColorSelected],
            kCellSecondaryIconName : @"ic_payment_label_pro",
            @"value" : @([_plugin.enable3DMaps get]),
        }];
        if (isRelief3D && [_plugin.enable3DMaps get])
        {
            NSString *alphaValueString = OALocalizedString(@"shared_string_none");
            double scaleValue = _app.data.verticalExaggerationScale;
            if (scaleValue > 1)
            {
                alphaValueString = [NSString stringWithFormat:@"x%.1f", scaleValue];
            }
            [relief3DSection addRowFromDictionary:@{
                kCellKeyKey : @"vertical_exaggeration",
                kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
                kCellTitleKey : OALocalizedString(@"vertical_exaggeration"),
                kCellIconNameKey : @"ic_custom_terrain_scale",
                kCellIconTintColor : [UIColor colorNamed:ACColorNameIconColorSelected],
                @"value" : alphaValueString,
            }];
        }
        if (_mapItems.count > 0)
        {
            OATableSectionData *availableMapsSection = [_data createNewSection];
            _availableMapsSection = [_data sectionCount] - 1;
            availableMapsSection.headerText = OALocalizedString(@"available_maps");
            availableMapsSection.footerText = type == EOATerrainTypeHillshade ? OALocalizedString(@"map_settings_add_maps_hillshade") : OALocalizedString(@"map_settings_add_maps_slopes");
            for (NSInteger i = 0; i < _mapItems.count; i++)
            {
                [availableMapsSection addRowFromDictionary:@{
                    kCellKeyKey : @"mapItem",
                    kCellTypeKey : [OARightIconTableViewCell getCellIdentifier]
                }];
            }
        }
        else
        {
            _availableMapsSection = -1;
        }
    }
}

- (void)updateAvailableMaps
{
    CLLocationCoordinate2D loc = [OAResourcesUIHelper getMapLocation];
    OsmAnd::ResourcesManager::ResourceType resType = OsmAndResourceType::GeoTiffRegion;
    _mapItems = [OAResourcesUIHelper findIndexItemsAt:loc
                                                 type:resType
                                    includeDownloaded:NO
                                                limit:-1
                                  skipIfOneDownloaded:YES];

    [self initData];
    [UIView transitionWithView:tblView
                      duration:.35
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void)
     {
        [self.tblView reloadData];
     }
                    completion:nil];
}

- (void) setupView
{
    title = OALocalizedString(@"shared_string_terrain");
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRestored:) name:OAIAPProductsRestoredNotification object:nil];
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
}

- (void)onRotation
{
    tblView.separatorInset = UIEdgeInsetsMake(0, [OAUtilities getLeftMargin] + 16, 0, 0);
    [tblView reloadData];
}

- (UIMenu *)createTerrainTypeMenuForCellButton:(UIButton *)button
{
    NSMutableArray<UIMenuElement *> *menuElements = [NSMutableArray array];

    UIAction *hillshade = [UIAction actionWithTitle:OALocalizedString(@"shared_string_hillshade")
                                             image:nil
                                        identifier:nil
                                           handler:^(__kindof UIAction * _Nonnull action) {
        [_app.data setTerrainType: EOATerrainTypeHillshade];
        [self terrainTypeChanged];
    }];
    [menuElements addObject:hillshade];

    UIAction *slope = [UIAction actionWithTitle:OALocalizedString(@"shared_string_slope")
                                          image:nil
                                     identifier:nil
                                        handler:^(__kindof UIAction * _Nonnull action) {
        [_app.data setTerrainType: EOATerrainTypeSlope];
        [self terrainTypeChanged];
    }];
    [menuElements addObject:slope];

    NSInteger selectedIndex = _app.data.terrainType == EOATerrainTypeHillshade ? 0 : 1;
    if (selectedIndex >= 0 && selectedIndex < menuElements.count)
        ((UIAction *)menuElements[selectedIndex]).state = UIMenuElementStateOn;
    
    NSString *title = [menuElements[selectedIndex] title];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:title];
    
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightBold];
    UIImage *image = [UIImage systemImageNamed:@"chevron.up.chevron.down" withConfiguration:config];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    attachment.image = image;
    
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    [attributedString appendAttributedString:attachmentString];
    
    [button setAttributedTitle:attributedString forState:UIControlStateNormal];
    
    return [UIMenu menuWithChildren:menuElements];
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_data sectionCount];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data rowCount:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item =  [_data itemForIndexPath:indexPath];
    if ([item.key isEqualToString:@"relief3D"])
        return kRelief3DCellRowHeight;
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
            cell.leftIconView.tintColor = item.iconTintColor;
            [cell.switchView setOn:[item boolForKey:@"value"]];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(mapSettingSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.valueLabel.text = [item stringForKey:@"value"];
            [cell leftIconVisibility:item.iconName.length > 0];
            cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
            cell.leftIconView.tintColor = item.iconTintColor;
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OATextLineViewCell getCellIdentifier]])
    {
        OATextLineViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextLineViewCell getCellIdentifier]];
        BOOL isTerrainTypeSlope = _app.data.terrainType == EOATerrainTypeSlope;
        
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextLineViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextLineViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textTopLargeConstraint.constant = 0;
            cell.textTopSmallConstraint.constant = 0;
            [cell layoutIfNeeded];
        }
        if (cell)
        {
            cell.separatorInset = isTerrainTypeSlope ? UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.) : UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingOnSideOfContent, 0., 0.);;
            cell.textView.text = item.descr;
            cell.textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.textView.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OAButtonTableViewCell getCellIdentifier]])
    {
        OAButtonTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAButtonTableViewCell getCellIdentifier]];
        BOOL isTerrainTypeCell = [item.key isEqualToString:@"terrainType"];

        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAButtonTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAButtonTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            [cell setCustomLeftSeparatorInset:isTerrainTypeCell];
            cell.titleLabel.text = item.title;

            if (isTerrainTypeCell)
            {
                cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
                [cell leftIconVisibility:NO];
                cell.leftIconView.image = nil;
                [cell.button setTitleColor:[UIColor colorNamed:ACColorNameTextColorActive] forState:UIControlStateHighlighted];
                cell.button.tintColor = [UIColor colorNamed:ACColorNameTextColorActive];
                cell.button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
                
                cell.button.menu = [self createTerrainTypeMenuForCellButton:cell.button];
                cell.button.showsMenuAsPrimaryAction = YES;
                cell.button.changesSelectionAsPrimaryAction = YES;
            }
            else
            {
                cell.separatorInset = UIEdgeInsetsZero;
                [cell leftIconVisibility:YES];
                cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
                cell.leftIconView.tintColor = item.iconTintColor;
                [cell.button setTitle:nil forState:UIControlStateNormal];

                UIButtonConfiguration *conf = [UIButtonConfiguration plainButtonConfiguration];
                conf.image = [UIImage imageNamed:item.secondaryIconName];
                cell.button.configuration = conf;
                cell.button.menu = nil;
                [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
                [cell.button addTarget:self action:@selector(showChoosePlanScreen) forControlEvents:UIControlEventTouchUpInside];
            }
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
            cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        }
        if (cell)
        {
            if ([item.key isEqualToString:@"mapItem"])
            {
                [cell leftIconVisibility:YES];
                [cell descriptionVisibility:YES];

                OAResourceItem *mapItem = _mapItems[indexPath.row];
                cell.leftIconView.image = [UIImage templateImageNamed:@"ic_custom_terrain"];
                cell.titleLabel.text = mapItem.title;
                cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
                cell.descriptionLabel.text = [NSString stringWithFormat:@"%@  •  %@", [OAResourceType resourceTypeLocalized:mapItem.resourceType],
                                              [NSByteCountFormatter stringFromByteCount:mapItem.sizePkg countStyle:NSByteCountFormatterCountStyleFile]];

                if (![_iapHelper.srtm isActive] && (mapItem.resourceType == OsmAndResourceType::HillshadeRegion || mapItem.resourceType == OsmAndResourceType::SlopeRegion))
                    mapItem.disabled = YES;

                if (!mapItem.downloadTask)
                {
                    cell.accessoryView = nil;
                    cell.titleLabel.textColor = !mapItem.disabled ? [UIColor colorNamed:ACColorNameTextColorPrimary] : [UIColor colorNamed:ACColorNameTextColorSecondary];
                    cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_download"];
                }
                else
                {
                    cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
                    cell.rightIconView.image = nil;
                    if (!cell.accessoryView)
                    {
                        FFCircularProgressView *progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0., 0., 25., 25.)];
                        progressView.iconView = [[UIView alloc] init];
                        progressView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
                        cell.accessoryView = progressView;
                    }
                    [self updateDownloadingCell:cell indexPath:indexPath];
                }
            }
            else
            {
                cell.accessoryView = nil;
                BOOL isReadMore = [item.key isEqualToString:@"readMore"];
                [cell leftIconVisibility:!isReadMore];
                [cell descriptionVisibility:!isReadMore];
                cell.titleLabel.textColor = isReadMore ? [UIColor colorNamed:ACColorNameTextColorActive] : [UIColor colorNamed:ACColorNameTextColorPrimary];
                cell.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:isReadMore ? UIFontWeightSemibold : UIFontWeightRegular];
                cell.rightIconView.image = [UIImage templateImageNamed:item.iconName];
                cell.titleLabel.text = item.title;
            }
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OAImageTextViewCell getCellIdentifier]])
    {
        OAImageTextViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAImageTextViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAImageTextViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAImageTextViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell showExtraDesc:NO];
            cell.descView.delegate = self;
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0, [OAUtilities getLeftMargin] + kPaddingOnSideOfContent, 0, 0);
            cell.iconView.image = [UIImage rtlImageNamed:item.iconName];

            BOOL isDisabled = [item.key isEqualToString:@"disabledImage"];
            NSString *descr = item.descr;
            if (isDisabled)
            {
                cell.descView.attributedText = nil;
                cell.descView.text = descr;
            }
            else if (descr && descr.length > 0)
            {
                NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:descr attributes:@{
                    NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline],
                    NSForegroundColorAttributeName: [UIColor colorNamed:ACColorNameTextColorPrimary]
                }];
                NSRange range = [descr rangeOfString:@" " options:NSBackwardsSearch];
                if (range.location != NSNotFound)
                {
                    NSDictionary *linkAttributes = @{ NSLinkAttributeName : [item stringForKey:@"link"] };
                    [str setAttributes:linkAttributes range:NSMakeRange(range.location + 1, descr.length - range.location - 1)];
                }
                cell.descView.text = nil;
                cell.descView.attributedText = str;
            }
            else
            {
                cell.descView.text = nil;
                cell.descView.attributedText = nil;
            }

            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
        }
        return cell;
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tblView deselectRowAtIndexPath:indexPath animated:YES];

    OATableRowData *item =  [_data itemForIndexPath:indexPath];

    OAMapSettingsTerrainParametersViewController *terrainParametersScreen;
    if ([item.key isEqualToString:@"visibility"])
        terrainParametersScreen = [[OAMapSettingsTerrainParametersViewController alloc] initWithSettingsType:EOATerrainSettingsTypeVisibility];
    else if ([item.key isEqualToString:@"zoomLevels"])
        terrainParametersScreen = [[OAMapSettingsTerrainParametersViewController alloc] initWithSettingsType:EOATerrainSettingsTypeZoomLevels];
    else if ([item.key isEqualToString:@"vertical_exaggeration"])
        terrainParametersScreen = [[OAMapSettingsTerrainParametersViewController alloc] initWithSettingsType:EOATerrainSettingsTypeVerticalExaggeration];
    if (terrainParametersScreen)
    {
        [vwController hide:YES animated:YES];
        terrainParametersScreen.delegate = self;
        [OARootViewController.instance.mapPanel showScrollableHudViewController:terrainParametersScreen];
    }
    else if ([item.key isEqualToString:@"readMore"])
    {
        SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:[item stringForKey:@"link"]]];
        [self.vwController presentViewController:safariViewController animated:YES completion:nil];
    }
    else if ([item.key isEqualToString:@"mapItem"])
    {
        OAResourceItem *mapItem = _mapItems[indexPath.row];
        if (mapItem.downloadTask != nil)
        {
            [OAResourcesUIHelper offerCancelDownloadOf:mapItem];
        }
        else if ([mapItem isKindOfClass:[OARepositoryResourceItem class]])
        {
            OARepositoryResourceItem* item = (OARepositoryResourceItem*)mapItem;
            if ((item.resourceType == OsmAndResourceType::SrtmMapRegion || item.resourceType == OsmAndResourceType::HillshadeRegion
                 || item.resourceType == OsmAndResourceType::SlopeRegion) && ![_iapHelper.srtm isActive])
            {
                [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Srtm];
            }
            else
            {
                [OAResourcesUIHelper offerDownloadAndInstallOf:item onTaskCreated:^(id<OADownloadTask> task) {
                    [self updateAvailableMaps];
                } onTaskResumed:nil];
            }
        }
    }
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:URL];
    [self.vwController presentViewController:safariViewController animated:YES completion:nil];
    return NO;
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - OATerrainParametersDelegate

- (void)onBackTerrainParameters
{
    [[OARootViewController instance].mapPanel showTerrainScreen];
}

#pragma mark - Selectors

- (void)mapSettingSwitchChanged:(UISwitch *)switchView
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    BOOL isOn = switchView.isOn;

    if ([item.key isEqualToString:@"terrainStatus"])
    {
        if (isOn)
        {
            EOATerrainType prevType = _app.data.lastTerrainType;
            [_app.data setTerrainType:prevType != EOATerrainTypeDisabled ? prevType : EOATerrainTypeHillshade];
        }
        else
        {
            _availableMapsSection = -1;
            _app.data.lastTerrainType = _app.data.terrainType;
            [_app.data setTerrainType:EOATerrainTypeDisabled];
        }
    }
    else if ([item.key isEqualToString:@"relief3D"])
    {
        [_plugin.enable3DMaps set:isOn];
    }

    [self updateAvailableMaps];
}

- (void)showChoosePlanScreen
{
    [OAChoosePlanHelper showChoosePlanScreenWithFeature:OAFeature.RELIEF_3D navController:[OARootViewController instance].navigationController];
}

- (void) terrainTypeChanged
{
    _availableMapsSection = -1;
    [self updateAvailableMaps];
}

#pragma mark - Downloading cell progress methods

- (void) updateDownloadingCellAtIndexPath:(NSIndexPath *)indexPath
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UITableViewCell *cell = [tblView cellForRowAtIndexPath:indexPath];
        [self updateDownloadingCell:cell indexPath:indexPath];
    });
}

- (void) updateDownloadingCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    if (_mapItems && _mapItems.count > 0)
    {
        OAResourceItem *mapItem = _mapItems[indexPath.row];
        if (mapItem.downloadTask)
        {
            if (cell.accessoryView && [cell.accessoryView isKindOfClass:FFCircularProgressView.class])
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
                    if (!progressView.isSpinning)
                        [progressView startSpinProgressBackgroundLayer];
                }
            }
        }
    }
}

- (void) refreshDownloadingContent:(NSString *)downloadTaskKey
{
    @synchronized(_dataLock)
    {
        if (_availableMapsSection != -1)
        {
            for (int i = 0; i < _mapItems.count; i++)
            {
                OAResourceItem *item = (OAResourceItem *)_mapItems[i];
                if (item && [[item.downloadTask key] isEqualToString:downloadTaskKey])
                    [self updateDownloadingCellAtIndexPath:[NSIndexPath indexPathForRow:i inSection:_availableMapsSection]];
            }
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
        if (!vwController.isViewLoaded || vwController.view.window == nil)
            return;

        [self refreshDownloadingContent:task.key];
    });
}

- (void) onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;

    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!vwController.isViewLoaded || vwController.view.window == nil)
            return;

        if (task.progressCompleted < 1.0)
        {
            if ([_app.downloadsManager.keysOfDownloadTasks count] > 0) {
                id<OADownloadTask> nextTask =  [_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks objectAtIndex:0]];
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
        if (!vwController.isViewLoaded || vwController.view.window == nil)
        {
            return;
        }

        [OAManageResourcesViewController prepareData];
        [self updateAvailableMaps];
    });
}

#pragma mark - OAIAPProductNotification

- (void)productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self initData];
        [self.tblView reloadData];
    });
}

- (void)productsRestored:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self initData];
        [self.tblView reloadData];
    });
}

@end
