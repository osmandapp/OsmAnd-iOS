//
//  OANavigationSettingsViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 07/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OANavigationSettingsViewController.h"
#import "OASettingsTableViewCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"

#include <generalRouter.h>

#define kCellTypeSwitch @"switch"
#define kCellTypeSingleSelList @"single_selection_list"
#define kCellTypeMultiSelList @"multi_selection_list"

@interface OANavigationSettingsViewController ()

@end

@implementation OANavigationSettingsViewController
{
    NSDictionary *_data;
}

- (id) initWithSettingsType:(kNavigationSettingsScreen)settingsType
{
    self = [super init];
    if (self)
    {
        _settingsType = settingsType;
    }
    return self;
}

-(void) applyLocalization
{
    _titleView.text = OALocalizedString(@"routing_settings");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [self setupView];
}

- (void) setupView
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    switch (self.settingsType)
    {
        case kNavigationSettingsScreenGeneral:
        {
            NSMutableArray *dataArr = [NSMutableArray array];
            data[OALocalizedString(@"routing_preferences_descr")] = dataArr;

            OAApplicationMode *am = settings.applicationMode;
            auto router = [self getRouter:am];
            //clearParameters();
            if (router)
            {
                auto& parameters = router->getParameters();
                if (parameters.find("short_way") != parameters.end())
                {
                    [dataArr addObject:
                     @{
                       @"name" : @"fastRouteMode",
                       @"title": OALocalizedString(@"fast_route_mode"),
                       @"description" : OALocalizedString(@"fast_route_mode_descr"),
                       @"value" : settings.fastRouteMode,
                       @"type": kCellTypeSwitch
                       }
                     ];
                }
                BOOL avoidParameters = NO;
                BOOL preferParameters = NO;
                BOOL reliefFactorParameters = NO;
                NSString *reliefFactorParameterGroup = nil;
                vector<RoutingParameter> others;
                for (auto it = parameters.begin() ; it != parameters.end(); ++it)
                {
                    NSString *param = [NSString stringWithUTF8String:it->first.c_str()];
                    auto& routingParameter = it->second;
                    if ([param hasPrefix:@"avoid_"])
                    {
                        avoidParameters = YES;
                    }
                    else if ([param hasPrefix:@"prefer_"])
                    {
                        preferParameters = YES;
                    }
                    else if ("relief_smoothness_factor" == routingParameter.group)
                    {
                        reliefFactorParameters = YES;
                        if (!reliefFactorParameterGroup)
                            reliefFactorParameterGroup = [NSString stringWithUTF8String:routingParameter.group.c_str()];
                    }
                    else if (![param isEqualToString:@"short_way"] && "driving_style" != routingParameter.group)
                    {
                        others.push_back(routingParameter);
                    }
                }
                if (avoidParameters)
                {
                    [dataArr addObject:
                     @{
                       @"name" : @"avoidRouting",
                       @"title": OALocalizedString(@"avoid_in_routing_title"),
                       @"description" : OALocalizedString(@"avoid_in_routing_descr"),
                       @"type": kCellTypeMultiSelList
                       }
                     ];
                }
                if (preferParameters)
                {
                    [dataArr addObject:
                     @{
                       @"name" : @"preferRouting",
                       @"title": OALocalizedString(@"prefer_in_routing_title"),
                       @"description" : OALocalizedString(@"prefer_in_routing_descr"),
                       @"type": kCellTypeMultiSelList
                       }
                     ];
                }
                if (reliefFactorParameters)
                {
                    [dataArr addObject:
                     @{
                       @"name" : @"preferRouting",
                       @"title": [self getRoutingStringPropertyName:reliefFactorParameterGroup],
                       @"description" : OALocalizedString(@"relief_smoothness_factor_descr"),
                       @"type": kCellTypeSingleSelList
                       }
                     ];
                }
                for (auto& p : others)
                {
                    NSString *paramId = [NSString stringWithUTF8String:p.id.c_str()];
                    NSString *title = [self getRoutingStringPropertyName:paramId defaultName:[NSString stringWithUTF8String:p.name.c_str()]];
                    NSString *description = [self getRoutingStringPropertyDescription:paramId defaultName:[NSString stringWithUTF8String:p.description.c_str()]];

                    if (p.type == RoutingParameterType::BOOLEAN)
                    {
                        OAProfileBoolean *booleanParam = [settings getCustomRoutingBooleanProperty:paramId defaultValue:p.defaultBoolean];

                        [dataArr addObject:
                         @{
                           @"name" : paramId,
                           @"title": title,
                           @"description" : description,
                           @"value" : booleanParam,
                           @"type": kCellTypeSwitch
                           }
                         ];
                    }
                    else
                    {
                        OAProfileString *stringParam = [settings getCustomRoutingProperty:paramId defaultValue:p.type == RoutingParameterType::NUMERIC ? @"0.0" : @"-"];
                        
                        [dataArr addObject:
                         @{
                           @"name" : paramId,
                           @"title": title,
                           @"description" : description,
                           @"value" : stringParam,
                           @"type": kCellTypeSingleSelList
                           }
                         ];
                    }
                }
            }
            
            dataArr = [NSMutableArray array];
            data[OALocalizedString(@"guidance_preferences_descr")] = dataArr;
            
            [dataArr addObject:
             @{
               @"name" : @"auto_follow_route",
               @"title": OALocalizedString(@"choose_auto_follow_route"),
               @"description" : OALocalizedString(@"choose_auto_follow_route_descr"),
               @"type": kCellTypeSingleSelList
               }
             ];

            [dataArr addObject:
             @{
               @"name" : @"auto_zoom_map_on_off",
               @"title": OALocalizedString(@"auto_zoom_map"),
               @"description" : OALocalizedString(@"auto_zoom_map_descr"),
               @"type": kCellTypeSingleSelList
               }
             ];


            break;
        }
        case kNavigationSettingsScreenAvoidRouting:
        {
            /*
            _titleView.text = OALocalizedString(@"do_not_send_anonymous_data");
            self.data = @[@{@"name": OALocalizedString(@"shared_string_yes"), @"value": @"", @"img": settings.settingDoNotUseFirebase ? @"menu_cell_selected.png" : @""},
                          @{@"name": OALocalizedString(@"shared_string_no"), @"value": @"", @"img": !settings.settingDoNotUseFirebase ? @"menu_cell_selected.png" : @""}
                          ];
             */
            break;
        }
        default:
            break;
    }
    
    _data = [NSDictionary dictionaryWithDictionary:data];
}

- (std::shared_ptr<GeneralRouter>) getRouter:(OAApplicationMode *)am
{
    OsmAndAppInstance app = [OsmAndApp instance];
    auto router = app.defaultRoutingConfig->getRouter([am.stringKey UTF8String]);
    if (!router && am.parent)
        router = app.defaultRoutingConfig->getRouter([am.parent.stringKey UTF8String]);
    
    return router;
}

- (NSString *) getRoutingStringPropertyName:(NSString *)propertyName
{
    NSString *key = [NSString stringWithFormat:@"routing_attr_%@_name", propertyName];
    NSString *res = OALocalizedString(key);
    if ([res isEqualToString:key])
        res = [[propertyName stringByReplacingOccurrencesOfString:@"_" withString:@" "] capitalizedStringWithLocale:[NSLocale currentLocale]];
    
    return res;
}

- (NSString *) getRoutingStringPropertyName:(NSString *)propertyName defaultName:(NSString *)defaultName
{
    NSString *key = [NSString stringWithFormat:@"routing_attr_%@_name", propertyName];
    NSString *res = OALocalizedString(key);
    if ([res isEqualToString:key])
        res = defaultName;
    
    return res;
}

- (NSString *) getRoutingStringPropertyDescription:(NSString *)propertyName defaultName:(NSString *)defaultName
{
    NSString *key = [NSString stringWithFormat:@"routing_attr_%@_description", propertyName];
    NSString *res = OALocalizedString(key);
    if ([res isEqualToString:key])
        res = defaultName;
    
    return res;
}

@end
