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
#import "OAAppData.h"
#import "OAObservable.h"
#import <SafariServices/SafariServices.h>
#import "GeneratedAssetSymbols.h"
#import "OAPluginsHelper.h"
#import "OsmAnd_Maps-Swift.h"

static NSString *kCellTypeMap = @"MapCell";
static NSString *kCellItemKey = @"kCellItemKey";

static const CGFloat kRelief3DCellRowHeight = 48.3;

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

@interface OAMapSettingsTerrainScreen() <SFSafariViewControllerDelegate, UITextViewDelegate, OATerrainParametersDelegate, DownloadingCellResourceHelperDelegate>

@property (nonatomic) OASRTMPlugin *plugin;

@end

@implementation OAMapSettingsTerrainScreen
{
    OsmAndAppInstance _app;
    DownloadingCellResourceHelper *_downloadingCellResourceHelper;
    OAIAPHelper *_iapHelper;
    OATableDataModel *_data;
    NSInteger _availableMapsSection;
    NSInteger _minZoom;
    NSInteger _maxZoom;

    NSObject *_dataLock;
    NSArray<OAResourceItem *> *_mapItems;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;

-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _data = [OATableDataModel model];
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
        [self setupDownloadingCellHelper];
        [self initData];
    }
    return self;
}

- (void) initData
{
    [_data clearAllData];

    TerrainMode *terrainMode = [_plugin getTerrainMode];
    _minZoom = [_plugin getTerrainMinZoom];
    _maxZoom = [_plugin getTerrainMaxZoom];

    BOOL isRelief3D = [OAIAPHelper isOsmAndProAvailable];
    BOOL isTerrainEbabled = [_plugin isTerrainLayerEnabled];
    BOOL isHillshade = [terrainMode isHillshade];
    BOOL isSlope = [terrainMode isSlope];

    OATableSectionData *switchSection = [_data createNewSection];
    [switchSection addRowFromDictionary:@{
        kCellKeyKey : @"terrainStatus",
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(isTerrainEbabled ? @"shared_string_enabled" : @"rendering_value_disabled_name"),
        kCellIconNameKey : isTerrainEbabled ? @"ic_custom_show.png" : @"ic_custom_hide.png",
        kCellIconTintColor : [UIColor colorNamed:isTerrainEbabled ? ACColorNameIconColorSelected : ACColorNameIconColorDisabled],
        @"value" : @(isTerrainEbabled)
    }];

    if (!isTerrainEbabled)
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
            kCellDescrKey : OALocalizedString(isHillshade ? @"map_settings_hillshade_description"
                : isSlope ? @"map_settings_slopes_description" : @"height_legend_description"),

        }];
        if (isSlope)
        {
            [titleSection addRowFromDictionary:@{
                kCellTypeKey : [OAImageTextViewCell getCellIdentifier],
                kCellDescrKey : OALocalizedString(@"map_settings_slopes_legend"),
                kCellIconNameKey : @"img_legend_slope",
                @"link" : kUrlWikipediaSlope
            }];
        }
        [titleSection addRowFromDictionary:@{
            kCellKeyKey : @"modifyPalette",
            kCellTypeKey : [OAButtonTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(@"shared_string_modify"),
            kCellSecondaryIconName : @"ic_payment_label_pro",
            @"purchased" : @(isRelief3D)
        }];

        OATableSectionData *appearanceSection = [_data createNewSection];
        appearanceSection.headerText = OALocalizedString(@"shared_string_appearance");

        [appearanceSection addRowFromDictionary:@{
            kCellKeyKey : @"visibility",
            kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(@"visibility"),
            kCellIconNameKey : @"ic_custom_visibility",
            kCellIconTintColor : [UIColor colorNamed:ACColorNameIconColorDefault],
            @"value" : [NSString stringWithFormat:@"%d%%", [terrainMode getTransparency]]
        }];
        [appearanceSection addRowFromDictionary:@{
            kCellKeyKey : @"zoomLevels",
            kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(@"shared_string_zoom_levels"),
            kCellIconNameKey : @"ic_custom_overlay_map",
            kCellIconTintColor : [UIColor colorNamed:ACColorNameIconColorDefault],
            @"value" : [NSString stringWithFormat:@"%ld-%ld", _minZoom, _maxZoom]
        }];

        OATableSectionData *relief3DSection = [_data createNewSection];
        [relief3DSection addRowFromDictionary:@{
            kCellKeyKey : @"relief3D",
            kCellTypeKey : isRelief3D ? [OASwitchTableViewCell getCellIdentifier] : [OAButtonTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(@"shared_string_relief_3d"),
            kCellIconNameKey : @"ic_custom_3d_relief",
            kCellIconTintColor : ![_plugin.enable3dMapsPref get] || !isRelief3D ? [UIColor colorNamed:ACColorNameIconColorDisabled] : [UIColor colorNamed:ACColorNameIconColorSelected],
            kCellSecondaryIconName : @"ic_payment_label_pro",
            @"value" : @([_plugin.enable3dMapsPref get]),
            @"purchased" : @(isRelief3D)
        }];
        if (isRelief3D && [_plugin.enable3dMapsPref get])
        {
            double scaleValue = _app.data.verticalExaggerationScale;
            NSString *alphaValueString = scaleValue <= kExaggerationDefScale ? OALocalizedString(@"shared_string_none") : (scaleValue < 1.0 ? [NSString stringWithFormat:@"x%.2f", scaleValue] : [NSString stringWithFormat:@"x%.1f", scaleValue]);
            if (scaleValue > 1)
            {
                alphaValueString = [NSString stringWithFormat:@"x%.1f", scaleValue];
            }
            [relief3DSection addRowFromDictionary:@{
                kCellKeyKey : @"vertical_exaggeration",
                kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
                kCellTitleKey : OALocalizedString(@"vertical_exaggeration"),
                kCellIconNameKey : @"ic_custom_terrain_scale",
                kCellIconTintColor : [UIColor colorNamed:scaleValue > 1 ? ACColorNameIconColorSelected : ACColorNameIconColorDefault],
                @"value" : alphaValueString,
            }];
        }
        if (_mapItems.count > 0)
        {
            OATableSectionData *availableMapsSection = [_data createNewSection];
            _availableMapsSection = [_data sectionCount] - 1;
            availableMapsSection.headerText = OALocalizedString(@"available_maps");
            availableMapsSection.footerText = OALocalizedString(isHillshade ? @"map_settings_add_maps_hillshade" : @"map_settings_add_maps_slopes");
            for (NSInteger i = 0; i < _mapItems.count; i++)
            {
                [availableMapsSection addRowFromDictionary:@{
                    kCellKeyKey : @"mapItem",
                    kCellTypeKey : @"mapItem",
                    kCellItemKey : _mapItems[i]
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
    [_downloadingCellResourceHelper cleanCellCache];
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
    NSMutableAttributedString *attributedString;

    __weak __typeof(self) weakSelf = self;
    for (NSInteger i = 0; i < TerrainMode.values.count; i++)
    {
        TerrainMode *mode = TerrainMode.values[i];
        if (![mode isDefaultMode])
            continue;

        UIAction *action = [UIAction actionWithTitle:[mode getDescription]
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf.plugin setTerrainMode:mode];
            [weakSelf terrainTypeChanged];
        }];

        if ([mode getKeyName] == [_plugin.terrainModeTypePref get])
        {
            action.state = UIMenuElementStateOn;

            attributedString = [[NSMutableAttributedString alloc] initWithString:action.title];
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightBold];
            UIImage *image = [UIImage systemImageNamed:@"chevron.up.chevron.down" withConfiguration:config];
            image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            attachment.image = image;
            
            NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
            [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
            [attributedString appendAttributedString:attachmentString];
        }

        [menuElements addObject:action];
    }

    if (attributedString)
        [button setAttributedTitle:attributedString forState:UIControlStateNormal];
    return [UIMenu menuWithChildren:menuElements];
}

- (void)setupDownloadingCellHelper
{
    __weak OAMapSettingsTerrainScreen *weakSelf = self;
    _downloadingCellResourceHelper = [DownloadingCellResourceHelper new];
    _downloadingCellResourceHelper.hostViewController = weakSelf.vwController;
    [_downloadingCellResourceHelper setHostTableView:weakSelf.tblView];
    _downloadingCellResourceHelper.delegate = weakSelf;
    _downloadingCellResourceHelper.rightIconStyle = DownloadingCellRightIconTypeHideIconAfterDownloading;
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
            cell.separatorInset = [[_plugin getTerrainMode] isSlope] ? UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.) : UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingOnSideOfContent, 0., 0.);
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
        BOOL isModifyTypeCell = [item.key isEqualToString:@"modifyPalette"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAButtonTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAButtonTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            [cell.button setTitle:nil forState:UIControlStateNormal];
            [cell.button setTitleColor:[UIColor colorNamed:ACColorNameTextColorActive] forState:UIControlStateHighlighted];
            cell.button.tintColor = [UIColor colorNamed:ACColorNameTextColorActive];
            cell.button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        }
        if (cell)
        {
            cell.selectionStyle = isModifyTypeCell ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            [cell setCustomLeftSeparatorInset:isTerrainTypeCell];
            cell.titleLabel.text = item.title;
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];

            if (isTerrainTypeCell)
            {
                cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
                [cell leftIconVisibility:NO];
                cell.leftIconView.image = nil;
                cell.leftIconView.tintColor = nil;
                [cell buttonVisibility:YES];
                cell.button.configuration = nil;
                cell.button.menu = [self createTerrainTypeMenuForCellButton:cell.button];
                cell.button.showsMenuAsPrimaryAction = YES;
                cell.button.changesSelectionAsPrimaryAction = YES;
            }
            else
            {
                cell.separatorInset = UIEdgeInsetsZero;
                [cell leftIconVisibility:item.iconName && item.iconName.length > 0];
                cell.leftIconView.image = cell.leftIconView.hidden ? nil : [UIImage templateImageNamed:item.iconName];
                cell.leftIconView.tintColor = item.iconTintColor;
                cell.button.showsMenuAsPrimaryAction = NO;
                cell.button.changesSelectionAsPrimaryAction = NO;

                BOOL isPurchased = [item boolForKey:@"purchased"];
                [cell buttonVisibility:!isPurchased];
                if (!isPurchased)
                {
                    UIButtonConfiguration *conf = [UIButtonConfiguration plainButtonConfiguration];
                    conf.image = [UIImage imageNamed:item.secondaryIconName];
                    cell.button.configuration = conf;
                }
                else
                {
                    cell.button.configuration = nil;
                }
                cell.button.menu = nil;
                if (!isPurchased)
                    [cell.button addTarget:self action:@selector(showChoosePlanScreen) forControlEvents:UIControlEventTouchUpInside];
            }
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:@"mapItem"])
    {
        OAResourceSwiftItem *mapItem = [[OAResourceSwiftItem alloc] initWithItem:[item objForKey:kCellItemKey]];
        return [_downloadingCellResourceHelper getOrCreateCell:mapItem.resourceId swiftResourceItem:mapItem];
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
            cell.accessoryView = nil;
            BOOL isReadMore = [item.key isEqualToString:@"readMore"];
            [cell leftIconVisibility:!isReadMore];
            [cell descriptionVisibility:!isReadMore];
            cell.titleLabel.textColor = [UIColor colorNamed: isReadMore ? ACColorNameTextColorActive : ACColorNameTextColorPrimary];
            cell.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:isReadMore ? UIFontWeightSemibold : UIFontWeightRegular];
            cell.rightIconView.image = [UIImage templateImageNamed:item.iconName];
            cell.titleLabel.text = item.title;
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
    else if ([item.key isEqualToString:@"modifyPalette"])
        terrainParametersScreen = [[OAMapSettingsTerrainParametersViewController alloc] initWithSettingsType:EOATerrainSettingsTypePalette];
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
        [_downloadingCellResourceHelper onCellClicked:mapItem.resourceId.toNSString()];
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
        [_plugin setTerrainLayerEnabled:isOn];
        if (!isOn)
            _availableMapsSection = -1;
    }
    else if ([item.key isEqualToString:@"relief3D"])
    {
        [_plugin.enable3dMapsPref set:isOn];
    }

    [self updateAvailableMaps];
    [[_app updateGpxTracksOnMapObservable] notifyEvent];
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

#pragma mark - DownloadingCellResourceHelperDelegate

- (void)onDownldedResourceInstalled
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateAvailableMaps];
    });
}

#pragma mark - OAIAPProductNotification

- (void)productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self initData];
        [_downloadingCellResourceHelper cleanCellCache];
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
