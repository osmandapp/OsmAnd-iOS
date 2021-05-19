//
//  OACopyProfileBottomSheetViewControler.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 05.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACopyProfileBottomSheetViewControler.h"
#import "OAAppSettings.h"
#import "OAIconTitleIconRoundCell.h"
#import "OAUtilities.h"
#import "OASettingsHelper.h"
#import "OAMapStyleSettings.h"
#import "OARouteProvider.h"
#import "OAMapWidgetRegInfo.h"
#import "OAMapWidgetRegistry.h"
#import "OARootViewController.h"
#import "OsmAndApp.h"
#import "OAAppData.h"

#import "Localization.h"
#import "OAColors.h"
#import "OASizes.h"

@interface OACopyProfileBottomSheetViewControler()

@end

@implementation OACopyProfileBottomSheetViewControler
{
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;
    OAApplicationMode *_targetAppMode;
    OAApplicationMode *_sourceAppMode;
    NSInteger _selectedModeIndex;
}

- (instancetype) initWithMode:(OAApplicationMode *)am
{
    self = [super init];
    if (self)
    {
        _targetAppMode = am;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, 0.01f)];
    [self.tableView setShowsVerticalScrollIndicator:YES];
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    self.tableView.layer.cornerRadius = 12.;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
}

- (void) applyLocalization
{
    self.titleView.text = OALocalizedString(@"copy_from_other_profile");
    [self.leftButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.rightButton setTitle:OALocalizedString(@"shared_string_copy") forState:UIControlStateNormal];
}

- (void) commonInit
{
    _settings = [OAAppSettings sharedManager];
    [self generateData];
}

- (void) generateData
{
    NSMutableArray *dataArr = [NSMutableArray array];
    
    for (OAApplicationMode *am in OAApplicationMode.allPossibleValues)
    {
        if ([am.stringKey isEqualToString:_targetAppMode.stringKey])
            continue;
        [dataArr addObject:@{
            @"type" : [OAIconTitleIconRoundCell getCellIdentifier],
            @"app_mode" : am,
            @"selected" : @(_sourceAppMode == am),
        }];
    }
    _data = [NSArray arrayWithObject:dataArr];
    
    self.rightButton.userInteractionEnabled = _sourceAppMode;
    self.rightButton.backgroundColor = _sourceAppMode ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_route_button_inactive);
    [self.rightButton setTintColor:_sourceAppMode ? UIColor.whiteColor : UIColorFromRGB(color_text_footer)];
    [self.rightButton setTitleColor:_sourceAppMode ? UIColor.whiteColor : UIColorFromRGB(color_text_footer) forState:UIControlStateNormal];
}

- (void) onRightButtonPressed
{
    [self copyProfile];
    if (self.delegate)
        [self.delegate onCopyProfileCompleted];
    [super onRightButtonPressed];
}

- (void) copyRegisteredPreferences
{
    for (NSString *key in _settings.getRegisteredSettings)
    {
        OACommonPreference *setting = [_settings.getRegisteredSettings objectForKey:key];
        if (setting)
            [setting copyValueFromAppMode:_sourceAppMode targetAppMode:_targetAppMode];
    }
}

- (void) copyRoutingPreferences
{
    const auto router = [OsmAndApp.instance getRouter:_sourceAppMode];
    if (router)
    {
        const auto& parameters = router->getParametersList();
        for (const auto& p : parameters)
        {
            if (p.type == RoutingParameterType::BOOLEAN)
            {
                OACommonBoolean *boolSetting = [_settings getCustomRoutingBooleanProperty:[NSString stringWithUTF8String:p.id.c_str()] defaultValue:p.defaultBoolean];
                [boolSetting set:[boolSetting get:_sourceAppMode] mode:_targetAppMode];
            }
            else
            {
                OACommonString *stringSetting = [_settings getCustomRoutingProperty:[NSString stringWithUTF8String:p.id.c_str()] defaultValue:p.type == RoutingParameterType::NUMERIC ? @"0.0" : @"-"];
                [stringSetting set:[stringSetting get:_sourceAppMode] mode:_targetAppMode];
            }
        }
    }
}

- (void) copyRenderingPreferences
{
    OAMapStyleSettings *sourceStyleSettings = [self getMapStyleSettingsForMode:_sourceAppMode];
    OAMapStyleSettings *targetStyleSettings = [self getMapStyleSettingsForMode:_targetAppMode];
    
    for (OAMapStyleParameter *param in [sourceStyleSettings getAllParameters])
    {
        OAMapStyleParameter *p = [targetStyleSettings getParameter:param.name];
        if (p)
        {
            p.value = param.value;
            [targetStyleSettings save:p refreshMap:NO];
        }
    }
}

- (NSString *) getRendererByName:(NSString *)rendererName
{
    if ([rendererName isEqualToString:@"OsmAnd"])
        return @"default";
    else if ([rendererName isEqualToString:@"Touring view (contrast and details)"])
        return @"Touring-view_(more-contrast-and-details)";
    else if (![rendererName isEqualToString:@"LightRS"] && ![rendererName isEqualToString:@"UniRS"])
        return [rendererName lowerCase];
    
    return rendererName;
}

- (OAMapStyleSettings *) getMapStyleSettingsForMode:(OAApplicationMode *)am
{
    NSString *renderer = [OAAppSettings.sharedManager.renderer get:am];
    NSString *resName = [self getRendererByName:renderer];
    return [[OAMapStyleSettings alloc] initWithStyleName:resName mapPresetName:am.variantKey];
}

- (void) copyMapWidgetRegistryPreference
{
    OAMapWidgetRegistry *mapWidgetRegistry = [OARootViewController instance].mapPanel.mapWidgetRegistry;
    for (OAMapWidgetRegInfo *r in [mapWidgetRegistry getLeftWidgetSet])
    {
        [mapWidgetRegistry setVisibility:_targetAppMode m:r visible:[r visible:_sourceAppMode] collapsed:[r visibleCollapsed:_sourceAppMode]];
    }
    for (OAMapWidgetRegInfo *r in [mapWidgetRegistry getRightWidgetSet])
    {
        [mapWidgetRegistry setVisibility:_targetAppMode m:r visible:[r visible:_sourceAppMode] collapsed:[r visibleCollapsed:_sourceAppMode]];
    }
}

- (void) copyProfile
{
    OsmAndAppInstance app = [OsmAndApp instance];
    
    [self copyRegisteredPreferences];
    [self copyRoutingPreferences];
    [app.data copyAppDataFrom:_sourceAppMode toMode:_targetAppMode];
    [self copyRenderingPreferences];
    [self copyMapWidgetRegistryPreference];
    
    if ([_targetAppMode isCustomProfile])
        [_targetAppMode setParent: [_sourceAppMode isCustomProfile] ? _sourceAppMode.parent : _sourceAppMode];
    [_targetAppMode setIconName:_sourceAppMode.getIconName];
    [_targetAppMode setRoutingProfile:_sourceAppMode.getRoutingProfile];
    [_targetAppMode setRouterService:_sourceAppMode.getRouterService];
    [_targetAppMode setIconColor:_sourceAppMode.getIconColor];
    [_targetAppMode setLocationIcon:_sourceAppMode.getLocationIcon];
    [_targetAppMode setNavigationIcon:_sourceAppMode.getNavigationIcon];
    [_targetAppMode setBaseMinSpeed:_sourceAppMode.baseMinSpeed];
    [_targetAppMode setBaseMaxSpeed:_sourceAppMode.baseMaxSpeed];
    
    [app.data.mapLayerChangeObservable notifyEvent];
}

#pragma mark - Table View

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    
    if ([item[@"type"] isEqualToString:[OAIconTitleIconRoundCell getCellIdentifier]])
    {
        OAIconTitleIconRoundCell* cell = nil;
        OAApplicationMode *am = item[@"app_mode"];
        
        cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleIconRoundCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleIconRoundCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleIconRoundCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.secondaryImageView.image = [UIImage templateImageNamed:@"ic_checkmark_default"];
            cell.secondaryImageView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleView.text = am.toHumanString;
            UIImage *img = am.getIcon;
            cell.iconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(am.getIconColor);
            cell.secondaryImageView.hidden = ![item[@"selected"] boolValue];
            [cell roundCorners:(indexPath.row == 0) bottomCorners:(indexPath.row == OAApplicationMode.allPossibleValues.count - 2)];
            cell.separatorView.hidden = indexPath.row == OAApplicationMode.allPossibleValues.count - 2;
        }
        return cell;
    }
    return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    _sourceAppMode = item[@"app_mode"];
    [self generateData];
    [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section], [NSIndexPath indexPathForRow:_selectedModeIndex inSection:indexPath.section]] withRowAnimation:(UITableViewRowAnimation)UITableViewRowAnimationFade];
    _selectedModeIndex = indexPath.row;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat labelHeight = [OAUtilities heightForHeaderViewText:[NSString stringWithFormat:@"%@%@.", OALocalizedString(@"copy_from_other_profile_descr"), _targetAppMode.toHumanString] width:tableView.bounds.size.width - 32 font:[UIFont systemFontOfSize:15] lineSpacing:6.];
    return labelHeight + 32;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *descriptionString = [NSString stringWithFormat:@"%@%@.", OALocalizedString(@"copy_from_other_profile_descr"), _targetAppMode.toHumanString];
    CGFloat textWidth = tableView.bounds.size.width - 32;
    CGFloat heightForHeader = [OAUtilities heightForHeaderViewText:descriptionString width:textWidth font:[UIFont systemFontOfSize:15] lineSpacing:6.] + 16;
    UIView *vw = [[UIView alloc] initWithFrame:CGRectMake(0., 0., tableView.bounds.size.width, heightForHeader)];
    UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(16., 8., textWidth, heightForHeader)];
    description.attributedText = [OAUtilities getStringWithBoldPart:descriptionString mainString:OALocalizedString(@"copy_from_other_profile_descr") boldString:_targetAppMode.toHumanString lineSpacing:4.];
    description.textColor = UIColorFromRGB(color_text_footer);
    description.numberOfLines = 0;
    description.lineBreakMode = NSLineBreakByWordWrapping;
    description.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [vw addSubview:description];
    return vw;
}

@end
