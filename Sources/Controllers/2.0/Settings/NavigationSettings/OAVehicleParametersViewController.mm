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
#import "OASettingsTitleTableViewCell.h"
#import "OANavigationTypeViewController.h"
#import "OARouteParametersViewController.h"
#import "OAVoicePromptsViewController.h"
#import "OAScreenAlertsViewController.h"
#import "OASettingsModalPresentationViewController.h"
#import "OAVehicleParametersSettingsViewController.h"
#import "OADefaultSpeedViewController.h"
#import "OARouteSettingsBaseViewController.h"

#import "Localization.h"
#import "OAColors.h"

#define kCellTypeIconTitleValue @"OAIconTitleValueCell"
#define kCellTypeIconText @"OAIconTextCell"

@interface OAVehicleParametersViewController () <UITableViewDelegate, UITableViewDataSource>

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
    self.titleLabel.text = OALocalizedString(@"vehicle_parameters");
    self.subtitleLabel.text = self.appMode.name;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self setupView];
}

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *parametersArr = [NSMutableArray array];
    NSMutableArray *defaultSpeedArr = [NSMutableArray array];
    auto router = [self.class getRouter:self.appMode];
    if (router)
    {
        auto& parameters = router->getParametersList();
        for (const auto& p : parameters)
        {
            NSString *param = [NSString stringWithUTF8String:p.id.c_str()];
            if (![param hasPrefix:@"avoid_"] && ![param hasPrefix:@"prefer_"] &&![param isEqualToString:@"short_way"] && "driving_style" != p.group)
                _otherParameters.push_back(p);
        }
        for (auto& p : _otherParameters)
        {
            NSString *paramId = [NSString stringWithUTF8String:p.id.c_str()];
            NSString *title = [self getRoutingStringPropertyName:paramId defaultName:[NSString stringWithUTF8String:p.name.c_str()]];
            //NSArray *possibleValues = p.possibleValues;
            //NSString *description = [self getRoutingStringPropertyDescription:paramId defaultName:[NSString stringWithUTF8String:p.description.c_str()]];

            if (!(p.type == RoutingParameterType::BOOLEAN))
            {
                OAProfileString *stringParam = [_settings getCustomRoutingProperty:paramId defaultValue:p.type == RoutingParameterType::NUMERIC ? @"0.0" : @"-"];
                NSString *value = [stringParam get:self.appMode];
                NSMutableArray *possibleValues = [NSMutableArray array];
                NSMutableArray *possibleValuesDescr = [NSMutableArray array];
                double d = value ? floorf(value.doubleValue * 100 + 0.5) / 100 : DBL_MAX;
                int index = -1;
                
                for (int i = 0; i < p.possibleValues.size(); i++)
                {
                    double vl = floorf(p.possibleValues[i] * 100 + 0.5) / 100;
                    [possibleValues addObject:[NSString stringWithFormat:@"%f", vl]];
                    [possibleValuesDescr addObject:[NSString stringWithUTF8String:p.possibleValueDescriptions[i].c_str()]];
                    if (vl == d)
                    {
                        index = i;
                        //break;
                    }
                }
                if (index != -1)
                    value = [NSString stringWithUTF8String:p.possibleValueDescriptions[index].c_str()];
                [parametersArr addObject:
                    @{
                    @"name" : paramId,
                    @"title" : title,
                    @"value" : value,
                    @"icon" : [self getParameterIcon:paramId],
                    @"possibleValues" : possibleValues,
                    @"possibleValuesDescr" : possibleValuesDescr,
                    @"type" : kCellTypeIconTitleValue }
                    ];
            }
        }
    }
    [defaultSpeedArr addObject:@{
        @"type" : kCellTypeIconText,
        @"title" : OALocalizedString(@"default_speed"),
        @"icon" : @"ic_action_speed",
        @"name" : @"defaultSpeed",
        
    }];
    [tableData addObject:parametersArr];
    [tableData addObject:defaultSpeedArr];
    _data = [NSArray arrayWithArray:tableData];
}

+ (std::shared_ptr<GeneralRouter>) getRouter:(OAApplicationMode *)am
{
    OsmAndAppInstance app = [OsmAndApp instance];
    auto router = app.defaultRoutingConfig->getRouter([am.stringKey UTF8String]);
    if (!router && am.parent)
        router = app.defaultRoutingConfig->getRouter([am.parent.stringKey UTF8String]);
    return router;
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
    if ([cellType isEqualToString:kCellTypeIconTitleValue])
    {
        static NSString* const identifierCell = kCellTypeIconTitleValue;
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            cell.leftImageView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.leftImageView.tintColor = [item[@"value"] isEqualToString:@"-"] ? UIColorFromRGB(color_icon_inactive) : UIColorFromRGB(color_osmand_orange);
        }
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypeIconText])
    {
        static NSString* const identifierCell = kCellTypeIconText;
        OAIconTextTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.arrowIconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.arrowIconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.iconView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_icon_inactive);
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
    if ([itemName isEqualToString:@"weight"])
        settingsViewController = [[OAVehicleParametersSettingsViewController alloc] initWithApplicationMode:self.appMode vehicleParameter:item];
    else if ([itemName isEqualToString:@"height"])
        settingsViewController = [[OAVehicleParametersSettingsViewController alloc] initWithApplicationMode:self.appMode vehicleParameter:item];
    else if ([itemName isEqualToString:@"width"])
        settingsViewController = [[OAVehicleParametersSettingsViewController alloc] initWithApplicationMode:self.appMode vehicleParameter:item];
    else if ([itemName isEqualToString:@"length"])
        settingsViewController = [[OAVehicleParametersSettingsViewController alloc] initWithApplicationMode:self.appMode vehicleParameter:item];
    else if ([itemName isEqualToString:@"defaultSpeed"])
        settingsViewController = [[OADefaultSpeedViewController alloc] initWithApplicationMode:self.appMode];
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
    return section == 0 ? @"" : OALocalizedString(@"announce");
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return section == 0 ? OALocalizedString(@"touting_specified_vehicle_parameters_descr") : OALocalizedString(@"default_speed_descr");
}

@end
