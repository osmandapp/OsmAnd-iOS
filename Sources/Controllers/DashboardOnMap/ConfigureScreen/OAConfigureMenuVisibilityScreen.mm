//
//  OAConfigureMenuVisibilityScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAConfigureMenuVisibilityScreen.h"
#import "OAMapWidgetRegistry.h"
#import "OAMapWidgetRegInfo.h"
#import "OAConfigureMenuViewController.h"
#import "Localization.h"
#import "OAIconTextDescCell.h"
#import "OARootViewController.h"
#import "OAColors.h"

@implementation OAConfigureMenuVisibilityScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAMapWidgetRegistry *_mapWidgetRegistry;

    OAMapWidgetRegInfo *_r;
    NSDictionary *_data;
}

@synthesize configureMenuScreen, tableData, vwController, tblView, title;

- (id) initWithTable:(UITableView *)tableView viewController:(OAConfigureMenuViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _mapWidgetRegistry = [OARootViewController instance].mapPanel.mapWidgetRegistry;

        _key = param;
        if (_key)
            _r = [_mapWidgetRegistry widgetByKey:_key];
        
        if (_r)
            title = [_r getMessage];

        configureMenuScreen = EConfigureMenuScreenVisibility;
        
        vwController = viewController;
        tblView = tableView;

        [self commonInit];
        [self initData];
    }
    return self;
}

- (void) dealloc
{
    [self deinit];
}

- (void) commonInit
{
}

- (void) deinit
{
}

- (void) initData
{
    _data = [NSDictionary dictionary];
}

- (NSDictionary *)createTableItem:(NSString *)itemTitle
                      description:(NSString *)description
                              key:(NSString *)key
                             icon:(NSString *)icon
                         selected:(BOOL)selected
{
    return @{
            @"title": itemTitle,
            @"description": description,
            @"key": key,
            @"img": icon,
            @"selected": @(selected),
            @"color": selected ? UIColorFromRGB(color_osmand_orange) : UIColorFromRGB(color_footer_icon_gray),
            @"type": [OAIconTextDescCell getCellIdentifier]
    };
}

- (void) setupView
{
    if (_r)
    {
        OAApplicationMode *mode = [OAAppSettings sharedManager].applicationMode.get;
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        NSMutableArray<NSDictionary *> *additionalList = [NSMutableArray array];

        if ([_r getItemIds])
        {
            for (int i = 0; i < [_r getItemIds].count; i++)
            {
                NSString *itemId = [_r getItemIds][i];
                NSString *messageId = [_r getMessages][i];
                NSString *imageId = [_r getImageIds][i];
                BOOL selected = [[_r getItemId] isEqualToString:itemId];

                NSString *descriptionId = @"";
                NSArray<NSString *> *descriptions = [_r getDescriptions];
                if (descriptions)
                    descriptionId = [_r getDescriptions][i];

                [additionalList addObject:[self createTableItem:OALocalizedString(messageId)
                                                    description:OALocalizedString(descriptionId)
                                                            key:itemId
                                                           icon:imageId
                                                       selected:selected]];
            }
        }

        if (additionalList.count > 0)
            data[@"additional"] = additionalList;

        if (![_r.key isEqualToString:@"compass"])
        {
            NSMutableArray<NSDictionary *> *standardList = [NSMutableArray array];

            BOOL showSelected = ![_r visibleCollapsed:mode] && [_r visible:mode];
            BOOL hideSelected = ![_r visibleCollapsed:mode] && ![_r visible:mode];
            BOOL collapsedSelected = [_r visibleCollapsed:mode];

            [standardList addObject:[self createTableItem:OALocalizedString(@"recording_context_menu_show")
                                              description:@""
                                                      key:@"action_show"
                                                     icon:@"ic_action_view"
                                                 selected:showSelected]];
            [standardList addObject:[self createTableItem:OALocalizedString(@"shared_string_hide")
                                              description:@""
                                                      key:@"action_hide"
                                                     icon:@"ic_action_hide"
                                                 selected:hideSelected]];
            [standardList addObject:[self createTableItem:OALocalizedString(@"shared_string_collapse")
                                              description:@""
                                                      key:@"action_collapse"
                                                     icon:@"ic_action_widget_collapse"
                                                 selected:collapsedSelected]];

            data[@"standard"] = standardList;
        }

        _data = data;
    }
}

- (void) setVisibility:(BOOL)visible collapsed:(BOOL)collapsed
{
    if (_r)
    {
        [_mapWidgetRegistry setVisibility:_r visible:visible collapsed:collapsed];
        [[OARootViewController instance].mapPanel recreateControls];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data[_data.allKeys[section]] count];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[_data.allKeys[indexPath.section]][indexPath.row];
    OAIconTextDescCell *cell = [tblView dequeueReusableCellWithIdentifier:[OAIconTextDescCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextDescCell getCellIdentifier] owner:self options:nil];
        cell = (OAIconTextDescCell *) nib[0];
        cell.textView.numberOfLines = 0;
        cell.descView.font = [UIFont systemFontOfSize:15.];
        cell.separatorInset = UIEdgeInsetsMake(0., 66., 0., 0.);
    }
    if (cell)
    {
        cell.textView.text = item[@"title"];

        NSString *description = item[@"description"];
        cell.descView.hidden = description.length == 0;
        cell.descView.text = description;

        NSString *imageName = item[@"img"];
        if (imageName)
        {
            UIColor *color = nil;
            if (item[@"color"] != [NSNull null])
                color = item[@"color"];

            if (color)
                cell.iconView.image = [UIImage templateImageNamed:imageName];
            else
                cell.iconView.image = [UIImage imageNamed:imageName];

            cell.iconView.tintColor = color;
        }
        cell.textView.text = item[@"title"];

        BOOL selected = [item[@"selected"] boolValue];
        cell.arrowIconView.tintColor = UIColorFromRGB(color_primary_purple);
        cell.arrowIconView.image = selected ? [UIImage templateImageNamed:@"menu_cell_selected"] : nil;

        if ([cell needsUpdateConstraints])
            [cell updateConstraints];
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [_data.allKeys containsObject:@"additional"] ? [_r getDescription] : nil;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[_data.allKeys[indexPath.section]][indexPath.row];
    NSString *key = item[@"key"];
    if ([key isEqualToString:@"action_show"])
    {
        [self setVisibility:YES collapsed:NO];
    }
    else if ([key isEqualToString:@"action_hide"])
    {
        [self setVisibility:NO collapsed:NO];
    }
    else if ([key isEqualToString:@"action_collapse"])
    {
        [self setVisibility:YES collapsed:YES];
    }
    else if (_r)
    {
        NSArray<NSString *> *menuItemIds = [_r getItemIds];
        if (menuItemIds)
        {
            for (NSString *menuItemId in menuItemIds)
            {
                if ([key isEqualToString:menuItemId])
                {
                    [_r changeState:menuItemId];
                    [[OARootViewController instance].mapPanel recreateControls];
                }
            }
        }
    }

    [self setupView];
    [tableView reloadRowsAtIndexPaths:[tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationFade];
}

@end
