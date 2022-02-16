//
//  OAVehicleParametersViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 27.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAVehicleParametersViewController.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"
#import "OAIconTitleValueCell.h"
#import "OAIconTextTableViewCell.h"
#import "OANavigationTypeViewController.h"
#import "OARouteParametersViewController.h"
#import "OAVoicePromptsViewController.h"
#import "OAScreenAlertsViewController.h"
#import "OASettingsModalPresentationViewController.h"
#import "OAVehicleParametersSettingsViewController.h"
#import "OADefaultSpeedViewController.h"
#import "OARouteSettingsBaseViewController.h"
#import "OARouteProvider.h"
#import "OARoutePreferencesParameters.h"

#import "Localization.h"
#import "OAColors.h"

@interface OAVehicleParametersViewController () <UITableViewDelegate, UITableViewDataSource, OAVehicleParametersSettingDelegate>

@end

@implementation OAVehicleParametersViewController
{
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;
    vector<RoutingParameter> _otherParameters;
}

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super initWithAppMode:appMode];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

-(void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"vehicle_parameters");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16., 0., 0.);
    [self setupView];
}

- (NSString *)addSpaceToValue:(NSString *)descr
{
    NSString *editedDescr;
    NSRange range = [descr rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
    if (range.location != NSNotFound && descr.length > 1)
        editedDescr = [[[descr substringToIndex:range.location] stringByAppendingString:@" "] stringByAppendingString:[descr substringFromIndex:range.location]];
    else
        editedDescr = descr;
    return editedDescr;
}

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *parametersArr = [NSMutableArray array];
    NSMutableArray *defaultSpeedArr = [NSMutableArray array];
    auto router = [OsmAndApp.instance getRouter:self.appMode];
    _otherParameters.clear();
    NSString *appModeRoutingProfile = self.appMode.getRoutingProfile;
    NSString *parentAppModeRoutingProfile = self.appMode.parent.getRoutingProfile;
    
    if (router && ![appModeRoutingProfile isEqualToString:OAApplicationMode.PUBLIC_TRANSPORT.stringKey] &&
        ![appModeRoutingProfile isEqualToString:OAApplicationMode.SKI.stringKey] &&
        ![parentAppModeRoutingProfile isEqualToString:OAApplicationMode.PUBLIC_TRANSPORT.stringKey] &&
        ![parentAppModeRoutingProfile isEqualToString:OAApplicationMode.SKI.stringKey])
    {
        auto& parameters = router->getParametersList();
        for (const auto& p : parameters)
        {
            NSString *param = [NSString stringWithUTF8String:p.id.c_str()];
            NSString *group = [NSString stringWithUTF8String:p.group.c_str()];
            if (![param hasPrefix:@"avoid_"] && ![param hasPrefix:@"prefer_"] && ![param isEqualToString:kRouteParamIdShortWay] && ![group isEqualToString:kRouteParamGroupDrivingStyle])
                _otherParameters.push_back(p);
        }
        for (const auto& p : _otherParameters)
        {
            NSString *paramId = [NSString stringWithUTF8String:p.id.c_str()];
            NSString *title = [self getRoutingStringPropertyName:paramId defaultName:[NSString stringWithUTF8String:p.name.c_str()]];
            if (!(p.type == RoutingParameterType::BOOLEAN))
            {
                OACommonString *stringParam = [_settings getCustomRoutingProperty:paramId defaultValue:@"0"];
                NSString *value = [stringParam get:self.appMode];
                int index = -1;
                
                NSMutableArray<NSNumber *> *possibleValues = [NSMutableArray new];
                NSMutableArray<NSString *> *valueDescriptions = [NSMutableArray new];
                
                double d = value ? floorf(value.doubleValue * 100 + 0.5) / 100 : DBL_MAX;
                
                for (int i = 0; i < p.possibleValues.size(); i++)
                {
                    double vl = floorf(p.possibleValues[i] * 100 + 0.5) / 100;
                    [possibleValues addObject:@(vl)];
                    NSString *descr = [NSString stringWithUTF8String:p.possibleValueDescriptions[i].c_str()];
                    NSString *editedDescr = [self addSpaceToValue:descr];
                    [valueDescriptions addObject:editedDescr];
                    if (vl == d)
                    {
                        index = i;
                    }
                }

                if (index == 0)
                    value = OALocalizedString(@"shared_string_none");
                else if (index != -1)
                    value = [self addSpaceToValue:[NSString stringWithUTF8String:p.possibleValueDescriptions[index].c_str()]];
                else
                    value = [NSString stringWithFormat:@"%@ %@", value, [paramId isEqualToString:@"weight"] ? OALocalizedString(@"units_t") : OALocalizedString(@"units_m")];
                [parametersArr addObject:
                 @{
                     @"name" : paramId,
                     @"title" : title,
                     @"value" : value,
                     @"selectedItem" : [NSNumber numberWithInt:index],
                     @"icon" : [self getParameterIcon:paramId],
                     @"possibleValues" : possibleValues,
                     @"possibleValuesDescr" : valueDescriptions,
                     @"setting" : stringParam,
                     @"type" : [OAIconTitleValueCell getCellIdentifier] }
                 ];
            }
        }
    }
    [defaultSpeedArr addObject:@{
        @"type" : [OAIconTextTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"default_speed"),
        @"icon" : @"ic_action_speed",
        @"name" : @"defaultSpeed",
    }];
    if (parametersArr.count > 0)
        [tableData addObject:parametersArr];
    if (defaultSpeedArr.count > 0)
        [tableData addObject:defaultSpeedArr];
    _data = [NSArray arrayWithArray:tableData];
}

- (NSString *) getRoutingStringPropertyName:(NSString *)propertyName defaultName:(NSString *)defaultName
{
    NSString *key = [NSString stringWithFormat:@"routing_attr_%@_name", propertyName];
    NSString *res = OALocalizedString(key);
    if ([res isEqualToString:key])
        res = defaultName;
    return res;
}

- (NSString *) getParameterIcon:(NSString *)parameterName
{
    if ([parameterName isEqualToString:@"weight"])
        return @"ic_custom_weight_limit";
    else if ([parameterName isEqualToString:@"height"])
        return @"ic_custom_height_limit";
    else if ([parameterName isEqualToString:@"length"])
        return @"ic_custom_length_limit";
    else if ([parameterName isEqualToString:@"width"])
        return @"ic_custom_width_limit";
    return @"";
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            cell.rightIconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
            cell.leftIconView.tintColor = [item[@"selectedItem"] intValue] == 0 ? UIColorFromRGB(color_icon_inactive) : UIColorFromRGB(self.appMode.getIconColor);
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAIconTextTableViewCell getCellIdentifier]])
    {
        OAIconTextTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.arrowIconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            cell.arrowIconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.iconView.image = [UIImage templateImageNamed:item[@"icon"]];
            cell.iconView.tintColor = UIColorFromRGB(self.appMode.getIconColor);
        }
        return cell;
    }
    return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *itemName = item[@"name"];
    OASettingsModalPresentationViewController* settingsViewController = nil;
    if ([itemName isEqualToString:@"defaultSpeed"])
        settingsViewController = [[OADefaultSpeedViewController alloc] initWithApplicationMode:self.appMode speedParameters:item];
    else
        settingsViewController = [[OAVehicleParametersSettingsViewController alloc] initWithApplicationMode:self.appMode vehicleParameter:item];
    
    settingsViewController.delegate = self;
    [self presentViewController:settingsViewController animated:YES completion:nil];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? @"" : OALocalizedString(@"help_other_header");
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return section == 0 ? OALocalizedString(@"touting_specified_vehicle_parameters_descr") : OALocalizedString(@"default_speed_descr");
}

-(void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *vw = (UITableViewHeaderFooterView *) view;
    [vw.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

#pragma mark - OAVehicleParametersSettingDelegate

- (void) onSettingsChanged
{
    [self setupView];
    [self.tableView reloadData];
}

@end
